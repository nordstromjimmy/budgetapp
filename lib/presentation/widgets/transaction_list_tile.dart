import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';

/// A single transaction row used on both the home screen and
/// the full transaction list screen.
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
  });

  final Transaction transaction;

  /// Pass null if the category has been deleted — the tile handles it gracefully.
  final Category? category;

  final VoidCallback? onTap;

  static final _dateFormat = DateFormat('d MMM', 'sv_SE');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = category != null
        ? category!.color
        : theme.colorScheme.onSurface.withOpacity(0.4);
    final icon = category?.icon ?? Icons.help_outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // ── Category icon ──────────────────────────────────
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

            // ── Description & date ─────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description.isNotEmpty
                        ? transaction.description
                        : category?.name ?? '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    '${category?.name ?? 'Okänd kategori'} · ${_dateFormat.format(transaction.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(8),

            // ── Amount ─────────────────────────────────────────
            Text(
              CurrencyFormatter.formatSigned(
                transaction.amount,
                isExpense: transaction.isExpense,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: transaction.isExpense
                    ? AppColors.expense
                    : AppColors.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
