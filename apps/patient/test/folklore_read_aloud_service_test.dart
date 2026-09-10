import 'package:flutter_test/flutter_test.dart';
import 'package:patient/services/folklore_read_aloud_service.dart';

void main() {
  group('FolkloreReadAloudService unit tests', () {
    test('maps language codes to BCP-47 TTS locales', () {
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('en'), 'en-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('English'), 'en-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('hi'), 'hi-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('हिन्दी'), 'hi-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('mni'), 'bn-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('Meitei / Manipuri'), 'bn-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('as'), 'bn-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('Khasi'), 'en-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('ang'), 'en-IN');
      expect(FolkloreReadAloudService.mapLanguageToTtsCode('Karbi'), 'en-IN');
    });

    test('splits English text into sentence chunks under max limit', () {
      const text =
          'Long ago in Manipur lived Khamba. He was brave and honest. His sister Khamnu cared for him.';
      final chunks =
          FolkloreReadAloudService.splitIntoChunks(text, maxChunkLength: 60);

      expect(chunks, isNotEmpty);
      expect(chunks.every((c) => c.length <= 60), isTrue);
      expect(chunks, contains('Long ago in Manipur lived Khamba.'));
    });

    test('splits Hindi text on purna viram (।)', () {
      const text = 'प्राचीन काल में मणिपुर में खम्बा रहता था। वह अत्यंत वीर था।';
      final chunks =
          FolkloreReadAloudService.splitIntoChunks(text, maxChunkLength: 100);

      expect(chunks.length, 2);
      expect(chunks[0], 'प्राचीन काल में मणिपुर में खम्बा रहता था।');
      expect(chunks[1], 'वह अत्यंत वीर था।');
    });

    test('handles empty and whitespace-only text gracefully', () {
      expect(FolkloreReadAloudService.splitIntoChunks(''), isEmpty);
      expect(FolkloreReadAloudService.splitIntoChunks('   \n  '), isEmpty);
    });

    test('splitIntoChunks returns non-empty result for valid text', () {
      expect(FolkloreReadAloudService.splitIntoChunks('Test sentence.'),
          isNotEmpty);
    });
  });
}
