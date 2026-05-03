import { Product } from '@/types';
import { getProductByBarcode, upsertProduct, generateId } from './db';
import { supabase } from './supabase';

interface OFFProduct {
  product?: {
    product_name?: string;
    categories_tags?: string[];
    image_url?: string;
  };
  status: number;
}

export async function lookupProduct(barcode: string): Promise<Product | null> {
  // 1. Check local SQLite first (works offline)
  const local = await getProductByBarcode(barcode);
  if (local) return local;

  // 2. Check Supabase remote (requires connectivity)
  try {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('barcode', barcode)
      .single();

    if (!error && data) {
      const product: Product = {
        id: data.id,
        barcode: data.barcode,
        name: data.name,
        category: data.category,
        default_price: parseFloat(data.default_price),
        image_url: data.image_url,
        synced_at: Date.now(),
      };
      await upsertProduct(product);
      return product;
    }
  } catch {
    // No connectivity — fall through to OFT
  }

  // 3. Open Food Facts API (best-effort for known consumer products)
  try {
    const response = await fetch(
      `https://world.openfoodfacts.org/api/v0/product/${barcode}.json`,
      { signal: AbortSignal.timeout(4000) }
    );
    const data: OFFProduct = await response.json();

    if (data.status === 1 && data.product?.product_name) {
      const product: Product = {
        id: generateId(),
        barcode,
        name: data.product.product_name,
        category: data.product.categories_tags?.[0]?.replace('en:', '') ?? null,
        default_price: 0,
        image_url: data.product.image_url ?? null,
        synced_at: null,
      };
      await upsertProduct(product);
      return product;
    }
  } catch {
    // OFT unavailable
  }

  return null;
}
