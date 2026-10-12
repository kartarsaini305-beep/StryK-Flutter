import { colors, fonts, spacing } from '@/theme/tokens';
import { type ReactNode } from 'react';
import { StyleSheet, Text, View } from 'react-native';

type Props = {
  title: string;
  body: string;
  children?: ReactNode;
};

export function ScreenScaffold({ title, body, children }: Props) {
  return (
    <View style={styles.wrap}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.body}>{body}</Text>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1,
    backgroundColor: colors.background,
    paddingHorizontal: spacing[20],
    paddingTop: spacing[24],
  },
  title: {
    fontFamily: fonts.headingBold,
    fontSize: 28,
    color: colors.text,
    marginBottom: spacing[8],
  },
  body: {
    fontFamily: fonts.body,
    fontSize: 16,
    lineHeight: 24,
    color: colors.muted,
  },
});
