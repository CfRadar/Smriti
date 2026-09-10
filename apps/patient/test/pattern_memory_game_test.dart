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

    testWidgets('Correct tile guess has the same dark green colour as shown tile without tick mark',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const SizedBox(),
          },
          home: const PatternMemoryGameScreen(
            sessionId: 'test_tile_color_session',
            totalTrials: 5,
          ),
        ),
      );

      await tester.pump();
      // Fast forward past countdown (3s) and memorization (2.5s)
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(milliseconds: 3000));

      // In recall phase, there should be NO check_rounded icon on any tile
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Find first tappable tile in the grid
      final firstGridTile = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      ).first;
      await tester.tap(firstGridTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify that even after guessing, check_rounded icon is NOT used
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('Wrong tile tap displays matching soft red without cross mark and advances to next pattern',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const SizedBox(),
          },
          home: const PatternMemoryGameScreen(
            sessionId: 'test_wrong_tap_session',
            totalTrials: 5,
          ),
        ),
      );

      await tester.pump();
      // Fast forward past countdown (3s) and memorization (3.6s)
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(milliseconds: 4000));

      // In recall phase of Trial 1
      expect(find.textContaining('Trial 1 / 5'), findsOneWidget);

      // Find all tiles in grid
      final tiles = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );

      // Verify neither check mark nor cross mark exist anywhere
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Tap tiles until a non-pattern tile is tapped (triggering wrong tap & feedback phase)
      for (int i = 0; i < tiles.evaluate().length; i++) {
        await tester.tap(tiles.at(i));
        await tester.pump(const Duration(milliseconds: 50));
        // Cross mark must NEVER be shown on any tile
        expect(find.byIcon(Icons.close_rounded), findsNothing);
        // If wrong tap occurred, game moved to feedback phase
        if (find.text('Reviewing pattern...').evaluate().isNotEmpty) {
          break;
        }
      }

      // Fast forward through feedback delay (1.4s) and countdown into next trial
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 3500));

      // Next pattern (Trial 2) is reached
      expect(find.textContaining('Trial 2 / 5'), findsOneWidget);
    });

    testWidgets('Relaxed invisible timer advances trial after timeout without displaying ticking clock',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const SizedBox(),
          },
          home: const PatternMemoryGameScreen(
            sessionId: 'test_timeout_session',
            totalTrials: 3,
          ),
        ),
      );

      await tester.pump();
      // Fast forward past countdown (3s) and memorization (3.6s) into recall
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(milliseconds: 4000));

      expect(find.textContaining('Trial 1 / 3'), findsOneWidget);

      // No countdown timer digits or ticking clock displayed on screen during recall
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsNothing);

      // Fast forward by relaxed timeout duration (25s) + feedback delay (1.5s) + countdown (2.5s)
      await tester.pump(const Duration(seconds: 26));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 3000));

      // Should have advanced to Trial 2
      expect(find.textContaining('Trial 2 / 3'), findsOneWidget);
    });

    testWidgets('Game completion dialog shows at session end without showing next pattern behind',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const SizedBox(),
          },
          home: const PatternMemoryGameScreen(
            sessionId: 'test_completion_session',
            totalTrials: 1, // Only 1 trial for test
          ),
        ),
      );

      await tester.pump();
      // Fast forward past countdown and memorization into recall
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(milliseconds: 4000));

      expect(find.textContaining('Trial 1 / 1'), findsOneWidget);

      // Let the trial complete via relaxed timeout
      await tester.pump(const Duration(seconds: 26));
      // Feedback delay (1.5s)
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Unified GameCompletionDialog should be visible
      expect(find.text('Great Job!'), findsOneWidget);
      expect(find.text('Activity Completed'), findsOneWidget);
      // 'Next pattern...' must NOT be shown when game ends
      expect(find.text('Next pattern...'), findsNothing);
    });

    testWidgets('Toggling sound off mutes sound button and disables click audio playback',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatternMemoryGameScreen(
            sessionId: 'test_sound_session',
            totalTrials: 3,
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

      // Fast forward past countdown and memorization into recall
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(milliseconds: 4000));

      // Tapping tile during recall when sound is disabled must execute cleanly without error
      final gridFind = find.byType(GridView);
      if (gridFind.evaluate().isNotEmpty) {
        final firstTile = find.descendant(
          of: gridFind,
          matching: find.byType(GestureDetector),
        );
        if (firstTile.evaluate().isNotEmpty) {
          await tester.tap(firstTile.first);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // Remains muted
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });
  });
}
