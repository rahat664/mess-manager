import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/notification_service.dart';
import '../providers/notification_providers.dart';

/// Notification icon button for app bar.
class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(notificationPermissionProvider);

    return permissionAsync.when(
      loading: () => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.pushNamed(AppRoute.notificationSettings.name),
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_off_outlined),
        onPressed: () => context.pushNamed(AppRoute.notificationSettings.name),
      ),
      data: (status) {
        final icon = _getIconForStatus(status);
        final color = _getColorForStatus(status, context);
        
        return IconButton(
          icon: Badge(
            isLabelVisible: status == NotificationPermissionStatus.denied,
            backgroundColor: Colors.red,
            child: Icon(icon, color: color),
          ),
          tooltip: _getTooltipForStatus(status),
          onPressed: () => context.pushNamed(AppRoute.notificationSettings.name),
        );
      },
    );
  }

  IconData _getIconForStatus(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return Icons.notifications_active;
      case NotificationPermissionStatus.provisional:
        return Icons.notifications_outlined;
      case NotificationPermissionStatus.denied:
        return Icons.notifications_off_outlined;
    }
  }

  Color? _getColorForStatus(NotificationPermissionStatus status, BuildContext context) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return Colors.green;
      case NotificationPermissionStatus.provisional:
        return Colors.orange;
      case NotificationPermissionStatus.denied:
        return Colors.red;
    }
  }

  String _getTooltipForStatus(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Notifications enabled';
      case NotificationPermissionStatus.provisional:
        return 'Notifications provisional';
      case NotificationPermissionStatus.denied:
        return 'Notifications disabled';
    }
  }
}
