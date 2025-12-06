import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../auth/data/auth_repository.dart';
import '../../mess/providers/mess_providers.dart';
import '../data/member_repository.dart';
import '../providers/member_providers.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mess = ref.watch(currentMessProvider).value;
    if (mess == null) {
      return const Scaffold(body: Center(child: Text('Select a mess first.')));
    }
    final members = ref.watch(membersProvider(mess.id));
    final currentUserId = ref.watch(authStateProvider).value?.uid;

    return ModernScaffold(
      title: 'Members',
      body: AsyncValueWidget(
        value: members,
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No members yet', style: TextStyle(color: Colors.white70)));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final member = items[index];
              final isSelf = member.userId == currentUserId;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: GlassCard(
                  child: ListTile(
                    title: Text(member.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${member.email} • ${member.role.label}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      color: const Color(0xFF0B1224),
                      onSelected: (value) {
                        if (value == 'role') {
                          final newRole =
                              member.role == UserRole.admin ? UserRole.member : UserRole.admin;
                          ref.read(memberRepositoryProvider).updateRole(member.id, newRole);
                        } else if (value == 'deactivate') {
                          ref.read(memberRepositoryProvider).deactivate(member.id);
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isSelf)
                          PopupMenuItem(
                            value: 'role',
                            child: Text(
                              member.role == UserRole.admin ? 'Make member' : 'Promote to admin',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        if (!isSelf)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Deactivate', style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
