import { AppShell } from '@/components/navigation/AppShell';
import { colors } from '@/theme/tokens';
import { Stack } from 'expo-router';

export default function AppGroupLayout() {
  return (
    <AppShell>
      <Stack
        screenOptions={{
          headerShown: false,
          animation: 'ios_from_right',
          contentStyle: { backgroundColor: colors.background },
        }}
      />
    </AppShell>
  );
}
