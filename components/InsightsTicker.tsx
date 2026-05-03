import React, { useRef, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, Animated } from 'react-native';
import { COLORS, FONTS, SPACING, SCREEN_PADDING } from '../constants';
import type { WeekStats } from '../types';

interface Props {
  stats: WeekStats;
}

// Horizontal scrolling stats ticker — Bloomberg terminal aesthetic.
// Auto-scrolls slowly to reveal all chips.
export default function InsightsTicker({ stats }: Props) {
  const scrollX = useRef(new Animated.Value(0)).current;
  const scrollRef = useRef<ScrollView>(null);

  const totalMinutes = Math.round(stats.totalDurationSeconds / 60);
  const assertSign = stats.assertivenessChangePct >= 0 ? '+' : '';

  const chips = [
    { label: `${stats.sessionCount} SESSIONS`, value: 'THIS WEEK' },
    { label: `${totalMinutes}m RECORDED`, value: null },
    { label: stats.topTopic.toUpperCase(), value: 'TOP TOPIC' },
    { label: `${stats.avgTalkRatio}%`, value: 'AVG TALK RATIO' },
    {
      label: `${assertSign}${stats.assertivenessChangePct}%`,
      value: 'ASSERTIVENESS vs LAST MONTH',
      accent: true,
    },
    { label: `${stats.avgFillerWordsPerMin}/MIN`, value: 'FILLER WORDS' },
  ];

  return (
    <View style={styles.container}>
      <View style={styles.labelContainer}>
        <Text style={styles.liveLabel}>◆</Text>
      </View>
      <ScrollView
        ref={scrollRef}
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {chips.map((chip, i) => (
          <React.Fragment key={i}>
            <View style={styles.chip}>
              {chip.value && <Text style={styles.chipValue}>{chip.value}</Text>}
              <Text style={[styles.chipLabel, chip.accent && styles.chipLabelAccent]}>
                {chip.label}
              </Text>
            </View>
            {i < chips.length - 1 && (
              <Text style={styles.separator}>·</Text>
            )}
          </React.Fragment>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: COLORS.border,
    paddingVertical: SPACING.sm,
    backgroundColor: COLORS.surface,
  },
  labelContainer: {
    paddingLeft: SCREEN_PADDING,
    paddingRight: SPACING.sm,
  },
  liveLabel: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.accent,
    letterSpacing: 0,
  },
  scrollContent: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingRight: SCREEN_PADDING,
    gap: SPACING.sm,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'baseline',
    gap: SPACING.xs,
  },
  chipValue: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.label,
  },
  chipLabel: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.base,
    color: COLORS.textSecondary,
    letterSpacing: FONTS.tracking.wide,
    fontWeight: FONTS.weights.semibold,
  },
  chipLabelAccent: {
    color: COLORS.accent,
  },
  separator: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.base,
    color: COLORS.border,
  },
});
