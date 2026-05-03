export const COLORS = {
  // Backgrounds
  background: '#0A0A0A',
  surface: '#111111',
  surfaceElevated: '#161616',
  surfaceHover: '#1A1A1A',

  // Borders
  border: '#1E1E1E',
  borderSubtle: '#141414',

  // Typography
  textPrimary: '#F0EEE9',
  textSecondary: '#888888',
  textMuted: '#3D3D3D',
  textDisabled: '#2A2A2A',

  // Accent — electric lime, use sparingly
  accent: '#C8FF00',
  accentDim: 'rgba(200, 255, 0, 0.12)',
  accentSubtle: 'rgba(200, 255, 0, 0.06)',

  // Semantic
  error: '#FF4444',
  warning: '#FFB800',

  // Energy arc gradient stops (low → high energy)
  energyLow: '#2A2A2A',
  energyMid: '#555555',
  energyHigh: '#C8FF00',

  // Transparent overlays
  overlay: 'rgba(10, 10, 10, 0.95)',
} as const;

export type ColorKey = keyof typeof COLORS;
