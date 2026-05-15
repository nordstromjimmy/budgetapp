import 'package:intl/intl.dart';

/// Formats monetary values according to Swedish conventions.
///
/// Examples:
///   formatAmount(1234.5)   → "1 234,50 kr"
///   formatAmount(0)        → "0,00 kr"
///   formatCompact(12345)   → "12 345 kr"
///   formatSigned(500, isExpense: true)  → "-500,00 kr"
///   formatSigned(500, isExpense: false) → "+500,00 kr"
abstract class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'sv_SE',
    symbol: 'kr',
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.currency(
    locale: 'sv_SE',
    symbol: 'kr',
    decimalDigits: 0,
  );

  /// Full format with decimals: "1 234,50 kr"
  static String formatAmount(double amount) {
    return _formatter.format(amount.abs());
  }

  /// No decimals, for compact display: "1 234 kr"
  static String formatCompact(double amount) {
    return _compactFormatter.format(amount.abs());
  }

  /// With +/- sign prefix: "+1 234,50 kr" or "-1 234,50 kr"
  static String formatSigned(double amount, {required bool isExpense}) {
    final prefix =
        isExpense ? '−' : '+'; // uses minus sign (U+2212), not hyphen
    return '$prefix${_formatter.format(amount.abs())}';
  }

  /// Parses a user-typed string into a double.
  /// Handles both "," and "." as decimal separators.
  /// Returns null if the input cannot be parsed.
  static double? tryParse(String input) {
    if (input.trim().isEmpty) return null;
    // Normalise: remove spaces, swap comma for dot
    final normalised = input
        .replaceAll(' ', '')
        .replaceAll('\u00a0', '') // non-breaking space
        .replaceAll(',', '.');
    return double.tryParse(normalised);
  }
}
