import 'package:flutter/material.dart';

/// Central color palette for the app.
/// All colors reference this file — never use raw hex values in widgets.
abstract class AppColors {
  // ── Brand / Primary ───────────────────────────────────────────
  static const primary = Color(0xFF4F6EF7); // Blue
  static const primaryLight = Color(0xFF7B93F9);
  static const primaryDark = Color(0xFF2D4ED8);

  // ── Semantic ──────────────────────────────────────────────────
  static const income = Color(0xFF2DBD7E); // Green  – inkomst
  static const expense = Color(0xFFEF5B5B); // Red    – utgift
  static const warning = Color(0xFFFFB830); // Amber  – budget warning
  static const error = Color(0xFFD93025);

  // ── Neutrals (light mode) ─────────────────────────────────────
  static const backgroundLight = Color(0xFFF6F7FB);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  static const dividerLight = Color(0xFFE8EAF0);

  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textTertiaryLight = Color(0xFF9CA3AF);

  // ── Neutrals (dark mode) ──────────────────────────────────────
  static const backgroundDark = Color(0xFF111318);
  static const surfaceDark = Color(0xFF1C1F26);
  static const cardDark = Color(0xFF242831);
  static const dividerDark = Color(0xFF2E3340);

  static const textPrimaryDark = Color(0xFFF1F3F9);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const textTertiaryDark = Color(0xFF6B7280);

  // ── Category palette ──────────────────────────────────────────
  // Used when users create custom categories
  static const categoryColors = [
    Color(0xFFEF5B5B), // röd
    Color(0xFFFF8C42), // orange
    Color(0xFFFFB830), // gul
    Color(0xFF2DBD7E), // grön
    Color(0xFF4F6EF7), // blå
    Color(0xFF9B59B6), // lila
    Color(0xFFE91E8C), // rosa
    Color(0xFF00BCD4), // cyan
    Color(0xFF607D8B), // blågrå
    Color(0xFF795548), // brun
  ];
}
