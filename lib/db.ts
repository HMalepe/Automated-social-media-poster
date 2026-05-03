import * as SQLite from 'expo-sqlite';
import { Product, InventoryItem, Sale, SaleItem, SyncQueueEntry } from '@/types';

let _db: SQLite.SQLiteDatabase | null = null;

export async function getDb(): Promise<SQLite.SQLiteDatabase> {
  if (_db) return _db;
  _db = await SQLite.openDatabaseAsync('spaza.db');
  await initSchema(_db);
  return _db;
}

async function initSchema(db: SQLite.SQLiteDatabase): Promise<void> {
  await db.execAsync(`
    PRAGMA journal_mode = WAL;
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS products (
      id TEXT PRIMARY KEY,
      barcode TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      category TEXT,
      default_price REAL NOT NULL,
      image_url TEXT,
      synced_at INTEGER
    );

    CREATE TABLE IF NOT EXISTS inventory (
      id TEXT PRIMARY KEY,
      shop_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 0,
      cost_price REAL,
      selling_price REAL,
      expiry_date TEXT,
      low_stock_threshold INTEGER DEFAULT 5,
      synced_at INTEGER,
      UNIQUE(shop_id, product_id)
    );

    CREATE TABLE IF NOT EXISTS sales (
      id TEXT PRIMARY KEY,
      shop_id TEXT NOT NULL,
      total_amount REAL NOT NULL,
      payment_method TEXT DEFAULT 'cash',
      cash_received REAL,
      change_given REAL,
      created_at INTEGER NOT NULL,
      synced_at INTEGER
    );

    CREATE TABLE IF NOT EXISTS sale_items (
      id TEXT PRIMARY KEY,
      sale_id TEXT NOT NULL,
      product_id TEXT,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price REAL NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES sales(id)
    );

    CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      retry_count INTEGER DEFAULT 0,
      last_error TEXT
    );
  `);
}

// --- Products ---

export async function getProductByBarcode(barcode: string): Promise<Product | null> {
  const db = await getDb();
  const row = await db.getFirstAsync<Product>(
    'SELECT * FROM products WHERE barcode = ?',
    [barcode]
  );
  return row ?? null;
}

export async function upsertProduct(product: Product): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    `INSERT INTO products (id, barcode, name, category, default_price, image_url, synced_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(barcode) DO UPDATE SET
       name = excluded.name,
       category = excluded.category,
       default_price = excluded.default_price,
       image_url = excluded.image_url,
       synced_at = excluded.synced_at`,
    [product.id, product.barcode, product.name, product.category ?? null,
     product.default_price, product.image_url ?? null, product.synced_at ?? null]
  );
}

// --- Inventory ---

export async function getInventoryByShop(shopId: string): Promise<(InventoryItem & { product: Product })[]> {
  const db = await getDb();
  const rows = await db.getAllAsync<InventoryItem & Product & { inv_id: string }>(
    `SELECT i.id as inv_id, i.shop_id, i.product_id, i.quantity, i.cost_price,
            i.selling_price, i.expiry_date, i.low_stock_threshold, i.synced_at,
            p.id, p.barcode, p.name, p.category, p.default_price, p.image_url
     FROM inventory i
     JOIN products p ON i.product_id = p.id
     WHERE i.shop_id = ?
     ORDER BY p.name ASC`,
    [shopId]
  );
  return rows.map((r) => ({
    id: r.inv_id,
    shop_id: r.shop_id,
    product_id: r.product_id,
    quantity: r.quantity,
    cost_price: r.cost_price,
    selling_price: r.selling_price,
    expiry_date: r.expiry_date,
    low_stock_threshold: r.low_stock_threshold,
    synced_at: r.synced_at,
    product: {
      id: r.product_id,
      barcode: r.barcode,
      name: r.name,
      category: r.category,
      default_price: r.default_price,
      image_url: r.image_url,
      synced_at: r.synced_at,
    },
  }));
}

export async function getExpiringInventory(shopId: string, withinDays: number): Promise<(InventoryItem & { product: Product })[]> {
  const db = await getDb();
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() + withinDays);
  const cutoffStr = cutoff.toISOString().split('T')[0];
  const todayStr = new Date().toISOString().split('T')[0];

  const rows = await db.getAllAsync<InventoryItem & Product & { inv_id: string }>(
    `SELECT i.id as inv_id, i.shop_id, i.product_id, i.quantity, i.cost_price,
            i.selling_price, i.expiry_date, i.low_stock_threshold, i.synced_at,
            p.id, p.barcode, p.name, p.category, p.default_price, p.image_url
     FROM inventory i
     JOIN products p ON i.product_id = p.id
     WHERE i.shop_id = ? AND i.expiry_date IS NOT NULL
       AND i.expiry_date <= ? AND i.expiry_date >= ? AND i.quantity > 0
     ORDER BY i.expiry_date ASC`,
    [shopId, cutoffStr, todayStr]
  );
  return rows.map((r) => ({
    id: r.inv_id,
    shop_id: r.shop_id,
    product_id: r.product_id,
    quantity: r.quantity,
    cost_price: r.cost_price,
    selling_price: r.selling_price,
    expiry_date: r.expiry_date,
    low_stock_threshold: r.low_stock_threshold,
    synced_at: r.synced_at,
    product: {
      id: r.product_id,
      barcode: r.barcode,
      name: r.name,
      category: r.category,
      default_price: r.default_price,
      image_url: r.image_url,
      synced_at: r.synced_at,
    },
  }));
}

export async function upsertInventory(item: Omit<InventoryItem, 'product'>): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    `INSERT INTO inventory (id, shop_id, product_id, quantity, cost_price, selling_price, expiry_date, low_stock_threshold, synced_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(shop_id, product_id) DO UPDATE SET
       quantity = excluded.quantity,
       cost_price = excluded.cost_price,
       selling_price = excluded.selling_price,
       expiry_date = excluded.expiry_date,
       low_stock_threshold = excluded.low_stock_threshold,
       synced_at = excluded.synced_at`,
    [item.id, item.shop_id, item.product_id, item.quantity,
     item.cost_price ?? null, item.selling_price ?? null,
     item.expiry_date ?? null, item.low_stock_threshold, item.synced_at ?? null]
  );
}

export async function decrementInventory(shopId: string, productId: string, qty: number): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    `UPDATE inventory SET quantity = MAX(0, quantity - ?), synced_at = NULL
     WHERE shop_id = ? AND product_id = ?`,
    [qty, shopId, productId]
  );
}

export async function updateInventoryQuantity(shopId: string, productId: string, quantity: number): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    `UPDATE inventory SET quantity = ?, synced_at = NULL
     WHERE shop_id = ? AND product_id = ?`,
    [quantity, shopId, productId]
  );
}

// --- Sales ---

export async function insertSaleWithItems(
  sale: Omit<Sale, 'synced_at'>,
  items: Omit<SaleItem, 'id'>[]
): Promise<void> {
  const db = await getDb();
  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `INSERT INTO sales (id, shop_id, total_amount, payment_method, cash_received, change_given, created_at, synced_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, NULL)`,
      [sale.id, sale.shop_id, sale.total_amount, sale.payment_method,
       sale.cash_received ?? null, sale.change_given ?? null, sale.created_at]
    );
    for (const item of items) {
      const itemId = generateId();
      await db.runAsync(
        `INSERT INTO sale_items (id, sale_id, product_id, product_name, quantity, unit_price)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [itemId, sale.id, item.product_id ?? null, item.product_name, item.quantity, item.unit_price]
      );
    }
    await db.runAsync(
      `INSERT INTO sync_queue (id, entity_type, entity_id, operation, payload, created_at, retry_count)
       VALUES (?, 'sale', ?, 'insert', ?, ?, 0)`,
      [generateId(), sale.id, JSON.stringify({ sale, items }), Date.now()]
    );
  });
}

export async function getTodaySales(shopId: string): Promise<{ count: number; revenue: number }> {
  const db = await getDb();
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const row = await db.getFirstAsync<{ count: number; revenue: number }>(
    `SELECT COUNT(*) as count, COALESCE(SUM(total_amount), 0) as revenue
     FROM sales WHERE shop_id = ? AND created_at >= ?`,
    [shopId, startOfDay.getTime()]
  );
  return row ?? { count: 0, revenue: 0 };
}

export async function getUnsyncedSales(): Promise<SyncQueueEntry[]> {
  const db = await getDb();
  return db.getAllAsync<SyncQueueEntry>(
    `SELECT * FROM sync_queue WHERE entity_type = 'sale' ORDER BY created_at ASC LIMIT 50`
  );
}

export async function getPendingSyncCount(): Promise<number> {
  const db = await getDb();
  const row = await db.getFirstAsync<{ count: number }>(
    `SELECT COUNT(*) as count FROM sync_queue`
  );
  return row?.count ?? 0;
}

export async function markSyncQueueEntryComplete(id: string): Promise<void> {
  const db = await getDb();
  await db.runAsync(`DELETE FROM sync_queue WHERE id = ?`, [id]);
}

export async function markSyncQueueEntryFailed(id: string, error: string): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    `UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ? WHERE id = ?`,
    [error, id]
  );
}

export async function markSaleSynced(saleId: string): Promise<void> {
  const db = await getDb();
  await db.runAsync(
    `UPDATE sales SET synced_at = ? WHERE id = ?`,
    [Date.now(), saleId]
  );
}

export function generateId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
  });
}
