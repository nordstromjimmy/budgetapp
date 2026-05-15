import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/utils/currency_formatter.dart';

/// A card that displays a single financial metric.
/// Used on the home screen for balance, income, and expenses.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isLarge = false,
    this.showSign = false,
    this.isExpense = false,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  /// When true, renders a taller card with larger text — used for balance.
  final bool isLarge;

  /// When true, prefixes the amount with + or −
  final bool showSign;

  /// Only relevant when [showSign] is true
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedAmount = showSign
        ? CurrencyFormatter.formatSigned(amount, isExpense: isExpense)
        : CurrencyFormatter.formatAmount(amount);

    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLarge
          ? _largLayout(theme, formattedAmount)
          : _compactLayout(theme, formattedAmount),
    );
  }

  Widget _largLayout(ThemeData theme, String formattedAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Gap(16),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formattedAmount,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactLayout(ThemeData theme, String formattedAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const Gap(12),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formattedAmount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
