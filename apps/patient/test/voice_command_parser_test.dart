import 'package:flutter_test/flutter_test.dart';
import 'package:patient/models/voice_command.dart';
import 'package:patient/utils/voice_command_parser.dart';

void main() {
  group('VoiceCommandParser', () {
    test('parses open blinking game phrases', () {
      final command = VoiceCommandParser.parse('Open blinking game');
      expect(command.intent, VoiceIntent.openBlinkingGame);
      expect(command.parameter, isNull);
    });

    test('parses start blinking alias', () {
      final command = VoiceCommandParser.parse('start blinking');
      expect(command.intent, VoiceIntent.openBlinkingGame);
    });

    test('parses short open game commands', () {
      expect(VoiceCommandParser.parse('open blink').intent,
          VoiceIntent.openBlinkingGame);
      expect(VoiceCommandParser.parse('open memory').intent,
          VoiceIntent.openMemoryGame);
    });

    test('parses play memory game', () {
      final command = VoiceCommandParser.parse('play memory game');
      expect(command.intent, VoiceIntent.openMemoryGame);
    });

    test('parses go home phrases', () {
      final command = VoiceCommandParser.parse('Take me home');
      expect(command.intent, VoiceIntent.goHome);
    });

    test('parses pause and resume', () {
      expect(VoiceCommandParser.parse('pause').intent, VoiceIntent.pauseGame);
      expect(VoiceCommandParser.parse('continue the game').intent,
          VoiceIntent.resumeGame);
    });

    test('parses tap numbers from words and digits', () {
      expect(VoiceCommandParser.parse('tap 5').intent, VoiceIntent.tapNumber);
      expect(VoiceCommandParser.parse('tap five').parameter, 5);
      expect(VoiceCommandParser.parse('select number five').parameter, 5);
    });

    test('returns unknown for unrelated phrases', () {
      final command = VoiceCommandParser.parse('What is the weather today?');
      expect(command.intent, VoiceIntent.unknown);
    });
  });
}
