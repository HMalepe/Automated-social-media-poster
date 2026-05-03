import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  ScrollView,
} from 'react-native';
import { COLORS, FONTS, SPACING, SCREEN_PADDING, RADIUS } from '../constants';
import EnergySparkline from './EnergySparkline';
import TalkRatioBar from './TalkRatioBar';
import InsightTag from './InsightTag';
import type { Recording } from '../types';

interface Props {
  recording: Recording;
  onPress: (id: string) => void;
  // First card in the list gets an accent left-border — most recent = most relevant
  isLatest?: boolean;
}

// Format seconds → "8m 32s" or "1h 2m"
function formatDuration(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m ${s}s`;
}

// Format timestamp → "MAY 03  2:30 PM"
function formatTimestamp(date: Date): { date: string; time: string } {
  const d = date.toLocaleDateString('en-US', { month: 'short', day: '2-digit' }).toUpperCase();
  const t = date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  return { date: d, time: t };
}

export default function RecordingCard({ recording, onPress, isLatest }: Props) {
  const { date, time } = formatTimestamp(recording.timestamp);
  const duration = formatDuration(recording.duration);
  const mostRepeated = recording.repeatedThemes[0];

  return (
    <Pressable
      style={({ pressed }) => [
        styles.container,
        isLatest && styles.containerLatest,
        pressed && styles.containerPressed,
      ]}
      onPress={() => onPress(recording.id)}
    >
      {/* Accent left border for latest card */}
      {isLatest && <View style={styles.accentBar} />}

      <View style={styles.inner}>
        {/* ── Header row: date / time / duration ── */}
        <View style={styles.headerRow}>
          <View style={styles.dateGroup}>
            <Text style={styles.date}>{date}</Text>
            <Text style={styles.separator}>·</Text>
            <Text style={styles.time}>{time}</Text>
          </View>
          <Text style={styles.duration}>{duration}</Text>
        </View>

        {/* ── Title ── */}
        <Text style={styles.title} numberOfLines={1}>
          {recording.title.toUpperCase()}
        </Text>

        {/* ── Summary ── */}
        <Text style={styles.summary} numberOfLines={2}>
          {recording.summary}
        </Text>

        {/* ── Energy arc sparkline ── */}
        <View style={styles.sparklineWrapper}>
          <EnergySparkline data={recording.energyArc} height={20} />
        </View>

        {/* ── Talk ratio ── */}
        <TalkRatioBar talkRatio={recording.talkRatio} />

        {/* ── Insight tags (horizontal scroll so they never wrap) ── */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.tagsContainer}
        >
          {recording.tags.map((tag, i) => (
            <InsightTag key={i} tag={tag} />
          ))}
        </ScrollView>

        {/* ── Repeated theme callout ── */}
        {mostRepeated && (
          <View style={styles.repeatRow}>
            <Text style={styles.repeatIcon}>↩</Text>
            <Text style={styles.repeatText}>
              You mentioned{' '}
              <Text style={styles.repeatTheme}>"{mostRepeated.theme}"</Text>
              {' '}{mostRepeated.count}× — seems important
            </Text>
          </View>
        )}

        {/* ── Footer: word count + questions ── */}
        <View style={styles.footerRow}>
          <Text style={styles.footerStat}>
            {recording.wordCount.toLocaleString()} WORDS
          </Text>
          <Text style={styles.footerDot}>·</Text>
          <Text style={styles.footerStat}>
            {recording.questionsAsked} QUESTIONS ASKED
          </Text>
          <Text style={styles.footerDot}>·</Text>
          <Text style={styles.footerStat}>
            {recording.speakingPace} WPM
          </Text>
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    marginHorizontal: SCREEN_PADDING,
    marginBottom: SPACING.sm,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: RADIUS.xs,
    backgroundColor: COLORS.surface,
    overflow: 'hidden',
    flexDirection: 'row',
  },
  containerLatest: {
    borderColor: COLORS.border,
  },
  containerPressed: {
    backgroundColor: COLORS.surfaceHover,
  },
  accentBar: {
    width: 2,
    backgroundColor: COLORS.accent,
  },
  inner: {
    flex: 1,
    padding: SPACING.base,
    gap: SPACING.sm,
  },

  // Header
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  dateGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.xs,
  },
  date: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textSecondary,
    letterSpacing: FONTS.tracking.wide,
    fontWeight: FONTS.weights.semibold,
  },
  separator: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
  },
  time: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
  },
  duration: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.base,
    color: COLORS.textSecondary,
    fontWeight: FONTS.weights.bold,
    letterSpacing: FONTS.tracking.tight,
  },

  // Title
  title: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textPrimary,
    letterSpacing: FONTS.tracking.label,
    fontWeight: FONTS.weights.bold,
  },

  // Summary — this is the "sting" — the most important text in the card
  summary: {
    fontFamily: FONTS.sans,
    fontSize: FONTS.sizes.md,
    color: COLORS.textPrimary,
    lineHeight: FONTS.sizes.md * 1.5,
    fontWeight: FONTS.weights.regular,
  },

  // Sparkline
  sparklineWrapper: {
    marginVertical: SPACING.xs,
  },

  // Tags
  tagsContainer: {
    flexDirection: 'row',
    gap: SPACING.xs,
    paddingVertical: SPACING.xs,
  },

  // Repeated theme
  repeatRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: SPACING.xs,
    paddingTop: SPACING.xs,
    borderTopWidth: 1,
    borderColor: COLORS.borderSubtle,
  },
  repeatIcon: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  repeatText: {
    fontFamily: FONTS.sans,
    fontSize: FONTS.sizes.base,
    color: COLORS.textSecondary,
    flex: 1,
    lineHeight: FONTS.sizes.base * 1.5,
  },
  repeatTheme: {
    color: COLORS.textPrimary,
    fontWeight: FONTS.weights.medium,
  },

  // Footer stats
  footerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.xs,
    paddingTop: SPACING.xs,
    borderTopWidth: 1,
    borderColor: COLORS.borderSubtle,
  },
  footerStat: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textMuted,
    letterSpacing: FONTS.tracking.wide,
  },
  footerDot: {
    fontFamily: FONTS.mono,
    fontSize: FONTS.sizes.xs,
    color: COLORS.textDisabled,
  },
});
