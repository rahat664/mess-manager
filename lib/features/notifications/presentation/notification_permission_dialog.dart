import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_service.dart';
import '../providers/notification_providers.dart';

class NotificationPermissionDialog extends ConsumerStatefulWidget {
  const NotificationPermissionDialog({super.key});

  @override
  ConsumerState<NotificationPermissionDialog> createState() => _NotificationPermissionDialogState();
}

class _NotificationPermissionDialogState extends ConsumerState<NotificationPermissionDialog> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.notifications_active, size: 48),
      title: const Text('Enable Notifications'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stay updated with important mess activities:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _FeatureItem(
            icon: Icons.restaurant_menu,
            text: 'Meal entries and updates',
          ),
          SizedBox(height: 8),
          _FeatureItem(
            icon: Icons.shopping_bag,
            text: 'New expenses and bills',
          ),
          SizedBox(height: 8),
          _FeatureItem(
            icon: Icons.account_balance_wallet,
            text: 'Deposit confirmations',
          ),
          SizedBox(height: 8),
          _FeatureItem(
            icon: Icons.summarize,
            text: 'Monthly report reminders',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isRequesting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Not Now'),
        ),
        FilledButton.icon(
          onPressed: _isRequesting ? null : _requestPermission,
          icon: _isRequesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Enable'),
        ),
      ],
    );
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    try {
      final service = ref.read(notificationServiceProvider);
      final status = await service.requestPermission();
      
      if (status != NotificationPermissionStatus.denied) {
        // Get and save FCM token
        await service.getAndSaveToken();
        
        // Invalidate providers to refresh state
        ref.invalidate(notificationPermissionProvider);
        ref.invalidate(fcmTokenProvider);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to enable notifications: $e')),
        );
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}

/// Shows notification permission dialog if not already requested.
Future<void> showNotificationPermissionDialogIfNeeded(BuildContext context, WidgetRef ref) async {
  try {
    final service = ref.read(notificationServiceProvider);
    final status = await service.getPermissionStatus();
    
    // Only show if permission was never requested (denied by default on first run)
    if (status == NotificationPermissionStatus.denied && context.mounted) {
      await showDialog<bool>(
        context: context,
        builder: (context) => const NotificationPermissionDialog(),
      );
    }
  } catch (e) {
    // Silently handle errors
  }
}
