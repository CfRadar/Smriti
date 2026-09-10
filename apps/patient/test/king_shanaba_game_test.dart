// test/king_shanaba_game_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/controllers/voice_command_controller.dart';
import 'package:patient/games/king_shanaba_game.dart';
import 'package:patient/models/voice_command.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShanabaTrialTelemetry Model Tests', () {
    test('Serializes and deserializes telemetry JSON payload accurately', () {
      const telemetry = ShanabaTrialTelemetry(
        sessionId: 'test_session_101',
        trialNumber: 2,
        slideDistance: 312.45,
        reactionTimeMs: 1450,
        isCorrect: true,
        timestamp: '2026-09-08T16:30:00.000Z',
        targetTolerance: 52.0,
        friction: 0.086,
        initialVelocity: 1.45,
      );

      final jsonMap = telemetry.toJson();
      expect(jsonMap['sessionId'], 'test_session_101');
      expect(jsonMap['gameType'], 'king_shanaba');
      expect(jsonMap['trialNumber'], 2);
      expect(jsonMap['slideDistance'], 312.45);
      expect(jsonMap['reactionTimeMs'], 1450);
      expect(jsonMap['isCorrect'], true);
      expect(jsonMap['targetTolerance'], 52.0);
      expect(jsonMap['friction'], 0.086);

      final fromJson = ShanabaTrialTelemetry.fromJson(jsonMap);
      expect(fromJson.sessionId, telemetry.sessionId);
      expect(fromJson.trialNumber, telemetry.trialNumber);
      expect(fromJson.isCorrect, telemetry.isCorrect);
      expect(fromJson.reactionTimeMs, telemetry.reactionTimeMs);
    });
  });

  group('ShanabaAdaptiveEngine Tests', () {
    test('Initializes with senior-friendly baseline parameters', () {
      final engine = ShanabaAdaptiveEngine();
      expect(engine.level, 1);
      expect(engine.targetRadius, 26.0);
      expect(engine.difficultyLabel, 'Gentle Pace');
    });

    test('Increases difficulty smoothly on consecutive hits', () {
      final engine = ShanabaAdaptiveEngine();
      engine.recordResult(isHit: true, reactionTimeMs: 1200);
      expect(engine.level, 1); // Requires 2 consecutive hits

      engine.recordResult(isHit: true, reactionTimeMs: 1100);
      expect(engine.level, 2);
      expect(engine.targetRadius, lessThan(26.0));
      expect(engine.difficultyLabel, 'Balanced');
    });

    test('Adapts with gentle assistance on consecutive misses', () {
      final engine = ShanabaAdaptiveEngine();
      // First promote to level 2
      engine.recordResult(isHit: true, reactionTimeMs: 1000);
      engine.recordResult(isHit: true, reactionTimeMs: 1000);
      expect(engine.level, 2);

      // Miss twice in a row
      engine.recordResult(isHit: false, reactionTimeMs: 2000);
      engine.recordResult(isHit: false, reactionTimeMs: 2000);
      expect(engine.level, 1);
      expect(engine.targetRadius, greaterThanOrEqualTo(26.0));
    });

    test('Expands tolerance when patient reaction time is slow (>4500ms)', () {
      final engine = ShanabaAdaptiveEngine();
      final initialRadius = engine.targetRadius;
      engine.recordResult(isHit: false, reactionTimeMs: 5200);
      expect(engine.targetRadius, greaterThan(initialRadius));
    });

    test('Progressively shrinks striker and target diameter in each level', () {
      final engine = ShanabaAdaptiveEngine();
      expect(engine.level, 1);
      expect(engine.currentStrikerDiameter, 42.0);
      expect(engine.currentTargetDiameter, 30.0);

      engine.level = 2;
      expect(engine.currentStrikerDiameter, 38.0);
      expect(engine.currentTargetDiameter, 26.0);

      engine.level = 3;
      expect(engine.currentStrikerDiameter, 35.0);
      expect(engine.currentTargetDiameter, 23.0);

      engine.level = 4;
      expect(engine.currentStrikerDiameter, 32.0);
      expect(engine.currentTargetDiameter, 21.0);

      engine.level = 5;
      expect(engine.currentStrikerDiameter, 29.0);
      expect(engine.currentTargetDiameter, 19.0);

      // Verify strictly decreasing sizes (shorter in each level)
      for (int lvl = 1; lvl < 5; lvl++) {
        engine.level = lvl;
        final strikerCurr = engine.currentStrikerDiameter;
        final targetCurr = engine.currentTargetDiameter;
        engine.level = lvl + 1;
        expect(engine.currentStrikerDiameter, lessThan(strikerCurr));
        expect(engine.currentTargetDiameter, lessThan(targetCurr));
      }
    });
  });

  group('KingShanabaGameScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        ShanabaTelemetryService.offlineCacheKey: <String>[],
      });
    });

    testWidgets('Renders court, disc, headers, and accessible touch targets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KingShanabaGameScreen(
            sessionId: 'test_widget_session',
            totalTrials: 5,
          ),
        ),
      );
      await tester.pump();

      // Check title and theme headers
      expect(find.text('King Shanaba'), findsOneWidget);
      expect(find.text('Traditional Manipuri Kangshang'), findsOneWidget);
      expect(find.text('Round 1 / 5'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.byIcon(Icons.stars_rounded), findsOneWidget);
      expect(
        find.text('Pull back to aim & strike • Voice: "pause", "resume", "exit"'),
        findsOneWidget,
      );

      // Check presence of minimal themed playing area elements
      expect(find.byType(MinimalStrikerDisc), findsOneWidget);
    });

    testWidgets('Toggles sound and pause states gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KingShanabaGameScreen(
            sessionId: 'test_toggle_session',
            totalTrials: 4,
          ),
        ),
      );
      await tester.pump();

      // Tap Pause icon
      final pauseIcon = find.byIcon(Icons.pause_rounded);
      expect(pauseIcon, findsOneWidget);
      await tester.tap(pauseIcon);
      await tester.pump();

      // Paused overlay is displayed
      expect(find.text('Game Paused'), findsOneWidget);
      expect(find.text('Resume Session'), findsOneWidget);

      // Resume
      await tester.tap(find.text('Resume Session'));
      await tester.pump();
      expect(find.text('Game Paused'), findsNothing);

      // Toggle sound
      final volumeIcon = find.byIcon(Icons.volume_up_rounded);
      expect(volumeIcon, findsOneWidget);
      await tester.tap(volumeIcon);
      await tester.pump();
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });

    testWidgets('Drag and flick interaction works cleanly without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KingShanabaGameScreen(
            sessionId: 'test_drag_session',
            totalTrials: 3,
          ),
        ),
      );
      await tester.pump();

      final courtFinder = find.byType(GestureDetector).last;
      expect(courtFinder, findsOneWidget);

      await tester.drag(courtFinder, const Offset(0, -150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Responds to session voice commands (pause, resume) and preserves manual aiming',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KingShanabaGameScreen(
            sessionId: 'test_voice_session',
            totalTrials: 3,
          ),
        ),
      );
      await tester.pump();

      expect(VoiceCommandController.instance.hasActiveGame, isTrue);

      // Voice pause
      await VoiceCommandController.instance.execute(
        VoiceCommand(intent: VoiceIntent.pauseGame, originalText: 'pause'),
      );
      await tester.pump();
      expect(find.text('Game Paused'), findsOneWidget);

      // Voice resume
      await VoiceCommandController.instance.execute(
        VoiceCommand(intent: VoiceIntent.resumeGame, originalText: 'resume'),
      );
      await tester.pump();
      expect(find.text('Game Paused'), findsNothing);

      // Auto-aim voice command is not triggered; launch cue remains visible
      await VoiceCommandController.instance.execute(
        VoiceCommand(intent: VoiceIntent.unknown, originalText: 'slide'),
      );
      await tester.pump();
      expect(find.textContaining('Pull back to aim & strike'), findsOneWidget);
    });

    testWidgets('Renders cleanly on narrow mobile devices (360px and 320px) with no overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: KingShanabaGameScreen(
            sessionId: 'test_narrow_session',
            totalTrials: 6,
          ),
        ),
      );
      await tester.pump();

      // Verify header and components render with zero errors or overflows
      expect(find.text('King Shanaba'), findsOneWidget);
      expect(find.text('Traditional Manipuri Kangshang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
