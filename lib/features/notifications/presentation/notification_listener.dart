import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../providers/notification_providers.dart';

/// Widget that listens to notification events and handles navigation.
class NotificationListener extends ConsumerWidget {
  const NotificationListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to notification stream
    ref.listen(notificationStreamProvider, (previous, next) {
      next.whenData((message) {
        _handleNotificationNavigation(context, message.data);
      });
    });

    return child;
  }

  void _handleNotificationNavigation(BuildContext context, Map<String, dynamic> data) {
    // Handle navigation based on notification type
    final type = data['type'] as String?;
    
    if (type == null) return;
    
    switch (type) {
      case 'meal_added':
        context.pushNamed(AppRoute.meals.name);
        break;
      case 'expense_added':
        context.pushNamed(AppRoute.expenses.name);
        break;
      case 'deposit_made':
        context.pushNamed(AppRoute.deposits.name);
        break;
      case 'monthly_report':
        context.pushNamed(AppRoute.report.name);
        break;
      case 'new_member':
        context.pushNamed(AppRoute.members.name);
        break;
      case 'due_reminder':
        context.pushNamed(AppRoute.dashboard.name);
        break;
      case 'meal_reminder':
        context.pushNamed(AppRoute.meals.name);
        break;
      default:
        // Unknown notification type, navigate to dashboard
        context.pushNamed(AppRoute.dashboard.name);
    }
  }
}
