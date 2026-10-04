import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stryk/app.dart';
import 'package:stryk/core/constants/app_copy.dart';
import 'package:stryk/widgets/stryk_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('splash shows StryK logo without tagline', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StrykApp()));
    await tester.pump();
    expect(find.byType(StrykLogo), findsOneWidget);
    expect(find.text(AppCopy.tagline), findsNothing);
    expect(find.textContaining('JUST SHOWED UP'), findsNothing);
  });
}
