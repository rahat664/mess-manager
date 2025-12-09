import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/notification_service.dart';

/// Helper class to send notifications for various mess events.
class NotificationHelper {
  NotificationHelper({
    required NotificationService notificationService,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _notificationService = notificationService,
        _firestore = firestore,
        _auth = auth;

  final NotificationService _notificationService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Notify when a meal is added.
  Future<void> notifyMealAdded({
    required String messId,
    required String memberName,
    required String date,
  }) async {
    try {
      await _notificationService.showLocalNotification(
        title: 'Meal Added',
        body: '$memberName added meals for $date',
        payload: 'meal_added',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Notify when an expense is added.
  Future<void> notifyExpenseAdded({
    required String messId,
    required double amount,
    required String category,
    required String date,
  }) async {
    try {
      await _notificationService.showLocalNotification(
        title: 'New Expense',
        body: 'Expense of ৳$amount added for $category on $date',
        payload: 'expense_added',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Notify when a deposit is made.
  Future<void> notifyDepositMade({
    required String messId,
    required String memberName,
    required double amount,
    required String date,
  }) async {
    try {
      await _notificationService.showLocalNotification(
        title: 'Deposit Made',
        body: '$memberName deposited ৳$amount on $date',
        payload: 'deposit_made',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Notify about monthly report generation.
  Future<void> notifyMonthlyReport({
    required String messId,
    required String month,
    required double mealRate,
  }) async {
    try {
      await _notificationService.showLocalNotification(
        title: 'Monthly Report Ready',
        body: 'Report for $month is ready. Meal rate: ৳${mealRate.toStringAsFixed(2)}',
        payload: 'monthly_report',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Notify when a new member joins.
  Future<void> notifyNewMember({
    required String messId,
    required String memberName,
  }) async {
    try {
      await _notificationService.showLocalNotification(
        title: 'New Member',
        body: '$memberName joined the mess',
        payload: 'new_member',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Notify about pending balance/dues.
  Future<void> notifyDueReminder({
    required String messId,
    required double dueAmount,
  }) async {
    try {
      await _notificationService.showLocalNotification(
        title: 'Payment Reminder',
        body: 'You have a pending balance of ৳${dueAmount.toStringAsFixed(0)}',
        payload: 'due_reminder',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Notify about meal logging reminder.
  Future<void> notifyMealReminder() async {
    try {
      await _notificationService.showLocalNotification(
        title: 'Log Your Meals',
        body: "Don't forget to log today's meals!",
        payload: 'meal_reminder',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Subscribe to mess-specific topic for notifications.
  Future<void> subscribeToMessTopic(String messId) async {
    try {
      await _notificationService.subscribeToTopic('mess_$messId');
    } catch (e) {
      // Handle error silently
    }
  }

  /// Unsubscribe from mess-specific topic.
  Future<void> unsubscribeFromMessTopic(String messId) async {
    try {
      await _notificationService.unsubscribeFromTopic('mess_$messId');
    } catch (e) {
      // Handle error silently
    }
  }
}
