import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/app_controller.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
