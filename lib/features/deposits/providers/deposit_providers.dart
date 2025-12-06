import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/deposit_repository.dart';
import '../models/deposit.dart';

typedef DepositQuery = ({String messId, String month, String? memberId});

final depositsProvider = StreamProvider.family<List<Deposit>, DepositQuery>((ref, args) {
  return ref
      .watch(depositRepositoryProvider)
      .streamDeposits(messId: args.messId, month: args.month, memberId: args.memberId);
});
