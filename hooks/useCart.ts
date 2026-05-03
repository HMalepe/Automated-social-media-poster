import { create } from 'zustand';
import { CartItem, Product, Sale } from '@/types';
import { insertSaleWithItems, decrementInventory, generateId } from '@/lib/db';

interface CartStore {
  items: CartItem[];
  shopId: string | null;
  setShopId: (id: string) => void;
  addItem: (product: Product, price?: number) => void;
  removeItem: (productId: string) => void;
  updateQuantity: (productId: string, qty: number) => void;
  clearCart: () => void;
  getTotal: () => number;
  completeSale: (opts: { paymentMethod: 'cash' | 'card' | 'other'; cashReceived?: number; changeGiven?: number }) => Promise<Sale>;
}

export const useCart = create<CartStore>((set, get) => ({
  items: [],
  shopId: null,

  setShopId: (id) => set({ shopId: id }),

  addItem: (product, price) => {
    const { items } = get();
    const existing = items.find((i) => i.product.id === product.id);
    const unit_price = price ?? product.default_price;

    if (existing) {
      set({
        items: items.map((i) =>
          i.product.id === product.id ? { ...i, quantity: i.quantity + 1 } : i
        ),
      });
    } else {
      set({ items: [...items, { product, quantity: 1, unit_price }] });
    }
  },

  removeItem: (productId) => {
    set({ items: get().items.filter((i) => i.product.id !== productId) });
  },

  updateQuantity: (productId, qty) => {
    if (qty <= 0) {
      get().removeItem(productId);
      return;
    }
    set({
      items: get().items.map((i) =>
        i.product.id === productId ? { ...i, quantity: qty } : i
      ),
    });
  },

  clearCart: () => set({ items: [] }),

  getTotal: () =>
    get().items.reduce((sum, i) => sum + i.quantity * i.unit_price, 0),

  completeSale: async ({ paymentMethod, cashReceived, changeGiven }) => {
    const { items, shopId, clearCart } = get();
    if (!shopId) throw new Error('No shop ID set');
    if (items.length === 0) throw new Error('Cart is empty');

    const sale: Sale = {
      id: generateId(),
      shop_id: shopId,
      total_amount: get().getTotal(),
      payment_method: paymentMethod,
      cash_received: cashReceived ?? null,
      change_given: changeGiven ?? null,
      created_at: Date.now(),
      synced_at: null,
    };

    const saleItems = items.map((i) => ({
      sale_id: sale.id,
      product_id: i.product.id,
      product_name: i.product.name,
      quantity: i.quantity,
      unit_price: i.unit_price,
    }));

    await insertSaleWithItems(sale, saleItems);

    // Decrement inventory for each item
    for (const item of items) {
      await decrementInventory(shopId, item.product.id, item.quantity);
    }

    clearCart();
    return sale;
  },
}));
