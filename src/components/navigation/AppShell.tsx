import { AppBar } from '@/components/navigation/AppBar';
import { AppDrawer } from '@/components/navigation/AppDrawer';
import { useUiStore } from '@/store/ui-store';
import { colors } from '@/theme/tokens';
import { type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { runOnJS } from 'react-native-reanimated';

type Props = {
  children: ReactNode;
};

export function AppShell({ children }: Props) {
  const drawerOpen = useUiStore((s) => s.drawerOpen);
  const openDrawer = useUiStore((s) => s.openDrawer);

  const edgeOpen = Gesture.Pan()
    .activeOffsetX(12)
    .failOffsetY([-20, 20])
    .onEnd((e) => {
      if (e.translationX > 36) {
        runOnJS(openDrawer)();
      }
    });

  return (
    <View style={styles.root}>
      <AppBar />
      <View style={styles.body}>
        <GestureDetector gesture={edgeOpen}>
          <View style={styles.edge} />
        </GestureDetector>
        {children}
      </View>
      <AppDrawer open={drawerOpen} />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.background,
  },
  body: {
    flex: 1,
  },
  edge: {
    position: 'absolute',
    left: 0,
    top: 0,
    bottom: 0,
    width: 24,
    zIndex: 2,
  },
});
