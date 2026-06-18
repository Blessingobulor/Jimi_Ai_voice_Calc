/// Converts spoken number words into numeric digit strings.
/// e.g. "two hundred and fifty" → "250"
/// e.g. "fifteen" → "15"
class WordToNumber {
  static const _ones = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
    'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
    'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
    'eighteen': 18, 'nineteen': 19,
  };

  static const _tens = {
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
  };

  static const _multipliers = {
    'hundred': 100,
    'thousand': 1000,
    'million': 1000000,
  };

  /// Try to parse a sequence of words as a number.
  /// Returns null if no number found.
  static int? parseWords(List<String> words) {
    int result = 0;
    int current = 0;

    for (final word in words) {
      final lower = word.toLowerCase().replaceAll(',', '');

      if (_ones.containsKey(lower)) {
        current += _ones[lower]!;
      } else if (_tens.containsKey(lower)) {
        current += _tens[lower]!;
      } else if (lower == 'hundred') {
        current *= 100;
      } else if (lower == 'thousand') {
        result += current * 1000;
        current = 0;
      } else if (lower == 'million') {
        result += current * 1000000;
        current = 0;
      } else if (lower == 'and') {
        continue;
      } else {
        // Not a number word
        return null;
      }
    }

    return result + current;
  }

  /// Convert a single word to its numeric value if it is a number word.
  static int? wordToInt(String word) {
    final lower = word.toLowerCase();
    if (_ones.containsKey(lower)) return _ones[lower];
    if (_tens.containsKey(lower)) return _tens[lower];
    if (_multipliers.containsKey(lower)) return _multipliers[lower];
    return null;
  }
}