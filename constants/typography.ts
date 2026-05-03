import { Platform } from 'react-native';

// Monospace for data, numbers, labels. Sans-serif for prose.
export const FONTS = {
  mono: Platform.select({
    ios: 'Courier New',
    android: 'monospace',
    default: 'monospace',
  }) as string,

  sans: Platform.select({
    ios: 'System',
    android: 'sans-serif',
    default: 'sans-serif',
  }) as string,

  sizes: {
    xs: 10,
    sm: 11,
    base: 13,
    md: 15,
    lg: 17,
    xl: 21,
    xxl: 27,
    xxxl: 36,
    display: 48,
  },

  weights: {
    regular: '400' as const,
    medium: '500' as const,
    semibold: '600' as const,
    bold: '700' as const,
    black: '900' as const,
  },

  tracking: {
    tighter: -1,
    tight: -0.4,
    normal: 0,
    wide: 0.8,
    wider: 1.5,
    widest: 3,
    // For ALL-CAPS labels
    label: 2,
  },

  lineHeights: {
    tight: 1.2,
    normal: 1.5,
    relaxed: 1.7,
  },
} as const;
