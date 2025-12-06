import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../members/providers/member_providers.dart';
import '../../mess/providers/mess_providers.dart';
import '../providers/expense_providers.dart';

class ExpensesListScreen extends ConsumerStatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  ConsumerState<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends ConsumerState<ExpensesListScreen> {
  String? category;

  @override
  Widget build(BuildContext context) {
    final mess = ref.watch(currentMessProvider).value;
    if (mess == null) {
      return const Scaffold(body: Center(child: Text('Select a mess first.')));
    }
    final expenses = ref.watch(expensesProvider((messId: mess.id, month: mess.currentMonth, category: category)));
    final members = ref.watch(membersProvider(mess.id));

    return ModernScaffold(
      title: 'Expenses',
      body: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: category,
              dropdownColor: const Color(0xFF0B1224),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All categories')),
                ...expenseCategories.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                )
              ],
              onChanged: (v) => setState(() => category = v),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AsyncValueWidget(
              value: expenses,
              data: (items) {
                final total = items.fold<double>(0, (sum, e) => sum + e.amount);
                final memberMap = {for (final m in members.value ?? []) m.userId: m.name};
                return ListView.builder(
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GlassCard(
                          child: Text(
                            'Monthly total: $total',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                    final expense = items[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: GlassCard(
                        child: ListTile(
                          title: Text(
                            '${expense.category} • ${expense.amount}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${expense.date} • Paid by: ${memberMap[expense.paidByMemberId] ?? 'N/A'}\n${expense.description ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: () => context.pushNamed(
                              AppRoute.expenseEdit.name,
                              queryParameters: {'id': expense.id},
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoute.expenseEdit.name),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}
