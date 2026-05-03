import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ActivityIndicator, ViewStyle } from 'react-native';
import { Colors, BorderRadius, FontSize, Spacing } from '@/constants/theme';

interface ButtonProps {
  label: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  disabled?: boolean;
  style?: ViewStyle;
}

export function Button({ label, onPress, variant = 'primary', size = 'md', loading, disabled, style }: ButtonProps) {
  const isDisabled = disabled || loading;

  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={isDisabled}
      activeOpacity={0.75}
      style={[styles.base, styles[variant], styles[size], isDisabled && styles.disabled, style]}
    >
      {loading ? (
        <ActivityIndicator color={variant === 'primary' ? Colors.white : Colors.primary} size="small" />
      ) : (
        <Text style={[styles.label, styles[`${variant}Label`], styles[`${size}Label`]]}>{label}</Text>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: BorderRadius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primary: { backgroundColor: Colors.primary },
  secondary: { backgroundColor: Colors.gray100, borderWidth: 1, borderColor: Colors.border },
  danger: { backgroundColor: Colors.danger },
  ghost: { backgroundColor: 'transparent' },
  sm: { paddingVertical: Spacing.xs, paddingHorizontal: Spacing.sm },
  md: { paddingVertical: Spacing.sm + 2, paddingHorizontal: Spacing.lg },
  lg: { paddingVertical: Spacing.md, paddingHorizontal: Spacing.xl },
  disabled: { opacity: 0.5 },
  label: { fontWeight: '600' },
  primaryLabel: { color: Colors.white },
  secondaryLabel: { color: Colors.gray800 },
  dangerLabel: { color: Colors.white },
  ghostLabel: { color: Colors.primary },
  smLabel: { fontSize: FontSize.sm },
  mdLabel: { fontSize: FontSize.md },
  lgLabel: { fontSize: FontSize.lg },
});
