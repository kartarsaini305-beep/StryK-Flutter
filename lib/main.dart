import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/app_controller.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = LocalStorageService();
  await storage.init();
  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWith((ref) => storage),
      ],
      child: const StrykApp(),
    ),
  );
}
