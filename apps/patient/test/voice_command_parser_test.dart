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

    test('parses generic and multilingual game opening commands', () {
      expect(VoiceCommandParser.parse('Open blinking game').gameName,
          'blinking game');
      expect(VoiceCommandParser.parse('मेमोरी गेम खोलो').intent,
          VoiceIntent.openGame);
      expect(VoiceCommandParser.parse('প্যাটাৰ্ণ মেমৰি আৰম্ভ কৰা').intent,
          VoiceIntent.openGame);
    });

    test('parses multilingual exit commands', () {
      for (final phrase in [
        'close the game',
        'exit',
        'stop playing',
        "I don't want to play anymore",
        'गेम बंद करो',
        'मुझे नहीं खेलना',
        'खेलना बंद करो',
        'খেলটো বন্ধ কৰা',
        'মই আৰু খেলিব নিবিচাৰোঁ',
      ]) {
        expect(VoiceCommandParser.parse(phrase).intent, VoiceIntent.exitGame,
            reason: phrase);
      }
    });

    test('keeps pause distinct from exit', () {
      expect(VoiceCommandParser.parse('pause').intent, VoiceIntent.pauseGame);
      expect(VoiceCommandParser.parse('stop').intent, VoiceIntent.pauseGame);
    });

    test('parses Hindi number tap commands', () {
      expect(VoiceCommandParser.parse('5 दबाओ').parameter, 5);
      expect(VoiceCommandParser.parse('पाँच दबाओ').parameter, 5);
      expect(VoiceCommandParser.parse('नंबर 5 दबाओ').parameter, 5);
      expect(VoiceCommandParser.parse('paanch dabao').parameter, 5);
      expect(VoiceCommandParser.parse('number 5 dabao').parameter, 5);
    });

    test('parses Roman Hindi game and control commands', () {
      expect(VoiceCommandParser.parse('memory game kholo').gameName,
          'pattern memory game');
      expect(VoiceCommandParser.parse('mujhe nahi khelna').intent,
          VoiceIntent.exitGame);
      expect(VoiceCommandParser.parse('game band karo').intent,
          VoiceIntent.exitGame);
      expect(VoiceCommandParser.parse('game rok do').intent,
          VoiceIntent.pauseGame);
      expect(VoiceCommandParser.parse('jari rakho').intent,
          VoiceIntent.resumeGame);
    });

    test('returns unknown for unrelated phrases', () {
      final command = VoiceCommandParser.parse('What is the weather today?');
      expect(command.intent, VoiceIntent.unknown);
    });
  });
}
