import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FolkloreReadAloudService {
  FolkloreReadAloudService() : _tts = FlutterTts() {
    _init();
  }

  final FlutterTts _tts;
  bool _isSpeaking = false;

  bool get isPlaying => _isSpeaking;

  void _init() {
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
    });
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  Future<void> readAloud(
    String text,
    String language, {
    String? languageCode,
    VoidCallback? onComplete,
    void Function(String)? onError,
    void Function(bool isPlaying)? onStateChanged,
  }) async {
    final ttsLang = _mapToTtsLanguage(languageCode ?? language);

    try {
      await _tts.stop();
    } catch (_) {}

    try {
      await _tts.setLanguage(ttsLang);
    } catch (_) {
      // Fallback to English if language not available
      await _tts.setLanguage('en-US');
    }

    _isSpeaking = true;
    onStateChanged?.call(true);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onStateChanged?.call(false);
      onComplete?.call();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      onStateChanged?.call(false);
      onError?.call(msg.toString());
    });

    try {
      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      onStateChanged?.call(false);
      onError?.call(e.toString());
    }
  }

  Future<void> stop() async {
    _isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _isSpeaking = false;
    try {
      _tts.stop();
    } catch (_) {}
  }

  /// Maps language label or code to BCP-47 locale for flutter_tts.
  static String _mapToTtsLanguage(String languageOrCode) {
    final clean = languageOrCode.trim().toLowerCase();
    if (clean == 'hi' || clean.contains('hindi') || clean.contains('हिन्दी')) {
      return 'hi-IN';
    }
    if (clean == 'mni' ||
        clean.contains('meitei') ||
        clean.contains('manipuri') ||
        clean.contains('মৈতেই')) {
      return 'bn-IN'; // Closest supported; Meitei not widely supported by TTS engines
    }
    if (clean == 'as' ||
        clean.contains('assam') ||
        clean.contains('অসমীয়া')) {
      return 'bn-IN'; // Bengali fallback for Assamese
    }
    if (clean == 'en' || clean.contains('english')) {
      return 'en-IN';
    }
    return 'en-IN';
  }

  // Keep these static helpers for tests / other consumers
  static String mapLanguageToTtsCode(String languageOrCode) =>
      _mapToTtsLanguage(languageOrCode);

  static List<String> splitIntoChunks(String text, {int maxChunkLength = 160}) {
    final clean = text.trim();
    if (clean.isEmpty) return const [];

    final sentencePattern = RegExp(r'[^.!?।\n]+[.!?।\n]*');
    final matches = sentencePattern.allMatches(clean);
    final rawSentences = matches
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (rawSentences.isEmpty) {
      if (clean.isNotEmpty) return [clean];
      return const [];
    }

    final chunks = <String>[];

    for (final sentence in rawSentences) {
      if (sentence.length <= maxChunkLength) {
        chunks.add(sentence);
      } else {
        final words = sentence.split(' ');
        final buffer = StringBuffer();

        for (final word in words) {
          if (buffer.isEmpty) {
            buffer.write(word);
          } else if (buffer.length + 1 + word.length <= maxChunkLength) {
            buffer.write(' ');
            buffer.write(word);
          } else {
            chunks.add(buffer.toString());
            buffer.clear();
            buffer.write(word);
          }
        }
        if (buffer.isNotEmpty) {
          chunks.add(buffer.toString());
        }
      }
    }

    return chunks;
  }
}
