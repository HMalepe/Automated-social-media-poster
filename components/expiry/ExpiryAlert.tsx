import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { InventoryItem, Product } from '@/types';
import { MarkdownSuggestion } from './MarkdownSuggestion';
import { daysUntilDate, formatZAR } from '@/lib/currency';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface ExpiryAlertProps {
  item: InventoryItem & { product: Product };
}

export function ExpiryAlert({ item }: ExpiryAlertProps) {
  if (!item.expiry_date) return null;

  const days = daysUntilDate(item.expiry_date);
  const price = item.selling_price ?? item.product.default_price;

  const urgency = days <= 1 ? 'critical' : days <= 3 ? 'high' : 'medium';
  const urgencyColor = { critical: Colors.danger, high: Colors.warning, medium: Colors.accent };

  return (
    <View style={[styles.card, { borderLeftColor: urgencyColor[urgency] }]}>
      <View style={styles.header}>
        <Text style={styles.name} numberOfLines={1}>{item.product.name}</Text>
        <View style={[styles.badge, { backgroundColor: urgencyColor[urgency] }]}>
          <Text style={styles.badgeText}>{days === 0 ? 'Today' : days === 1 ? 'Tomorrow' : `${days} days`}</Text>
        </View>
      </View>
      <View style={styles.meta}>
        <Text style={styles.metaText}>{item.quantity} units · {formatZAR(price)} each</Text>
        <Text style={styles.metaText}>Expires {item.expiry_date}</Text>
      </View>
      <MarkdownSuggestion originalPrice={price} daysUntilExpiry={days} />
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
    borderLeftWidth: 4,
  },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: Spacing.xs },
  name: { fontSize: FontSize.md, fontWeight: '600', color: Colors.gray800, flex: 1, marginRight: Spacing.sm },
  badge: { paddingHorizontal: Spacing.sm, paddingVertical: 2, borderRadius: BorderRadius.full },
  badgeText: { fontSize: FontSize.xs, color: Colors.white, fontWeight: '700' },
  meta: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: Spacing.xs },
  metaText: { fontSize: FontSize.sm, color: Colors.gray500 },
});
