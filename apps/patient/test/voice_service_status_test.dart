import 'package:flutter_test/flutter_test.dart';
import 'package:patient/services/voice_service.dart';

void main() {
  group('VoiceService status handling', () {
    test('keeps the indicator red when microphone permission is denied', () {
      expect(
        VoiceService.resolveSpeechStatus(
          speechStatus: 'notListening',
          isProcessing: false,
          isPermissionGranted: false,
          isSpeechAvailable: true,
        ),
        VoiceStatus.error,
      );
    });

    test('treats browser not-allowed errors as a microphone denial', () {
      expect(VoiceService.isPermissionDeniedError('not-allowed'), isTrue);
      expect(VoiceService.isPermissionDeniedError('Permission denied'), isTrue);
      expect(VoiceService.isPermissionDeniedError('Microphone access blocked'), isTrue);
    });

    test('switches to listening when the mic is active and permission is granted', () {
      expect(
        VoiceService.resolveSpeechStatus(
          speechStatus: 'listening',
          isProcessing: false,
          isPermissionGranted: true,
          isSpeechAvailable: true,
        ),
        VoiceStatus.listening,
      );
    });
  });
}
