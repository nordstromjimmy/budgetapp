import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_list_tile.dart';
import 'widgets/month_selector.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildBody(context, ref),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        tooltip: AppStrings.addTransactionTitle,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      title: Text(_greeting()),
      actions: const [
        MonthSelector(),
        Gap(12),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.homeGreetingMorning;
    if (hour < 18) return AppStrings.homeGreetingDay;
    return AppStrings.homeGreetingEvening;
  }

  // ── Body ────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildBody(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(monthlyBalanceProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final recentTransactions =
        ref.watch(transactionsForMonthProvider).take(5).toList();
    final categories = ref.watch(categoryNotifierProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance card ─────────────────────────────────
            SummaryCard(
              label: AppStrings.homeBalance,
              amount: balance,
              icon: Icons.account_balance_wallet,
              color: balance >= 0 ? AppColors.income : AppColors.expense,
              isLarge: true,
              showSign: true,
              isExpense: balance < 0,
            ),
            const Gap(12),

            // ── Income + Expenses row ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    label: AppStrings.homeIncome,
                    amount: income,
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.income,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: SummaryCard(
                    label: AppStrings.homeExpenses,
                    amount: expenses,
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const Gap(24),

            // ── Recent transactions ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.homeRecentTransactions,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/transaktioner'),
                  child: const Text(AppStrings.homeSeeAll),
                ),
              ],
            ),
            const Gap(4),

            if (recentTransactions.isEmpty)
              _buildEmptyState(context)
            else
              _buildTransactionList(context, recentTransactions, categories),
          ],
        ),
      ),
    );
  }

  // ── Recent transactions list ─────────────────────────────────────

  Widget _buildTransactionList(BuildContext context, transactions, categories) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            TransactionListTile(
              transaction: transactions[i],
              category: categories.cast<dynamic>().firstWhere(
                    (c) => c.id == transactions[i].categoryId,
                    orElse: () => null,
                  ),
              onTap: () {}, // edit handled in transaction list screen
            ),
            if (i < transactions.length - 1)
              const Divider(height: 1, indent: 72),
          ],
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const Gap(12),
          Text(
            AppStrings.homeNoTransactions,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                ),
          ),
        ],
      ),
    );
  }

  // ── FAB sheet ────────────────────────────────────────────────────

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expense.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: AppColors.expense),
              ),
              title: const Text(AppStrings.transactionExpense,
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Lägg till en utgift'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/transaktion/lagg-till', extra: true);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_downward_rounded,
                    color: AppColors.income),
              ),
              title: const Text(AppStrings.transactionIncome,
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Lägg till en inkomst'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/transaktion/lagg-till', extra: false);
              },
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
