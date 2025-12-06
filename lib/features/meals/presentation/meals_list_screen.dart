import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../auth/data/auth_repository.dart';
import '../../members/providers/member_providers.dart';
import '../../mess/providers/mess_providers.dart';
import '../data/meal_repository.dart';
import '../providers/meal_providers.dart';

class MealsListScreen extends ConsumerStatefulWidget {
  const MealsListScreen({super.key});

  @override
  ConsumerState<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends ConsumerState<MealsListScreen> {
  String? selectedMember;

  @override
  Widget build(BuildContext context) {
    final mess = ref.watch(currentMessProvider).value;
    if (mess == null) {
      return const Scaffold(body: Center(child: Text('Select a mess first.')));
    }
    final members = ref.watch(membersProvider(mess.id));
    final meals = ref.watch(mealsProvider(
      (messId: mess.id, month: mess.currentMonth, memberId: selectedMember),
    ));

    return ModernScaffold(
      title: 'Meals',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_task),
          tooltip: 'Add today for me',
          onPressed: () async {
            final userId = ref.read(authStateProvider).value?.uid;
            if (userId == null) return;
            await ref.read(mealRepositoryProvider).addQuickToday(
                  messId: mess.id,
                  memberId: userId,
                );
          },
        )
      ],
      body: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: AsyncValueWidget(
              value: members,
              data: (items) {
                return DropdownButtonFormField<String>(
                  value: selectedMember,
                  dropdownColor: const Color(0xFF0B1224),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Filter by member',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All members'),
                    ),
                    ...items.map(
                      (m) => DropdownMenuItem(
                        value: m.userId,
                        child: Text(m.name),
                      ),
                    )
                  ],
                  onChanged: (v) => setState(() => selectedMember = v),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AsyncValueWidget(
              value: meals,
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No meals logged yet.', style: TextStyle(color: Colors.white70)),
                  );
                }
                final memberMap = {
                  for (final m in members.value ?? []) m.userId: m.name,
                };
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final meal = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: GlassCard(
                        child: ListTile(
                          title: Text(
                            '${meal.date} • ${memberMap[meal.memberId] ?? 'Member'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'B ${meal.breakfastCount} • L ${meal.lunchCount} • D ${meal.dinnerCount}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: () => context.pushNamed(
                              AppRoute.mealEdit.name,
                              queryParameters: {'id': meal.id},
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
        onPressed: () => context.pushNamed(AppRoute.mealEdit.name),
        icon: const Icon(Icons.add),
        label: const Text('Add meal'),
      ),
    );
  }
}
