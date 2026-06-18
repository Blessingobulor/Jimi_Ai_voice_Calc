import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/parser_service.dart';
import '../services/calculator_service.dart';
import '../services/speech_service.dart';
import '../services/env_service.dart';
import '../../utils/expression_formatter.dart';
import 'speech_provider.dart' show speechServiceProvider;

class CalculatorState {
  final String rawExpression;     // e.g. "250*18"
  final String displayExpression; // e.g. "250 × 18"  (from Claude's "readable")
  final String explanation;       // e.g. "Multiplying 250 by 18" (from Claude)
  final String result;
  final bool hasError;
  final bool isParsingWithAI;     // true while waiting for Claude response
  final String? errorMessage;

  const CalculatorState({
    this.rawExpression = '',
    this.displayExpression = '',
    this.explanation = '',
    this.result = '',
    this.hasError = false,
    this.isParsingWithAI = false,
    this.errorMessage,
  });

  CalculatorState copyWith({
    String? rawExpression,
    String? displayExpression,
    String? explanation,
    String? result,
    bool? hasError,
    bool? isParsingWithAI,
    String? errorMessage,
  }) {
    return CalculatorState(
      rawExpression: rawExpression ?? this.rawExpression,
      displayExpression: displayExpression ?? this.displayExpression,
      explanation: explanation ?? this.explanation,
      result: result ?? this.result,
      hasError: hasError ?? this.hasError,
      isParsingWithAI: isParsingWithAI ?? this.isParsingWithAI,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  final ParserService _parser;
  final CalculatorService _calculator;
  final SpeechService _speech;

  CalculatorNotifier(this._parser, this._calculator, this._speech)
      : super(const CalculatorState());

  /// Called with the final voice transcript.
  /// Sends it to Claude AI for parsing, then evaluates the result.
  Future<void> processTranscript(String transcript) async {
    if (transcript.trim().isEmpty) return;

    // Show AI parsing indicator
    state = state.copyWith(
      isParsingWithAI: true,
      hasError: false,
      errorMessage: null,
      displayExpression: transcript,
      explanation: 'Understanding your calculation...',
    );

    // ── AI PARSING LAYER ──────────────────────────────────
    final parseResult = await _parser.parse(transcript);
    // ──────────────────────────────────────────────────────

    state = state.copyWith(isParsingWithAI: false);

    if (parseResult.hasError) {
      state = state.copyWith(
        hasError: true,
        errorMessage: parseResult.error,
        displayExpression: transcript,
        explanation: '',
        result: '',
      );
      return;
    }

    if (!parseResult.isValid) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Could not extract a math expression',
        result: '',
      );
      return;
    }

    // Evaluate the expression Claude produced
    final value = _calculator.evaluate(parseResult.expression);

    if (value == null) {
      state = state.copyWith(
        rawExpression: parseResult.expression,
        displayExpression: parseResult.readable,
        explanation: parseResult.explanation,
        hasError: true,
        errorMessage: 'Expression could not be evaluated',
        result: '',
      );
      return;
    }

    final formatted = ExpressionFormatter.formatResult(value);

    state = state.copyWith(
      rawExpression: parseResult.expression,
      displayExpression: parseResult.readable,
      explanation: parseResult.explanation,
      result: formatted,
      hasError: false,
      errorMessage: null,
    );

    // Speak result aloud — completes the voice-first loop
    await _speech.speak('${parseResult.explanation}. The answer is $formatted');
  }

  /// Manual keyboard input — bypasses AI parser, evaluates directly
  void processManual(String expression) {
    final value = _calculator.evaluate(expression);

    if (value == null) {
      state = state.copyWith(
        rawExpression: expression,
        displayExpression: ExpressionFormatter.format(expression),
        explanation: '',
        hasError: true,
        errorMessage: 'Invalid expression',
        result: '',
      );
      return;
    }

    state = state.copyWith(
      rawExpression: expression,
      displayExpression: ExpressionFormatter.format(expression),
      explanation: 'Manual calculation',
      result: ExpressionFormatter.formatResult(value),
      hasError: false,
      errorMessage: null,
    );
  }

  void clear() {
    state = const CalculatorState();
  }
}

// ── Providers ──────────────────────────────────────────────

final parserServiceProvider = Provider<ParserService>((ref) {
  return ParserService(apiKey: EnvService.geminiApiKey);
});

final calculatorServiceProvider = Provider<CalculatorService>((ref) {
  return CalculatorService();
});

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier(
    ref.watch(parserServiceProvider),
    ref.watch(calculatorServiceProvider),
    ref.watch(speechServiceProvider),
  );
});