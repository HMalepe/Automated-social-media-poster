import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Pressable,
  ListRenderItemInfo,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { COLORS, FONTS, SPACING, SCREEN_PADDING } from '../constants';
import RecordingCard from '../components/RecordingCard';
import StatsBar from '../components/StatsBar';
import WatchStatusBanner from '../components/WatchStatusBanner';
import InsightsTicker from '../components/InsightsTicker';
import PatternAlert from '../components/PatternAlert';
import EmptyState from '../components/EmptyState';

import {
  MOCK_RECORDINGS,
  MOCK_WEEK_STATS,
  MOCK_WATCH_STATE,
  MOCK_PATTERN_ALERTS,
} from '../mock/recordings';
import type { Recording, WatchState } from '../types';

// ─── Relative time helper ────────────────────────────────────────────────────

function relativeTime(date: Date): string {
  const diffMs = Date.now() - date.getTime();
  const diffMin = Math.round(diffMs / 60_000);
  if (diffMin < 1) return 'just now';
  if (diffMin === 1) return '1m ago';
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffH = Math.floor(diffMin / 60);
  return `${diffH}h ago`;
}

// ─── Sub-components ───────────────────────────────────────────────────────────

function Header({
  watchState,
  onSettingsPress,
}: {
  watchState: WatchState;
  onSettingsPress: () => void;
}) {
  const isRecording = watchState.status === 'recording';
  const isSyncing = watchState.status === 'syncing';
  const syncedAt = watchState.lastSyncedAt;

  let watchLabel = '';
  if (isRecording) watchLabel = 'Recording…';
  else if (isSyncing) watchLabel = 'Syncing…';
  else if (syncedAt) watchLabel = `Synced ${relativeTime(syncedAt)}`;
  else watchLabel = 'Watch not connected';

  const watchDotColor =
    isRecording ? COLORS.accent :
    isSyncing ? COLORS.textSecondary :
    syncedAt ? COLORS.textMuted : COLORS.error;

  return (
    <View style={styles.header}>
      {/* App wordmark */}
      <Text style={styles.wordmark}>ECHO</Text>

      {/* Watch sync status — center */}
      <View style={styles.watchStatus}>
        <View style={[styles.watchDot, { backgroundColor: watchDotColor }]} />
        <Text style={styles.watchLabel}>{watchLabel}</Text>
      </View>

      {/* Settings */}
      <Pressable
        style={({ pressed }) => [styles.headerButton, pressed && styles.headerButtonPressed]}
        onPress={onSettingsPress}
        hitSlop={12}
      >
        <Ionicons name="settings-outline" size={18} color={COLORS.textSecondary} />
      </Pressable>
    </View>
  );
}

function SectionHeader({ title, count }: { title: string; count: number }) {
  return (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <Text style={styles.sectionCount}>{count}</Text>
    </View>
  );
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────

export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  const [recordings] = useState<Recording[]>(MOCK_RECORDINGS);

  const handleRecordingPress = useCallback((id: string) => {
    router.push(`/recording/${id}`);
  }, []);

  const handleSettingsPress = useCallback(() => {
    router.push('/settings');
  }, []);

  // Renders each recording card — called by FlatList
  const renderItem = useCallback(
    ({ item, index }: ListRenderItemInfo<Recording>) => (
      <RecordingCard
        recording={item}
        onPress={handleRecordingPress}
        isLatest={index === 0}
      />
    ),
    [handleRecordingPress]
  );

  // Everything above the recording list renders as FlatList header component.
  // This keeps scrolling seamless — header scrolls with the list.
  const ListHeader = useCallback(
    () => (
      <View>
        {/* ── Insights ticker ── */}
        <InsightsTicker stats={MOCK_WEEK_STATS} />

        {/* ── Stats dashboard ── */}
        <View style={styles.statsSection}>
          <StatsBar stats={MOCK_WEEK_STATS} />
        </View>

        {/* ── Pattern alert (AI cross-session insight) ── */}
        {MOCK_PATTERN_ALERTS.length > 0 && (
          <PatternAlert alert={MOCK_PATTERN_ALERTS[0]} />
        )}

        {/* ── Section heading ── */}
        <SectionHeader
          title="RECENT SESSIONS"
          count={recordings.length}
        />
      </View>
    ),
    [recordings.length]
  );

  const ListEmpty = useCallback(() => <EmptyState />, []);

  const keyExtractor = useCallback((item: Recording) => item.id, []);

  return (
    <View style={[styles.screen, { paddingTop: insets.top }]}>
      {/* ── Fixed header — doesn't scroll ── */}
      <Header
        watchState={MOCK_WATCH_STATE}
        onSettingsPress={handleSettingsPress}
      />

      {/* ── Scrollable recording list with header ── */}
      <FlatList
        data={recordings}
        keyExtractor={keyExtractor}
        renderItem={renderItem}
        ListHeaderComponent={ListHeader}
        ListEmptyComponent={ListEmpty}
        contentContainerStyle={[
          styles.listContent,
          recordings.length === 0 && styles.listContentEmpty,
        ]}
        showsVerticalScrollIndicator={false}
        // Performance: recordings don't change in this mock
        removeClippedSubviews
        maxToRenderPerBatch={4}
        initialNumToRender={3}
      />

      {/* ── Fixed bottom Watch status bar ── */}
      <View style={{ paddingBottom: insets.bottom }}>
        <WatchStatusBanner watchState={MOCK_WATCH_STATE} onOpenWatch={() => {}} />
      </View>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: COLORS.background,
  },

  // ── Header
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: SCREEN_PADDING,
    paddingVertical: SPACING.base,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
    backgroundColor: COLORS.background,
  },
  wordmark: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.lg,
    color: COLORS.textPrimary,
    fontWeight: FONTS.weights.black,
    letterSpacing: FONTS.tracking.widest,
    // Tight optical correction for all-caps mono wordmark
    marginRight: SPACING.sm,
  },
  watchStatus: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: SPACING.xs,
  },
  watchDot: {
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  watchLabel: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.wide,
  },
  headerButton: {
    padding: SPACING.xs,
  },
  headerButtonPressed: {
    opacity: 0.5,
  },

  // ── Stats section
  statsSection: {
    paddingTop: SPACING.xl,
    paddingBottom: SPACING.base,
  },

  // ── Section header
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    paddingHorizontal: SCREEN_PADDING,
    paddingBottom: SPACING.sm,
    paddingTop: SPACING.xs,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    marginBottom: SPACING.sm,
  },
  sectionTitle: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textSecondary,
    letterSpacing: FONTS.tracking.label,
    fontWeight: FONTS.weights.bold,
  },
  sectionCount: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.wide,
  },

  // ── List
  listContent: {
    paddingBottom: SPACING.xxl,
  },
  listContentEmpty: {
    flex: 1,
  },
});
