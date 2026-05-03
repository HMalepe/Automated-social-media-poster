import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { formatZAR, suggestMarkdownPercent } from '@/lib/currency';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface MarkdownSuggestionProps {
  originalPrice: number;
  daysUntilExpiry: number;
}

export function MarkdownSuggestion({ originalPrice, daysUntilExpiry }: MarkdownSuggestionProps) {
  const pct = suggestMarkdownPercent(daysUntilExpiry);
  const newPrice = originalPrice * (1 - pct / 100);

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Suggested markdown</Text>
      <View style={styles.row}>
        <Text style={styles.discount}>−{pct}%</Text>
        <Text style={styles.newPrice}>{formatZAR(newPrice)}</Text>
        <Text style={styles.oldPrice}>{formatZAR(originalPrice)}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FEF3C7',
    borderRadius: BorderRadius.sm,
    padding: Spacing.sm,
    marginTop: Spacing.xs,
  },
  label: { fontSize: FontSize.xs, color: Colors.gray500, marginBottom: 4 },
  row: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  discount: { fontSize: FontSize.sm, fontWeight: '700', color: Colors.warning },
  newPrice: { fontSize: FontSize.md, fontWeight: '700', color: Colors.gray800 },
  oldPrice: { fontSize: FontSize.sm, color: Colors.gray400, textDecorationLine: 'line-through' },
});
