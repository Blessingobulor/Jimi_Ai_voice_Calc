/// Formats a raw math expression string for clean on-screen display.
/// e.g. "250*18" → "250 × 18"
/// e.g. "300/4" → "300 ÷ 4"
class ExpressionFormatter {
  static String format(String raw) {
    return raw
        .replaceAll('*', ' × ')
        .replaceAll('/', ' ÷ ')
        .replaceAll('+', ' + ')
        .replaceAll('-', ' − ')
        .replaceAll('%', '%')
        .replaceAll('  ', ' ')
        .trim();
  }

  /// Format the result — remove unnecessary trailing zeros
  static String formatResult(double value) {
    if (value == value.truncateToDouble()) {
      // Whole number
      return value.toInt().toString();
    }
    // Round to 6 decimal places, remove trailing zeros
    String str = value.toStringAsFixed(6);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }
}
