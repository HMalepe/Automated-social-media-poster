import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS, SPACING, SCREEN_PADDING } from '../constants';

export default function EmptyState() {
  return (
    <View style={styles.container}>
      <Text style={styles.glyph}>◎</Text>
      <Text style={styles.heading}>NO SESSIONS YET</Text>
      <Text style={styles.body}>
        Open the Watch app and tap the button to record your first session.
        {'\n\n'}
        Your insights will appear here within seconds of syncing.
      </Text>
      <View style={styles.hintBox}>
        <Text style={styles.hintLabel}>WHAT TO RECORD</Text>
        <View style={styles.hintList}>
          {[
            'Sales calls',
            'One-on-ones',
            'Board meetings',
            'Coaching sessions',
            'Any conversation that matters',
          ].map((item, i) => (
            <Text key={i} style={styles.hintItem}>
              — {item}
            </Text>
          ))}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: SCREEN_PADDING,
    paddingTop: SPACING.xxxl,
    alignItems: 'flex-start',
    gap: SPACING.base,
  },
  glyph: {
    fontSize: 32,
    color: COLORS.textMuted,
    marginBottom: SPACING.sm,
  },
  heading: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.base,
    color: COLORS.textSecondary,
    letterSpacing: FONTS.tracking.label,
    fontWeight: FONTS.weights.bold,
  },
  body: {
    fontFamily: FONTS.sans,
    fontSize: FONTS.sizes.md,
    color: COLORS.textSecondary,
    lineHeight: FONTS.sizes.md * 1.6,
  },
  hintBox: {
    marginTop: SPACING.xl,
    paddingTop: SPACING.base,
    borderTopWidth: 1,
    borderColor: COLORS.border,
    width: '100%',
    gap: SPACING.sm,
  },
  hintLabel: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.label,
  },
  hintList: {
    gap: SPACING.xs,
  },
  hintItem: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.base,
    color: COLORS.textSecondary,
    letterSpacing: FONTS.tracking.normal,
  },
});
