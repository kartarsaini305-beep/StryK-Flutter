import { colors } from '@/theme/tokens';
import { useEffect } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import Animated, {
  interpolate,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';

type Props = {
  open: boolean;
  onPress: () => void;
  reduceMotion?: boolean;
};

export function Hamburger({ open, onPress, reduceMotion = false }: Props) {
  const progress = useSharedValue(open ? 1 : 0);

  useEffect(() => {
    progress.value = withTiming(open ? 1 : 0, { duration: reduceMotion ? 0 : 220 });
  }, [open, progress, reduceMotion]);

  const top = useAnimatedStyle(() => ({
    transform: [
      { translateY: interpolate(progress.value, [0, 1], [0, 7]) },
      { rotate: `${interpolate(progress.value, [0, 1], [0, 45])}deg` },
    ],
  }));

  const mid = useAnimatedStyle(() => ({
    opacity: interpolate(progress.value, [0, 1], [1, 0]),
  }));

  const bottom = useAnimatedStyle(() => ({
    transform: [
      { translateY: interpolate(progress.value, [0, 1], [0, -7]) },
      { rotate: `${interpolate(progress.value, [0, 1], [0, -45])}deg` },
    ],
  }));

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={open ? 'Close menu' : 'Open menu'}
      onPress={onPress}
      hitSlop={8}
      style={styles.hit}>
      <View style={styles.box}>
        <Animated.View style={[styles.bar, top]} />
        <Animated.View style={[styles.bar, mid]} />
        <Animated.View style={[styles.bar, bottom]} />
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  hit: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 22,
    height: 16,
    justifyContent: 'space-between',
  },
  bar: {
    height: 2,
    borderRadius: 2,
    backgroundColor: colors.text,
    width: '100%',
  },
});
