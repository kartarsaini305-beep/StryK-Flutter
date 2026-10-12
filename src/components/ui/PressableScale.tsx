/* eslint-disable react-hooks/immutability -- Reanimated shared values are mutated on the UI thread */
import { useReduceMotion } from '@/hooks/use-reduce-motion';
import { minTapTarget } from '@/theme/tokens';
import { type ReactNode } from 'react';
import { Pressable, type PressableProps, type StyleProp, type ViewStyle } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

type Props = PressableProps & {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
};

export function PressableScale({ children, onPressIn, onPressOut, style, ...rest }: Props) {
  const reduceMotion = useReduceMotion();
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <AnimatedPressable
      {...rest}
      style={[animatedStyle, { minHeight: minTapTarget, minWidth: minTapTarget }, style]}
      onPressIn={(e) => {
        // Reanimated shared values are mutated by design.
        scale.value = withTiming(reduceMotion ? 1 : 0.97, { duration: reduceMotion ? 0 : 90 });
        onPressIn?.(e);
      }}
      onPressOut={(e) => {
        scale.value = withTiming(1, { duration: reduceMotion ? 0 : 120 });
        onPressOut?.(e);
      }}>
      {children}
    </AnimatedPressable>
  );
}
import { minTapTarget } from '@/theme/tokens';
import { type ReactNode } from 'react';
import { Pressable, type PressableProps, type StyleProp, type ViewStyle } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

type Props = PressableProps & {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
};

export function PressableScale({ children, onPressIn, onPressOut, style, ...rest }: Props) {
  const reduceMotion = useReduceMotion();
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <AnimatedPressable
      {...rest}
      style={[animatedStyle, { minHeight: minTapTarget, minWidth: minTapTarget }, style]}
      onPressIn={(e) => {
        scale.value = withTiming(reduceMotion ? 1 : 0.97, { duration: reduceMotion ? 0 : 90 });
        onPressIn?.(e);
      }}
      onPressOut={(e) => {
        scale.value = withTiming(1, { duration: reduceMotion ? 0 : 120 });
        onPressOut?.(e);
      }}>
      {children}
    </AnimatedPressable>
  );
}
