import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../providers/mess_providers.dart';

class MessSelectionScreen extends ConsumerWidget {
  const MessSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMessId = ref.watch(currentMessIdProvider);
    final messes = ref.watch(userMessesProvider);
    return ModernScaffold(
      title: 'Your Messes',
      body: AsyncValueWidget(
        value: messes,
        data: (items) {
          // If the user only has one mess, pick it automatically and jump to dashboard.
          if (currentMessId == null && items.length == 1) {
            final targetMess = items.first;
            Future.microtask(() {
              ref.read(currentMessIdProvider.notifier).state = targetMess.id;
              context.goNamed(AppRoute.dashboard.name);
            });
            return const AppLoading();
          }

          final listContent = items.isEmpty
              ? const Expanded(
                  child: Center(
                    child: Text('No mess yet. Create or join one.', style: TextStyle(color: Colors.white70)),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final mess = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GlassCard(
                          child: ListTile(
                            title: Text(mess.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Current month: ${mess.currentMonth}',
                                style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                            onTap: () {
                              ref.read(currentMessIdProvider.notifier).state = mess.id;
                              context.goNamed(AppRoute.dashboard.name);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );

          return Column(
            children: [
              listContent,
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.pushNamed(AppRoute.joinMess.name),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join via code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.pushNamed(AppRoute.createMess.name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0B1224),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_business),
                        label: const Text('Create mess'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
