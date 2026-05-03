import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS, SPACING, SCREEN_PADDING } from '../constants';
import WeekDots from './WeekDots';
import type { WeekStats } from '../types';

interface Props {
  stats: WeekStats;
}

export default function StatsBar({ stats }: Props) {
  const totalMinutes = Math.round(stats.totalDurationSeconds / 60);
  const assertSign = stats.assertivenessChangePct >= 0 ? '+' : '';

  return (
    <View style={styles.container}>
      {/* Week activity grid */}
      <WeekDots recordedDays={stats.recordedDays} />

      <View style={styles.divider} />

      {/* Three-column stat summary */}
      <View style={styles.statsRow}>
        <StatCell
          value={String(stats.sessionCount)}
          label="SESSIONS"
          unit="THIS WEEK"
        />
        <View style={styles.columnDivider} />
        <StatCell
          value={`${totalMinutes}m`}
          label="RECORDED"
          unit="TOTAL"
        />
        <View style={styles.columnDivider} />
        <StatCell
          value={`${assertSign}${stats.assertivenessChangePct}%`}
          label="ASSERTIVENESS"
          unit="VS LAST MONTH"
          accent
        />
      </View>

      <View style={styles.divider} />

      {/* Mood summary */}
      <Text style={styles.moodSummary}>{stats.moodSummary}</Text>
    </View>
  );
}

function StatCell({
  value,
  label,
  unit,
  accent,
}: {
  value: string;
  label: string;
  unit: string;
  accent?: boolean;
}) {
  return (
    <View style={styles.statCell}>
      <Text style={styles.statUnit}>{unit}</Text>
      <Text style={[styles.statValue, accent && styles.statValueAccent]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginHorizontal: SCREEN_PADDING,
    marginBottom: SPACING.xxl,
    gap: SPACING.base,
  },
  divider: {
    height: 1,
    backgroundColor: COLORS.border,
  },
  statsRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  statCell: {
    flex: 1,
    gap: 2,
  },
  columnDivider: {
    width: 1,
    backgroundColor: COLORS.border,
    marginHorizontal: SPACING.base,
    alignSelf: 'stretch',
  },
  statUnit: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.label,
  },
  statValue: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xl,
    color: COLORS.textPrimary,
    fontWeight: FONTS.weights.bold,
    letterSpacing: FONTS.tracking.tight,
  },
  statValueAccent: {
    color: COLORS.accent,
  },
  statLabel: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textSecondary,
    letterSpacing: FONTS.tracking.label,
  },
  moodSummary: {
    fontFamily: FONTS.sans,
    fontSize: FONTS.sizes.base,
    color: COLORS.textSecondary,
    fontStyle: 'italic',
    lineHeight: FONTS.sizes.base * 1.5,
  },
});
