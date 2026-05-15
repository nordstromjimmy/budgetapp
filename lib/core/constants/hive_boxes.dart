/// Hive box names used across the app.
/// Defined once here so a typo can never cause a silent mismatch
/// between the box that was opened and the box being read from.
abstract class HiveBoxes {
  static const transactions = 'transactions';
  static const categories = 'categories';
  static const budgets = 'budgets';
  static const recurringTransactions = 'recurringTransactions';

  /// Non-typed box — stores primitive settings values (String, int, bool).
  static const settings = 'settings';
}

/// Keys used inside [HiveBoxes.settings].
abstract class SettingsKeys {
  /// Stored as int: 0 = system, 1 = light, 2 = dark
  static const themeMode = 'themeMode';
}
