import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface NumericKeypadProps {
  onPress: (key: string) => void;
}

const KEYS = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  ['.', '0', '⌫'],
];

export function NumericKeypad({ onPress }: NumericKeypadProps) {
  return (
    <View style={styles.container}>
      {KEYS.map((row, ri) => (
        <View key={ri} style={styles.row}>
          {row.map((key) => (
            <TouchableOpacity
              key={key}
              style={styles.key}
              onPress={() => onPress(key)}
              activeOpacity={0.7}
            >
              <Text style={styles.keyText}>{key}</Text>
            </TouchableOpacity>
          ))}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { width: '100%' },
  row: { flexDirection: 'row', marginBottom: Spacing.xs },
  key: {
    flex: 1,
    marginHorizontal: Spacing.xs / 2,
    height: 64,
    borderRadius: BorderRadius.md,
    backgroundColor: Colors.gray100,
    alignItems: 'center',
    justifyContent: 'center',
  },
  keyText: {
    fontSize: FontSize.xl,
    fontWeight: '500',
    color: Colors.gray800,
  },
});
