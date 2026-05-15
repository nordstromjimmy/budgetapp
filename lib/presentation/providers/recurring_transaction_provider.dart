import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recurring_transaction.dart';
import '../../data/repositories/recurring_transaction_repository.dart';
import 'transaction_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORY
// ─────────────────────────────────────────────────────────────────────────────

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>(
  (ref) => RecurringTransactionRepository(),
);

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class RecurringTransactionNotifier
    extends StateNotifier<List<RecurringTransaction>> {
  final RecurringTransactionRepository _repository;
  final TransactionNotifier _transactionNotifier;

  RecurringTransactionNotifier(this._repository, this._transactionNotifier)
      : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAll();
  }

  void reload() => _load();

  Future<void> add({
    required double amount,
    required String description,
    required String categoryId,
    required bool isExpense,
    required int dayOfMonth,
  }) async {
    await _repository.add(
      amount: amount,
      description: description,
      categoryId: categoryId,
      isExpense: isExpense,
      dayOfMonth: dayOfMonth,
    );
    // Immediately generate for the current month if applicable
    await _repository.generateForCurrentMonth();
    // Notify the transaction notifier to reload so the new tx appears
    _transactionNotifier.reload();
    _load();
  }

  Future<void> skipThisMonth(String recurringId) async {
    await _repository.skipThisMonth(recurringId);
    _load();
  }

  Future<void> toggleActive(String id) async {
    await _repository.toggleActive(id);
    _load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    // Reload transactions since generated ones were deleted
    _transactionNotifier.reload();
    _load();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    _load();
  }
}

final recurringTransactionNotifierProvider = StateNotifierProvider<
    RecurringTransactionNotifier, List<RecurringTransaction>>(
  (ref) => RecurringTransactionNotifier(
    ref.watch(recurringTransactionRepositoryProvider),
    ref.read(transactionNotifierProvider.notifier),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// DERIVED
// ─────────────────────────────────────────────────────────────────────────────

final activeRecurringProvider = Provider<List<RecurringTransaction>>((ref) {
  return ref
      .watch(recurringTransactionNotifierProvider)
      .where((r) => r.isActive)
      .toList();
});

final recurringExpensesProvider = Provider<List<RecurringTransaction>>((ref) {
  return ref
      .watch(recurringTransactionNotifierProvider)
      .where((r) => r.isExpense)
      .toList();
});

final recurringIncomeProvider = Provider<List<RecurringTransaction>>((ref) {
  return ref
      .watch(recurringTransactionNotifierProvider)
      .where((r) => !r.isExpense)
      .toList();
});
