import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/notifications/presentation/notification_listener.dart';
import '../features/notifications/presentation/notification_topic_subscriber.dart';
import 'router.dart';

class MessApp extends ConsumerWidget {
  const MessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
