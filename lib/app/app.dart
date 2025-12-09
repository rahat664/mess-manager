import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/notifications/presentation/notification_listener.dart';
import '../features/notifications/presentation/notification_topic_subscriber.dart';
import '../features/notifications/providers/notification_providers.dart';
import 'router.dart';

class MessApp extends ConsumerStatefulWidget {
  const MessApp({super.key});

  @override
  ConsumerState<MessApp> createState() => _MessAppState();
}

class _MessAppState extends ConsumerState<MessApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service after the first build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return NotificationTopicSubscriber(
      child: NotificationListener(
        child: MaterialApp.router(
          title: 'Mess Manager',
          theme: AppTheme.light,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
