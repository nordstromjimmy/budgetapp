import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

part 'transaction.g.dart';

/// Hive typeId: 1
/// ⚠️  Never change existing @HiveField indexes after release —
///     doing so corrupts data already stored on user devices.
@HiveType(typeId: 1)
class Transaction extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  /// Always stored as a positive number.
  /// Whether it is income or expense is determined by [isExpense].
  @HiveField(1)
  final double amount;

  /// Optional note from the user (e.g. "ICA Maxi fredag")
  @HiveField(2)
  final String description;

  /// References [Category.id]
  @HiveField(3)
  final String categoryId;

  /// The date the transaction occurred (time component ignored in UI)
  @HiveField(4)
  final DateTime date;

  /// true  → utgift  (money going out)
  /// false → inkomst (money coming in)
  @HiveField(5)
  final bool isExpense;

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.date,
    required this.isExpense,
  });

  // ── copyWith ──────────────────────────────────────────────────

  Transaction copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    DateTime? date,
    bool? isExpense,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  // ── Equatable ─────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        categoryId,
        date,
        isExpense,
      ];
}
