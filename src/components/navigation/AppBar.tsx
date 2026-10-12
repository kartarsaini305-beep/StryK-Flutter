import { Logo } from '@/components/Logo';
import { Hamburger } from '@/components/navigation/Hamburger';
import { ShareIcon } from '@/components/icons';
import { useReduceMotion } from '@/hooks/use-reduce-motion';
import { useUiStore } from '@/store/ui-store';
import { colors } from '@/theme/tokens';
import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export function AppBar() {
  const insets = useSafeAreaInsets();
  const { drawerOpen, toggleDrawer, closeDrawer } = useUiStore();
  const reduceMotion = useReduceMotion();

  return (
    <View style={[styles.bar, { paddingTop: insets.top + 6 }]}>
      <Hamburger open={drawerOpen} onPress={toggleDrawer} reduceMotion={reduceMotion} />
      <Logo size="sm" />
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Share card"
        hitSlop={8}
        style={styles.hit}
        onPress={() => {
          closeDrawer();
          router.push('/share');
        }}>
        <ShareIcon />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    backgroundColor: colors.background,
    paddingHorizontal: 8,
    paddingBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.border,
  },
  hit: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
