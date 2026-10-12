import { Logo } from '@/components/Logo';
import { Button } from '@/components/ui/Button';
import { colors, fonts, spacing } from '@/theme/tokens';
import { router } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function SignUpScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.root, { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 20 }]}>
      <Pressable accessibilityRole="button" accessibilityLabel="Back" onPress={() => router.back()}>
        <Text style={styles.back}>Back</Text>
      </Pressable>
      <Logo size="sm" />
      <Text style={styles.title}>Create your account</Text>
      <Text style={styles.body}>
        Full sign-up with two consent checkboxes, phone OTP, and Google arrives in step 2.
      </Text>
      <View style={styles.actions}>
        <Button label="Send OTP" onPress={() => router.replace('/home')} />
        <Button label="Continue with Google" variant="ghost" onPress={() => router.replace('/home')} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.background,
    paddingHorizontal: spacing[24],
  },
  back: {
    fontFamily: fonts.bodyMedium,
    color: colors.muted,
    fontSize: 16,
    marginBottom: spacing[24],
    minHeight: 44,
  },
  title: {
    fontFamily: fonts.headingBold,
    fontSize: 32,
    color: colors.text,
    marginTop: spacing[24],
  },
  body: {
    fontFamily: fonts.body,
    fontSize: 16,
    color: colors.muted,
    marginTop: spacing[8],
    lineHeight: 24,
  },
  actions: {
    marginTop: 'auto',
    gap: spacing[12],
  },
});
