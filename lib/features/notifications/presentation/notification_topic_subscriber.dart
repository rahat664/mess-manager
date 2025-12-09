import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mess/providers/mess_providers.dart';
import '../providers/notification_providers.dart';

/// Widget that manages notification topic subscriptions based on current mess.
class NotificationTopicSubscriber extends ConsumerStatefulWidget {
  const NotificationTopicSubscriber({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationTopicSubscriber> createState() => _NotificationTopicSubscriberState();
}

class _NotificationTopicSubscriberState extends ConsumerState<NotificationTopicSubscriber> {
  String? _currentSubscribedMessId;

  @override
  Widget build(BuildContext context) {
    // Listen to current mess changes
    ref.listen(currentMessProvider, (previous, next) {
      next.whenData((mess) {
        if (mess != null) {
          _subscribeTo(mess.id);
        }
      });
    });

    return widget.child;
  }

  Future<void> _subscribeTo(String messId) async {
    if (_currentSubscribedMessId == messId) return;

    final helper = ref.read(notificationHelperProvider);

    // Unsubscribe from previous mess if any
    if (_currentSubscribedMessId != null) {
      await helper.unsubscribeFromMessTopic(_currentSubscribedMessId!);
    }

    // Subscribe to new mess
    await helper.subscribeToMessTopic(messId);
    _currentSubscribedMessId = messId;
  }

  @override
  void dispose() {
    // Optionally unsubscribe when widget is disposed
    // Note: In practice, we might want to keep subscriptions active
    super.dispose();
  }
}
