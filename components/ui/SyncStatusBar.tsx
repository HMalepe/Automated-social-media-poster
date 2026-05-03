import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors, FontSize, Spacing } from '@/constants/theme';
import { SyncStatus } from '@/types';

interface SyncStatusBarProps {
  status: SyncStatus;
  pendingCount: number;
}

export function SyncStatusBar({ status, pendingCount }: SyncStatusBarProps) {
  if (status === 'synced') return null;

  const config: Record<SyncStatus, { bg: string; text: string }> = {
    synced: { bg: Colors.success, text: 'All synced' },
    syncing: { bg: Colors.info, text: `Syncing ${pendingCount} sale${pendingCount !== 1 ? 's' : ''}...` },
    offline: { bg: Colors.warning, text: pendingCount > 0 ? `Offline — ${pendingCount} sale${pendingCount !== 1 ? 's' : ''} queued` : 'Offline mode' },
    error: { bg: Colors.danger, text: 'Sync error — will retry' },
  };

  const { bg, text } = config[status];

  return (
    <View style={[styles.bar, { backgroundColor: bg }]}>
      <Text style={styles.text}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    paddingVertical: Spacing.xs,
    paddingHorizontal: Spacing.md,
    alignItems: 'center',
  },
  text: {
    color: Colors.white,
    fontSize: FontSize.sm,
    fontWeight: '600',
  },
});
