enum VoiceIntent {
  openBlinkingGame,
  openMemoryGame,
  goHome,
  pauseGame,
  resumeGame,
  tapNumber,
  unknown,
}

class VoiceCommand {
  VoiceCommand({
    required this.intent,
    required this.originalText,
    this.parameter,
    this.confidence = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final VoiceIntent intent;
  final String originalText;
  final int? parameter;
  final double confidence;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'recognizedText': originalText,
        'intent': intent.name,
        'parameter': parameter,
        'confidence': confidence,
      };
}
