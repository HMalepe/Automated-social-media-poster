// 4px base grid — every value is a multiple of 4
export const SPACING = {
  px: 1,
  xs: 4,
  sm: 8,
  md: 12,
  base: 16,
  lg: 20,
  xl: 24,
  xxl: 32,
  xxxl: 48,
  section: 64,
} as const;

// Screen-level horizontal padding
export const SCREEN_PADDING = 20;

// Consistent border radius — minimal (we're brutalist)
export const RADIUS = {
  none: 0,
  xs: 2,
  sm: 4,
} as const;
