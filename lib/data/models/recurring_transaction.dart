import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

part 'recurring_transaction.g.dart';

/// A template that generates a [Transaction] automatically each month.
///
/// Hive typeId: 3
/// ⚠️  Never change existing @HiveField indexes after release.
@HiveType(typeId: 3)
class RecurringTransaction with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final bool isExpense;

  /// Day of month this transaction is generated on (1–28).
  /// Capped at 28 to avoid issues with February and shorter months.
  @HiveField(5)
  final int dayOfMonth;

  /// When false, the template is paused — no new transactions are generated
  /// but the template is kept so the user can re-activate it later.
  @HiveField(6)
  final bool isActive;

  /// The month/year this recurring transaction was first created.
  /// Used to avoid generating transactions for past months on first setup.
  @HiveField(7)
  final DateTime createdAt;

  /// List of "YYYY-MM" strings for months where the user intentionally
  /// deleted this month's generated transaction.
  /// generateForCurrentMonth() skips these months.
  @HiveField(8)
  final List<String> skippedMonths;

  RecurringTransaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.isExpense,
    required this.dayOfMonth,
    required this.isActive,
    required this.createdAt,
    this.skippedMonths = const [],
  });

  RecurringTransaction copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    bool? isExpense,
    int? dayOfMonth,
    bool? isActive,
    DateTime? createdAt,
    List<String>? skippedMonths,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      isExpense: isExpense ?? this.isExpense,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      skippedMonths: skippedMonths ?? this.skippedMonths,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        categoryId,
        isExpense,
        dayOfMonth,
        isActive,
        createdAt,
        skippedMonths
      ];
}
