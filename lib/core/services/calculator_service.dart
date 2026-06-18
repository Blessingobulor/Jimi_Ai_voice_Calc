import 'package:math_expressions/math_expressions.dart';

class CalculatorService {
  final Parser _parser = Parser();
  final ContextModel _context = ContextModel();

  /// Evaluates a math expression string and returns the result as a double.
  /// Returns null if the expression is invalid.
  double? evaluate(String expression) {
    if (expression.trim().isEmpty) return null;

    try {
      // Sanitise: replace ^ with pow notation math_expressions understands
      String sanitised = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .trim();

      final exp = _parser.parse(sanitised);
      final result = exp.evaluate(EvaluationType.REAL, _context) as double;

      if (result.isNaN || result.isInfinite) return null;
      return result;
    } catch (_) {
      return null;
    }
  }
}