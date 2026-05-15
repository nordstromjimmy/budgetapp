import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../../core/constants/hive_boxes.dart';

/// Current schema version — bump this if the export format ever changes
/// so the importer can handle older backups gracefully.
const _kSchemaVersion = 1;

class BackupService {
  // ─────────────────────────────────────────────────────────────
  // EXPORT
  // ─────────────────────────────────────────────────────────────

  /// Serialises all data to JSON and shares the file via the system
  /// share sheet (save to Files, send via email, etc.)
  Future<void> exportToJson(BuildContext context) async {
    final transactions =
        Hive.box<Transaction>(HiveBoxes.transactions).values.toList();
    final categories = Hive.box<Category>(HiveBoxes.categories).values.toList();
    final budgets = Hive.box<Budget>(HiveBoxes.budgets).values.toList();
    final recurring =
        Hive.box<RecurringTransaction>(HiveBoxes.recurringTransactions)
            .values
            .toList();

    final payload = {
      'schemaVersion': _kSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map(_transactionToJson).toList(),
      'categories': categories.map(_categoryToJson).toList(),
      'budgets': budgets.map(_budgetToJson).toList(),
      'recurringTransactions': recurring.map(_recurringToJson).toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);

    // Write to a temp file then share it
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('${dir.path}/budgetapp_backup_$dateStr.json');
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Budgetapp – säkerhetskopia $dateStr',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // IMPORT
  // ─────────────────────────────────────────────────────────────

  /// Opens a file picker, parses the JSON and writes all data to Hive.
  /// Returns a [BackupResult] describing what was imported or the error.
  Future<BackupResult> importFromJson() async {
    // Pick a file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return BackupResult.cancelled();
    }

    final path = result.files.single.path;
    if (path == null) return BackupResult.error('Kunde inte läsa filen.');

    // Parse JSON
    final Map<String, dynamic> payload;
    try {
      final content = await File(path).readAsString();
      payload = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return BackupResult.error(
          'Ogiltig fil. Kontrollera att du valt rätt JSON-fil.');
    }

    // Schema version check
    final version = payload['schemaVersion'] as int? ?? 0;
    if (version > _kSchemaVersion) {
      return BackupResult.error(
          'Filen är skapad med en nyare version av appen.');
    }

    // Write to Hive — clear existing data first so we get a clean import
    try {
      await _writeTransactions((payload['transactions'] as List? ?? []).cast());
      await _writeCategories((payload['categories'] as List? ?? []).cast());
      await _writeBudgets((payload['budgets'] as List? ?? []).cast());
      await _writeRecurring(
          (payload['recurringTransactions'] as List? ?? []).cast());
    } catch (e) {
      return BackupResult.error('Import misslyckades: $e');
    }

    final txCount = (payload['transactions'] as List? ?? []).length;
    return BackupResult.success(transactionCount: txCount);
  }

  // ─────────────────────────────────────────────────────────────
  // SERIALISERS
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _transactionToJson(Transaction t) => {
        'id': t.id,
        'amount': t.amount,
        'description': t.description,
        'categoryId': t.categoryId,
        'date': t.date.toIso8601String(),
        'isExpense': t.isExpense,
        'recurringTransactionId': t.recurringTransactionId,
      };

  Map<String, dynamic> _categoryToJson(Category c) => {
        'id': c.id,
        'name': c.name,
        'colorValue': c.colorValue,
        'iconKey': c.iconKey,
        'isExpense': c.isExpense,
      };

  Map<String, dynamic> _budgetToJson(Budget b) => {
        'id': b.id,
        'categoryId': b.categoryId,
        'amount': b.amount,
        'month': b.month,
        'year': b.year,
      };

  Map<String, dynamic> _recurringToJson(RecurringTransaction r) => {
        'id': r.id,
        'amount': r.amount,
        'description': r.description,
        'categoryId': r.categoryId,
        'isExpense': r.isExpense,
        'dayOfMonth': r.dayOfMonth,
        'isActive': r.isActive,
        'createdAt': r.createdAt.toIso8601String(),
        'skippedMonths': r.skippedMonths,
      };

  // ─────────────────────────────────────────────────────────────
  // WRITERS
  // ─────────────────────────────────────────────────────────────

  Future<void> _writeTransactions(List<Map<String, dynamic>> list) async {
    final box = Hive.box<Transaction>(HiveBoxes.transactions);
    await box.clear();
    for (final m in list) {
      final t = Transaction(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        description: m['description'] as String,
        categoryId: m['categoryId'] as String,
        date: DateTime.parse(m['date'] as String),
        isExpense: m['isExpense'] as bool,
        recurringTransactionId: m['recurringTransactionId'] as String?,
      );
      await box.put(t.id, t);
    }
  }

  Future<void> _writeCategories(List<Map<String, dynamic>> list) async {
    final box = Hive.box<Category>(HiveBoxes.categories);
    await box.clear();
    for (final m in list) {
      final c = Category(
        id: m['id'] as String,
        name: m['name'] as String,
        colorValue: m['colorValue'] as int,
        iconKey: m['iconKey'] as String,
        isExpense: m['isExpense'] as bool,
      );
      await box.put(c.id, c);
    }
  }

  Future<void> _writeBudgets(List<Map<String, dynamic>> list) async {
    final box = Hive.box<Budget>(HiveBoxes.budgets);
    await box.clear();
    for (final m in list) {
      final b = Budget(
        id: m['id'] as String,
        categoryId: m['categoryId'] as String,
        amount: (m['amount'] as num).toDouble(),
        month: m['month'] as int,
        year: m['year'] as int,
      );
      await box.put(b.id, b);
    }
  }

  Future<void> _writeRecurring(List<Map<String, dynamic>> list) async {
    final box = Hive.box<RecurringTransaction>(HiveBoxes.recurringTransactions);
    await box.clear();
    for (final m in list) {
      final r = RecurringTransaction(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        description: m['description'] as String,
        categoryId: m['categoryId'] as String,
        isExpense: m['isExpense'] as bool,
        dayOfMonth: m['dayOfMonth'] as int,
        isActive: m['isActive'] as bool,
        createdAt: DateTime.parse(m['createdAt'] as String),
        skippedMonths: (m['skippedMonths'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
      );
      await box.put(r.id, r);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT
// ─────────────────────────────────────────────────────────────────────────────

class BackupResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;
  final int transactionCount;

  const BackupResult._({
    required this.success,
    required this.cancelled,
    this.errorMessage,
    this.transactionCount = 0,
  });

  factory BackupResult.success({required int transactionCount}) =>
      BackupResult._(
          success: true, cancelled: false, transactionCount: transactionCount);

  factory BackupResult.cancelled() =>
      BackupResult._(success: false, cancelled: true);

  factory BackupResult.error(String message) =>
      BackupResult._(success: false, cancelled: false, errorMessage: message);
}
