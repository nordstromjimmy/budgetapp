import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/budget.dart';
import '../../data/repositories/budget_repository.dart';
import 'transaction_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORY
// ─────────────────────────────────────────────────────────────────────────────

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(),
);

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class BudgetNotifier extends StateNotifier<List<Budget>> {
  final BudgetRepository _repository;

  BudgetNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllBudgets();
  }

  void reload() => _load();

  Future<void> setBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    await _repository.setBudget(
      categoryId: categoryId,
      amount: amount,
      month: month,
      year: year,
    );
    // setBudget may upsert (delete old + add new), so re-read is safest here
    _load();
  }

  Future<void> deleteBudget(String id) async {
    await _repository.deleteBudget(id);
    state = state.where((b) => b.id != id).toList();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    state = [];
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, List<Budget>>(
  (ref) => BudgetNotifier(ref.watch(budgetRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// DERIVED
// ─────────────────────────────────────────────────────────────────────────────

/// All budgets for the currently selected month.
final budgetsForMonthProvider = Provider<List<Budget>>((ref) {
  final all = ref.watch(budgetNotifierProvider);
  final month = ref.watch(selectedMonthProvider);
  return all
      .where((b) => b.month == month.month && b.year == month.year)
      .toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET PROGRESS
// ─────────────────────────────────────────────────────────────────────────────

/// A snapshot of one budget's progress for the UI.
class BudgetProgress {
  final Budget budget;
  final double spent;

  const BudgetProgress({required this.budget, required this.spent});

  double get remaining => (budget.amount - spent).clamp(0, double.infinity);
  double get overSpent => spent > budget.amount ? spent - budget.amount : 0;

  /// 0.0 → 1.0. Clamped at 1.0 so the progress bar never overflows.
  double get progress => (spent / budget.amount).clamp(0.0, 1.0);

  bool get isOver => spent > budget.amount;

  /// True when spent is between 80% and 100% of the budget — show a warning.
  bool get isNearLimit => !isOver && progress >= 0.8;
}

/// List of [BudgetProgress] for the selected month.
/// Each entry combines the budget limit with actual spending from transactions.
/// Sorted: over-budget first, then by progress descending.
final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetsForMonthProvider);
  final transactions = ref.watch(transactionsForMonthProvider);
  final month = ref.watch(selectedMonthProvider);

  final progresses = budgets.map((budget) {
    final spent = transactions
        .where(
          (t) => t.isExpense && t.categoryId == budget.categoryId,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    return BudgetProgress(budget: budget, spent: spent);
  }).toList();

  // Sort: over-budget first, then by highest usage
  progresses.sort((a, b) {
    if (a.isOver && !b.isOver) return -1;
    if (!a.isOver && b.isOver) return 1;
    return b.progress.compareTo(a.progress);
  });

  return progresses;
});

/// Total budget limit for the selected month across all categories.
final totalBudgetForMonthProvider = Provider<double>((ref) {
  return ref
      .watch(budgetsForMonthProvider)
      .fold(0.0, (sum, b) => sum + b.amount);
});

/// Total spent against budgeted categories only (not all expenses).
final totalSpentAgainstBudgetProvider = Provider<double>((ref) {
  return ref.watch(budgetProgressProvider).fold(0.0, (sum, p) => sum + p.spent);
});
