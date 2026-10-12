import { colors, fonts, spacing } from '@/theme/tokens';
import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function TermsScreen() {
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.root, { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 16 }]}>
      <Pressable accessibilityRole="button" accessibilityLabel="Back" onPress={() => router.back()}>
        <Text style={styles.back}>Back</Text>
      </Pressable>
      <ScrollView>
        <Text style={styles.title}>Terms of use</Text>
        <Text style={styles.body}>
          Placeholder. By using StryK you agree to use the app for personal fitness tracking. Streak
          math is computed on the server. Anti-cheat checks may flag mock locations. Full terms will
          replace this text before store submission.
        </Text>
      </ScrollView>
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
    minHeight: 44,
  },
  title: {
    fontFamily: fonts.headingBold,
    fontSize: 28,
    color: colors.text,
    marginBottom: spacing[16],
  },
  body: {
    fontFamily: fonts.body,
    fontSize: 16,
    lineHeight: 24,
    color: colors.muted,
  },
});
