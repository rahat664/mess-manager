import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );
      if (mounted) context.goNamed(AppRoute.dashboard.name);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) context.goNamed(AppRoute.dashboard.name);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1224), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    final loginCard = ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sign in to keep your mess running smoothly.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.alternate_email_outlined),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  child: Text(_loading ? 'Please wait...' : 'Login'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _loading ? null : _google,
                                  icon: const Icon(Icons.g_mobiledata, size: 28),
                                  label: const Text('Continue with Google'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () => context.goNamed(AppRoute.register.name),
                                  child: const Text('Create account'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _HeroPanel(theme: theme)),
                          const SizedBox(width: 32),
                          loginCard,
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroPanel(theme: theme),
                        const SizedBox(height: 20),
                        loginCard,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white.withOpacity(0.9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_graph_rounded, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text('Mess Manager', style: theme.textTheme.labelMedium?.copyWith(color: textColor)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Run your mess with clarity and calm.',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Track meals, expenses, and balances in one modern workspace.',
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _FeatureChip(icon: Icons.dashboard_customize_outlined, label: 'Live dashboard'),
            _FeatureChip(icon: Icons.receipt_long_outlined, label: 'Expense control'),
            _FeatureChip(icon: Icons.person_rounded, label: 'Member clarity'),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: const [
            Expanded(
              child: _HeroStat(
                title: 'Avg. balance updates',
                value: 'Instant',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _HeroStat(
                title: 'Meal logging',
                value: '2 taps',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 6,
          color: Colors.white.withOpacity(0.92),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}
