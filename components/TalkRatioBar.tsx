import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS, SPACING } from '../constants';

interface Props {
  talkRatio: number; // 0–100, your % of speaking time
}

export default function TalkRatioBar({ talkRatio }: Props) {
  const them = 100 - talkRatio;
  const isHigh = talkRatio > 65;

  return (
    <View style={styles.container}>
      <View style={styles.labels}>
        <Text style={[styles.label, isHigh && styles.labelHighlighted]}>
          YOU {talkRatio}%
        </Text>
        <Text style={styles.label}>THEM {them}%</Text>
      </View>
      <View style={styles.track}>
        <View
          style={[
            styles.fill,
            {
              flex: talkRatio,
              // Accent if you dominate, muted otherwise
              backgroundColor: isHigh ? COLORS.accent : COLORS.textSecondary,
            },
          ]}
        />
        <View style={[styles.fill, { flex: them, backgroundColor: COLORS.border }]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: SPACING.xs,
  },
  labels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  label: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.wide,
  },
  labelHighlighted: {
    color: COLORS.accent,
  },
  track: {
    flexDirection: 'row',
    height: 3,
    overflow: 'hidden',
    gap: 2,
  },
  fill: {
    height: '100%',
  },
});
