// ─── Insight Tags ────────────────────────────────────────────────────────────

export type InsightTagType = 'emotion' | 'topic' | 'behavior';

export interface InsightTag {
  emoji: string;
  label: string;
  type: InsightTagType;
}

// ─── Energy Arc ──────────────────────────────────────────────────────────────

// Sampled energy level at a point in the recording. position = 0–100 (% through).
export interface EnergyPoint {
  position: number;
  level: number; // 0–100
}

// ─── Recording ───────────────────────────────────────────────────────────────

export interface Recording {
  id: string;
  timestamp: Date;
  duration: number;       // seconds
  title: string;          // auto-generated context label
  summary: string;        // one-line TL;DR — the "sting in the tail" insight
  tags: InsightTag[];
  talkRatio: number;      // % of time YOU spoke
  keyTopics: string[];
  energyArc: EnergyPoint[];
  wordCount: number;
  questionsAsked: number;
  speakingPace: number;   // words per minute
  fillerWordCount: number; // um, uh, like, you know
  // Things you circled back to — "you mentioned X 3 times"
  repeatedThemes: Array<{ theme: string; count: number }>;
}

// ─── Week Stats ───────────────────────────────────────────────────────────────

export interface WeekStats {
  sessionCount: number;
  totalDurationSeconds: number;
  topTopic: string;
  moodSummary: string;
  // Positive = more assertive vs last week, negative = less
  assertivenessChangePct: number;
  // 7 booleans Mon–Sun — did they record on this day?
  recordedDays: boolean[];
  avgTalkRatio: number;
  avgFillerWordsPerMin: number;
}

// ─── Watch ───────────────────────────────────────────────────────────────────

export type WatchConnectionStatus =
  | 'not-paired'
  | 'not-reachable'
  | 'connected'
  | 'recording'
  | 'syncing';

export interface WatchState {
  status: WatchConnectionStatus;
  lastSyncedAt: Date | null;
  recordingDurationSeconds: number; // only relevant when status === 'recording'
}

// ─── Pattern Alert ────────────────────────────────────────────────────────────

// Cross-recording AI-detected behavioral pattern
export interface PatternAlert {
  id: string;
  title: string;
  description: string;
  occurrences: number;
  totalSessions: number;
  severity: 'observation' | 'notable' | 'critical';
}

// ─── Navigation Params ────────────────────────────────────────────────────────

export interface RecordingDetailParams {
  id: string;
}
