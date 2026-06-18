import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// AI-powered parser — sends voice transcript to Google Gemini (free tier)
/// and receives a structured JSON response with the math expression,
/// a readable display string, and a plain-English explanation.
class ParserService {
  late final GenerativeModel _model;

  static const _systemPrompt = '''
You are a math expression parser for a voice calculator app.
The user will speak a calculation or math word problem in natural language.

Your job is to:
1. Understand the intent — even with ambiguous phrasing, slang, or imperfect speech
2. Extract the mathematical operation
3. Return ONLY a valid JSON object — no markdown, no explanation, no backticks

JSON format (always return exactly this shape):
{
  "expression": "<evaluable math string using only digits and + - * / ^ % ( )>",
  "readable": "<clean human-readable version e.g. 250 × 18>",
  "explanation": "<one sentence plain English e.g. Multiplying 250 by 18>",
  "error": null
}

If you cannot parse the input as a calculation, return:
{
  "expression": "",
  "readable": "",
  "explanation": "",
  "error": "<brief reason why>"
}

Rules for the expression field:
- Use * for multiply, / for divide, + for add, - for subtract, ^ for power
- Percentages: "15% of 4000" → "(15/100)*4000"
- Fractions: "half of 300" → "300/2"
- No spaces in the expression string
- Always use standard operator characters only — never words

Examples:
Input: "two hundred and fifty times eighteen"
Output: {"expression":"250*18","readable":"250 × 18","explanation":"Multiplying 250 by 18","error":null}

Input: "what is fifteen percent of four thousand naira"
Output: {"expression":"(15/100)*4000","readable":"15% of ₦4,000","explanation":"Finding 15% of 4,000","error":null}

Input: "split forty five thousand between four people"
Output: {"expression":"45000/4","readable":"45,000 ÷ 4","explanation":"Dividing 45,000 equally among 4 people","error":null}

Input: "add 7.5 percent VAT to twelve thousand"
Output: {"expression":"12000+(12000*(7.5/100))","readable":"₦12,000 + 7.5% VAT","explanation":"Adding 7.5% VAT to 12,000","error":null}

Input: "what is my change from five thousand if I spent three thousand seven hundred and fifty"
Output: {"expression":"5000-3750","readable":"5,000 − 3,750","explanation":"Subtracting 3,750 from 5,000","error":null}

Input: "square root of one hundred and forty four"
Output: {"expression":"144^0.5","readable":"√144","explanation":"Square root of 144","error":null}

Input: "hello how are you"
Output: {"expression":"","readable":"","explanation":"","error":"Not a mathematical expression"}
''';

  ParserService({required String apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Free tier — fast and capable
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.1,   // Low temperature = consistent structured output
        maxOutputTokens: 256,
        responseMimeType: 'application/json', // Force JSON output
      ),
    );
  }

  /// Sends [transcript] to Gemini and returns a [ParseResult].
  /// Never throws — always returns a result (with error field set on failure).
  Future<ParseResult> parse(String transcript) async {
    if (transcript.trim().isEmpty) return ParseResult.empty();

    try {
      final response = await _model.generateContent([
        Content.text(transcript.trim()),
      ]);

      final raw = response.text?.trim() ?? '';

      if (raw.isEmpty) {
        return ParseResult.error('Gemini returned an empty response');
      }

      return _parseJson(raw);
    } on GenerativeAIException catch (e) {
      return ParseResult.error('Gemini API error: ${e.message}');
    } catch (e) {
      return ParseResult.error('Could not reach AI parser: $e');
    }
  }

  ParseResult _parseJson(String raw) {
    try {
      // Strip any accidental markdown fences
      final clean = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> json = jsonDecode(clean);

      final error = json['error'];
      if (error != null && error.toString().isNotEmpty) {
        return ParseResult.error(error.toString());
      }

      final expression = json['expression']?.toString() ?? '';
      if (expression.isEmpty) {
        return ParseResult.error('No expression could be extracted');
      }

      return ParseResult(
        expression: expression,
        readable: json['readable']?.toString() ?? expression,
        explanation: json['explanation']?.toString() ?? '',
        error: null,
      );
    } catch (_) {
      return ParseResult.error('AI returned an unexpected response format');
    }
  }

  void dispose() {
    // GenerativeModel has no explicit close — nothing to clean up
  }
}

/// The structured result returned from the AI parser.
class ParseResult {
  final String expression;   // e.g. "250*18"       — fed to CalculatorService
  final String readable;     // e.g. "250 × 18"     — shown on DisplayPanel
  final String explanation;  // e.g. "Multiplying 250 by 18" — subtitle
  final String? error;       // non-null if parsing failed

  const ParseResult({
    required this.expression,
    required this.readable,
    required this.explanation,
    required this.error,
  });

  bool get hasError => error != null && error!.isNotEmpty;
  bool get isValid => !hasError && expression.isNotEmpty;

  factory ParseResult.empty() => const ParseResult(
        expression: '',
        readable: '',
        explanation: '',
        error: null,
      );

  factory ParseResult.error(String message) => ParseResult(
        expression: '',
        readable: '',
        explanation: '',
        error: message,
      );
}