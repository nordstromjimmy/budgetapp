import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../home/widgets/month_selector.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progresses = ref.watch(budgetProgressProvider);
    final totalBudget = ref.watch(totalBudgetForMonthProvider);
    final totalSpent = ref.watch(totalSpentAgainstBudgetProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────
          const SliverAppBar(
            floating: true,
            snap: true,
            title: Text(AppStrings.budgetTitle),
            actions: [MonthSelector(), Gap(12)],
          ),

          if (progresses.isEmpty)
            SliverFillRemaining(child: _EmptyState())
          else ...[
            // ── Month summary ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _MonthSummaryCard(
                  totalBudget: totalBudget,
                  totalSpent: totalSpent,
                ),
              ),
            ),

            // ── Budget cards ───────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final progress = progresses[index];
                    final categories = ref.read(categoryNotifierProvider);
                    final category = categories.cast<Category?>().firstWhere(
                          (c) => c?.id == progress.budget.categoryId,
                          orElse: () => null,
                        );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BudgetCard(
                        progress: progress,
                        category: category,
                        onEdit: () => _showBudgetSheet(
                          context,
                          ref,
                          categoryId: progress.budget.categoryId,
                          currentAmount: progress.budget.amount,
                          categoryName: category?.name ?? '—',
                          categoryColor: category?.color ?? AppColors.primary,
                          categoryIcon:
                              category?.icon ?? Icons.category_outlined,
                        ),
                        onDelete: () async {
                          await ref
                              .read(budgetNotifierProvider.notifier)
                              .deleteBudget(progress.budget.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text(AppStrings.snackBudgetDeleted),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                  childCount: progresses.length,
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetSheet(context, ref),
        tooltip: AppStrings.budgetAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Add new budget ────────────────────────────────────────────

  void _showAddBudgetSheet(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.read(selectedMonthProvider);
    final budgets = ref.read(budgetsForMonthProvider);
    final budgetedCategoryIds = budgets.map((b) => b.categoryId).toSet();

    // Only show expense categories that don't have a budget yet this month
    final available = ref
        .read(expenseCategoriesProvider)
        .where((c) => !budgetedCategoryIds.contains(c.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Alla kategorier har redan en budget denna månad.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddBudgetSheet(
        availableCategories: available,
        month: selectedMonth.month,
        year: selectedMonth.year,
        onSave: (categoryId, amount) async {
          await ref.read(budgetNotifierProvider.notifier).setBudget(
                categoryId: categoryId,
                amount: amount,
                month: selectedMonth.month,
                year: selectedMonth.year,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(AppStrings.snackBudgetSaved),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }

  // ── Edit existing budget ──────────────────────────────────────

  void _showBudgetSheet(
    BuildContext context,
    WidgetRef ref, {
    required String categoryId,
    required double currentAmount,
    required String categoryName,
    required Color categoryColor,
    required IconData categoryIcon,
  }) {
    final selectedMonth = ref.read(selectedMonthProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditBudgetSheet(
        categoryId: categoryId,
        currentAmount: currentAmount,
        categoryName: categoryName,
        categoryColor: categoryColor,
        categoryIcon: categoryIcon,
        onSave: (amount) async {
          await ref.read(budgetNotifierProvider.notifier).setBudget(
                categoryId: categoryId,
                amount: amount,
                month: selectedMonth.month,
                year: selectedMonth.year,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(AppStrings.snackBudgetSaved),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTH SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({
    required this.totalBudget,
    required this.totalSpent,
  });

  final double totalBudget;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final isOver = totalSpent > totalBudget && totalBudget > 0;
    final barColor = isOver ? AppColors.expense : AppColors.primary;
    final remaining = (totalBudget - totalSpent).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.budgetMonthly,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${CurrencyFormatter.formatCompact(totalSpent)} ${AppStrings.budgetOf} ${CurrencyFormatter.formatCompact(totalBudget)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryChip(
                label: AppStrings.budgetSpent,
                value: CurrencyFormatter.formatCompact(totalSpent),
                color: AppColors.expense,
              ),
              _SummaryChip(
                label:
                    isOver ? AppStrings.budgetOver : AppStrings.budgetRemaining,
                value: CurrencyFormatter.formatCompact(
                    isOver ? totalSpent - totalBudget : remaining.toDouble()),
                color: isOver ? AppColors.expense : AppColors.income,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.progress,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final Category? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = category?.color ?? AppColors.primary;
    final icon = category?.icon ?? Icons.category_outlined;
    final name = category?.name ?? '—';

    final barColor = progress.isOver
        ? AppColors.expense
        : progress.isNearLimit
            ? AppColors.warning
            : color;

    return Slidable(
      key: ValueKey(progress.budget.id),
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
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: progress.isOver
                ? Border.all(
                    color: AppColors.expense.withOpacity(0.4), width: 1.5)
                : progress.isNearLimit
                    ? Border.all(
                        color: AppColors.warning.withOpacity(0.5), width: 1.5)
                    : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // ── Icon ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Gap(12),

                  // ── Name & amounts ────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          '${CurrencyFormatter.formatCompact(progress.spent)} ${AppStrings.budgetOf} ${CurrencyFormatter.formatCompact(progress.budget.amount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Status badge ──────────────────────────
                  _StatusBadge(progress: progress),
                ],
              ),
              const Gap(12),

              // ── Progress bar ──────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.progress});
  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress.isOver) {
      return _Badge(
        label: AppStrings.budgetOver,
        color: AppColors.expense,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (progress.isNearLimit) {
      return _Badge(
        label: '${(progress.progress * 100).toInt()}%',
        color: AppColors.warning,
        icon: Icons.trending_up_rounded,
      );
    }
    return _Badge(
      label: '${(progress.progress * 100).toInt()}%',
      color: AppColors.income,
      icon: null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const Gap(4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD BUDGET SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet({
    required this.availableCategories,
    required this.month,
    required this.year,
    required this.onSave,
  });

  final List<Category> availableCategories;
  final int month;
  final int year;
  final Future<void> Function(String categoryId, double amount) onSave;

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Category? _selectedCategory;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ──────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                AppStrings.budgetAdd,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Gap(20),

              // ── Category picker ──────────────────────────────
              Text(AppStrings.fieldCategory,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  )),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableCategories.map((cat) {
                  final selected = _selectedCategory?.id == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? cat.color.withOpacity(0.15)
                            : theme.colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: cat.color, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const Gap(6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? cat.color
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(20),

              // ── Amount ────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: AppStrings.budgetLimit,
                  prefixIcon: Icon(Icons.savings_outlined),
                  suffixText: 'kr',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppStrings.validationRequired;
                  }
                  final parsed = CurrencyFormatter.tryParse(v);
                  if (parsed == null || parsed <= 0) {
                    return AppStrings.validationInvalidAmount;
                  }
                  return null;
                },
              ),
              const Gap(24),

              // ── Save ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(AppStrings.buttonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.validationSelectCategory),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final amount = CurrencyFormatter.tryParse(_amountController.text)!;
    await widget.onSave(_selectedCategory!.id, amount);
    if (mounted) Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT BUDGET SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _EditBudgetSheet extends StatefulWidget {
  const _EditBudgetSheet({
    required this.categoryId,
    required this.currentAmount,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onSave,
  });

  final String categoryId;
  final double currentAmount;
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;
  final Future<void> Function(double amount) onSave;

  @override
  State<_EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends State<_EditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Category header ───────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.categoryIcon,
                        color: widget.categoryColor, size: 20),
                  ),
                  const Gap(12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.budgetEdit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        widget.categoryName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(20),

              // ── Amount ────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                autofocus: false,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: AppStrings.budgetLimit,
                  prefixIcon: Icon(Icons.savings_outlined),
                  suffixText: 'kr',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppStrings.validationRequired;
                  }
                  final parsed = CurrencyFormatter.tryParse(v);
                  if (parsed == null || parsed <= 0) {
                    return AppStrings.validationInvalidAmount;
                  }
                  return null;
                },
              ),
              const Gap(24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(AppStrings.buttonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount = CurrencyFormatter.tryParse(_amountController.text)!;
    await widget.onSave(amount);
    if (mounted) Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withOpacity(0.18),
            ),
            const Gap(16),
            Text(
              AppStrings.budgetEmpty,
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
