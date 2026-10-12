import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stryk/app.dart';
import 'package:stryk/providers/app_controller.dart';
import 'package:stryk/services/mock_auth_service.dart';
import 'package:stryk/widgets/stryk_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('splash shows StryK wordmark branding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => MockAuthService()),
        ],
        child: const StrykApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(StrykLogo), findsWidgets);
    expect(find.textContaining('JUST SHOWED UP'), findsNothing);
  });
}
