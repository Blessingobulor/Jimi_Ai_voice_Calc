enum MicStatus { idle, listening, processing, error }

class SpeechState {
  final MicStatus status;
  final String transcript;
  final String? errorMessage;

  const SpeechState({
    this.status = MicStatus.idle,
    this.transcript = '',
    this.errorMessage,
  });

  bool get isListening => status == MicStatus.listening;
  bool get isProcessing => status == MicStatus.processing;
  bool get hasError => status == MicStatus.error;
  bool get isIdle => status == MicStatus.idle;

  SpeechState copyWith({
    MicStatus? status,
    String? transcript,
    String? errorMessage,
  }) {
    return SpeechState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}