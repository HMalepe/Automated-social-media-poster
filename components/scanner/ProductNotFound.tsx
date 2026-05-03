import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import { Button } from '@/components/ui/Button';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface ProductNotFoundProps {
  barcode: string;
  onDismiss: () => void;
}

export function ProductNotFound({ barcode, onDismiss }: ProductNotFoundProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.icon}>🔍</Text>
      <Text style={styles.title}>Product not found</Text>
      <Text style={styles.barcode}>{barcode}</Text>
      <Text style={styles.subtitle}>This barcode isn't in your inventory yet.</Text>
      <Button
        label="Add product"
        onPress={() => {
          onDismiss();
          router.push({ pathname: '/product/new', params: { barcode } });
        }}
        style={styles.btn}
      />
      <Button
        label="Scan again"
        onPress={onDismiss}
        variant="ghost"
        style={styles.btn}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.surface,
    borderRadius: BorderRadius.lg,
    padding: Spacing.xl,
    alignItems: 'center',
    marginHorizontal: Spacing.md,
  },
  icon: { fontSize: 48, marginBottom: Spacing.sm },
  title: { fontSize: FontSize.xl, fontWeight: '700', color: Colors.gray800, marginBottom: Spacing.xs },
  barcode: {
    fontSize: FontSize.sm,
    color: Colors.gray400,
    fontFamily: 'monospace',
    marginBottom: Spacing.sm,
  },
  subtitle: { fontSize: FontSize.md, color: Colors.gray500, textAlign: 'center', marginBottom: Spacing.lg },
  btn: { width: '100%', marginBottom: Spacing.sm },
});
