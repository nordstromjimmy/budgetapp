import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../../core/constants/hive_boxes.dart';

/// Handles all read/write operations for [Transaction] and [Category].
///
/// Both live here because categories are tightly coupled to transactions
/// (every transaction belongs to a category) and it keeps the surface area
/// of Hive box management small.
class TransactionRepository {
  final _uuid = const Uuid();

  // ── Internal box access ───────────────────────────────────────

  Box<Transaction> get _transactionBox =>
      Hive.box<Transaction>(HiveBoxes.transactions);

  Box<Category> get _categoryBox => Hive.box<Category>(HiveBoxes.categories);

  // ─────────────────────────────────────────────────────────────
  // TRANSACTIONS
  // ─────────────────────────────────────────────────────────────

  /// Returns all transactions sorted by date descending (newest first).
  List<Transaction> getAllTransactions() {
    final transactions = _transactionBox.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Returns transactions for a specific [month] and [year], newest first.
  List<Transaction> getTransactionsByMonth(int month, int year) {
    return getAllTransactions()
        .where((t) => t.date.month == month && t.date.year == year)
        .toList();
  }

  /// Returns transactions for a specific [categoryId], newest first.
  List<Transaction> getTransactionsByCategory(String categoryId) {
    return getAllTransactions()
        .where((t) => t.categoryId == categoryId)
        .toList();
  }

  /// Adds a new transaction. Returns the created [Transaction].
  Future<Transaction> addTransaction({
    required double amount,
    required String description,
    required String categoryId,
    required DateTime date,
    required bool isExpense,
    String? recurringTransactionId,
  }) async {
    final transaction = Transaction(
      id: _uuid.v4(),
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      isExpense: isExpense,
      recurringTransactionId: recurringTransactionId,
    );
    await _transactionBox.put(transaction.id, transaction);
    return transaction;
  }

  /// Replaces an existing transaction. Identified by [transaction.id].
  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionBox.put(transaction.id, transaction);
  }

  /// Permanently deletes a transaction by its [id].
  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
  }

  // ── Aggregates ────────────────────────────────────────────────

  /// Total income for a given month/year.
  double totalIncomeForMonth(int month, int year) {
    return getTransactionsByMonth(month, year)
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total expenses for a given month/year.
  double totalExpensesForMonth(int month, int year) {
    return getTransactionsByMonth(month, year)
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Net balance (income − expenses) for a given month/year.
  double balanceForMonth(int month, int year) {
    return totalIncomeForMonth(month, year) -
        totalExpensesForMonth(month, year);
  }

  /// Total spent in a given [categoryId] for a given month/year.
  /// Used by the budget screen to calculate progress.
  double spentInCategoryForMonth(
    String categoryId,
    int month,
    int year,
  ) {
    return getTransactionsByMonth(month, year)
        .where((t) => t.isExpense && t.categoryId == categoryId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────

  /// Returns all categories.
  List<Category> getAllCategories() => _categoryBox.values.toList();

  /// Returns only expense categories.
  List<Category> getExpenseCategories() =>
      getAllCategories().where((c) => c.isExpense).toList();

  /// Returns only income categories.
  List<Category> getIncomeCategories() =>
      getAllCategories().where((c) => !c.isExpense).toList();

  /// Looks up a single category by [id]. Returns null if not found.
  Category? getCategoryById(String id) => _categoryBox.get(id);

  /// Adds a new custom category.
  Future<void> addCategory({
    required String name,
    required int colorValue,
    required String iconKey,
    required bool isExpense,
  }) async {
    final category = Category(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      iconKey: iconKey,
      isExpense: isExpense,
    );
    await _categoryBox.put(category.id, category);
  }

  /// Updates an existing category.
  Future<void> updateCategory(Category category) async {
    await _categoryBox.put(category.id, category);
  }

  /// Deletes a category. Note: does NOT cascade-delete its transactions.
  /// The UI should warn the user before allowing this.
  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }

  /// Seeds the default Swedish categories on first launch.
  /// Safe to call multiple times — skips if already seeded.
  Future<void> seedDefaultCategories() async {
    if (_categoryBox.isNotEmpty) return;
    for (final category in Category.defaults) {
      await _categoryBox.put(category.id, category);
    }
  }

  /// Deletes all transactions and categories. Used in Settings → Rensa data.
  Future<void> clearAll() async {
    await _transactionBox.clear();
    await _categoryBox.clear();
  }
}
