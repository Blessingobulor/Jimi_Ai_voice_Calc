import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads environment variables from the .env file.
class EnvService {
  static String get groqApiKey {
    final key = dotenv.env['GROQ_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw Exception(
        'GROQ_API_KEY is not set in your .env file.\n'
      );
    }
    return key;
  }
}