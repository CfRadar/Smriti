// test/pattern_memory_game_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/games/pattern_memory_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PatternDifficultyConfig Tests', () {
    test('Config has exactly 10 levels with progressing difficulty', () {
      expect(PatternDifficultyConfig.levels.length, 10);

      // Verify Level 1
      final lvl1 = PatternDifficultyConfig.getForLevel(1);
      expect(lvl1.level, 1);
      expect(lvl1.gridSize, 3);
      expect(lvl1.totalTiles, 9);
      expect(lvl1.patternCount, 3);
      expect(lvl1.displayDurationMs, 3600);

      // Verify Level 4 (transition to 4x4)
      final lvl4 = PatternDifficultyConfig.getForLevel(4);
      expect(lvl4.level, 4);
      expect(lvl4.gridSize, 4);
      expect(lvl4.totalTiles, 16);
      expect(lvl4.patternCount, 4);

      // Verify Level 8 (transition to 5x5)
      final lvl8 = PatternDifficultyConfig.getForLevel(8);
      expect(lvl8.level, 8);
      expect(lvl8.gridSize, 5);
      expect(lvl8.totalTiles, 25);
      expect(lvl8.patternCount, 6);

      // Verify Level 10
      final lvl10 = PatternDifficultyConfig.getForLevel(10);
      expect(lvl10.level, 10);
      expect(lvl10.gridSize, 5);
      expect(lvl10.patternCount, 8);
      expect(lvl10.displayDurationMs, 2000);
    });

    test('Clamps level gracefully between 1 and 10', () {
      final clampedLow = PatternDifficultyConfig.getForLevel(-5);
      expect(clampedLow.level, 1);

      final clampedHigh = PatternDifficultyConfig.getForLevel(42);
      expect(clampedHigh.level, 10);
    });
  });

  group('PatternMemoryGameScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'smriti_pattern_memory_level': 3,
        'smriti_pattern_memory_best_streak': 5,
      });
    });

    testWidgets('Loads saved level from SharedPreferences and renders UI',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatternMemoryGameScreen(
            sessionId: 'test_session',
            totalTrials: 5,
          ),
        ),
      );

      // Allow preferences to load and initial frame to render
      await tester.pumpAndSettle();

      // Should display Pattern Memory title
      expect(find.text('Pattern Memory'), findsOneWidget);

      // Should find trial header
      expect(find.textContaining('Trial 1 / 5'), findsOneWidget);

      // Should reflect saved Level 3
      expect(find.text('Level 3'), findsOneWidget);

      // Should show the countdown screen or initial state
      expect(find.byType(PatternMemoryGameScreen), findsOneWidget);
    });

    testWidgets('Tapping level badge opens manual difficulty picker bottom sheet',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatternMemoryGameScreen(
            sessionId: 'test_session',
            totalTrials: 5,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap level badge
      final levelBadgeFinder = find.text('Level 3');
      expect(levelBadgeFinder, findsOneWidget);
      await tester.tap(levelBadgeFinder);
      await tester.pumpAndSettle();

      // Sheet title should be visible
      expect(find.text('Difficulty Preset (1–10)'), findsOneWidget);

      // Level 1 should be immediately visible
      expect(find.textContaining('Level 1 (3×3)'), findsOneWidget);

      // Scroll to find Level 10
      await tester.scrollUntilVisible(
        find.textContaining('Level 10 (5×5)'),
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('Level 10 (5×5)'), findsOneWidget);
    });

    testWidgets('Selecting a level in the sheet updates state and persists preference',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatternMemoryGameScreen(
            sessionId: 'test_session',
            totalTrials: 5,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap level badge to open sheet
      await tester.tap(find.text('Level 3'));
      await tester.pumpAndSettle();

      // Tap Level 1
      await tester.tap(find.textContaining('Level 1 (3×3)'));
      await tester.pumpAndSettle();

      // Verify level updated to Level 1
      expect(find.text('Level 1'), findsOneWidget);

      // Verify SharedPreferences updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('smriti_pattern_memory_level'), 1);
    });
  });
}
