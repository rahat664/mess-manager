import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../auth/data/auth_repository.dart';
import '../data/mess_repository.dart';
import '../providers/mess_providers.dart';

class CreateMessScreen extends ConsumerStatefulWidget {
  const CreateMessScreen({super.key});

  @override
  ConsumerState<CreateMessScreen> createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends ConsumerState<CreateMessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final mess = await ref.read(messRepositoryProvider).createMess(
            name: _nameCtrl.text.trim(),
            createdBy: user.uid,
            adminName: user.displayName ?? user.email ?? '',
            adminEmail: user.email ?? '',
          );
      ref.read(currentMessIdProvider.notifier).state = mess.id;
      if (mounted) context.goNamed(AppRoute.dashboard.name);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      title: 'Create Mess',
      body: Center(
        child: SingleChildScrollView(
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_business, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'New mess workspace',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Mess name', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. North Hall Mess',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0B1224),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_loading ? 'Creating...' : 'Create'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
