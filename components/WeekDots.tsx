import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS, SPACING } from '../constants';

const DAY_LABELS = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

interface Props {
  // 7 booleans Mon–Sun — true if a recording exists for that day
  recordedDays: boolean[];
}

export default function WeekDots({ recordedDays }: Props) {
  const streak = getStreak(recordedDays);

  return (
    <View style={styles.container}>
      <View style={styles.dots}>
        {recordedDays.map((recorded, i) => (
          <View key={i} style={styles.dayColumn}>
            <View
              style={[
                styles.dot,
                recorded ? styles.dotActive : styles.dotInactive,
              ]}
            />
            <Text style={styles.dayLabel}>{DAY_LABELS[i]}</Text>
          </View>
        ))}
      </View>
      {streak > 0 && (
        <Text style={styles.streak}>
          {streak}
          <Text style={styles.streakLabel}> DAY STREAK</Text>
        </Text>
      )}
    </View>
  );
}

// Count consecutive recorded days working backward from today (end of array).
function getStreak(days: boolean[]): number {
  let streak = 0;
  for (let i = days.length - 1; i >= 0; i--) {
    if (days[i]) streak++;
    else break;
  }
  return streak;
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  dots: {
    flexDirection: 'row',
    gap: SPACING.sm,
    alignItems: 'flex-end',
  },
  dayColumn: {
    alignItems: 'center',
    gap: 3,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  dotActive: {
    backgroundColor: COLORS.accent,
  },
  dotInactive: {
    backgroundColor: COLORS.border,
  },
  dayLabel: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.wide,
  },
  streak: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.md,
    color: COLORS.accent,
    fontWeight: FONTS.weights.bold,
  },
  streakLabel: {
    fontSize: FONTS.sizes.xs,
    color: COLORS.textSecondary,
    fontWeight: FONTS.weights.regular,
    letterSpacing: FONTS.tracking.label,
  },
});
