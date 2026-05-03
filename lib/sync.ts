import { supabase } from './supabase';
import {
  getUnsyncedSales,
  markSyncQueueEntryComplete,
  markSyncQueueEntryFailed,
  markSaleSynced,
} from './db';
import { SyncQueueEntry } from '@/types';

export type SyncResult = { synced: number; failed: number };

export async function syncPendingSales(): Promise<SyncResult> {
  const queue = await getUnsyncedSales();
  let synced = 0;
  let failed = 0;

  for (const entry of queue) {
    try {
      await syncEntry(entry);
      await markSyncQueueEntryComplete(entry.id);
      await markSaleSynced(entry.entity_id);
      synced++;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      await markSyncQueueEntryFailed(entry.id, message);
      failed++;
    }
  }

  return { synced, failed };
}

async function syncEntry(entry: SyncQueueEntry): Promise<void> {
  if (entry.entity_type !== 'sale' || entry.operation !== 'insert') return;

  const { sale, items } = JSON.parse(entry.payload) as {
    sale: { id: string; shop_id: string; total_amount: number; payment_method: string; cash_received: number | null; change_given: number | null; created_at: number };
    items: Array<{ sale_id: string; product_id: string | null; product_name: string; quantity: number; unit_price: number }>;
  };

  // Upsert sale using local_id for idempotency
  const { data: saleData, error: saleError } = await supabase
    .from('sales')
    .upsert({
      local_id: sale.id,
      shop_id: sale.shop_id,
      total_amount: sale.total_amount,
      payment_method: sale.payment_method,
      cash_received: sale.cash_received,
      change_given: sale.change_given,
      created_at: new Date(sale.created_at).toISOString(),
    }, { onConflict: 'local_id' })
    .select('id')
    .single();

  if (saleError) throw new Error(saleError.message);

  const remoteSaleId = saleData.id;

  // Insert sale items
  const saleItemsPayload = items.map((item) => ({
    sale_id: remoteSaleId,
    product_id: item.product_id,
    product_name: item.product_name,
    quantity: item.quantity,
    unit_price: item.unit_price,
  }));

  const { error: itemsError } = await supabase
    .from('sale_items')
    .insert(saleItemsPayload);

  if (itemsError && !itemsError.message.includes('duplicate')) {
    throw new Error(itemsError.message);
  }
}
