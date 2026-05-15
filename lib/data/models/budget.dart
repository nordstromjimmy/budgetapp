import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

part 'budget.g.dart';

/// A monthly spending limit tied to one [Category].
///
/// Hive typeId: 2
/// ⚠️  Never change existing @HiveField indexes after release —
///     doing so corrupts data already stored on user devices.
@HiveType(typeId: 2)
class Budget with EquatableMixin {
  @HiveField(0)
  final String id;

  /// References [Category.id] — one budget per category per month
  @HiveField(1)
  final String categoryId;

  /// The spending limit in SEK for this month (always positive)
  @HiveField(2)
  final double amount;

  /// 1–12
  @HiveField(3)
  final int month;

  /// e.g. 2025
  @HiveField(4)
  final int year;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
  });

  // ── Convenience ───────────────────────────────────────────────

  /// Returns true if this budget belongs to the given month/year
  bool isForMonth(int month, int year) =>
      this.month == month && this.year == year;

  // ── copyWith ──────────────────────────────────────────────────

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  // ── Equatable ─────────────────────────────────────────────────

  @override
  List<Object?> get props => [id, categoryId, amount, month, year];
}
