import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'category.g.dart';

/// Hive typeId: 0
/// ⚠️  Never change existing @HiveField indexes after release —
///     doing so corrupts data already stored on user devices.
@HiveType(typeId: 0)
class Category extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  /// Display name shown in the UI (Swedish, e.g. "Mat & dryck")
  @HiveField(1)
  final String name;

  /// Stored as an int so Hive can persist it (Color.value)
  @HiveField(2)
  final int colorValue;

  /// Stored as an int so Hive can persist it (IconData.codePoint)
  @HiveField(3)
  final int iconCodePoint;

  /// true  → expense category (utgift)
  /// false → income category  (inkomst)
  @HiveField(4)
  final bool isExpense;

  Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.isExpense,
  });

  // ── Convenience getters ───────────────────────────────────────

  Color get color => Color(colorValue);

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  // ── copyWith ──────────────────────────────────────────────────

  Category copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    bool? isExpense,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  // ── Equatable ─────────────────────────────────────────────────

  @override
  List<Object?> get props => [id, name, colorValue, iconCodePoint, isExpense];

  // ── Default categories (seeded on first launch) ───────────────

  static List<Category> get defaults => [
    // ── Utgifter (expenses) ───────────────────────────────
    Category(
      id: 'cat_mat',
      name: 'Mat & dryck',
      colorValue: const Color(0xFFE53935).value,
      iconCodePoint: Icons.restaurant.codePoint,
      isExpense: true,
    ),
    Category(
      id: 'cat_transport',
      name: 'Transport',
      colorValue: const Color(0xFF1E88E5).value,
      iconCodePoint: Icons.directions_car.codePoint,
      isExpense: true,
    ),
    Category(
      id: 'cat_boende',
      name: 'Boende',
      colorValue: const Color(0xFF8E24AA).value,
      iconCodePoint: Icons.home.codePoint,
      isExpense: true,
    ),
    Category(
      id: 'cat_noje',
      name: 'Nöje & fritid',
      colorValue: const Color(0xFFFF6F00).value,
      iconCodePoint: Icons.sports_esports.codePoint,
      isExpense: true,
    ),
    Category(
      id: 'cat_halsa',
      name: 'Hälsa',
      colorValue: const Color(0xFF00ACC1).value,
      iconCodePoint: Icons.favorite.codePoint,
      isExpense: true,
    ),
    Category(
      id: 'cat_klader',
      name: 'Kläder',
      colorValue: const Color(0xFFD81B60).value,
      iconCodePoint: Icons.checkroom.codePoint,
      isExpense: true,
    ),
    Category(
      id: 'cat_ovrigt_utgift',
      name: 'Övrigt',
      colorValue: const Color(0xFF757575).value,
      iconCodePoint: Icons.more_horiz.codePoint,
      isExpense: true,
    ),

    // ── Inkomster (income) ────────────────────────────────
    Category(
      id: 'cat_lon',
      name: 'Lön',
      colorValue: const Color(0xFF43A047).value,
      iconCodePoint: Icons.work.codePoint,
      isExpense: false,
    ),
    Category(
      id: 'cat_frilans',
      name: 'Frilans',
      colorValue: const Color(0xFF00897B).value,
      iconCodePoint: Icons.computer.codePoint,
      isExpense: false,
    ),
    Category(
      id: 'cat_ovrigt_inkomst',
      name: 'Övrigt',
      colorValue: const Color(0xFF757575).value,
      iconCodePoint: Icons.more_horiz.codePoint,
      isExpense: false,
    ),
  ];
}
