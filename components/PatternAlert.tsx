import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS, SPACING, SCREEN_PADDING, RADIUS } from '../constants';
import type { PatternAlert as PatternAlertType } from '../types';

interface Props {
  alert: PatternAlertType;
}

// Cross-session behavioral pattern detected by AI — this is the "magic" moment
// where the app earns its value by surfacing what individual sessions miss.
export default function PatternAlert({ alert }: Props) {
  const pct = Math.round((alert.occurrences / alert.totalSessions) * 100);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.icon}>▲</Text>
        <Text style={styles.badge}>PATTERN DETECTED</Text>
        <Text style={styles.meta}>
          {alert.occurrences}/{alert.totalSessions} SESSIONS
        </Text>
      </View>
      <Text style={styles.title}>{alert.title}</Text>
      <Text style={styles.description}>{alert.description}</Text>
      <View style={styles.progressTrack}>
        <View style={[styles.progressFill, { flex: pct }]} />
        <View style={[styles.progressEmpty, { flex: 100 - pct }]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginHorizontal: SCREEN_PADDING,
    marginBottom: SPACING.base,
    padding: SPACING.base,
    borderWidth: 1,
    borderColor: COLORS.accent,
    borderRadius: RADIUS.xs,
    backgroundColor: COLORS.accentSubtle,
    gap: SPACING.sm,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  icon: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.accent,
  },
  badge: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.accent,
    letterSpacing: FONTS.tracking.label,
    fontWeight: FONTS.weights.bold,
    flex: 1,
  },
  meta: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.wide,
  },
  title: {
    fontFamily: FONTS.sans,
    fontSize: FONTS.sizes.base,
    color: COLORS.textPrimary,
    fontWeight: FONTS.weights.semibold,
    lineHeight: FONTS.sizes.base * 1.4,
  },
  description: {
    fontFamily: FONTS.sans,
    fontSize: FONTS.sizes.base,
    color: COLORS.textSecondary,
    lineHeight: FONTS.sizes.base * 1.6,
  },
  progressTrack: {
    flexDirection: 'row',
    height: 2,
    marginTop: SPACING.xs,
  },
  progressFill: {
    backgroundColor: COLORS.accent,
    height: '100%',
  },
  progressEmpty: {
    backgroundColor: COLORS.border,
    height: '100%',
  },
});
