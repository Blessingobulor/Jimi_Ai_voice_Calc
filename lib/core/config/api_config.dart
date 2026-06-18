/// API configuration for VoiceCalc.
///
/// ⚠️  SECURITY NOTE:
/// Never commit your real API key to version control.
/// The key is loaded at runtime from the .env file via EnvService.
///
/// Get your FREE Gemini key at: https://aistudio.google.com/app/apikey
class ApiConfig {
  /// Gemini model used for AI math parsing.
  /// gemini-1.5-flash is free tier — fast and capable.
  static const String geminiModel = 'gemini-1.5-flash';

  /// Temperature for structured JSON output — keep low for consistency.
  static const double parserTemperature = 0.1;

  /// Max tokens for the parser response — 256 is enough for JSON output.
  static const int parserMaxTokens = 256;
}