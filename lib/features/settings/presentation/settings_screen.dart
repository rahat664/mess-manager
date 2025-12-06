import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/data/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(user?.email ?? 'User'),
            subtitle: const Text('Signed in'),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch mess'),
            onTap: () => context.goNamed(AppRoute.messSelection.name),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.goNamed(AppRoute.login.name);
            },
          ),
        ],
      ),
    );
  }
}
