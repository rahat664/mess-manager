import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/member_repository.dart';
import '../models/mess_member.dart';

final membersProvider = StreamProvider.family<List<MessMember>, String>((ref, messId) {
  return ref.watch(memberRepositoryProvider).streamMembers(messId);
});
