import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_loading.dart';
import '../data/notification_service.dart';
import '../providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(notificationPermissionProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: permissionAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Unable to load notification settings',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (status) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notification Status',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getStatusText(status),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: _getStatusColor(status),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (status == NotificationPermissionStatus.denied) ...[
                        const SizedBox(height: 12),
                        Text(
                          'To receive notifications, you need to grant permission in your device settings.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final service = ref.read(notificationServiceProvider);
                            final newStatus = await service.requestPermission();
                            if (newStatus != NotificationPermissionStatus.denied) {
                              ref.invalidate(notificationPermissionProvider);
                              ref.invalidate(fcmTokenProvider);
                            }
                          },
                          icon: const Icon(Icons.notification_add),
                          label: const Text('Request Permission'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: notificationsEnabled,
                      onChanged: status != NotificationPermissionStatus.denied
                          ? (value) {
                              ref.read(notificationsEnabledProvider.notifier).state = value;
                            }
                          : null,
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Receive notifications about mess activities'),
                      secondary: const Icon(Icons.notifications_active),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Notification Types',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Currently, all notification types are enabled when notifications are turned on. Per-type preferences coming soon.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    _NotificationTypeTile(
                      title: 'Meals Added',
                      subtitle: 'When you or others add meal entries',
                      icon: Icons.restaurant_menu,
                      enabled: notificationsEnabled && status != NotificationPermissionStatus.denied,
                    ),
                    const Divider(height: 1),
                    _NotificationTypeTile(
                      title: 'Expenses Added',
                      subtitle: 'When new expenses are recorded',
                      icon: Icons.shopping_bag,
                      enabled: notificationsEnabled && status != NotificationPermissionStatus.denied,
                    ),
                    const Divider(height: 1),
                    _NotificationTypeTile(
                      title: 'Deposits Made',
                      subtitle: 'When deposits are made to the mess',
                      icon: Icons.account_balance_wallet,
                      enabled: notificationsEnabled && status != NotificationPermissionStatus.denied,
                    ),
                    const Divider(height: 1),
                    _NotificationTypeTile(
                      title: 'Monthly Reports',
                      subtitle: 'When monthly reports are generated',
                      icon: Icons.summarize,
                      enabled: notificationsEnabled && status != NotificationPermissionStatus.denied,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'About Notifications',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stay updated with real-time notifications about mess activities. '
                        'You can control which notifications you receive and manage permissions at any time.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return Icons.check_circle;
      case NotificationPermissionStatus.provisional:
        return Icons.access_time;
      case NotificationPermissionStatus.denied:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return Colors.green;
      case NotificationPermissionStatus.provisional:
        return Colors.orange;
      case NotificationPermissionStatus.denied:
        return Colors.red;
    }
  }

  String _getStatusText(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Granted - You will receive notifications';
      case NotificationPermissionStatus.provisional:
        return 'Provisional - Notifications will appear quietly';
      case NotificationPermissionStatus.denied:
        return 'Denied - You will not receive notifications';
    }
  }
}

class _NotificationTypeTile extends StatelessWidget {
  const _NotificationTypeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      trailing: Icon(
        Icons.check,
        color: enabled ? Colors.green : Colors.grey,
      ),
    );
  }
}
