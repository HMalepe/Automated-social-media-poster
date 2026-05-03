import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import { CartItem as CartItemType } from '@/types';
import { CartItem } from './CartItem';
import { Button } from '@/components/ui/Button';
import { formatZAR } from '@/lib/currency';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { useCart } from '@/hooks/useCart';

interface CartSummaryProps {
  onCheckout: () => void;
}

export function CartSummary({ onCheckout }: CartSummaryProps) {
  const { items, addItem, updateQuantity, removeItem, getTotal } = useCart();
  const total = getTotal();

  if (items.length === 0) {
    return (
      <View style={styles.empty}>
        <Text style={styles.emptyIcon}>🛒</Text>
        <Text style={styles.emptyText}>Scan a product to add it to the cart</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView style={styles.list} showsVerticalScrollIndicator={false}>
        {items.map((item: CartItemType) => (
          <CartItem
            key={item.product.id}
            item={item}
            onIncrement={() => addItem(item.product, item.unit_price)}
            onDecrement={() => updateQuantity(item.product.id, item.quantity - 1)}
            onRemove={() => removeItem(item.product.id)}
          />
        ))}
      </ScrollView>
      <View style={styles.footer}>
        <View style={styles.totalRow}>
          <Text style={styles.totalLabel}>Total</Text>
          <Text style={styles.totalAmount}>{formatZAR(total)}</Text>
        </View>
        <Button label="Checkout" onPress={onCheckout} size="lg" style={styles.checkoutBtn} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  list: { flex: 1, paddingHorizontal: Spacing.md },
  empty: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingBottom: 80 },
  emptyIcon: { fontSize: 48, marginBottom: Spacing.md },
  emptyText: { fontSize: FontSize.md, color: Colors.gray400, textAlign: 'center' },
  footer: {
    padding: Spacing.md,
    borderTopWidth: 1,
    borderTopColor: Colors.border,
    backgroundColor: Colors.surface,
  },
  totalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  totalLabel: { fontSize: FontSize.lg, color: Colors.gray600, fontWeight: '500' },
  totalAmount: { fontSize: FontSize.xxxl, fontWeight: '800', color: Colors.primary },
  checkoutBtn: { borderRadius: BorderRadius.lg },
});
