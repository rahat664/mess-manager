import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../members/providers/member_providers.dart';
import '../../mess/providers/mess_providers.dart';
import '../providers/deposit_providers.dart';

class DepositsListScreen extends ConsumerStatefulWidget {
  const DepositsListScreen({super.key});

  @override
  ConsumerState<DepositsListScreen> createState() => _DepositsListScreenState();
}

class _DepositsListScreenState extends ConsumerState<DepositsListScreen> {
  String? memberId;

  @override
  Widget build(BuildContext context) {
    final mess = ref.watch(currentMessProvider).value;
    if (mess == null) {
      return const Scaffold(body: Center(child: Text('Select a mess first.')));
    }
    final deposits = ref.watch(depositsProvider((messId: mess.id, month: mess.currentMonth, memberId: memberId)));
    final members = ref.watch(membersProvider(mess.id));

    return ModernScaffold(
      title: 'Deposits',
      body: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: AsyncValueWidget(
              value: members,
              data: (items) => DropdownButtonFormField<String>(
                value: memberId,
                dropdownColor: const Color(0xFF0B1224),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Filter by member'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All members')),
                  ...items.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.name)))
                ],
                onChanged: (v) => setState(() => memberId = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AsyncValueWidget(
              value: deposits,
              data: (items) {
                final total = items.fold<double>(0, (sum, d) => sum + d.amount);
                final memberMap = {for (final m in members.value ?? []) m.userId: m.name};
                return ListView.builder(
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GlassCard(
                          child: Text(
                            'Total deposited: $total',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                    final deposit = items[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: GlassCard(
                        child: ListTile(
                          title: Text(
                            '${deposit.amount} by ${memberMap[deposit.memberId] ?? 'Member'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${deposit.date} • ${deposit.description ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: () => context.pushNamed(
                              AppRoute.depositEdit.name,
                              queryParameters: {'id': deposit.id},
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoute.depositEdit.name),
        icon: const Icon(Icons.add),
        label: const Text('Add deposit'),
      ),
    );
  }
}
