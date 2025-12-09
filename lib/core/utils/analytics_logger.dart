import 'package:flutter/foundation.dart';

/// Simple analytics logger for tracking events.
/// In production, this could be replaced with Firebase Analytics or similar.
class AnalyticsLogger {
  /// Log notification permission status change.
  static void logNotificationPermission(String status) {
    if (kDebugMode) {
      debugPrint('🔔 [Analytics] Notification permission: $status');
    }
  }

  /// Log FCM token update.
  static void logTokenUpdate() {
    if (kDebugMode) {
      debugPrint('🔔 [Analytics] FCM token updated');
    }
  }

  /// Log notification received.
  static void logNotificationReceived(String type) {
    if (kDebugMode) {
      debugPrint('🔔 [Analytics] Notification received: $type');
    }
  }

  /// Log notification opened.
  static void logNotificationOpened(String type) {
    if (kDebugMode) {
      debugPrint('🔔 [Analytics] Notification opened: $type');
    }
  }

  /// Log topic subscription.
  static void logTopicSubscription(String topic) {
    if (kDebugMode) {
      debugPrint('🔔 [Analytics] Subscribed to topic: $topic');
    }
  }

  /// Log topic unsubscription.
  static void logTopicUnsubscription(String topic) {
    if (kDebugMode) {
      debugPrint('🔔 [Analytics] Unsubscribed from topic: $topic');
    }
  }

  /// Log user event (generic).
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      debugPrint('📊 [Analytics] Event: $eventName ${parameters != null ? parameters.toString() : ""}');
    }
  }
}
