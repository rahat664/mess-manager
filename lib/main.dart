import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/notifications/providers/notification_providers.dart';

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
      
      // Create a container to initialize notification service
      final container = ProviderContainer();
      final notificationService = container.read(notificationServiceProvider);
      
      // Initialize notification service
      try {
        await notificationService.initialize();
      } catch (e) {
        debugPrint('Failed to initialize notifications: $e');
      }
      
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const MessApp(),
        ),
      );
    },
    (error, stack) => debugPrint('Uncaught error: $error'),
  );
}
