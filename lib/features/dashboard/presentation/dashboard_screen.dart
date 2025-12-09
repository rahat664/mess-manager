import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/data/auth_repository.dart';
import '../../deposits/data/deposit_repository.dart';
import '../../deposits/models/deposit.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/models/expense.dart';
import '../../meals/data/meal_repository.dart';
import '../../meals/models/meal.dart';
import '../../mess/providers/mess_providers.dart';
import '../../notifications/presentation/notification_permission_dialog.dart';
import '../../notifications/presentation/notification_icon_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasShownPermissionDialog = false;

  @override
  void initState() {
    super.initState();
    // Show notification permission dialog after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownPermissionDialog) {
        _hasShownPermissionDialog = true;
        // Add a small delay to ensure navigation is complete
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showNotificationPermissionDialogIfNeeded(context, ref);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messAsync = ref.watch(currentMessProvider);
    final user = ref.watch(authStateProvider).value;
    return messAsync.when(
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(child: Text('Unable to load mess: $e')),
      ),
      data: (mess) {
        if (mess == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select or create a mess to start'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.goNamed(AppRoute.messSelection.name),
                    child: const Text('Choose mess'),
                  ),
                ],
              ),
            ),
          );
        }
        final selectedMonth = ref.watch(selectedMonthProvider(mess.id)) ?? mess.currentMonth;
        final stats = ref.watch(_dashboardStatsProvider((messId: mess.id, month: selectedMonth, userId: user?.uid)));

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('${mess.name} • ${_formatMonthLabel(selectedMonth)}'),
            actions: [
              const NotificationIconButton(),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => context.goNamed(AppRoute.messSelection.name),
              )
            ],
          ),
          floatingActionButton: _QuickActionsFab(onNavigate: (route) async {
            Future<void> navigate() async {
              switch (route) {
                case AppRoute.meals:
                  await context.pushNamed(AppRoute.meals.name);
                  break;
                case AppRoute.expenses:
                  await context.pushNamed(AppRoute.expenses.name);
                  break;
                case AppRoute.deposits:
                  await context.pushNamed(AppRoute.deposits.name);
                  break;
                case AppRoute.members:
                  await context.pushNamed(AppRoute.members.name);
                  break;
                case AppRoute.report:
                  await context.pushNamed(AppRoute.report.name);
                  break;
                case AppRoute.settings:
                  await context.pushNamed(AppRoute.settings.name);
                  break;
                default:
                  break;
              }
            }

            await navigate();
            ref.invalidate(_dashboardStatsProvider((messId: mess.id, month: selectedMonth, userId: user?.uid)));
          }),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B1224), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: stats.when(
                loading: () => const Center(child: AppLoading()),
                error: (e, _) => _DashboardError(
                  message: '$e',
                  onRetry: () => ref.refresh(
                    _dashboardStatsProvider((messId: mess.id, month: selectedMonth, userId: user?.uid)),
                  ),
                ),
                data: (data) {
                  final refreshArgs = (messId: mess.id, month: selectedMonth, userId: user?.uid);
                  return RefreshIndicator(
                    color: Colors.white,
                    onRefresh: () => ref.refresh(_dashboardStatsProvider(refreshArgs).future),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: _HeaderCard(
                            messName: mess.name,
                            month: _formatMonthLabel(selectedMonth),
                            onSwitch: () => context.goNamed(AppRoute.messSelection.name),
                            onMonthTap: () => _showMonthPicker(context, ref, mess.id, selectedMonth),
                            balance: data.myBalance,
                            mealRate: data.mealRate,
                            joinCode: mess.joinCode,
                          ),
                        ),
                      ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _StatCard(
                                  title: 'Total meals',
                                  value: data.totalMealsAll.toStringAsFixed(1),
                                  icon: Icons.restaurant_menu,
                                  chip: 'All members',
                                  fullWidth: true,
                                ),
                                const SizedBox(height: 12),
                                _StatCard(
                                  title: 'Total spend',
                                  value: data.totalExpenses.toStringAsFixed(0),
                                  icon: Icons.payments_outlined,
                                  chip: 'This month',
                                  fullWidth: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _MySnapshot(
                              meals: data.myMeals,
                              deposits: data.myDeposits,
                              cost: data.myCost,
                              balance: data.myBalance,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 80),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardStats {
  DashboardStats({
    required this.totalMealsAll,
    required this.totalExpenses,
    required this.mealRate,
    required this.myMeals,
    required this.myDeposits,
    required this.myCost,
    required this.myBalance,
  });

  final double totalMealsAll;
  final double totalExpenses;
  final double mealRate;
  final double myMeals;
  final double myDeposits;
  final double myCost;
  final double myBalance;
}

final _dashboardStatsProvider = AutoDisposeStreamProvider.family<DashboardStats, ({String messId, String month, String? userId})>((ref, args) {
  final mealsRepo = ref.watch(mealRepositoryProvider);
  final expensesRepo = ref.watch(expenseRepositoryProvider);
  final depositsRepo = ref.watch(depositRepositoryProvider);

  return Stream.multi((controller) {
    List<Meal>? meals;
    List<Expense>? expenses;
    List<Deposit>? deposits;

    void emitIfReady() {
      if (meals == null || expenses == null || deposits == null) return;
      final totalMeals = meals!.fold<double>(0, (sum, m) => sum + m.totalMealsForDay);
      final totalExpenses = expenses!.fold<double>(0, (sum, e) => sum + e.amount);
      final mealRate = totalMeals == 0 ? 0.0 : totalExpenses / totalMeals;

      double myMeals = 0;
      double myDeposits = 0;
      if (args.userId != null) {
        myMeals = meals!.where((m) => m.memberId == args.userId).fold<double>(0, (sum, m) => sum + m.totalMealsForDay);
        myDeposits =
            deposits!.where((d) => d.memberId == args.userId).fold<double>(0, (sum, d) => sum + d.amount);
      }

      final myCost = myMeals * mealRate;
      final myBalance = myCost - myDeposits;

      controller.add(
        DashboardStats(
          totalMealsAll: totalMeals,
          totalExpenses: totalExpenses,
          mealRate: mealRate,
          myMeals: myMeals,
          myDeposits: myDeposits,
          myCost: myCost,
          myBalance: myBalance,
        ),
      );
    }

    final subMeals = mealsRepo
        .streamMeals(messId: args.messId, month: args.month)
        .listen((value) {
      meals = value;
      emitIfReady();
    }, onError: controller.addError);

    final subExpenses = expensesRepo
        .streamExpenses(messId: args.messId, month: args.month)
        .listen((value) {
      expenses = value;
      emitIfReady();
    }, onError: controller.addError);

    final subDeposits = depositsRepo
        .streamDeposits(messId: args.messId, month: args.month)
        .listen((value) {
      deposits = value;
      emitIfReady();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await subMeals.cancel();
      await subExpenses.cancel();
      await subDeposits.cancel();
    };
  });
});

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.chip,
    this.fullWidth = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? chip;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Constrain width to avoid overflows on small screens.
    return Container(
      width: fullWidth ? double.infinity : 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
              if (chip != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    chip!,
                    style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Keeps a per-mess selected month; defaults to the mess current month when null.
final selectedMonthProvider = StateProvider.family<String?, String>((ref, messId) => null);

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.messName,
    required this.month,
    required this.onSwitch,
    required this.onMonthTap,
    required this.balance,
    required this.mealRate,
    required this.joinCode,
  });

  final String messName;
  final String month;
  final VoidCallback onSwitch;
  final VoidCallback onMonthTap;
  final double balance;
  final double mealRate;
  final String joinCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSurplus = balance <= 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      messName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      month,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 0, maxWidth: 140),
                child: TextButton.icon(
                  onPressed: onSwitch,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    minimumSize: const Size(0, 0),
                  ),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch', overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 0, maxWidth: 150),
                child: OutlinedButton.icon(
                  onPressed: onMonthTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    'Month',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onLongPress: () => Clipboard.setData(ClipboardData(text: joinCode)).then(
              (_) => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Join code copied')),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.vpn_key, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite code', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
                        Text(
                          joinCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderChip(
                  label: 'Meal rate',
                  value: mealRate.toStringAsFixed(2),
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderChip(
                  label: hasSurplus ? 'Your balance' : 'Due',
                  value: balance.toStringAsFixed(0),
                  icon: hasSurplus ? Icons.trending_up : Icons.trending_down,
                  color: hasSurplus ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.white,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MySnapshot extends StatelessWidget {
  const _MySnapshot({
    required this.meals,
    required this.deposits,
    required this.cost,
    required this.balance,
  });

  final double meals;
  final double deposits;
  final double cost;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSurplus = balance <= 0;
    final balanceLabel = hasSurplus ? 'Balance' : 'Due';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your month',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hasSurplus ? 'On track' : 'Review spending',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: hasSurplus ? Colors.greenAccent : Colors.redAccent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SnapshotTile(
                  label: 'Meals logged',
                  value: meals.toStringAsFixed(1),
                  icon: Icons.restaurant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SnapshotTile(
                  label: 'Deposits',
                  value: deposits.toStringAsFixed(0),
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SnapshotTile(
                  label: 'Cost',
                  value: cost.toStringAsFixed(0),
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SnapshotTile(
                  label: balanceLabel,
                  value: balance.toStringAsFixed(0),
                  icon: hasSurplus ? Icons.trending_up : Icons.trending_down,
                  valueColor: hasSurplus ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = Colors.white,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.white70),
            const SizedBox(height: 10),
            Text('Unable to load mess summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMonthLabel(String month) {
  try {
    final date = DateTime.parse('$month-01');
    return DateFormat('MMMM yyyy').format(date);
  } catch (_) {
    return month;
  }
}

Future<void> _showMonthPicker(
  BuildContext context,
  WidgetRef ref,
  String messId,
  String selectedMonth,
) async {
  final now = DateTime.now();
  final months = List.generate(12, (i) {
    final dt = DateTime(now.year, now.month - i, 1);
    return DateFormatter.monthString(dt);
  });
  if (!months.contains(selectedMonth)) {
    months.insert(0, selectedMonth);
  }

  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF0B1224),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: months.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
          itemBuilder: (context, index) {
            final month = months[index];
            final isCurrent = month == selectedMonth;
            return ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.white70),
              title: Text(
                _formatMonthLabel(month),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
              trailing: isCurrent ? const Icon(Icons.check, color: Colors.greenAccent) : null,
              onTap: () => Navigator.of(context).pop(month),
            );
          },
        ),
      );
    },
  );

  if (selected != null) {
    ref.read(selectedMonthProvider(messId).notifier).state = selected;
  }
}
class _QuickActionsFab extends StatefulWidget {
  const _QuickActionsFab({required this.onNavigate});

  final Future<void> Function(AppRoute route) onNavigate;

  @override
  State<_QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends State<_QuickActionsFab> with SingleTickerProviderStateMixin {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (AppRoute.meals, 'Meals', Icons.restaurant),
      (AppRoute.expenses, 'Expenses', Icons.shopping_bag),
      (AppRoute.deposits, 'Deposits', Icons.account_balance_wallet),
      (AppRoute.members, 'Members', Icons.group),
      (AppRoute.report, 'Reports', Icons.summarize),
      (AppRoute.settings, 'Settings', Icons.settings),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_open)
          ...actions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                heroTag: item.$1.name,
                onPressed: () async {
                  await widget.onNavigate(item.$1);
                  if (mounted) setState(() => _open = false);
                },
                icon: Icon(item.$3),
                label: Text(item.$2),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0B1224),
              ),
            ),
          ),
        FloatingActionButton(
          heroTag: 'fab-main',
          onPressed: () => setState(() => _open = !_open),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0B1224),
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
