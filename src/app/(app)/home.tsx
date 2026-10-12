import { ScreenScaffold } from '@/components/ScreenScaffold';
import { fonts } from '@/theme/tokens';
import { StyleSheet, Text } from 'react-native';

export default function HomeScreen() {
  return (
    <ScreenScaffold
      title="Ready for day 1?"
      body="Check-in, live distance, and the streak ring land in later steps. Open the menu from the left, or swipe from the edge.">
      <Text style={styles.greeting}>Good evening</Text>
    </ScreenScaffold>
  );
}

const styles = StyleSheet.create({
  greeting: {
    marginTop: 20,
    fontFamily: fonts.bodyMedium,
    fontSize: 16,
    color: '#F5BD6E',
  },
});
