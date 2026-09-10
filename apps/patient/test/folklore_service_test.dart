import 'package:flutter_test/flutter_test.dart';
import 'package:patient/services/folklore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads folklore stories from the research asset', () async {
    final stories = await FolkloreService.instance.loadStories();

    expect(stories, isNotEmpty);
    expect(stories.length, 4);
    expect(stories.any((story) => story.title.contains('KARBANG')), isFalse);
    expect(stories.every((story) => story.translations.containsKey('en')), isTrue);
    expect(stories.every((story) => story.translations.containsKey('hi')), isTrue);
    expect(
      stories.every(
        (story) => story.translations.keys.any(
          (code) => const {'mni', 'kh', 'ang', 'kar'}.contains(code),
        ),
      ),
      isTrue,
    );
    expect(stories.any((story) => story.title.contains('KHAMBA')), isTrue);
    expect(stories.first.defaultLanguageCode, 'en');
    expect(
      stories.every((story) => story.imagePath != null && story.imagePath!.isNotEmpty),
      isTrue,
    );
    expect(
      stories.every((story) => story.translations.values.every((t) => !t.story.contains('????'))),
      isTrue,
    );
    expect(
      stories.every((story) => story.defaultTranslation.moral != null && story.defaultTranslation.moral!.isNotEmpty),
      isTrue,
    );
  });
}
