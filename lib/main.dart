import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Catch uncaught errors to avoid silent crashes in release.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };
      runApp(const ProviderScope(child: MessApp()));
    },
    (error, stack) => debugPrint('Uncaught error: $error'),
  );
}
