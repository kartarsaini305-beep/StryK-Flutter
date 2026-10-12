import { FlameIcon } from '@/components/icons';
import { Logo } from '@/components/Logo';
import { Button } from '@/components/ui/Button';
import { useReduceMotion } from '@/hooks/use-reduce-motion';
import { colors, fonts, spacing } from '@/theme/tokens';
import { router } from 'expo-router';
import { MotiView } from 'moti';
import { StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function WelcomeScreen() {
  const insets = useSafeAreaInsets();
  const reduceMotion = useReduceMotion();

  return (
    <View style={[styles.root, { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 20 }]}>
      <View style={styles.hero}>
        <MotiView
          from={{ scale: reduceMotion ? 1 : 0.92, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ type: 'timing', duration: reduceMotion ? 0 : 500 }}
          style={styles.orb}>
          <MotiView
            from={{ scale: 1 }}
            animate={{ scale: reduceMotion ? 1 : 1.08 }}
            transition={{ type: 'timing', duration: 1400, loop: !reduceMotion, repeatReverse: true }}
            style={styles.orbInner}>
            <FlameIcon size={48} />
          </MotiView>
        </MotiView>
        <Logo size="lg" />
        <Text style={styles.headline}>Just show up. We keep the streak.</Text>
        <Text style={styles.sub}>
          Gym check-ins, a daily streak, and share cards when the workout is done.
        </Text>
      </View>
      <View style={styles.actions}>
        <Button label="Get started" onPress={() => router.push('/signup')} />
        <Button
          label="I already have an account"
          variant="ghost"
          onPress={() => router.push('/login')}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.background,
    paddingHorizontal: spacing[24],
    justifyContent: 'space-between',
  },
  hero: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[16],
  },
  orb: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[8],
    borderWidth: 1,
    borderColor: colors.border,
    shadowColor: colors.accent,
    shadowOpacity: 0.25,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 0 },
  },
  orbInner: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  headline: {
    fontFamily: fonts.headingBold,
    fontSize: 28,
    lineHeight: 34,
    color: colors.text,
    textAlign: 'center',
    maxWidth: 320,
  },
  sub: {
    fontFamily: fonts.body,
    fontSize: 16,
    lineHeight: 24,
    color: colors.muted,
    textAlign: 'center',
    maxWidth: 340,
  },
  actions: {
    gap: spacing[12],
  },
});
