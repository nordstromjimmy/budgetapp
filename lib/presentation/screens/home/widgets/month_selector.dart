import 'package:budget_app/core/constants/app_strings.dart';
import 'package:budget_app/presentation/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Prev / current month / next navigation strip.
/// Displayed in the home screen app bar area.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selected.month == now.month && selected.year == now.year;

    final label = '${AppStrings.monthName(selected.month)} ${selected.year}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Previous month ─────────────────────────────────────
        _NavButton(
          icon: Icons.chevron_left,
          onTap: () {
            ref.read(selectedMonthProvider.notifier).state = DateTime(
              selected.year,
              selected.month - 1,
            );
          },
        ),
        const Gap(4),

        // ── Month label ────────────────────────────────────────
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(4),

        // ── Next month (disabled if already on current month) ──
        _NavButton(
          icon: Icons.chevron_right,
          onTap: isCurrentMonth
              ? null
              : () {
                  ref.read(selectedMonthProvider.notifier).state = DateTime(
                    selected.year,
                    selected.month + 1,
                  );
                },
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? theme.colorScheme.onSurface.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.25),
        ),
      ),
    );
  }
}
