import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/budget.dart';
import '../../core/constants/hive_boxes.dart';

/// Handles all read/write operations for [Budget].
class BudgetRepository {
  final _uuid = const Uuid();

  // ── Internal box access ───────────────────────────────────────

  Box<Budget> get _budgetBox => Hive.box<Budget>(HiveBoxes.budgets);

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  /// Returns all budgets stored on device.
  List<Budget> getAllBudgets() => _budgetBox.values.toList();

  /// Returns all budgets for a specific [month] and [year].
  List<Budget> getBudgetsForMonth(int month, int year) {
    return getAllBudgets()
        .where((b) => b.month == month && b.year == year)
        .toList();
  }

  /// Returns the budget for a specific category in a given month/year.
  /// Returns null if no budget has been set for that category yet.
  Budget? getBudgetForCategory(String categoryId, int month, int year) {
    try {
      return getAllBudgets().firstWhere(
        (b) => b.categoryId == categoryId && b.month == month && b.year == year,
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // WRITE
  // ─────────────────────────────────────────────────────────────

  /// Creates a new budget for a category/month/year combination.
  ///
  /// If a budget already exists for that combination it will be
  /// overwritten — enforcing the one-budget-per-category-per-month rule.
  Future<void> setBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    // Remove existing budget for this category+month+year if present
    final existing = getBudgetForCategory(categoryId, month, year);
    if (existing != null) {
      await _budgetBox.delete(existing.id);
    }

    final budget = Budget(
      id: _uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      month: month,
      year: year,
    );
    await _budgetBox.put(budget.id, budget);
  }

  /// Updates the limit amount of an existing budget.
  Future<void> updateBudget(Budget budget) async {
    await _budgetBox.put(budget.id, budget);
  }

  /// Permanently deletes a budget by its [id].
  Future<void> deleteBudget(String id) async {
    await _budgetBox.delete(id);
  }

  // ─────────────────────────────────────────────────────────────
  // AGGREGATES
  // ─────────────────────────────────────────────────────────────

  /// Total budget limit across all categories for a given month/year.
  double totalBudgetForMonth(int month, int year) {
    return getBudgetsForMonth(month, year)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  /// Deletes all budgets. Used in Settings → Rensa data.
  Future<void> clearAll() async {
    await _budgetBox.clear();
  }
}
