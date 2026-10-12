import { colors, fonts, radius, spacing } from '@/theme/tokens';
import { type ReactNode } from 'react';
import { ActivityIndicator, StyleSheet, Text, type ViewStyle } from 'react-native';

import { PressableScale } from './PressableScale';

type Variant = 'primary' | 'ghost';

type Props = {
  label: string;
  onPress: () => void;
  variant?: Variant;
  disabled?: boolean;
  loading?: boolean;
  icon?: ReactNode;
  style?: ViewStyle;
  accessibilityHint?: string;
};

export function Button({
  label,
  onPress,
  variant = 'primary',
  disabled = false,
  loading = false,
  icon,
  style,
  accessibilityHint,
}: Props) {
  const isDisabled = disabled || loading;
  const stylesForVariant = isDisabled ? styles.disabled : variant === 'primary' ? styles.primary : styles.ghost;
  const textStyle = isDisabled
    ? styles.disabledText
    : variant === 'primary'
      ? styles.primaryText
      : styles.ghostText;

  return (
    <PressableScale
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityHint={accessibilityHint}
      accessibilityState={{ disabled: isDisabled, busy: loading }}
      disabled={isDisabled}
      onPress={onPress}
      style={[styles.base, stylesForVariant, style]}>
      {loading ? (
        <ActivityIndicator color={variant === 'primary' ? '#141414' : colors.text} />
      ) : (
        <>
          {icon}
          <Text style={textStyle}>{label}</Text>
        </>
      )}
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 52,
    borderRadius: radius.button,
    paddingHorizontal: spacing[20],
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[8],
  },
  primary: {
    backgroundColor: colors.accent,
    shadowColor: colors.accent,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.35,
    shadowRadius: 16,
    elevation: 8,
  },
  ghost: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  disabled: {
    backgroundColor: colors.surface2,
  },
  primaryText: {
    fontFamily: fonts.bodySemi,
    fontSize: 16,
    color: '#141414',
  },
  ghostText: {
    fontFamily: fonts.bodySemi,
    fontSize: 16,
    color: colors.text,
  },
  disabledText: {
    fontFamily: fonts.bodySemi,
    fontSize: 16,
    color: colors.muted,
  },
});
