import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/analytics_logger.dart';

/// Top-level function for handling background messages.
/// This MUST be a top-level or static function.
/// Background messages are handled automatically by FCM.
/// Custom logic can be added here if needed (e.g., updating local state).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  // Don't call Firebase.initializeApp() here; it's already initialized.
  // The message is automatically displayed as a notification by the system.
  // Add custom logic here if you need to process the message data.
}

class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _messaging = messaging,
        _localNotifications = localNotifications,
        _firestore = firestore,
        _auth = auth;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final _notificationStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get notificationStream => _notificationStreamController.stream;

  bool _initialized = false;

  /// Initialize notification service.
  Future<void> initialize() async {
    if (_initialized) return;

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        notificationChannelId,
        notificationChannelName,
        description: notificationChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for notification taps (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _initialized = true;
  }

  /// Request notification permissions.
  Future<NotificationPermissionStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    NotificationPermissionStatus status;
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      status = NotificationPermissionStatus.granted;
      AnalyticsLogger.logNotificationPermission('granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      status = NotificationPermissionStatus.provisional;
      AnalyticsLogger.logNotificationPermission('provisional');
    } else {
      status = NotificationPermissionStatus.denied;
      AnalyticsLogger.logNotificationPermission('denied');
    }

    return status;
  }

  /// Get current notification permission status.
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      return NotificationPermissionStatus.granted;
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      return NotificationPermissionStatus.provisional;
    } else {
      return NotificationPermissionStatus.denied;
    }
  }

  /// Get FCM token and save it to Firestore.
  Future<String?> getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        AnalyticsLogger.logTokenUpdate();
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to a topic.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AnalyticsLogger.logTopicSubscription(topic);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AnalyticsLogger.logTopicUnsubscription(topic);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Delete FCM token.
  Future<void> deleteToken() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        });
      }
      await _messaging.deleteToken();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Send a local notification.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      notificationChannelId,
      notificationChannelName,
      channelDescription: notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Dispose resources.
  void dispose() {
    _notificationStreamController.close();
  }

  // Private methods

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _notificationStreamController.add(message);
    AnalyticsLogger.logNotificationReceived(message.data['type']?.toString() ?? 'unknown');

    // Show local notification for foreground messages
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'Mess Manager',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _notificationStreamController.add(message);
    AnalyticsLogger.logNotificationOpened(message.data['type']?.toString() ?? 'unknown');
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap from local notifications
    // The payload contains the notification data as a string
    // Navigation is handled by NotificationListener widget which listens to the stream
    // This is intentionally minimal as the main handling is done via the notification stream
  }
}

enum NotificationPermissionStatus {
  granted,
  denied,
  provisional,
}
