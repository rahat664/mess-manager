import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/mess_repository.dart';
import '../models/mess.dart';

final currentMessIdProvider = StateProvider<String?>((ref) => null);

final userMessesProvider = StreamProvider<List<Mess>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(messRepositoryProvider).streamUserMesses(user.uid);
});

final currentMessProvider = StreamProvider<Mess?>((ref) {
  final messId = ref.watch(currentMessIdProvider);
  if (messId == null) return const Stream.empty();
  return ref.watch(messRepositoryProvider).streamMess(messId);
});
