import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { CartItem as CartItemType } from '@/types';
import { formatZAR } from '@/lib/currency';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface CartItemProps {
  item: CartItemType;
  onIncrement: () => void;
  onDecrement: () => void;
  onRemove: () => void;
}

export function CartItem({ item, onIncrement, onDecrement, onRemove }: CartItemProps) {
  return (
    <View style={styles.container}>
      <View style={styles.info}>
        <Text style={styles.name} numberOfLines={1}>{item.product.name}</Text>
        <Text style={styles.price}>{formatZAR(item.unit_price)} each</Text>
      </View>
      <View style={styles.controls}>
        <TouchableOpacity onPress={onDecrement} style={styles.qtyBtn} activeOpacity={0.7}>
          <Text style={styles.qtyBtnText}>−</Text>
        </TouchableOpacity>
        <Text style={styles.qty}>{item.quantity}</Text>
        <TouchableOpacity onPress={onIncrement} style={styles.qtyBtn} activeOpacity={0.7}>
          <Text style={styles.qtyBtnText}>+</Text>
        </TouchableOpacity>
      </View>
      <View style={styles.lineTotal}>
        <Text style={styles.lineTotalText}>{formatZAR(item.quantity * item.unit_price)}</Text>
        <TouchableOpacity onPress={onRemove} activeOpacity={0.7} style={styles.removeBtn}>
          <Text style={styles.removeText}>✕</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.md,
    backgroundColor: Colors.surface,
    borderRadius: BorderRadius.md,
    marginBottom: Spacing.xs,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  info: { flex: 1 },
  name: { fontSize: FontSize.md, fontWeight: '500', color: Colors.gray800 },
  price: { fontSize: FontSize.sm, color: Colors.gray500, marginTop: 2 },
  controls: { flexDirection: 'row', alignItems: 'center', marginHorizontal: Spacing.sm },
  qtyBtn: {
    width: 32,
    height: 32,
    borderRadius: BorderRadius.sm,
    backgroundColor: Colors.gray100,
    alignItems: 'center',
    justifyContent: 'center',
  },
  qtyBtnText: { fontSize: FontSize.lg, color: Colors.gray700 },
  qty: { fontSize: FontSize.md, fontWeight: '600', marginHorizontal: Spacing.sm, minWidth: 24, textAlign: 'center' },
  lineTotal: { alignItems: 'flex-end' },
  lineTotalText: { fontSize: FontSize.md, fontWeight: '700', color: Colors.primary },
  removeBtn: { marginTop: 4 },
  removeText: { fontSize: FontSize.sm, color: Colors.gray400 },
});
