import React, { useState } from 'react';
import { View, Text, TouchableOpacity, TextInput, StyleSheet, Alert } from 'react-native';
import { InventoryItem, Product } from '@/types';
import { LowStockBadge } from './LowStockBadge';
import { formatZAR, daysUntilDate } from '@/lib/currency';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface StockCardProps {
  item: InventoryItem & { product: Product };
  onUpdateQuantity: (qty: number) => void;
}

export function StockCard({ item, onUpdateQuantity }: StockCardProps) {
  const [editing, setEditing] = useState(false);
  const [inputValue, setInputValue] = useState(String(item.quantity));

  const price = item.selling_price ?? item.product.default_price;
  const daysLeft = item.expiry_date ? daysUntilDate(item.expiry_date) : null;
  const expiryWarning = daysLeft !== null && daysLeft <= 7;

  const commitEdit = () => {
    const qty = parseInt(inputValue, 10);
    if (isNaN(qty) || qty < 0) {
      Alert.alert('Invalid quantity', 'Please enter a valid number.');
      setInputValue(String(item.quantity));
    } else {
      onUpdateQuantity(qty);
    }
    setEditing(false);
  };

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.name} numberOfLines={1}>{item.product.name}</Text>
        <LowStockBadge quantity={item.quantity} threshold={item.low_stock_threshold} />
      </View>

      <View style={styles.row}>
        <View style={styles.stat}>
          <Text style={styles.statLabel}>Price</Text>
          <Text style={styles.statValue}>{formatZAR(price)}</Text>
        </View>
        <View style={styles.stat}>
          <Text style={styles.statLabel}>Stock</Text>
          {editing ? (
            <TextInput
              style={styles.editInput}
              value={inputValue}
              onChangeText={setInputValue}
              onBlur={commitEdit}
              onSubmitEditing={commitEdit}
              keyboardType="numeric"
              autoFocus
            />
          ) : (
            <TouchableOpacity onPress={() => setEditing(true)}>
              <Text style={[styles.statValue, styles.editable]}>{item.quantity} units</Text>
            </TouchableOpacity>
          )}
        </View>
        {item.expiry_date && (
          <View style={styles.stat}>
            <Text style={styles.statLabel}>Expiry</Text>
            <Text style={[styles.statValue, expiryWarning && styles.expiryWarn]}>
              {expiryWarning ? `${daysLeft}d left` : item.expiry_date}
            </Text>
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surface,
    borderRadius: BorderRadius.md,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: Spacing.sm },
  name: { fontSize: FontSize.md, fontWeight: '600', color: Colors.gray800, flex: 1, marginRight: Spacing.sm },
  row: { flexDirection: 'row', gap: Spacing.md },
  stat: { flex: 1 },
  statLabel: { fontSize: FontSize.xs, color: Colors.gray400, marginBottom: 2 },
  statValue: { fontSize: FontSize.sm, fontWeight: '600', color: Colors.gray700 },
  editable: { color: Colors.primary, textDecorationLine: 'underline' },
  expiryWarn: { color: Colors.danger },
  editInput: {
    borderWidth: 1,
    borderColor: Colors.primary,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.xs,
    paddingVertical: 2,
    fontSize: FontSize.sm,
    color: Colors.gray800,
    minWidth: 60,
  },
});
