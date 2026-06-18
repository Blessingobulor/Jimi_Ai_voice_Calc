import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialised = false;

  Future<bool> initialise() async {
    if (_isInitialised) return true;
    _isInitialised = await _speech.initialize(
      onError: (e) => {},
      onStatus: (s) => {},
    );

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    return _isInitialised;
  }

  bool get isAvailable => _isInitialised && _speech.isAvailable;
  bool get isListening => _speech.isListening;

  /// Start listening and stream results via [onResult].
  /// [onResult] is called continuously with partial + final results.
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_isInitialised) await initialise();
    if (!isAvailable) return;

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Speak the result aloud using TTS
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}