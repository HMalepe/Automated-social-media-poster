import React, { useEffect, useRef } from 'react';
import { View, Text, Animated, StyleSheet, Pressable } from 'react-native';
import { COLORS, FONTS, SPACING, SCREEN_PADDING } from '../constants';
import type { WatchState } from '../types';

interface Props {
  watchState: WatchState;
  onOpenWatch?: () => void;
}

export default function WatchStatusBanner({ watchState, onOpenWatch }: Props) {
  const pulseAnim = useRef(new Animated.Value(1)).current;

  // Pulsing animation only runs during active recording
  useEffect(() => {
    if (watchState.status !== 'recording') {
      pulseAnim.setValue(1);
      return;
    }

    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 0.25,
          duration: 900,
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 900,
          useNativeDriver: true,
        }),
      ])
    );
    loop.start();
    return () => loop.stop();
  }, [watchState.status, pulseAnim]);

  if (watchState.status === 'recording') {
    return <RecordingBanner durationSeconds={watchState.recordingDurationSeconds} pulseAnim={pulseAnim} />;
  }

  if (watchState.status === 'syncing') {
    return <SyncingBanner />;
  }

  // 'connected' or 'not-reachable' or 'not-paired'
  return (
    <Pressable style={styles.container} onPress={onOpenWatch}>
      <View style={styles.row}>
        <View style={[styles.statusDot, { backgroundColor: COLORS.textMuted }]} />
        <Text style={styles.nudgeText}>OPEN WATCH APP TO RECORD</Text>
        <Text style={styles.arrow}>→</Text>
      </View>
    </Pressable>
  );
}

function RecordingBanner({
  durationSeconds,
  pulseAnim,
}: {
  durationSeconds: number;
  pulseAnim: Animated.Value;
}) {
  const mm = String(Math.floor(durationSeconds / 60)).padStart(2, '0');
  const ss = String(durationSeconds % 60).padStart(2, '0');

  return (
    <View style={[styles.container, styles.containerRecording]}>
      <View style={styles.row}>
        <Animated.View
          style={[
            styles.statusDot,
            styles.statusDotRecording,
            { opacity: pulseAnim },
          ]}
        />
        <Text style={styles.recordingText}>RECORDING</Text>
        <Text style={styles.recordingTimer}>
          {mm}:{ss}
        </Text>
      </View>
      <Text style={styles.recordingHint}>Tap Watch crown to stop</Text>
    </View>
  );
}

function SyncingBanner() {
  return (
    <View style={[styles.container, styles.containerSyncing]}>
      <View style={styles.row}>
        <View style={[styles.statusDot, { backgroundColor: COLORS.textSecondary }]} />
        <Text style={styles.nudgeText}>SYNCING FROM WATCH…</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: SCREEN_PADDING,
    paddingVertical: SPACING.base,
    borderTopWidth: 1,
    borderColor: COLORS.border,
    backgroundColor: COLORS.surface,
    gap: SPACING.xs,
  },
  containerRecording: {
    borderTopColor: COLORS.accent,
    backgroundColor: COLORS.accentSubtle,
  },
  containerSyncing: {
    borderTopColor: COLORS.border,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  statusDotRecording: {
    backgroundColor: COLORS.accent,
  },
  nudgeText: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.base,
    color: COLORS.textSecondary,
    letterSpacing: FONTS.tracking.label,
    flex: 1,
  },
  arrow: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.base,
    color: COLORS.textMuted,
  },
  recordingText: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.base,
    color: COLORS.accent,
    letterSpacing: FONTS.tracking.label,
    fontWeight: FONTS.weights.bold,
    flex: 1,
  },
  recordingTimer: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.lg,
    color: COLORS.accent,
    fontWeight: FONTS.weights.bold,
    letterSpacing: FONTS.tracking.wide,
  },
  recordingHint: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.wide,
    marginLeft: SPACING.lg,
  },
});
