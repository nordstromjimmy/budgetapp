import 'dart:math';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../../core/constants/hive_boxes.dart';

class RecurringTransactionRepository {
  final _uuid = const Uuid();

  Box<RecurringTransaction> get _box =>
      Hive.box<RecurringTransaction>(HiveBoxes.recurringTransactions);

  Box<Transaction> get _transactionBox =>
      Hive.box<Transaction>(HiveBoxes.transactions);

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  List<RecurringTransaction> getAll() => _box.values.toList();

  List<RecurringTransaction> getActive() =>
      _box.values.where((r) => r.isActive).toList();

  // ─────────────────────────────────────────────────────────────
  // WRITE
  // ─────────────────────────────────────────────────────────────

  Future<RecurringTransaction> add({
    required double amount,
    required String description,
    required String categoryId,
    required bool isExpense,
    required int dayOfMonth,
  }) async {
    final recurring = RecurringTransaction(
      id: _uuid.v4(),
      amount: amount,
      description: description,
      categoryId: categoryId,
      isExpense: isExpense,
      dayOfMonth: dayOfMonth.clamp(1, 28),
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _box.put(recurring.id, recurring);
    return recurring;
  }

  Future<void> update(RecurringTransaction recurring) async {
    await _box.put(recurring.id, recurring);
  }

  Future<void> toggleActive(String id) async {
    final recurring = _box.get(id);
    if (recurring == null) return;
    await _box.put(id, recurring.copyWith(isActive: !recurring.isActive));
  }

  /// Deletes the template AND all transactions generated from it.
  Future<void> delete(String id) async {
    // Remove all auto-generated transactions linked to this template
    final generated = _transactionBox.values
        .where((t) => t.recurringTransactionId == id)
        .toList();
    for (final t in generated) {
      await _transactionBox.delete(t.id);
    }
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  // ─────────────────────────────────────────────────────────────
  // SKIP LOGIC
  // ─────────────────────────────────────────────────────────────

  static String _monthKey(int month, int year) => '$year-$month';

  /// Marks a recurring template as skipped for the current month.
  /// Persisted directly inside the RecurringTransaction in Hive.
  Future<void> skipThisMonth(String recurringId) async {
    final recurring = _box.get(recurringId);
    if (recurring == null) return;
    final key = _monthKey(DateTime.now().month, DateTime.now().year);
    if (recurring.skippedMonths.contains(key)) return;
    final updated = recurring.copyWith(
      skippedMonths: [...recurring.skippedMonths, key],
    );
    await _box.put(recurringId, updated);
  }

  /// Returns true if this template has been skipped for the given month/year.
  bool isSkipped(RecurringTransaction recurring, int month, int year) {
    return recurring.skippedMonths.contains(_monthKey(month, year));
  }

  // ─────────────────────────────────────────────────────────────
  // GENERATION SERVICE
  // ─────────────────────────────────────────────────────────────

  /// Called on app startup. For each active template, creates a transaction
  /// for the current month if one hasn't been created yet.
  ///
  /// Safe to call multiple times — fully idempotent.
  Future<void> generateForCurrentMonth() async {
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;

    print('=== generateForCurrentMonth ===');
    print('Month: $month, Year: $year');

    final allRecurring = _box.values.toList();
    print('Templates in box: ${allRecurring.length}');

    for (final r in allRecurring) {
      print('Template: ${r.id} | skippedMonths: ${r.skippedMonths}');
    }

    final existingThisMonth = _transactionBox.values
        .where((t) => t.date.month == month && t.date.year == year)
        .toList();
    print('Existing transactions this month: ${existingThisMonth.length}');
    for (final t in existingThisMonth) {
      print('  tx: ${t.id} | recurringId: ${t.recurringTransactionId}');
    }

    for (final recurring in getActive()) {
      // Skip if this template was created after this month started —
      // it will be picked up next month automatically.
      final createdMonth = DateTime(
        recurring.createdAt.year,
        recurring.createdAt.month,
      );
      final currentMonth = DateTime(year, month);
      if (createdMonth.isAfter(currentMonth)) continue;

      // Skip if the user deleted this month's entry intentionally
      if (isSkipped(recurring, month, year)) continue;

      // Skip if already generated for this month
      final alreadyGenerated = existingThisMonth.any(
        (t) => t.recurringTransactionId == recurring.id,
      );
      if (alreadyGenerated) continue;

      // Cap day to the actual last day of this month (handles Feb, etc.)
      final lastDay = DateTime(year, month + 1, 0).day;
      final day = min(recurring.dayOfMonth, lastDay);

      final transaction = Transaction(
        id: _uuid.v4(),
        amount: recurring.amount,
        description: recurring.description,
        categoryId: recurring.categoryId,
        date: DateTime(year, month, day),
        isExpense: recurring.isExpense,
        recurringTransactionId: recurring.id,
      );

      await _transactionBox.put(transaction.id, transaction);
    }
  }
}
