import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../../members/models/mess_member.dart';
import '../../reports/models/monthly_member_report.dart';

class ReportService {
  ReportService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _meals => _db.collection('meals');
  CollectionReference<Map<String, dynamic>> get _expenses => _db.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _deposits => _db.collection('deposits');
  CollectionReference<Map<String, dynamic>> get _members => _db.collection('messMembers');

  Future<double> totalMealsForMember(String messId, String memberId, String month) async {
    final (start, end) = _monthBounds(month);
    try {
      final snapshot = await _meals
          .where('messId', isEqualTo: messId)
          .where('memberId', isEqualTo: memberId)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end)
          .get();
      return _sumMeals(snapshot.docs.map((d) => d.data()));
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      final fallback =
          await _meals.where('messId', isEqualTo: messId).where('memberId', isEqualTo: memberId).get();
      final filtered =
          fallback.docs.map((d) => d.data()).where((data) => _withinRange(data['date'] as String?, start, end));
      return _sumMeals(filtered);
    }
  }

  Future<double> totalMealsForMess(String messId, String month) async {
    final (start, end) = _monthBounds(month);
    try {
      final snapshot = await _meals
          .where('messId', isEqualTo: messId)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end)
          .get();
      return _sumMeals(snapshot.docs.map((d) => d.data()));
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      final fallback = await _meals.where('messId', isEqualTo: messId).get();
      final filtered =
          fallback.docs.map((d) => d.data()).where((data) => _withinRange(data['date'] as String?, start, end));
      return _sumMeals(filtered);
    }
  }

  Future<double> totalExpensesForMess(String messId, String month) async {
    final (start, end) = _monthBounds(month);
    try {
      final snapshot = await _expenses
          .where('messId', isEqualTo: messId)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end)
          .get();
      return _sumAmounts(snapshot.docs.map((d) => d.data()));
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      final fallback = await _expenses.where('messId', isEqualTo: messId).get();
      final filtered =
          fallback.docs.map((d) => d.data()).where((data) => _withinRange(data['date'] as String?, start, end));
      return _sumAmounts(filtered);
    }
  }

  Future<double> totalDepositsForMember(String messId, String memberId, String month) async {
    final (start, end) = _monthBounds(month);
    try {
      final snapshot = await _deposits
          .where('messId', isEqualTo: messId)
          .where('memberId', isEqualTo: memberId)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end)
          .get();
      return _sumAmounts(snapshot.docs.map((d) => d.data()));
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      final fallback =
          await _deposits.where('messId', isEqualTo: messId).where('memberId', isEqualTo: memberId).get();
      final filtered =
          fallback.docs.map((d) => d.data()).where((data) => _withinRange(data['date'] as String?, start, end));
      return _sumAmounts(filtered);
    }
  }

  Future<double> mealRateForMess(String messId, String month) async {
    final totalMeals = await totalMealsForMess(messId, month);
    final totalExpenses = await totalExpensesForMess(messId, month);
    if (totalMeals == 0) return 0;
    return totalExpenses / totalMeals;
  }

  Future<double> memberCost(String messId, String memberId, String month) async {
    final memberMeals = await totalMealsForMember(messId, memberId, month);
    final rate = await mealRateForMess(messId, month);
    return memberMeals * rate;
  }

  Future<double> memberBalance(String messId, String memberId, String month) async {
    final deposit = await totalDepositsForMember(messId, memberId, month);
    final cost = await memberCost(messId, memberId, month);
    return deposit - cost;
  }

  Future<List<MonthlyMemberReport>> monthlyBreakdown(String messId, String month) async {
    final membersSnapshot = await _members.where('messId', isEqualTo: messId).get();
    final members = membersSnapshot.docs.map((d) => MessMember.fromJson(d.data(), d.id)).toList();
    final rate = await mealRateForMess(messId, month);

    final List<MonthlyMemberReport> rows = [];
    for (final member in members.where((m) => m.isActive)) {
      final meals = await totalMealsForMember(messId, member.userId, month);
      final deposits = await totalDepositsForMember(messId, member.userId, month);
      final cost = meals * rate;
      rows.add(
        MonthlyMemberReport(
          memberId: member.userId,
          memberName: member.name,
          totalMeals: meals,
          totalDeposits: deposits,
          cost: cost,
          balance: deposits - cost,
        ),
      );
    }
    return rows;
  }

  /// Returns inclusive start and exclusive end dates (yyyy-MM-dd) for a given yyyy-MM string.
  (String, String) _monthBounds(String month) {
    final start = DateTime.parse('$month-01');
    final end = DateTime(start.year, start.month + 1, 1);
    return (DateFormatter.dayString(start), DateFormatter.dayString(end));
  }

  bool _withinRange(String? date, String start, String end) {
    if (date == null) return false;
    return date.compareTo(start) >= 0 && date.compareTo(end) < 0;
  }

  double _sumMeals(Iterable<Map<String, dynamic>> items) {
    return items.fold<double>(
      0,
      (runningTotal, data) =>
          runningTotal +
          (data['breakfastCount'] as num? ?? 0).toDouble() +
          (data['lunchCount'] as num? ?? 0).toDouble() +
          (data['dinnerCount'] as num? ?? 0).toDouble(),
    );
  }

  double _sumAmounts(Iterable<Map<String, dynamic>> items) {
    return items.fold<double>(0, (runningTotal, data) => runningTotal + (data['amount'] as num? ?? 0).toDouble());
  }
}

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(FirebaseFirestore.instance);
});
