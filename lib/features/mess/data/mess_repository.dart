import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../members/models/mess_member.dart';
import '../models/mess.dart';

class MessRepository {
  MessRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _messes => _db.collection('messes');
  CollectionReference<Map<String, dynamic>> get _members => _db.collection('messMembers');

  Stream<Mess?> streamMess(String id) {
    return _messes.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Mess.fromJson(doc.data()!, doc.id);
    });
  }

  Stream<List<Mess>> streamUserMesses(String userId) {
    return _members.where('userId', isEqualTo: userId).snapshots().asyncMap((snapshot) async {
      final messIds = snapshot.docs.map((d) => d['messId'] as String).toList();
      if (messIds.isEmpty) return <Mess>[];
      final messDocs = await _messes.where(FieldPath.documentId, whereIn: messIds).get();
      return messDocs.docs.map((d) => Mess.fromJson(d.data(), d.id)).toList();
    });
  }

  Stream<List<MessMember>> streamMembers(String messId) {
    return _members.where('messId', isEqualTo: messId).snapshots().map(
          (snapshot) => snapshot.docs.map((d) => MessMember.fromJson(d.data(), d.id)).toList(),
        );
  }

  Future<Mess> createMess({
    required String name,
    required String createdBy,
    required String adminName,
    required String adminEmail,
  }) async {
    final id = _messes.doc().id;
    final mess = Mess(
      id: id,
      name: name,
      createdBy: createdBy,
      currentMonth: DateFormatter.monthString(DateTime.now()),
      membersCount: 1,
      joinCode: id.substring(0, 6).toUpperCase(),
    );
    await _db.runTransaction((txn) async {
      txn.set(_messes.doc(id), mess.toJson());
      final memberId = '${id}_$createdBy';
      final member = MessMember(
        id: memberId,
        messId: id,
        userId: createdBy,
        name: adminName,
        email: adminEmail,
        role: UserRole.admin,
        isActive: true,
        monthlyFixedCostShare: 0,
      );
      txn.set(_members.doc(member.id), member.toJson());
      txn.update(_db.collection('users').doc(createdBy), {
        'messIds': FieldValue.arrayUnion([id]),
      });
    });
    return mess;
  }

  Future<String> joinMess({
    required String code,
    required String userId,
    required String name,
    required String email,
  }) async {
    final messQuery = await _messes.where('joinCode', isEqualTo: code.toUpperCase()).limit(1).get();
    if (messQuery.docs.isEmpty) {
      throw Exception('No mess found for this code');
    }
    final messDoc = messQuery.docs.first;
    final messId = messDoc.id;
    final existing = await _members
        .where('messId', isEqualTo: messId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _db.runTransaction((txn) async {
        final memberRef = _members.doc('${messId}_$userId');
        txn.set(
          memberRef,
          MessMember(
            id: memberRef.id,
            messId: messId,
            userId: userId,
            name: name,
            email: email,
            role: UserRole.member,
            isActive: true,
            monthlyFixedCostShare: 0,
          ).toJson(),
        );
        txn.update(messDoc.reference, {'membersCount': FieldValue.increment(1)});
        txn.update(_db.collection('users').doc(userId), {
          'messIds': FieldValue.arrayUnion([messId]),
        });
      });
    }
    return messId;
  }
}

final messRepositoryProvider = Provider<MessRepository>((ref) {
  return MessRepository(FirebaseFirestore.instance);
});
