import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/meal.dart';

class MealRepository {
  MealRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _meals => _db.collection('meals');

  Stream<List<Meal>> streamMeals({
    required String messId,
    required String month, // yyyy-MM
    String? memberId,
  }) {
    final start = DateTime.parse('$month-01');
    final end = DateTime(start.year, start.month + 1, 1);
    final startStr = DateFormatter.dayString(start);
    final endStr = DateFormatter.dayString(end);

    Query<Map<String, dynamic>> query = _meals
        .where('messId', isEqualTo: messId)
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThan: endStr);
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }

    final primary = query.snapshots().map(
      (snapshot) => snapshot.docs.map((d) => Meal.fromJson(d.data(), d.id)).toList(),
    );

    final fallback = _meals.where('messId', isEqualTo: messId).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => Meal.fromJson(d.data(), d.id))
          .where((meal) =>
              meal.date.compareTo(startStr) >= 0 &&
              meal.date.compareTo(endStr) < 0 &&
              (memberId == null || meal.memberId == memberId))
          .toList();
      return list;
    });

    // Start with the indexed query; if Firestore complains about missing index,
    // fall back to the messId-only query and filter client-side.
    return Stream.multi((controller) {
      StreamSubscription<List<Meal>>? sub;
      void listenPrimary() {
        sub = primary.listen(
          controller.add,
          onError: (error, stack) {
            if (error is FirebaseException && error.code == 'failed-precondition') {
              sub?.cancel();
              sub = fallback.listen(controller.add, onError: controller.addError);
            } else {
              controller.addError(error, stack);
            }
          },
          onDone: controller.close,
        );
      }

      listenPrimary();
      controller.onCancel = () => sub?.cancel();
    });
  }

  Future<Meal?> fetchMeal(String id) async {
    final doc = await _meals.doc(id).get();
    if (!doc.exists) return null;
    return Meal.fromJson(doc.data()!, doc.id);
  }

  Future<void> upsertMeal(Meal meal) async {
    final doc = meal.id.isEmpty ? _meals.doc() : _meals.doc(meal.id);
    await doc.set(meal.copyWith(createdAt: meal.createdAt ?? DateTime.now()).toJson());
  }

  Future<void> addQuickToday({
    required String messId,
    required String memberId,
    double breakfast = 1,
    double lunch = 1,
    double dinner = 1,
  }) async {
    final today = DateFormatter.dayString(DateTime.now());
    final doc = _meals.doc();
    final meal = Meal(
      id: doc.id,
      messId: messId,
      memberId: memberId,
      date: today,
      breakfastCount: breakfast,
      lunchCount: lunch,
      dinnerCount: dinner,
    );
    await doc.set(meal.toJson());
  }

  Future<void> deleteMeal(String id) => _meals.doc(id).delete();
}

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(FirebaseFirestore.instance);
});
