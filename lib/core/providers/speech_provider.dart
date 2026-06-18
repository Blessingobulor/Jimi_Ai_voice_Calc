import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/speech_service.dart';
import '../../models/speech_state.dart';

class SpeechNotifier extends StateNotifier<SpeechState> {
  final SpeechService _service;

  SpeechNotifier(this._service) : super(const SpeechState());

  Future<void> initialise() async {
    final ok = await _service.initialise();
    if (!ok) {
      state = state.copyWith(
        status: MicStatus.error,
        errorMessage: 'Microphone not available on this device.',
      );
    }
  }

  Future<void> startListening({
    required void Function(String transcript) onPartial,
    required void Function(String transcript) onFinal,
  }) async {
    state = state.copyWith(
      status: MicStatus.listening,
      transcript: '',
      errorMessage: null,
    );

    await _service.startListening(
      onResult: (transcript, isFinal) {
        state = state.copyWith(transcript: transcript);
        if (isFinal) {
          state = state.copyWith(status: MicStatus.processing);
          onFinal(transcript);
        } else {
          onPartial(transcript);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _service.stopListening();
    state = state.copyWith(status: MicStatus.idle);
  }

  Future<void> cancelListening() async {
    await _service.cancelListening();
    state = state.copyWith(
      status: MicStatus.idle,
      transcript: '',
    );
  }

  void resetTranscript() {
    state = state.copyWith(
      transcript: '',
      status: MicStatus.idle,
      errorMessage: null,
    );
  }

  void setError(String message) {
    state = state.copyWith(
      status: MicStatus.error,
      errorMessage: message,
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

// ── Providers ──────────────────────────────────────────────

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

final speechProvider = StateNotifierProvider<SpeechNotifier, SpeechState>((ref) {
  final service = ref.watch(speechServiceProvider);
  return SpeechNotifier(service);
});