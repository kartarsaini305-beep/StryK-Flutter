import { fonts } from '@/theme/tokens';
import { StyleSheet, Text, View, type ViewStyle } from 'react-native';

type LogoSize = 'sm' | 'md' | 'lg';

const sizes: Record<LogoSize, { fontSize: number; padH: number; padV: number; radius: number }> = {
  sm: { fontSize: 22, padH: 4, padV: 1, radius: 4 },
  md: { fontSize: 32, padH: 5, padV: 2, radius: 5 },
  lg: { fontSize: 48, padH: 7, padV: 3, radius: 6 },
};

type Props = {
  size?: LogoSize;
  style?: ViewStyle;
};

export function Logo({ size = 'md', style }: Props) {
  const s = sizes[size];
  const textStyle = {
    fontFamily: fonts.headingExtra,
    fontSize: s.fontSize,
    color: '#FFFFFF',
    letterSpacing: -0.6,
    lineHeight: s.fontSize * 1.15,
  };

  return (
    <View
      accessible
      accessibilityRole="image"
      accessibilityLabel="StryK"
      style={[styles.row, style]}>
      <Text style={textStyle}>St</Text>
      <View
        style={[
          styles.rWrap,
          {
            paddingHorizontal: s.padH,
            paddingVertical: s.padV,
            borderRadius: s.radius,
          },
        ]}>
        <Text style={[textStyle, { color: '#141414' }]}>r</Text>
      </View>
      <Text style={textStyle}>yK</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  rWrap: {
    backgroundColor: '#F5BD6E',
    marginHorizontal: 1,
  },
});
