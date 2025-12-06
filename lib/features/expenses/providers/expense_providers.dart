import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/expense_repository.dart';
import '../models/expense.dart';

typedef ExpenseQuery = ({String messId, String month, String? category});

final expensesProvider = StreamProvider.family<List<Expense>, ExpenseQuery>((ref, args) {
  return ref
      .watch(expenseRepositoryProvider)
      .streamExpenses(messId: args.messId, month: args.month, category: args.category);
});
