import { useState, useCallback } from 'react';
import { InventoryItem, Product } from '@/types';
import { getInventoryByShop, getExpiringInventory, updateInventoryQuantity, upsertInventory, upsertProduct, generateId } from '@/lib/db';

export function useInventory(shopId: string | null) {
  const [inventory, setInventory] = useState<(InventoryItem & { product: Product })[]>([]);
  const [expiring, setExpiring] = useState<(InventoryItem & { product: Product })[]>([]);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    if (!shopId) return;
    setLoading(true);
    try {
      const [inv, exp] = await Promise.all([
        getInventoryByShop(shopId),
        getExpiringInventory(shopId, 7),
      ]);
      setInventory(inv);
      setExpiring(exp);
    } finally {
      setLoading(false);
    }
  }, [shopId]);

  const updateQuantity = useCallback(async (productId: string, quantity: number) => {
    if (!shopId) return;
    await updateInventoryQuantity(shopId, productId, quantity);
    await refresh();
  }, [shopId, refresh]);

  const addProduct = useCallback(async (
    product: Omit<Product, 'id' | 'synced_at'>,
    inventoryData: { quantity: number; selling_price?: number; cost_price?: number; expiry_date?: string; low_stock_threshold?: number }
  ) => {
    if (!shopId) return;
    const productId = generateId();
    const inventoryId = generateId();

    await upsertProduct({
      id: productId,
      barcode: product.barcode,
      name: product.name,
      category: product.category,
      default_price: product.default_price,
      image_url: product.image_url,
      synced_at: null,
    });

    await upsertInventory({
      id: inventoryId,
      shop_id: shopId,
      product_id: productId,
      quantity: inventoryData.quantity,
      selling_price: inventoryData.selling_price ?? null,
      cost_price: inventoryData.cost_price ?? null,
      expiry_date: inventoryData.expiry_date ?? null,
      low_stock_threshold: inventoryData.low_stock_threshold ?? 5,
      synced_at: null,
    });

    await refresh();
  }, [shopId, refresh]);

  return { inventory, expiring, loading, refresh, updateQuantity, addProduct };
}
