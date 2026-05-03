export interface Product {
  id: string;
  barcode: string;
  name: string;
  category: string | null;
  default_price: number;
  image_url: string | null;
  synced_at: number | null;
}

export interface InventoryItem {
  id: string;
  shop_id: string;
  product_id: string;
  quantity: number;
  cost_price: number | null;
  selling_price: number | null;
  expiry_date: string | null;
  low_stock_threshold: number;
  synced_at: number | null;
  // Joined fields from products
  product?: Product;
}

export interface CartItem {
  product: Product;
  quantity: number;
  unit_price: number;
}

export interface Sale {
  id: string;
  shop_id: string;
  total_amount: number;
  payment_method: 'cash' | 'card' | 'other';
  cash_received: number | null;
  change_given: number | null;
  created_at: number;
  synced_at: number | null;
}

export interface SaleItem {
  id: string;
  sale_id: string;
  product_id: string | null;
  product_name: string;
  quantity: number;
  unit_price: number;
}

export interface SyncQueueEntry {
  id: string;
  entity_type: 'sale' | 'inventory' | 'product';
  entity_id: string;
  operation: 'insert' | 'update' | 'delete';
  payload: string;
  created_at: number;
  retry_count: number;
  last_error: string | null;
}

export type SyncStatus = 'synced' | 'syncing' | 'offline' | 'error';

export interface DashboardStats {
  today_sales_count: number;
  today_revenue: number;
  low_stock_count: number;
  expiring_soon_count: number;
  pending_sync_count: number;
}
