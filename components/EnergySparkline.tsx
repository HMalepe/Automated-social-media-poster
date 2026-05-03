import React from 'react';
import { View, StyleSheet } from 'react-native';
import { COLORS } from '../constants';
import type { EnergyPoint } from '../types';

interface Props {
  data: EnergyPoint[];
  height?: number;
}

// Maps an energy level to a bar color.
// Low = barely visible. Mid = muted white. High = electric accent.
function levelToColor(level: number): string {
  if (level >= 70) return COLORS.accent;
  if (level >= 45) return COLORS.textSecondary;
  if (level >= 20) return '#333333';
  return COLORS.energyLow;
}

export default function EnergySparkline({ data, height = 22 }: Props) {
  return (
    <View style={[styles.container, { height }]}>
      {data.map((point, index) => (
        <View
          key={index}
          style={[
            styles.bar,
            {
              height: `${Math.max(8, point.level)}%`,
              backgroundColor: levelToColor(point.level),
            },
          ]}
        />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 1.5,
    overflow: 'hidden',
  },
  bar: {
    flex: 1,
    minWidth: 2,
    borderRadius: 1,
  },
});
