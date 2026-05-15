import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/hive_boxes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<ThemeMode> {
  SettingsNotifier() : super(ThemeMode.system) {
    _load();
  }

  Box get _box => Hive.box(HiveBoxes.settings);

  void _load() {
    final stored = _box.get(SettingsKeys.themeMode, defaultValue: 0) as int;
    state = _fromInt(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put(SettingsKeys.themeMode, _toInt(mode));
    state = mode;
  }

  // ── Helpers ───────────────────────────────────────────────────

  static ThemeMode _fromInt(int value) => switch (value) {
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static int _toInt(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 1,
        ThemeMode.dark => 2,
        _ => 0,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, ThemeMode>(
  (ref) => SettingsNotifier(),
);
