import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_icons.dart';

part 'category.g.dart';

/// Hive typeId: 0
/// ⚠️  Never change existing @HiveField indexes after release —
///     doing so corrupts data already stored on user devices.
///
/// Note: we store [iconKey] as a String (e.g. "restaurant") rather than
/// an IconData codePoint int. This is required for Flutter release builds —
/// dynamic IconData(codePoint) constructions break the icon tree shaker.
@HiveType(typeId: 0)
class Category with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// Stored as an int so Hive can persist it (Color.value).
  @HiveField(2)
  final int colorValue;

  /// String key looked up in [AppIcons] — e.g. "restaurant", "home".
  /// Replaces the old iconCodePoint field to satisfy the Flutter tree shaker.
  @HiveField(3)
  final String iconKey;

  @HiveField(4)
  final bool isExpense;

  Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    required this.isExpense,
  });

  // ── Convenience getters ───────────────────────────────────────

  Color get color => Color(colorValue);

  /// Looks up the constant IconData from [AppIcons] — tree-shaker safe.
  IconData get icon => AppIcons.get(iconKey);

  // ── copyWith ──────────────────────────────────────────────────

  Category copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? iconKey,
    bool? isExpense,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  // ── Equatable ─────────────────────────────────────────────────

  @override
  List<Object?> get props => [id, name, colorValue, iconKey, isExpense];

  // ── Default categories (seeded on first launch) ───────────────

  static List<Category> get defaults => [
        // ── Utgifter (expenses) ───────────────────────────────
        Category(
          id: 'cat_mat',
          name: 'Mat & dryck',
          colorValue: const Color(0xFFE53935).value,
          iconKey: 'restaurant',
          isExpense: true,
        ),
        Category(
          id: 'cat_transport',
          name: 'Transport',
          colorValue: const Color(0xFF1E88E5).value,
          iconKey: 'directions_car',
          isExpense: true,
        ),
        Category(
          id: 'cat_boende',
          name: 'Boende',
          colorValue: const Color(0xFF8E24AA).value,
          iconKey: 'home',
          isExpense: true,
        ),
        Category(
          id: 'cat_noje',
          name: 'Nöje & fritid',
          colorValue: const Color(0xFFFF6F00).value,
          iconKey: 'sports_esports',
          isExpense: true,
        ),
        Category(
          id: 'cat_halsa',
          name: 'Hälsa',
          colorValue: const Color(0xFF00ACC1).value,
          iconKey: 'favorite',
          isExpense: true,
        ),
        Category(
          id: 'cat_klader',
          name: 'Kläder',
          colorValue: const Color(0xFFD81B60).value,
          iconKey: 'checkroom',
          isExpense: true,
        ),
        Category(
          id: 'cat_prenumerationer',
          name: 'Prenumerationer',
          colorValue: const Color(0xFF3949AB).value,
          iconKey: 'subscriptions',
          isExpense: true,
        ),
        Category(
          id: 'cat_ovrigt_utgift',
          name: 'Övrigt',
          colorValue: const Color(0xFF757575).value,
          iconKey: 'more_horiz',
          isExpense: true,
        ),

        // ── Inkomster (income) ────────────────────────────────
        Category(
          id: 'cat_lon',
          name: 'Lön',
          colorValue: const Color(0xFF43A047).value,
          iconKey: 'work',
          isExpense: false,
        ),
        Category(
          id: 'cat_frilans',
          name: 'Frilans',
          colorValue: const Color(0xFF00897B).value,
          iconKey: 'computer',
          isExpense: false,
        ),
        Category(
          id: 'cat_ovrigt_inkomst',
          name: 'Övrigt',
          colorValue: const Color(0xFF757575).value,
          iconKey: 'more_horiz',
          isExpense: false,
        ),
      ];
}
