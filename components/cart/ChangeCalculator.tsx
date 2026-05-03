import React, { useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { NumericKeypad } from '@/components/ui/NumericKeypad';
import { formatZAR, calculateChange } from '@/lib/currency';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface ChangeCalculatorProps {
  totalAmount: number;
  onCashConfirmed: (cashReceived: number, change: number) => void;
}

export function ChangeCalculator({ totalAmount, onCashConfirmed }: ChangeCalculatorProps) {
  const [input, setInput] = useState('');

  const cashReceived = parseFloat(input) || 0;
  const change = calculateChange(cashReceived, totalAmount);
  const isEnough = cashReceived >= totalAmount;

  const handleKey = (key: string) => {
    if (key === '⌫') {
      setInput((prev) => prev.slice(0, -1));
      return;
    }
    if (key === '.' && input.includes('.')) return;
    if (input === '0' && key !== '.') {
      setInput(key);
      return;
    }
    const next = input + key;
    // Limit to 2 decimal places
    const parts = next.split('.');
    if (parts[1] && parts[1].length > 2) return;
    setInput(next);

    if (parseFloat(next) >= totalAmount) {
      onCashConfirmed(parseFloat(next), calculateChange(parseFloat(next), totalAmount));
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Cash received from customer</Text>

      <View style={styles.display}>
        <Text style={styles.inputText}>{input ? `R${input}` : 'R0'}</Text>
      </View>

      {input.length > 0 && (
        <View style={[styles.changeBox, isEnough ? styles.changeBoxOk : styles.changeBoxError]}>
          {isEnough ? (
            <>
              <Text style={styles.changeLabel}>Change to give</Text>
              <Text style={styles.changeAmount}>{formatZAR(change)}</Text>
            </>
          ) : (
            <Text style={styles.notEnough}>Not enough — need {formatZAR(totalAmount - cashReceived)} more</Text>
          )}
        </View>
      )}

      <NumericKeypad onPress={handleKey} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { paddingHorizontal: Spacing.md },
  label: { fontSize: FontSize.sm, color: Colors.gray500, marginBottom: Spacing.sm, textAlign: 'center' },
  display: {
    backgroundColor: Colors.gray100,
    borderRadius: BorderRadius.md,
    padding: Spacing.md,
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  inputText: { fontSize: FontSize.xxxl, fontWeight: '700', color: Colors.gray800 },
  changeBox: {
    borderRadius: BorderRadius.md,
    padding: Spacing.md,
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  changeBoxOk: { backgroundColor: '#D1FAE5' },
  changeBoxError: { backgroundColor: '#FEE2E2' },
  changeLabel: { fontSize: FontSize.sm, color: Colors.gray600, marginBottom: 4 },
  changeAmount: { fontSize: FontSize.xxl, fontWeight: '800', color: Colors.success },
  notEnough: { fontSize: FontSize.md, color: Colors.danger, fontWeight: '600', textAlign: 'center' },
});
