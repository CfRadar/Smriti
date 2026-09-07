import '../models/voice_command.dart';

class VoiceCommandParser {
  static final Map<String, int> _numberWords = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
  };

  static VoiceCommand parse(String rawText, {double confidence = 0.0}) {
    final normalized = rawText
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return VoiceCommand(
        intent: VoiceIntent.unknown,
        originalText: rawText,
        confidence: confidence,
      );
    }

    if (_matchesNavigation(normalized, 'home', 'game hub', 'main menu')) {
      return VoiceCommand(
        intent: VoiceIntent.goHome,
        originalText: rawText,
        confidence: confidence,
      );
    }

    if (_matchesCommand(
      normalized,
      patterns: [
        'open blinking game',
        'open blink game',
        'open blinking',
        'open blink',
        'start blinking game',
        'start blink game',
        'start blinking',
        'start blink',
        'play blinking',
        'play blink',
        'blinking game',
        'blink game',
      ],
    )) {
      return VoiceCommand(
        intent: VoiceIntent.openBlinkingGame,
        originalText: rawText,
        confidence: confidence,
      );
    }

    if (_matchesCommand(
      normalized,
      patterns: [
        'open memory game',
        'open memory',
        'open pattern memory',
        'start memory game',
        'start pattern memory',
        'play memory game',
        'play memory',
        'pattern memory',
      ],
    )) {
      return VoiceCommand(
        intent: VoiceIntent.openMemoryGame,
        originalText: rawText,
        confidence: confidence,
      );
    }

    if (_matchesCommand(normalized, patterns: ['pause', 'pause the game', 'stop the game', 'stop']) ||
        normalized.startsWith('pause ') ||
        normalized.startsWith('stop ')) {
      return VoiceCommand(
        intent: VoiceIntent.pauseGame,
        originalText: rawText,
        confidence: confidence,
      );
    }

    if (_matchesCommand(normalized, patterns: ['resume', 'resume the game', 'continue', 'continue the game', 'keep going']) ||
        normalized.startsWith('resume ') ||
        normalized.startsWith('continue ')) {
      return VoiceCommand(
        intent: VoiceIntent.resumeGame,
        originalText: rawText,
        confidence: confidence,
      );
    }

    final tapNumber = _extractTapNumber(normalized);
    if (tapNumber != null) {
      return VoiceCommand(
        intent: VoiceIntent.tapNumber,
        originalText: rawText,
        parameter: tapNumber,
        confidence: confidence,
      );
    }

    return VoiceCommand(
      intent: VoiceIntent.unknown,
      originalText: rawText,
      confidence: confidence,
    );
  }

  static bool _matchesNavigation(String normalized, String first, String second, String third) {
    return normalized == first ||
        normalized == second ||
        normalized == third ||
        normalized.startsWith('go $first') ||
        normalized.startsWith('take me home') ||
        normalized.startsWith('take me to home') ||
        normalized.startsWith('go to home') ||
        normalized.startsWith('go to the home') ||
        normalized.startsWith('take me to the home');
  }

  static bool _matchesCommand(String normalized, {required List<String> patterns}) {
    for (final pattern in patterns) {
      final candidate = pattern.trim();
      if (normalized == candidate || normalized.startsWith('$candidate ') || normalized.contains(' $candidate ') || normalized.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  static int? _extractTapNumber(String normalized) {
    final hasTapWord = RegExp(r'\b(?:tap|press|select|pick|choose|hit|activate)\b').hasMatch(normalized);
    if (!hasTapWord) {
      return null;
    }

    final match = RegExp(
      r'\b(?:tap|press|select|pick|choose|hit|activate)\s+(?:number\s+)?([a-z0-9]+)\b',
    ).firstMatch(normalized);

    if (match == null) {
      return null;
    }

    final value = match.group(1) ?? '';
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) {
      return parsedInt;
    }

    final numberWord = _numberWords[value];
    if (numberWord != null) {
      return numberWord;
    }

    return null;
  }
}
