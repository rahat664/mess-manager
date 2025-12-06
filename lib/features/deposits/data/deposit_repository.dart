import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/deposit.dart';

class DepositRepository {
  DepositRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _deposits => _db.collection('deposits');

  Stream<List<Deposit>> streamDeposits({
    required String messId,
    required String month,
    String? memberId,
  }) {
    final start = DateTime.parse('$month-01');
    final end = DateTime(start.year, start.month + 1, 1);
    final startStr = DateFormatter.dayString(start);
    final endStr = DateFormatter.dayString(end);

    Query<Map<String, dynamic>> query = _deposits
        .where('messId', isEqualTo: messId)
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThan: endStr);
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    final primary = query.snapshots().map(
      (snapshot) => snapshot.docs.map((d) => Deposit.fromJson(d.data(), d.id)).toList(),
    );

    final fallback = _deposits.where('messId', isEqualTo: messId).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => Deposit.fromJson(d.data(), d.id))
          .where((deposit) =>
              deposit.date.compareTo(startStr) >= 0 &&
              deposit.date.compareTo(endStr) < 0 &&
              (memberId == null || deposit.memberId == memberId))
          .toList();
      return list;
    });

    return Stream.multi((controller) {
      StreamSubscription<List<Deposit>>? sub;
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

  Future<Deposit?> fetchDeposit(String id) async {
    final doc = await _deposits.doc(id).get();
    if (!doc.exists) return null;
    return Deposit.fromJson(doc.data()!, doc.id);
  }

  Future<void> upsertDeposit(Deposit deposit) async {
    final doc = deposit.id.isEmpty ? _deposits.doc() : _deposits.doc(deposit.id);
    await doc.set(deposit.copyWith(createdAt: deposit.createdAt ?? DateTime.now()).toJson());
  }

  Future<void> deleteDeposit(String id) => _deposits.doc(id).delete();
}

final depositRepositoryProvider = Provider<DepositRepository>((ref) {
  return DepositRepository(FirebaseFirestore.instance);
});
