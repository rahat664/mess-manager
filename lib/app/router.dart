import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/deposits/presentation/add_edit_deposit_screen.dart';
import '../features/deposits/presentation/deposits_list_screen.dart';
import '../features/expenses/presentation/add_edit_expense_screen.dart';
import '../features/expenses/presentation/expenses_list_screen.dart';
import '../features/members/presentation/members_list_screen.dart';
import '../features/mess/presentation/create_mess_screen.dart';
import '../features/mess/presentation/join_mess_screen.dart';
import '../features/mess/presentation/mess_selection_screen.dart';
import '../features/meals/presentation/add_edit_meal_screen.dart';
import '../features/meals/presentation/meals_list_screen.dart';
import '../features/reports/presentation/monthly_report_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/notifications/presentation/notification_settings_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/mess/providers/mess_providers.dart';

/// Notifies GoRouter when auth or mess selection changes, so redirects re-run.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, __) => notifyListeners());
    ref.listen<String?>(currentMessIdProvider, (_, __) => notifyListeners());
    ref.listen<AsyncValue<DocumentSnapshot<Map<String, dynamic>>?>>(
      userDocProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    final userDoc = ref.read(userDocProvider);
    final currentMessId = ref.read(currentMessIdProvider);
    final loggingIn = state.fullPath == '/login' || state.fullPath == '/register';
    final selectingMess = state.fullPath?.startsWith('/mess/') ?? false;

    if (currentUser == null) {
      return loggingIn ? null : '/login';
    }
    if (userDoc.hasError) {
      ref.read(authRepositoryProvider).signOut();
      return '/login';
    }
    if (userDoc.hasValue && userDoc.value?.exists == false) {
      ref.read(authRepositoryProvider).signOut();
      return '/login';
    }
    if (loggingIn) {
      return '/dashboard';
    }
    if (currentMessId == null && !selectingMess) {
      return '/mess/select';
    }
    return null;
  }
}

enum AppRoute {
  splash,
  login,
  register,
  messSelection,
  createMess,
  joinMess,
  dashboard,
  meals,
  mealEdit,
  expenses,
  expenseEdit,
  deposits,
  depositEdit,
  members,
  report,
  settings,
  notificationSettings,
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: routerNotifier,
    redirect: routerNotifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.splash.name,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: AppRoute.register.name,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/mess/select',
        name: AppRoute.messSelection.name,
        builder: (_, __) => const MessSelectionScreen(),
      ),
      GoRoute(
        path: '/mess/create',
        name: AppRoute.createMess.name,
        builder: (_, __) => const CreateMessScreen(),
      ),
      GoRoute(
        path: '/mess/join',
        name: AppRoute.joinMess.name,
        builder: (_, __) => const JoinMessScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: AppRoute.dashboard.name,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/meals',
        name: AppRoute.meals.name,
        builder: (_, __) => const MealsListScreen(),
      ),
      GoRoute(
        path: '/meals/edit',
        name: AppRoute.mealEdit.name,
        builder: (_, state) {
          final id = state.uri.queryParameters['id'];
          return AddEditMealScreen(mealId: id);
        },
      ),
      GoRoute(
        path: '/expenses',
        name: AppRoute.expenses.name,
        builder: (_, __) => const ExpensesListScreen(),
      ),
      GoRoute(
        path: '/expenses/edit',
        name: AppRoute.expenseEdit.name,
        builder: (_, state) {
          final id = state.uri.queryParameters['id'];
          return AddEditExpenseScreen(expenseId: id);
        },
      ),
      GoRoute(
        path: '/deposits',
        name: AppRoute.deposits.name,
        builder: (_, __) => const DepositsListScreen(),
      ),
      GoRoute(
        path: '/deposits/edit',
        name: AppRoute.depositEdit.name,
        builder: (_, state) {
          final id = state.uri.queryParameters['id'];
          return AddEditDepositScreen(depositId: id);
        },
      ),
      GoRoute(
        path: '/members',
        name: AppRoute.members.name,
        builder: (_, __) => const MembersListScreen(),
      ),
      GoRoute(
        path: '/reports/monthly',
        name: AppRoute.report.name,
        builder: (_, __) => const MonthlyReportScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings.name,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications/settings',
        name: AppRoute.notificationSettings.name,
        builder: (_, __) => const NotificationSettingsScreen(),
      ),
    ],
  );
});
