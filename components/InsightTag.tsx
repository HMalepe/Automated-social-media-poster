import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS, SPACING, RADIUS } from '../constants';
import type { InsightTag as InsightTagType } from '../types';

interface Props {
  tag: InsightTagType;
}

export default function InsightTag({ tag }: Props) {
  return (
    <View style={styles.container}>
      <Text style={styles.emoji}>{tag.emoji}</Text>
      <Text style={styles.label}>{tag.label.toUpperCase()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.xs,
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: RADIUS.xs,
    backgroundColor: COLORS.surfaceElevated,
  },
  emoji: {
    fontSize: FONTS.sizes.sm,
  },
  label: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textSecondary,
    letterSpacing: FONTS.tracking.label,
    fontWeight: FONTS.weights.medium,
  },
});
