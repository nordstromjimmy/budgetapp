import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../providers/transaction_provider.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringTransactionNotifierProvider);
    final categories = ref.watch(categoryNotifierProvider);
    final expenses = recurring.where((r) => r.isExpense).toList();
    final income = recurring.where((r) => !r.isExpense).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Återkommande')),
      body: recurring.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                if (expenses.isNotEmpty) ...[
                  _SectionLabel(label: 'Utgifter'),
                  const Gap(8),
                  _RecurringGroup(
                    items: expenses,
                    categories: categories,
                    ref: ref,
                  ),
                  const Gap(20),
                ],
                if (income.isNotEmpty) ...[
                  _SectionLabel(label: 'Inkomster'),
                  const Gap(8),
                  _RecurringGroup(
                    items: income,
                    categories: categories,
                    ref: ref,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded,
                size: 56,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.18)),
            const Gap(16),
            Text(
              'Inga återkommande transaktioner.\nLägg till via + knappen och aktivera "Månadsvis".',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.45),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringGroup extends StatelessWidget {
  const _RecurringGroup({
    required this.items,
    required this.categories,
    required this.ref,
  });

  final List<RecurringTransaction> items;
  final List<dynamic> categories;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _RecurringTile(
              item: items[i],
              category: categories.cast<dynamic>().firstWhere(
                    (c) => c.id == items[i].categoryId,
                    orElse: () => null,
                  ),
              ref: ref,
            ),
            if (i < items.length - 1) const Divider(height: 1, indent: 72),
          ],
        ],
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({
    required this.item,
    required this.category,
    required this.ref,
  });

  final RecurringTransaction item;
  final dynamic category;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = category?.color as Color? ??
        (item.isExpense ? AppColors.expense : AppColors.income);
    final icon = category?.icon as IconData? ?? Icons.repeat;

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          CustomSlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 22),
                Gap(2),
                Text('Ta bort',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),

            // ── Info ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description.isNotEmpty
                        ? item.description
                        : category?.name ?? '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: item.isActive
                          ? null
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Dag ${item.dayOfMonth} varje månad · ${category?.name ?? '—'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),

            // ── Amount + toggle ────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatSigned(item.amount,
                      isExpense: item.isExpense),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.isActive
                        ? (item.isExpense
                            ? AppColors.expense
                            : AppColors.income)
                        : theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
                ),
                const Gap(4),
                GestureDetector(
                  onTap: () => ref
                      .read(recurringTransactionNotifierProvider.notifier)
                      .toggleActive(item.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? AppColors.income.withOpacity(0.12)
                          : theme.colorScheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isActive ? 'Aktiv' : 'Pausad',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.isActive
                            ? AppColors.income
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ta bort återkommande?'),
        content: const Text(
            'Mallen och alla automatiskt genererade transaktioner från den tas bort.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(recurringTransactionNotifierProvider.notifier)
          .delete(item.id);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
      ),
    );
  }
}
