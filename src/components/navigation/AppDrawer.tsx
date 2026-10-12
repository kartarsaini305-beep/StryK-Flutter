import {
  CalendarIcon,
  FlameIcon,
  HomeIcon,
  LogoutIcon,
  MapPinIcon,
  ShareIcon,
  UserIcon,
} from '@/components/icons';
import { Logo } from '@/components/Logo';
import { PressableScale } from '@/components/ui/PressableScale';
import { useReduceMotion } from '@/hooks/use-reduce-motion';
import { useUiStore } from '@/store/ui-store';
import { colors, drawer as drawerTokens, fonts, radius, spacing } from '@/theme/tokens';
import { router, usePathname } from 'expo-router';
import { MotiView } from 'moti';
import { useEffect } from 'react';
import { Pressable, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

const items = [
  { href: '/home', label: 'Home', Icon: HomeIcon },
  { href: '/streak', label: 'My streak', Icon: CalendarIcon },
  { href: '/share', label: 'Share card', Icon: ShareIcon },
  { href: '/gym', label: 'Change gym', Icon: MapPinIcon },
  { href: '/profile', label: 'Profile', Icon: UserIcon },
] as const;

type Props = {
  open: boolean;
};

export function AppDrawer({ open }: Props) {
  const insets = useSafeAreaInsets();
  const { width: screenWidth } = useWindowDimensions();
  const closeDrawer = useUiStore((s) => s.closeDrawer);
  const currentStreak = useUiStore((s) => s.currentStreak);
  const pathname = usePathname();
  const reduceMotion = useReduceMotion();
  const drawerWidth = Math.min(drawerTokens.maxWidth, screenWidth * drawerTokens.widthRatio);
  const translateX = useSharedValue(-drawerWidth);
  const backdrop = useSharedValue(0);

  useEffect(() => {
    const duration = reduceMotion ? 0 : 240;
    translateX.value = withTiming(open ? 0 : -drawerWidth, { duration });
    backdrop.value = withTiming(open ? 1 : 0, { duration: reduceMotion ? 0 : 200 });
  }, [backdrop, drawerWidth, open, reduceMotion, translateX]);

  const panelStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
    width: drawerWidth,
  }));

  const backdropStyle = useAnimatedStyle(() => ({
    opacity: backdrop.value,
  }));

  const closePan = Gesture.Pan().onEnd((e) => {
    if (e.translationX < -40) {
      runOnJS(closeDrawer)();
    }
  });

  return (
    <View pointerEvents={open ? 'auto' : 'none'} style={StyleSheet.absoluteFill}>
      <Animated.View style={[styles.backdropWrap, backdropStyle]}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Close menu"
          style={StyleSheet.absoluteFill}
          onPress={closeDrawer}
        />
      </Animated.View>
      <GestureDetector gesture={closePan}>
        <Animated.View
          style={[
            styles.panel,
            panelStyle,
            { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 16 },
          ]}>
          <View style={styles.header}>
            <Logo size="sm" />
          </View>
          <View style={styles.list}>
            {items.map((item, index) => {
              const active = pathname === item.href;
              return (
                <MotiView
                  key={`${item.href}-${open ? 'open' : 'closed'}`}
                  from={{ opacity: open && !reduceMotion ? 0 : 1, translateX: open && !reduceMotion ? -10 : 0 }}
                  animate={{ opacity: 1, translateX: 0 }}
                  transition={{
                    type: 'timing',
                    duration: reduceMotion || !open ? 0 : 220,
                    delay: reduceMotion || !open ? 0 : 40 + index * 40,
                  }}>
                  <PressableScale
                    accessibilityRole="button"
                    accessibilityLabel={item.label}
                    accessibilityState={{ selected: active }}
                    onPress={() => {
                      closeDrawer();
                      router.push(item.href);
                    }}
                    style={[styles.item, active && styles.itemActive]}>
                    <item.Icon color={active ? colors.accent : colors.text} />
                    <Text style={[styles.itemLabel, active && styles.itemLabelActive]}>{item.label}</Text>
                  </PressableScale>
                </MotiView>
              );
            })}
            <MotiView
              key={`logout-${open ? 'open' : 'closed'}`}
              from={{ opacity: open && !reduceMotion ? 0 : 1, translateX: open && !reduceMotion ? -10 : 0 }}
              animate={{ opacity: 1, translateX: 0 }}
              transition={{
                type: 'timing',
                duration: reduceMotion || !open ? 0 : 220,
                delay: reduceMotion || !open ? 0 : 280,
              }}>
              <PressableScale
                accessibilityRole="button"
                accessibilityLabel="Log out"
                onPress={() => {
                  closeDrawer();
                  router.replace('/');
                }}
                style={styles.item}>
                <LogoutIcon />
                <Text style={[styles.itemLabel, { color: colors.danger }]}>Log out</Text>
              </PressableScale>
            </MotiView>
          </View>
          <View style={styles.footer}>
            <FlameIcon size={18} />
            <Text style={styles.footerText}>
              Current streak · {currentStreak} {currentStreak === 1 ? 'day' : 'days'}
            </Text>
          </View>
        </Animated.View>
      </GestureDetector>
    </View>
  );
}

const styles = StyleSheet.create({
  backdropWrap: {
    ...StyleSheet.absoluteFill,
    backgroundColor: colors.overlay,
  },
  panel: {
    position: 'absolute',
    left: 0,
    top: 0,
    bottom: 0,
    backgroundColor: colors.surface,
    paddingHorizontal: spacing[16],
    borderRightWidth: 1,
    borderRightColor: colors.border,
  },
  header: {
    paddingBottom: spacing[20],
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.border,
  },
  list: {
    flex: 1,
    paddingTop: spacing[16],
    gap: spacing[4],
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[12],
    minHeight: 48,
    paddingHorizontal: spacing[12],
    borderRadius: radius.input,
  },
  itemActive: {
    backgroundColor: colors.surface2,
  },
  itemLabel: {
    fontFamily: fonts.bodyMedium,
    fontSize: 16,
    color: colors.text,
  },
  itemLabelActive: {
    color: colors.accent,
    fontFamily: fonts.bodySemi,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[8],
    paddingTop: spacing[16],
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: colors.border,
  },
  footerText: {
    fontFamily: fonts.body,
    fontSize: 14,
    color: colors.muted,
  },
});
