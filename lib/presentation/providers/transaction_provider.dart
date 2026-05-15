import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORY
// ─────────────────────────────────────────────────────────────────────────────

/// Provides a single shared instance of [TransactionRepository].
/// Marked as const-like — never recreated unless the app restarts.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(),
);

// ─────────────────────────────────────────────────────────────────────────────
// SELECTED MONTH
// ─────────────────────────────────────────────────────────────────────────────

/// The month/year the user is currently viewing.
/// Defaults to the current month. The UI updates this when the user
/// navigates backwards or forwards through months.
final selectedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month),
);

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTION NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the full list of all transactions and exposes mutation methods.
/// Any provider that derives from this will automatically rebuild when
/// transactions are added, updated, or deleted.
class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final TransactionRepository _repository;

  TransactionNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllTransactions();
  }

  Future<void> addTransaction({
    required double amount,
    required String description,
    required String categoryId,
    required DateTime date,
    required bool isExpense,
  }) async {
    await _repository.addTransaction(
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      isExpense: isExpense,
    );
    _load();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.updateTransaction(transaction);
    _load();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    _load();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    _load();
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, List<Transaction>>(
  (ref) => TransactionNotifier(ref.watch(transactionRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class CategoryNotifier extends StateNotifier<List<Category>> {
  final TransactionRepository _repository;

  CategoryNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllCategories();
  }

  Future<void> addCategory({
    required String name,
    required int colorValue,
    required String iconKey,
    required bool isExpense,
  }) async {
    await _repository.addCategory(
      name: name,
      colorValue: colorValue,
      iconKey: iconKey,
      isExpense: isExpense,
    );
    _load();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
    _load();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    _load();
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>(
  (ref) => CategoryNotifier(ref.watch(transactionRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// DERIVED — filtered & aggregated (rebuilt automatically on state change)
// ─────────────────────────────────────────────────────────────────────────────

/// All transactions for the currently selected month, newest first.
final transactionsForMonthProvider = Provider<List<Transaction>>((ref) {
  final all = ref.watch(transactionNotifierProvider);
  final month = ref.watch(selectedMonthProvider);
  return all
      .where(
        (t) => t.date.month == month.month && t.date.year == month.year,
      )
      .toList();
});

/// Total income (inkomster) for the selected month.
final monthlyIncomeProvider = Provider<double>((ref) {
  return ref
      .watch(transactionsForMonthProvider)
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Total expenses (utgifter) for the selected month.
final monthlyExpensesProvider = Provider<double>((ref) {
  return ref
      .watch(transactionsForMonthProvider)
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Net balance (saldo) for the selected month.
final monthlyBalanceProvider = Provider<double>((ref) {
  return ref.watch(monthlyIncomeProvider) - ref.watch(monthlyExpensesProvider);
});

/// Only expense categories — used in the "add transaction" form.
final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoryNotifierProvider).where((c) => c.isExpense).toList();
});

/// Only income categories — used in the "add transaction" form.
final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  return ref
      .watch(categoryNotifierProvider)
      .where((c) => !c.isExpense)
      .toList();
});

/// Looks up a single category by id. Returns null if not found.
/// Takes a [categoryId] parameter — use it like:
///   ref.watch(categoryByIdProvider('cat_mat'))
final categoryByIdProvider =
    Provider.family<Category?, String>((ref, categoryId) {
  return ref
      .watch(categoryNotifierProvider)
      .cast<Category?>()
      .firstWhere((c) => c?.id == categoryId, orElse: () => null);
});
