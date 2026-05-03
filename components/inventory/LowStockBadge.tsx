import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface LowStockBadgeProps {
  quantity: number;
  threshold: number;
}

export function LowStockBadge({ quantity, threshold }: LowStockBadgeProps) {
  if (quantity > threshold) return null;

  const isOut = quantity === 0;

  return (
    <View style={[styles.badge, isOut ? styles.out : styles.low]}>
      <Text style={styles.text}>{isOut ? 'Out of stock' : 'Low stock'}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: BorderRadius.full,
  },
  low: { backgroundColor: '#FEF3C7' },
  out: { backgroundColor: '#FEE2E2' },
  text: { fontSize: FontSize.xs, fontWeight: '600', color: Colors.gray700 },
});
