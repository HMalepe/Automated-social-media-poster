import type { Recording, WeekStats, WatchState, PatternAlert } from '../types';

// ─── Helper ───────────────────────────────────────────────────────────────────

// Generates a plausible energy arc for a conversation:
// conversations usually start cautious, peak in the middle, dip at the end.
function energyArc(
  shape: 'peak-early' | 'peak-late' | 'consistent' | 'fade' | 'volatile'
): { position: number; level: number }[] {
  const points = 24;
  return Array.from({ length: points }, (_, i) => {
    const t = i / (points - 1); // 0 → 1
    let level: number;
    switch (shape) {
      case 'peak-early':
        level = Math.round(30 + 65 * Math.exp(-3 * (t - 0.2) ** 2) + (Math.random() - 0.5) * 10);
        break;
      case 'peak-late':
        level = Math.round(25 + 70 * Math.exp(-4 * (t - 0.8) ** 2) + (Math.random() - 0.5) * 10);
        break;
      case 'consistent':
        level = Math.round(60 + (Math.random() - 0.5) * 20);
        break;
      case 'fade':
        level = Math.round(80 - 55 * t + (Math.random() - 0.5) * 10);
        break;
      case 'volatile':
        level = Math.round(40 + 50 * Math.sin(t * Math.PI * 3) + (Math.random() - 0.5) * 20);
        break;
    }
    return { position: Math.round(t * 100), level: Math.max(5, Math.min(100, level)) };
  });
}

// ─── Mock Recordings ─────────────────────────────────────────────────────────

export const MOCK_RECORDINGS: Recording[] = [
  {
    id: 'rec_001',
    timestamp: new Date('2026-05-03T14:32:00'),
    duration: 512,
    title: 'Investor Call — Series A Update',
    summary:
      "You dominated the narrative but left their hardest question hanging. They noticed.",
    tags: [
      { emoji: '😤', label: 'Passionate', type: 'emotion' },
      { emoji: '💡', label: 'In Flow', type: 'emotion' },
      { emoji: '📊', label: 'Fundraising', type: 'topic' },
    ],
    talkRatio: 74,
    keyTopics: ['ARR growth', 'Burn rate', 'Team scaling', 'Product roadmap'],
    energyArc: energyArc('fade'),
    wordCount: 2103,
    questionsAsked: 2,
    speakingPace: 187,
    fillerWordCount: 11,
    repeatedThemes: [
      { theme: 'product-market fit', count: 4 },
      { theme: 'team', count: 3 },
      { theme: 'Q3 targets', count: 3 },
    ],
  },
  {
    id: 'rec_002',
    timestamp: new Date('2026-05-02T10:15:00'),
    duration: 738,
    title: 'Sales Call — Enterprise Prospect (Deel)',
    summary:
      "You asked zero discovery questions in the first 8 minutes. They were waiting to be understood.",
    tags: [
      { emoji: '🤔', label: 'Uncertain', type: 'emotion' },
      { emoji: '💼', label: 'Sales', type: 'topic' },
      { emoji: '⚡', label: 'High Stakes', type: 'behavior' },
    ],
    talkRatio: 68,
    keyTopics: ['Compliance automation', 'Pricing', 'Security review', 'Timeline'],
    energyArc: energyArc('peak-late'),
    wordCount: 2891,
    questionsAsked: 4,
    speakingPace: 162,
    fillerWordCount: 23,
    repeatedThemes: [
      { theme: 'our platform', count: 6 },
      { theme: 'pricing', count: 4 },
      { theme: 'integration', count: 3 },
    ],
  },
  {
    id: 'rec_003',
    timestamp: new Date('2026-05-01T16:45:00'),
    duration: 1024,
    title: '1-on-1 — Head of Engineering',
    summary:
      "You gave feedback that was technically accurate but landed as criticism. Watch the framing.",
    tags: [
      { emoji: '🧊', label: 'Guarded', type: 'emotion' },
      { emoji: '🔧', label: 'Management', type: 'topic' },
      { emoji: '🎯', label: 'Direct', type: 'behavior' },
    ],
    talkRatio: 58,
    keyTopics: ['Sprint velocity', 'Team morale', 'Technical debt', 'Roadmap ownership'],
    energyArc: energyArc('consistent'),
    wordCount: 3210,
    questionsAsked: 9,
    speakingPace: 144,
    fillerWordCount: 7,
    repeatedThemes: [
      { theme: 'ownership', count: 5 },
      { theme: 'velocity', count: 4 },
      { theme: 'trust', count: 3 },
    ],
  },
  {
    id: 'rec_004',
    timestamp: new Date('2026-04-30T09:00:00'),
    duration: 334,
    title: 'Board Check-in — Weekly Sync',
    summary:
      "Tightest version of yourself this week. Confident, brief, no filler. Do more of this.",
    tags: [
      { emoji: '💪', label: 'Confident', type: 'emotion' },
      { emoji: '📈', label: 'Strategic', type: 'behavior' },
      { emoji: '🏢', label: 'Board', type: 'topic' },
    ],
    talkRatio: 45,
    keyTopics: ['KPIs', 'Hiring pipeline', 'Customer churn', 'Next quarter'],
    energyArc: energyArc('consistent'),
    wordCount: 876,
    questionsAsked: 6,
    speakingPace: 153,
    fillerWordCount: 3,
    repeatedThemes: [
      { theme: 'Q2 targets', count: 4 },
      { theme: 'churn', count: 3 },
    ],
  },
  {
    id: 'rec_005',
    timestamp: new Date('2026-04-29T13:30:00'),
    duration: 891,
    title: 'Coaching Session — Executive Coach',
    summary:
      "You deflected every question about your co-founder relationship. That's where the tension lives.",
    tags: [
      { emoji: '🔍', label: 'Introspective', type: 'emotion' },
      { emoji: '😶', label: 'Deflecting', type: 'behavior' },
      { emoji: '🧠', label: 'Self-Awareness', type: 'topic' },
    ],
    talkRatio: 62,
    keyTopics: ['Leadership identity', 'Co-founder dynamic', 'Anxiety', 'Vision clarity'],
    energyArc: energyArc('volatile'),
    wordCount: 2654,
    questionsAsked: 1,
    speakingPace: 139,
    fillerWordCount: 41,
    repeatedThemes: [
      { theme: "I don't know", count: 7 },
      { theme: 'eventually', count: 5 },
      { theme: 'co-founder', count: 4 },
    ],
  },
  {
    id: 'rec_006',
    timestamp: new Date('2026-04-28T15:00:00'),
    duration: 623,
    title: 'Partnership Call — Potential Integration Partner',
    summary:
      "You built genuine rapport in the first 5 minutes — rare for you. Replicate this opener.",
    tags: [
      { emoji: '🤝', label: 'Warm', type: 'emotion' },
      { emoji: '💡', label: 'Curious', type: 'behavior' },
      { emoji: '🔗', label: 'Partnerships', type: 'topic' },
    ],
    talkRatio: 49,
    keyTopics: ['API integration', 'Revenue share', 'Customer overlap', 'Timeline'],
    energyArc: energyArc('peak-early'),
    wordCount: 1987,
    questionsAsked: 11,
    speakingPace: 158,
    fillerWordCount: 9,
    repeatedThemes: [
      { theme: 'mutual value', count: 4 },
      { theme: 'users', count: 5 },
      { theme: 'next steps', count: 3 },
    ],
  },
];

// ─── Week Stats ───────────────────────────────────────────────────────────────

export const MOCK_WEEK_STATS: WeekStats = {
  sessionCount: 6,
  totalDurationSeconds: MOCK_RECORDINGS.reduce((sum, r) => sum + r.duration, 0),
  topTopic: 'Leadership',
  moodSummary: "You've been 40% more assertive than last month",
  assertivenessChangePct: 40,
  // Week of Apr 28 – May 3: Mon–Sun
  // Mon=Apr28 ✓, Tue=Apr29 ✓, Wed=Apr30 ✓, Thu=May01 ✓, Fri=May02 ✓, Sat=May03 ✓, Sun=May04 ✗
  recordedDays: [true, true, true, true, true, true, false],
  avgTalkRatio: Math.round(
    MOCK_RECORDINGS.reduce((sum, r) => sum + r.talkRatio, 0) / MOCK_RECORDINGS.length
  ),
  avgFillerWordsPerMin:
    Math.round(
      (MOCK_RECORDINGS.reduce((sum, r) => sum + r.fillerWordCount, 0) /
        (MOCK_RECORDINGS.reduce((sum, r) => sum + r.duration, 0) / 60)) *
        10
    ) / 10,
};

// ─── Watch State ──────────────────────────────────────────────────────────────

export const MOCK_WATCH_STATE: WatchState = {
  status: 'connected',
  lastSyncedAt: new Date(Date.now() - 4 * 60 * 1000), // 4 minutes ago
  recordingDurationSeconds: 0,
};

// ─── Pattern Alerts ───────────────────────────────────────────────────────────

export const MOCK_PATTERN_ALERTS: PatternAlert[] = [
  {
    id: 'pat_001',
    title: 'You talk 70%+ of the time in high-stakes calls',
    description:
      'In 4 of 6 sessions this week, you spoke over 68% of the time. The calls you rated as "successful" averaged 49% talk ratio.',
    occurrences: 4,
    totalSessions: 6,
    severity: 'notable',
  },
];
