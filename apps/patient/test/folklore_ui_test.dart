import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/models/folklore_story.dart';
import 'package:patient/screens/folklore_list_screen.dart';
import 'package:patient/screens/folklore_reader_screen.dart';
import 'package:patient/widgets/folklore_theme.dart';

void main() {
  const sampleStory = FolkloreStory(
    id: 'khamba-thoibi',
    title: 'KHAMBA & THOIBI',
    subtitle: 'The Legendary Love Story of Manipur',
    region: 'Manipur',
    translations: {
      'en': FolkloreTranslation(
        languageCode: 'en',
        languageLabel: 'English',
        title: 'KHAMBA & THOIBI',
        story: 'Long ago in ancient Moirang, lived a brave youth named Khamba.\n\nHe met Princess Thoibi by the lake.',
        moral: 'True love and virtue transcend all hardships.',
      ),
      'hi': FolkloreTranslation(
        languageCode: 'hi',
        languageLabel: 'हिन्दी',
        title: 'खम्बा और थोइबी',
        story: 'प्राचीन काल में मणिपुर में खम्बा नाम का एक वीर युवक रहता था।',
        moral: 'सच्चा प्रेम और सत्यनिष्ठा सभी बाधाओं को पार कर लेती है।',
      ),
    },
  );

  group('FolkloreStoryTheme unit tests', () {
    test('correctly detects themes for each folklore story with minimalist canvas', () {
      final khambaTheme = FolkloreStoryTheme.forKey('KHAMBA & THOIBI');
      expect(khambaTheme.storyKey, 'khamba');
      expect(khambaTheme.particleType, FolkloreParticleType.lotusPetals);
      expect(FolkloreStoryTheme.canvasColor, const Color(0xFFF6F1E7));

      final thlenTheme = FolkloreStoryTheme.forKey('U THLEN');
      expect(thlenTheme.storyKey, 'thlen');
      expect(thlenTheme.particleType, FolkloreParticleType.mountainMist);

      final hunchibiliTheme = FolkloreStoryTheme.forKey('HUNCHIBILI');
      expect(hunchibiliTheme.storyKey, 'hunchibili');
      expect(hunchibiliTheme.particleType, FolkloreParticleType.goldenMotes);

      final orphanTheme = FolkloreStoryTheme.forKey('THE ORPHAN AND THE GIANT');
      expect(orphanTheme.storyKey, 'orphan');
      expect(orphanTheme.particleType, FolkloreParticleType.starlightEmbers);
    });
  });

  group('FolkloreReaderScreen Widget tests', () {
    testWidgets('renders story reader with clean book typography and no overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FolkloreReaderScreen(story: sampleStory),
        ),
      );

      // Verify header and drop cap text
      expect(find.text('KHAMBA & THOIBI'), findsWidgets);
      expect(find.text('Manipur'), findsWidgets);
      expect(find.text('MORAL OF THE TALE'), findsOneWidget);
      expect(find.text('True love and virtue transcend all hardships.'), findsOneWidget);

      // Verify floating audio bar
      expect(find.text('Read Aloud Story'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('font size modal opens and adjusts text size', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FolkloreReaderScreen(story: sampleStory),
        ),
      );

      // Tap font size button
      final prefButton = find.byIcon(Icons.format_size_rounded);
      expect(prefButton, findsOneWidget);
      await tester.tap(prefButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Check modal content
      expect(find.text('Reading Text Size'), findsOneWidget);

      // Tap increase font size
      final increaseBtn = find.byIcon(Icons.text_increase_rounded);
      expect(increaseBtn, findsOneWidget);
      await tester.tap(increaseBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('language popup button opens menu and switches translation', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FolkloreReaderScreen(story: sampleStory),
        ),
      );

      // Tap PopupMenuButton
      final popupBtn = find.byType(PopupMenuButton<String>);
      expect(popupBtn, findsOneWidget);
      await tester.tap(popupBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select Hindi
      final hindiItem = find.text('हिन्दी');
      expect(hindiItem, findsOneWidget);
      await tester.tap(hindiItem);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('खम्बा और थोइबी'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('FolkloreListScreen Widget tests', () {
    testWidgets('renders minimalist anthology header, tabs and ambient background', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FolkloreListScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));

      // Verify Header
      expect(find.text('Folklore'), findsOneWidget);
      expect(find.text('Tales & legends of Northeast India'), findsOneWidget);

      // Verify Ambient background is present
      expect(find.byType(StoryAmbientBackground), findsOneWidget);

      // No exceptions/overflows
      expect(tester.takeException(), isNull);
    });
  });
}
