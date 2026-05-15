import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/transaction_list_tile.dart';
import '../home/widgets/month_selector.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FILTER ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum _TransactionFilter { all, expenses, income }

extension on _TransactionFilter {
  String get label => switch (this) {
        _TransactionFilter.all => AppStrings.transactionAll,
        _TransactionFilter.expenses => AppStrings.transactionExpense,
        _TransactionFilter.income => AppStrings.transactionIncome,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  _TransactionFilter _filter = _TransactionFilter.all;

  static final _dateFormat = DateFormat('d MMMM yyyy', 'sv_SE');
  static final _todayFormat = DateFormat('d MMMM', 'sv_SE');

  // ── Filtering ─────────────────────────────────────────────────

  List<Transaction> _applyFilter(List<Transaction> transactions) {
    return switch (_filter) {
      _TransactionFilter.all => transactions,
      _TransactionFilter.expenses =>
        transactions.where((t) => t.isExpense).toList(),
      _TransactionFilter.income =>
        transactions.where((t) => !t.isExpense).toList(),
    };
  }

  // ── Date grouping ─────────────────────────────────────────────

  /// Groups a sorted (newest first) transaction list by date label.
  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<Transaction>>{};

    for (final t in transactions) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      final String label;

      if (tDate == today) {
        label = 'Idag · ${_todayFormat.format(t.date)}';
      } else if (tDate == yesterday) {
        label = 'Igår · ${_todayFormat.format(t.date)}';
      } else {
        label = _dateFormat.format(t.date);
      }

      grouped.putIfAbsent(label, () => []).add(t);
    }

    return grouped;
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsForMonthProvider);
    final categories = ref.watch(categoryNotifierProvider);
    final filtered = _applyFilter(allTransactions);
    final grouped = _groupByDate(filtered);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text(AppStrings.transactionsTitle),
            actions: const [MonthSelector(), Gap(12)],
          ),

          // ── Filter chips ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: _TransactionFilter.values.map((filter) {
                  final selected = _filter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = filter),
                      selectedColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(filter: _filter),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entries = grouped.entries.toList();
                    final entry = entries[index];
                    return _DateGroup(
                      label: entry.key,
                      transactions: entry.value,
                      categories: categories,
                      onDelete: (id) => _deleteTransaction(id),
                      onTap: (id) => context.push('/transaktion/redigera/$id'),
                    );
                  },
                  childCount: grouped.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transaktion/lagg-till', extra: true),
        tooltip: AppStrings.addTransactionTitle,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────

  Future<void> _deleteTransaction(String id) async {
    await ref.read(transactionNotifierProvider.notifier).deleteTransaction(id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.snackTransactionDeleted),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE GROUP
// ─────────────────────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.label,
    required this.transactions,
    required this.categories,
    required this.onDelete,
    required this.onTap,
  });

  final String label;
  final List<Transaction> transactions;
  final List<dynamic> categories;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Date label ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── Transaction cards ───────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (int i = 0; i < transactions.length; i++) ...[
                _SlidableTransaction(
                  transaction: transactions[i],
                  category: categories.cast<dynamic>().firstWhere(
                        (c) => c.id == transactions[i].categoryId,
                        orElse: () => null,
                      ),
                  onDelete: () => onDelete(transactions[i].id),
                  onTap: () => onTap(transactions[i].id),
                ),
                if (i < transactions.length - 1)
                  const Divider(height: 1, indent: 72),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDABLE TRANSACTION TILE
// ─────────────────────────────────────────────────────────────────────────────

class _SlidableTransaction extends StatelessWidget {
  const _SlidableTransaction({
    required this.transaction,
    required this.category,
    required this.onDelete,
    required this.onTap,
  });

  final Transaction transaction;
  final dynamic category;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(16),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 22),
                Gap(2),
                Text(
                  'Ta bort',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      child: TransactionListTile(
        transaction: transaction,
        category: category,
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final _TransactionFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFiltered = filter != _TransactionFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.filter_list_off_rounded
                  : Icons.receipt_long_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withOpacity(0.18),
            ),
            const Gap(16),
            Text(
              isFiltered
                  ? 'Inga ${filter.label.toLowerCase()} denna månad.'
                  : AppStrings.transactionsEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
