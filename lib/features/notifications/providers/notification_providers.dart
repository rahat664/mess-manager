import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_service.dart';
import '../data/notification_helper.dart';

/// Provider for FirebaseMessaging instance.
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// Provider for FlutterLocalNotificationsPlugin instance.
final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

/// Provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    messaging: ref.watch(firebaseMessagingProvider),
    localNotifications: ref.watch(localNotificationsProvider),
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Provider for NotificationHelper.
final notificationHelperProvider = Provider<NotificationHelper>((ref) {
  return NotificationHelper(
    notificationService: ref.watch(notificationServiceProvider),
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Provider for notification permission status.
final notificationPermissionProvider = FutureProvider<NotificationPermissionStatus>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getPermissionStatus();
});

/// Provider for FCM token.
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getAndSaveToken();
});

/// Provider for notification stream.
final notificationStreamProvider = StreamProvider<RemoteMessage>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationStream;
});

/// Provider for notification enabled state in user preferences.
/// Note: This is a simple in-memory state. For production, consider persisting
/// this to SharedPreferences or Firestore to maintain settings across app restarts.
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
