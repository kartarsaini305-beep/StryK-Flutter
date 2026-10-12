export const colors = {
  background: '#141414',
  surface: '#1E1E1E',
  surface2: '#282828',
  border: '#333333',
  text: '#FFFFFF',
  muted: '#9B9B9B',
  accent: '#F5BD6E',
  accentLight: '#FFD9A0',
  success: '#7FD6A0',
  danger: '#E5645F',
  overlay: 'rgba(0, 0, 0, 0.55)',
} as const;

export const spacing = {
  4: 4,
  8: 8,
  12: 12,
  16: 16,
  20: 20,
  24: 24,
  32: 32,
} as const;

export const radius = {
  input: 14,
  button: 16,
  card: 22,
  pill: 999,
} as const;

export const fonts = {
  headingBold: 'BricolageGrotesque-Bold',
  headingExtra: 'BricolageGrotesque-ExtraBold',
  body: 'DMSans-Regular',
  bodyMedium: 'DMSans-Medium',
  bodySemi: 'DMSans-SemiBold',
} as const;

export const minTapTarget = 44;

export const drawer = {
  widthRatio: 0.82,
  maxWidth: 330,
} as const;
