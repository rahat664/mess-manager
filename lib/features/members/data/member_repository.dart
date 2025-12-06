import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../models/mess_member.dart';

class MemberRepository {
  MemberRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _members => _db.collection('messMembers');

  Stream<List<MessMember>> streamMembers(String messId) {
    return _members.where('messId', isEqualTo: messId).snapshots().map(
          (snapshot) => snapshot.docs.map((d) => MessMember.fromJson(d.data(), d.id)).toList(),
        );
  }

  Future<void> updateRole(String memberId, UserRole role) {
    return _members.doc(memberId).update({'role': role.name});
  }

  Future<void> deactivate(String memberId) {
    return _members.doc(memberId).update({'isActive': false});
  }
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(FirebaseFirestore.instance);
});
