import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _expenses => _db.collection('expenses');

  Stream<List<Expense>> streamExpenses({
    required String messId,
    required String month,
    String? category,
  }) {
    final start = DateTime.parse('$month-01');
    final end = DateTime(start.year, start.month + 1, 1);
    final startStr = DateFormatter.dayString(start);
    final endStr = DateFormatter.dayString(end);

    Query<Map<String, dynamic>> query = _expenses
        .where('messId', isEqualTo: messId)
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThan: endStr);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    final primary = query.orderBy('date', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((d) => Expense.fromJson(d.data(), d.id)).toList(),
    );

    final fallback = _expenses.where('messId', isEqualTo: messId).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => Expense.fromJson(d.data(), d.id))
          .where((expense) =>
              expense.date.compareTo(startStr) >= 0 &&
              expense.date.compareTo(endStr) < 0 &&
              (category == null || category.isEmpty || expense.category == category))
          .toList()
        ..sort((a, b) {
          final cmp = b.date.compareTo(a.date);
          if (cmp != 0) return cmp;
          return b.id.compareTo(a.id);
        });
      return list;
    });

    return Stream.multi((controller) {
      StreamSubscription<List<Expense>>? sub;
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

  Future<Expense?> fetchExpense(String id) async {
    final doc = await _expenses.doc(id).get();
    if (!doc.exists) return null;
    return Expense.fromJson(doc.data()!, doc.id);
  }

  Future<void> upsertExpense(Expense expense) async {
    final doc = expense.id.isEmpty ? _expenses.doc() : _expenses.doc(expense.id);
    await doc.set(expense.copyWith(createdAt: expense.createdAt ?? DateTime.now()).toJson());
  }

  Future<String> uploadBillImage(Uint8List data, String messId) async {
    final path =
        'bills/$messId/${DateFormatter.monthString(DateTime.now())}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);
    final result = await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
    return result.ref.getDownloadURL();
  }

  Future<void> deleteExpense(String id) => _expenses.doc(id).delete();
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});
