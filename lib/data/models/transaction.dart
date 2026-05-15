import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

part 'transaction.g.dart';

/// Hive typeId: 1
/// ⚠️  Never change existing @HiveField indexes after release —
///     doing so corrupts data already stored on user devices.
@HiveType(typeId: 1)
class Transaction with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final bool isExpense;

  /// If set, this transaction was auto-generated from a [RecurringTransaction]
  /// with this id. Used to avoid duplicate generation and for cascade-delete.
  /// Null for all manually entered transactions.
  @HiveField(6)
  final String? recurringTransactionId;

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.date,
    required this.isExpense,
    this.recurringTransactionId,
  });

  bool get isRecurring => recurringTransactionId != null;

  Transaction copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    DateTime? date,
    bool? isExpense,
    String? recurringTransactionId,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
      recurringTransactionId:
          recurringTransactionId ?? this.recurringTransactionId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        categoryId,
        date,
        isExpense,
        recurringTransactionId,
      ];
}
