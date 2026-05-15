import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/budget/budget_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/transactions/add_transaction_screen.dart';
import 'presentation/screens/transactions/transaction_list_screen.dart';
import 'presentation/widgets/app_bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER
// ─────────────────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // StatefulShellRoute keeps each tab's widget tree alive when switching tabs.
    // This means scroll position, loaded data, etc. are preserved per tab.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0 — Hem
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 1 — Transaktioner
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transaktioner',
              builder: (context, state) => const TransactionListScreen(),
            ),
          ],
        ),

        // Tab 2 — Budget
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/budget',
              builder: (context, state) => const BudgetScreen(),
            ),
          ],
        ),

        // Tab 3 — Inställningar
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/installningar',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Modal routes (pushed on top of the shell) ─────────────────
    // These are full-screen pages navigated to from any tab.

    GoRoute(
      path: '/transaktion/lagg-till',
      builder: (context, state) {
        // Optional: pass 'isExpense' as extra to pre-select type
        final isExpense = state.extra as bool? ?? true;
        return AddTransactionScreen(isExpense: isExpense);
      },
    ),

    GoRoute(
      path: '/transaktion/redigera/:id',
      builder: (context, state) {
        final transactionId = state.pathParameters['id']!;
        return AddTransactionScreen(
          transactionId: transactionId,
          isExpense: true, // overridden once transaction is loaded
        );
      },
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────────────────────────────────────

class BudgetApp extends ConsumerWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // ── Themes ──────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(settingsNotifierProvider),

      // ── Localisation ────────────────────────────────────────
      // Delegates give Flutter widgets (date picker, etc.) their
      // Swedish translations. The locale tells intl to format
      // numbers and dates in Swedish convention.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('sv', 'SE')],
      locale: const Locale('sv', 'SE'),

      // ── Router ──────────────────────────────────────────────
      routerConfig: _router,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP SHELL — persistent bottom nav wrapper
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      // If the user taps the current tab again, jump back to its root route.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
