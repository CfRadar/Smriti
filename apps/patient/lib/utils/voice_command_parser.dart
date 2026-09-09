import '../models/voice_command.dart';

class VoiceCommandParser {
  static const Map<String, List<String>> _gameAliases = {
    'blinking game': [
      'blinking game',
      'blink game',
      'blinking',
      'blink',
      'ब्लिंकिंग गेम',
      'ब्लिंक गेम',
      'blink game kholo',
      'blinking game kholo',
      'blink game shuru karo',
      'blinking game chalao',
    ],
    'pattern memory game': [
      'pattern memory game',
      'pattern memory',
      'memory game',
      'memory',
      'memeory',
      'memeory game',
      'मेमोरी गेम',
      'पैटर्न मेमोरी',
      'memory game kholo',
      'memory game shuru karo',
      'memory game chalao',
      'pattern memory kholo',
      'memeory kholo',
      'play memory kholo',
      'play memeory kholo',
      'memory kholo',
      'pattern memory chalao',
      'play memory',
      'play memeory',
    ],
  };

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
    'शून्य': 0,
    'एक': 1,
    'दो': 2,
    'तीन': 3,
    'चार': 4,
    'पाँच': 5,
    'पांच': 5,
    'छह': 6,
    'सात': 7,
    'आठ': 8,
    'नौ': 9,
    'दस': 10,
    'shunya': 0,
    'ek': 1,
    'do': 2,
    'teen': 3,
    'char': 4,
    'paanch': 5,
    'panch': 5,
    'cheh': 6,
    'chhe': 6,
    'saat': 7,
    'aath': 8,
    'nau': 9,
    'das': 10,
  };

  static VoiceCommand parse(String rawText, {double confidence = 0.0}) {
    final normalized = _normalize(rawText);

    if (normalized.isEmpty) {
      return VoiceCommand(
        intent: VoiceIntent.unknown,
        originalText: rawText,
        confidence: confidence,
      );
    }

    if (_matchesAny(normalized, const [
      'close',
      'close the game',
      'close this game',
      'exit',
      'exit game',
      'exit the game',
      'leave',
      'leave the game',
      'quit',
      'quit the game',
      'stop playing',
      'end game',
      'end the game',
      'cancel',
      'cancel the game',
      'i don t want to play',
      'i don t want to play this game',
      'i don t want to play anymore',
      'i don t want to continue',
      'i don t want to continue playing',
      'i want to stop playing',
      'i want to stop',
      'i want to leave',
      'i want to leave the game',
      'i am done',
      'i m done',
      'i am finished',
      'i m finished',
      'that s enough',
      'enough',
      'let s stop',
      'let s quit',
      'take me out',
      'get me out of the game',
      'गेम बंद करो',
      'गेम बंद कर दो',
      'यह गेम बंद करो',
      'गेम से बाहर निकलो',
      'बाहर निकलो',
      'गेम छोड़ो',
      'गेम छोड़ दो',
      'खेल बंद करो',
      'खेल बंद कर दो',
      'खेलना बंद करो',
      'बंद करो',
      'कैंसल करो',
      'रद्द करो',
      'मुझे नहीं खेलना',
      'मुझे यह गेम नहीं खेलना',
      'मुझे अब नहीं खेलना',
      'मुझे और नहीं खेलना',
      'मैं खेलना बंद करना चाहती हूँ',
      'मैं खेलना बंद करना चाहता हूँ',
      'मैं नहीं खेलना चाहती',
      'मैं नहीं खेलना चाहता',
      'अब बस',
      'बस करो',
      'अब नहीं खेलना',
      'अब खेलना बंद',
      'मुझे बाहर जाना है',
      'मुझे बाहर निकालो',
      'मुझे गेम से बाहर निकालो',
      'मुझे घर जाना है',
      'मुझे वापस जाना है',
      'game band karo',
      'game band kar do',
      'ye game band karo',
      'game se bahar niklo',
      'bahar niklo',
      'game chhodo',
      'game chhod do',
      'khel band karo',
      'khel band kar do',
      'khelna band karo',
      'band karo',
      'cancel karo',
      'radd karo',
      'mujhe nahi khelna',
      'mujhe ye game nahi khelna',
      'mujhe ab nahi khelna',
      'mujhe aur nahi khelna',
      'main khelna band karna chahti hoon',
      'main khelna band karna chahta hoon',
      'main nahi khelna chahti',
      'main nahi khelna chahta',
      'ab bas',
      'bas karo',
      'ab nahi khelna',
      'mujhe bahar jana hai',
      'mujhe bahar nikalo',
      'mujhe game se bahar nikalo',
      'mujhe ghar jana hai',
      'mujhe wapas jana hai',
    ])) {
      return _command(VoiceIntent.exitGame, rawText, confidence);
    }

    if (_matchesNavigation(normalized, 'home', 'game hub', 'main menu') ||
        _matchesAny(normalized, const [
          'go home',
          'go to home',
          'go to the home',
          'go to main menu',
          'go to the main menu',
          'home menu',
          'main menu',
          'back to home',
          'return home',
          'return to home',
          'main screen',
          'home screen',
          'home par jao',
          'home par le jao',
          'home par chalo',
          'home le jao',
          'home jao',
          'ghar wapas jao',
          'home me le jao',
          'main menu par jao',
          'home menu par jao',
          'घर वापस जाओ',
          'होम पर जाओ',
          'होम पर ले जाओ',
          'वापस जाओ',
        ])) {
      return VoiceCommand(
        intent: VoiceIntent.goHome,
        originalText: rawText,
        confidence: confidence,
      );
    }

    final gameName = _extractGameName(normalized);
    if (gameName != null) {
      final legacyIntent = _legacyGameIntent(normalized, gameName);
      return _command(legacyIntent ?? VoiceIntent.openGame, rawText, confidence,
          gameName: gameName);
    }

    if (_matchesCommand(normalized, patterns: [
          'pause',
          'pause the game',
          'stop the game',
          'stop',
          'रुको',
          'रुक जाओ',
          'गेम रोक दो',
          'खेल रोक दो',
          'ruk jao',
          'game rok do',
          'khel rok do',
        ]) ||
        normalized.startsWith('pause ') ||
        normalized.startsWith('stop ')) {
      return VoiceCommand(
        intent: VoiceIntent.pauseGame,
        originalText: rawText,
        confidence: confidence,
      );
    }

    if (_matchesCommand(normalized, patterns: [
          'resume',
          'resume the game',
          'continue',
          'continue the game',
          'keep going',
          'जारी रखो',
          'फिर से शुरू करो',
          'दोबारा शुरू करो',
          'जारी रखिए',
          'जारी रखो',
          'jari rakho',
          'phir se shuru karo',
          'dobara shuru karo',
        ]) ||
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

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'''[.,!?;:"'“”‘’]+'''), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static VoiceCommand _command(
    VoiceIntent intent,
    String rawText,
    double confidence, {
    String? gameName,
    int? parameter,
  }) =>
      VoiceCommand(
        intent: intent,
        originalText: rawText,
        confidence: confidence,
        gameName: gameName,
        parameter: parameter,
      );

  static bool _matchesAny(String normalized, List<String> patterns) {
    return patterns
        .any((pattern) => _matchesCommand(normalized, patterns: [pattern]));
  }

  static String? _extractGameName(String normalized) {
    const openWords = [
      'open',
      'start',
      'play',
      'let s play',
      'i want to play',
      'take me to',
      'go to',
      'खोलो',
      'शुरू करो',
      'चलाओ',
      'खेलना है',
      'पर चलो',
      'खेलने चलो',
    ];
    for (final entry in _gameAliases.entries) {
      for (final alias in entry.value) {
        final hasGame = normalized == alias || normalized.contains(alias);
        if (!hasGame) continue;
        final hasOpenWord = openWords.any((word) => normalized.contains(word));
        if (hasOpenWord || normalized == alias) return entry.key;
      }
    }
    return null;
  }

  static VoiceIntent? _legacyGameIntent(String normalized, String gameName) {
    if (!RegExp(r'^[a-z0-9\s]+$').hasMatch(normalized)) return null;
    return gameName == 'blinking game'
        ? VoiceIntent.openBlinkingGame
        : VoiceIntent.openMemoryGame;
  }

  static bool _matchesNavigation(
      String normalized, String first, String second, String third) {
    final targets = [first, second, third];

    return targets.any((target) {
      final direct = target == 'main menu' ? 'main menu' : target;
      return normalized == target ||
          normalized == direct ||
          normalized.startsWith('go $target') ||
          normalized.startsWith('go to $target') ||
          normalized.startsWith('go to the $target') ||
          normalized.startsWith('take me home') ||
          normalized.startsWith('take me to home') ||
          normalized.startsWith('take me to the home') ||
          normalized.startsWith('take me to $target') ||
          normalized.startsWith('take me $target') ||
          normalized.startsWith('return to $target') ||
          normalized.startsWith('return to the $target') ||
          normalized.startsWith('back to $target') ||
          normalized.startsWith('back to the $target') ||
          normalized.startsWith('home par') ||
          normalized.startsWith('home le') ||
          normalized.startsWith('home jao') ||
          normalized.startsWith('ghar par') ||
          normalized.startsWith('ghar wapas') ||
          normalized.contains('home par') ||
          normalized.contains('home le') ||
          normalized.contains('ghar wapas');
    });
  }

  static bool _matchesCommand(String normalized,
      {required List<String> patterns}) {
    for (final pattern in patterns) {
      final candidate = pattern.trim();
      if (normalized == candidate ||
          normalized.startsWith('$candidate ') ||
          normalized.contains(' $candidate ') ||
          normalized.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  static int? _extractTapNumber(String normalized) {
    final englishMatch = RegExp(
      r'\b(?:tap|press|select|pick|choose|hit|activate)\s+(?:number\s+)?([a-z0-9]+)\b',
    ).firstMatch(normalized);
    final hindiMatch = RegExp(
      r'(?:नंबर\s*)?(\d+|[०-९]+|[एक-दोतीनचारपाँचपांचछहसातआठनौदस]+)\s*(?:दबाओ|चुनो)',
    ).firstMatch(normalized);
    final romanHindiMatch = RegExp(
      r'(?:number\s*)?(\d+|shunya|ek|do|teen|char|paanch|panch|cheh|chhe|saat|aath|nau|das)\s*(?:dabao|chuno)',
    ).firstMatch(normalized);
    final match = englishMatch ?? hindiMatch ?? romanHindiMatch;
    if (match == null) return null;

    final value = match.group(1) ?? '';
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) {
      return parsedInt;
    }

    if (value.runes.every((rune) => rune >= 0x0966 && rune <= 0x096f)) {
      return int.tryParse(value.runes.map((rune) => rune - 0x0966).join());
    }

    final numberWord = _numberWords[value];
    if (numberWord != null) {
      return numberWord;
    }

    return null;
  }
}
