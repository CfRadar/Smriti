// test/picture_recognition_game_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/games/blink_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameItem Catalog & Cultural Asset Tests', () {
    test('Catalog contains exactly 35 authentic North East items across 4 categories', () {
      expect(GameItem.catalog.length, 35);

      final animals = GameItem.catalog
          .where((item) => item.category == CulturalCategory.animals)
          .toList();
      final clothing = GameItem.catalog
          .where((item) => item.category == CulturalCategory.clothing)
          .toList();
      final food = GameItem.catalog
          .where((item) => item.category == CulturalCategory.food)
          .toList();
      final items = GameItem.catalog
          .where((item) => item.category == CulturalCategory.items)
          .toList();

      expect(animals.length, 8);
      expect(clothing.length, 8);
      expect(food.length, 10);
      expect(items.length, 9);

      // Verify no duplicate IDs
      final idSet = GameItem.catalog.map((e) => e.id).toSet();
      expect(idSet.length, 35);

      // Verify all items have non-empty regional origin and asset path
      for (final item in GameItem.catalog) {
        expect(item.name.isNotEmpty, isTrue);
        expect(item.regionalName.isNotEmpty, isTrue);
        expect(item.region.isNotEmpty, isTrue);
        expect(item.assetPath.startsWith('assets/images/'), isTrue);
      }
    });
  });

  group('AdaptiveDifficultyConfig Tests', () {
    test('Config correctly adapts target counts and base time allowances', () {
      // Level 1-3: 1 target, 8.0s per target
      final l1 = AdaptiveDifficultyConfig.getForLevel(1);
      expect(l1.targetCount, 1);
      expect(l1.timeAllowanceSecondsPerTarget, 8.0);
      expect(l1.totalAllowedSeconds, 8.0);

      final l3 = AdaptiveDifficultyConfig.getForLevel(3);
      expect(l3.targetCount, 1);

      // Level 4-7: 2 targets, 6.0s per target
      final l4 = AdaptiveDifficultyConfig.getForLevel(4);
      expect(l4.targetCount, 2);
      expect(l4.timeAllowanceSecondsPerTarget, 6.0);
      expect(l4.totalAllowedSeconds, 12.0);

      final l7 = AdaptiveDifficultyConfig.getForLevel(7);
      expect(l7.targetCount, 2);

      // Level 8-10: 3 targets, 4.5s per target
      final l8 = AdaptiveDifficultyConfig.getForLevel(8);
      expect(l8.targetCount, 3);
      expect(l8.timeAllowanceSecondsPerTarget, 4.5);
      expect(l8.totalAllowedSeconds, 13.5);

      // Level 11+: 3 targets, 3.5s per target
      final l11 = AdaptiveDifficultyConfig.getForLevel(11);
      expect(l11.targetCount, 3);
      expect(l11.timeAllowanceSecondsPerTarget, 3.5);
      expect(l11.totalAllowedSeconds, 10.5);
    });

    test('Clamps level gracefully between 1 and 15', () {
      final clampedLow = AdaptiveDifficultyConfig.getForLevel(-10);
      expect(clampedLow.level, 1);

      final clampedHigh = AdaptiveDifficultyConfig.getForLevel(100);
      expect(clampedHigh.level, 15);
    });
  });

  group('PictureRecognitionGameScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'smriti_picture_game_level': 2,
        'smriti_picture_game_high_score': 850,
        'smriti_picture_game_best_streak': 4,
      });
    });

    testWidgets('First displays target to be found, then transitions to guessing grid',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PictureRecognitionGameScreen(
            sessionId: 'test_recognition_session',
            totalRounds: 6,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Title & Stats Header
      expect(find.text('Picture Recognition'), findsOneWidget);
      expect(find.textContaining('Round 1 / 6'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);

      // Step 1: Target Display phase is active first
      expect(find.text('Find this Item'), findsOneWidget);
      expect(find.text("I'm Ready!"), findsOneWidget);

      // Tap "I'm Ready!" to transition to Step 2: Guessing Grid
      await tester.tap(find.text("I'm Ready!"));
      await tester.pumpAndSettle();

      // Step 2: Guessing phase is active, instruction banner is removed
      expect(find.text("I'm Ready!"), findsNothing);
      expect(find.byKey(const ValueKey('InteractiveGridPhase')), findsOneWidget);

      // Verify 3x3 Grid has 9 cards
      final gridTileCards = find.descendant(
        of: find.byKey(const ValueKey('InteractiveGridPhase')),
        matching: find.byType(InkWell),
      );
      expect(gridTileCards, findsNWidgets(9));
    });

    testWidgets('Tapping Level Badge opens Difficulty Sheet and allows selection',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PictureRecognitionGameScreen(
            sessionId: 'test_recognition_session',
            totalRounds: 6,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Level 2 badge
      await tester.tap(find.text('Level 2'));
      await tester.pumpAndSettle();

      // Difficulty sheet title
      expect(find.text('Select Difficulty Level'), findsOneWidget);
      expect(find.textContaining('Level 1 (1 Target)'), findsOneWidget);
      expect(find.textContaining('Level 4 (2 Targets)'), findsOneWidget);

      // Select Level 4
      await tester.tap(find.textContaining('Level 4 (2 Targets)'));
      await tester.pumpAndSettle();

      // Level updated in UI
      expect(find.text('Level 4'), findsOneWidget);

      // In Step 1 for Level 4 (dual targets), prompt displays 'Find Both Items'
      expect(find.text('Find Both Items'), findsOneWidget);

      // Preference persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('smriti_picture_game_level'), 4);
    });

    testWidgets('Legacy BlinkGameScreen backward compatibility works seamlessly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BlinkGameScreen(
            sessionId: 'legacy_blink_test',
            totalTrials: 5,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render PictureRecognitionGameScreen seamlessly
      expect(find.byType(PictureRecognitionGameScreen), findsOneWidget);
      expect(find.text('Picture Recognition'), findsOneWidget);
    });

    testWidgets('Toggling sound off mutes sound button and disables click audio playback',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const SizedBox(),
          },
          home: const PictureRecognitionGameScreen(
            sessionId: 'test_picture_sound_session',
            totalRounds: 3,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially sound is enabled with volume up icon
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.volume_off_rounded), findsNothing);

      // Tap sound toggle button to mute
      await tester.tap(find.bySemanticsLabel('Toggle Sound'));
      await tester.pumpAndSettle();

      // Sound should now be muted with volume off icon
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);

      // In Step 1, tap "I'm Ready!" to move to interactive guessing grid
      expect(find.text("I'm Ready!"), findsOneWidget);
      await tester.tap(find.text("I'm Ready!"));
      await tester.pumpAndSettle();

      // Tapping an option card when muted runs cleanly without sound
      final gridTileCards = find.descendant(
        of: find.byKey(const ValueKey('InteractiveGridPhase')),
        matching: find.byType(InkWell),
      );
      expect(gridTileCards, findsWidgets);
      await tester.tap(gridTileCards.first);
      await tester.pump(const Duration(milliseconds: 1500));

      // Remains muted
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });
  });
}
