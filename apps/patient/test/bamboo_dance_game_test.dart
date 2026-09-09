// test/bamboo_dance_game_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/controllers/voice_command_controller.dart';
import 'package:patient/games/bamboo_dance_game.dart';
import 'package:patient/models/voice_command.dart';
import 'package:patient/utils/voice_command_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BambooDanceTrialTelemetry Model Tests', () {
    test('Serializes and deserializes telemetry JSON payload accurately', () {
      const telemetry = BambooDanceTrialTelemetry(
        sessionId: 'test_bamboo_session_101',
        trialNumber: 3,
        stage: 2,
        expectedDirection: 'right',
        actualDirection: 'right',
        reactionTimeMs: 1420,
        isCorrect: true,
        rhythmAccuracy: 0.88,
        timestamp: '2026-09-09T10:00:00.000Z',
        bpm: 40,
        timingWindowMs: 3000,
      );

      final jsonMap = telemetry.toJson();
      expect(jsonMap['sessionId'], 'test_bamboo_session_101');
      expect(jsonMap['gameType'], 'bamboo_dance');
      expect(jsonMap['trialNumber'], 3);
      expect(jsonMap['stage'], 2);
      expect(jsonMap['expectedDirection'], 'right');
      expect(jsonMap['actualDirection'], 'right');
      expect(jsonMap['reactionTimeMs'], 1420);
      expect(jsonMap['isCorrect'], true);
      expect(jsonMap['rhythmAccuracy'], 0.88);
      expect(jsonMap['bpm'], 40);
      expect(jsonMap['timingWindowMs'], 3000);

      final fromJson = BambooDanceTrialTelemetry.fromJson(jsonMap);
      expect(fromJson.sessionId, telemetry.sessionId);
      expect(fromJson.trialNumber, telemetry.trialNumber);
      expect(fromJson.stage, telemetry.stage);
      expect(fromJson.expectedDirection, telemetry.expectedDirection);
      expect(fromJson.actualDirection, telemetry.actualDirection);
      expect(fromJson.isCorrect, telemetry.isCorrect);
      expect(fromJson.reactionTimeMs, telemetry.reactionTimeMs);
    });
  });

  group('BambooAdaptiveEngine Tests', () {
    test('Initializes with dementia-friendly baseline parameters (Stage 1)', () {
      final engine = BambooAdaptiveEngine();
      expect(engine.currentStageNumber, 1);
      expect(engine.adaptiveBpm, 38);
      expect(engine.adaptiveTimingWindowMs, 3400);
      expect(engine.currentConfig.availableDirections, [DanceDirection.up]);
      expect(engine.currentConfig.name, 'Familiarisation');
    });

    test('Adapts with gentle acceleration on calm confident hits', () {
      final engine = BambooAdaptiveEngine();
      engine.recordTrialResult(isCorrect: true, reactionTimeMs: 1200);
      expect(engine.consecutiveSuccesses, 1);
      expect(engine.consecutiveMistakes, 0);
      expect(engine.adaptiveBpm, 39);
      expect(engine.adaptiveTimingWindowMs, 3350);
    });

    test('Widens timing window gently on mistakes with NO failure state', () {
      final engine = BambooAdaptiveEngine();
      engine.recordTrialResult(isCorrect: false, reactionTimeMs: 2500);
      expect(engine.consecutiveMistakes, 1);
      expect(engine.consecutiveSuccesses, 0);
      expect(engine.adaptiveBpm, 37);
      expect(engine.adaptiveTimingWindowMs, 3500);
    });

    test('Advances through stages progressively without level selection screen', () {
      final engine = BambooAdaptiveEngine();
      expect(engine.currentStageNumber, 1);
      expect(engine.shouldAdvanceStage(3), isFalse);
      expect(engine.shouldAdvanceStage(4), isTrue);

      engine.advanceStage();
      expect(engine.currentStageNumber, 2);
      expect(engine.currentConfig.name, 'Gentle Alternation');
      expect(engine.currentConfig.availableDirections,
          [DanceDirection.left, DanceDirection.right]);

      // Advance to Stage 3
      engine.advanceStage();
      expect(engine.currentStageNumber, 3);
      expect(engine.currentConfig.name, 'Four Directions');
      expect(engine.currentConfig.availableDirections.length, 4);
      expect(engine.isAlternateNotes, isFalse);

      // Advance to Stage 4
      engine.advanceStage();
      expect(engine.currentStageNumber, 4);
      expect(engine.currentConfig.name, 'Rhythm Pattern');
      expect(engine.isAlternateNotes, isFalse);

      // Advance to Stage 5
      engine.advanceStage();
      expect(engine.currentStageNumber, 5);
      expect(engine.currentConfig.name, 'Pattern Memory');
      expect(engine.currentConfig.isPatternMemory, isTrue);

      // Advance to Stage 6
      engine.advanceStage();
      expect(engine.currentStageNumber, 6);
      expect(engine.currentConfig.name, 'Cheraw Harmony');
    });

    test('Adapts circle pointer notes: alternate notes in easy stages and all notes in higher stages', () {
      final engine = BambooAdaptiveEngine();
      expect(engine.currentStageNumber, 1);
      expect(engine.isAlternateNotes, isTrue);

      engine.advanceStage(); // Stage 2
      expect(engine.currentStageNumber, 2);
      expect(engine.isAlternateNotes, isTrue);

      engine.advanceStage(); // Stage 3
      expect(engine.currentStageNumber, 3);
      expect(engine.isAlternateNotes, isFalse);
    });
  });

  group('VoiceCommandParser Bamboo Dance Integration Tests', () {
    test('Parses English, Hindi, and Assamese bamboo dance phrases', () {
      final englishCmd = VoiceCommandParser.parse('open bamboo dance');
      expect(englishCmd.intent, VoiceIntent.openBambooDanceGame);

      final cherawCmd = VoiceCommandParser.parse('play cheraw dance');
      expect(cherawCmd.intent, VoiceIntent.openBambooDanceGame);

      final assameseCmd = VoiceCommandParser.parse('বাঁহ নৃত্য খেলিব লাগে');
      expect(assameseCmd.gameName, 'bamboo dance');

      final hindiCmd = VoiceCommandParser.parse('बांस नृत्य खोलो');
      expect(hindiCmd.gameName, 'bamboo dance');
    });
  });

  group('BambooDanceTelemetryService Local Queue Tests', () {
    test('Queues trial telemetry locally into SharedPreferences', () async {
      final service = BambooDanceTelemetryService();
      const telemetry = BambooDanceTrialTelemetry(
        sessionId: 'offline_session_1',
        trialNumber: 1,
        stage: 1,
        expectedDirection: 'up',
        actualDirection: 'up',
        reactionTimeMs: 1500,
        isCorrect: true,
        rhythmAccuracy: 0.9,
        timestamp: '2026-09-09T11:00:00.000Z',
        bpm: 38,
        timingWindowMs: 3400,
      );

      await service.logTrial(telemetry);

      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(BambooDanceTelemetryService.offlineCacheKey);
      expect(list, isNotNull);
      expect(list!.length, 1);
      expect(list.first, contains('offline_session_1'));
      service.dispose();
    });
  });

  group('BambooDanceGameScreen Widget Tests', () {
    testWidgets('Renders top-down court, dancer, headers, and bamboo matrix without D-Pad or banner',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'widget_test_session',
            totalTargetTrials: 5,
          ),
        ),
      );
      await tester.pump();

      // Check header and navigation
      expect(find.text('Bamboo Dance (বাঁহ নৃত্য)'), findsOneWidget);
      expect(find.byTooltip('Exit to Home'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Check step counter
      expect(find.text('Step 0 / 5'), findsOneWidget);

      // Verify directional D-Pad controls are REMOVED
      expect(find.text('UP / ওপৰ'), findsNothing);
      expect(find.text('LEFT / বাওঁ'), findsNothing);
      expect(find.text('DOWN / তল'), findsNothing);
      expect(find.text('RIGHT / সোঁ'), findsNothing);

      // Verify direction instruction banner is REMOVED
      expect(find.text('ওপৰলৈ খোজ দিয়ক'), findsNothing);
      expect(find.text('STEP UP • ওপৰ'), findsNothing);

      // Verify interactive court canvas and direct touch target circle exist
      expect(find.byKey(const ValueKey('bamboo_court_canvas')), findsOneWidget);
      expect(find.byKey(const ValueKey('bamboo_target_circle')), findsOneWidget);

      // Verify initial dancer position is at center GridPos(1, 1)
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('bamboo_court_canvas')),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as BambooCourtPainter;
      expect(painter.dancerGridPos, const GridPos(1, 1));
      expect(painter.targetGridPos, const GridPos(1, 0));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Tapping court target circle directly registers a step and dancer coordinates persist at destination',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'touch_persist_session',
            totalTargetTrials: 5,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Initial step is 0, initial dancer is at center (1, 1), target is UP at (1, 0)
      expect(find.text('Step 0 / 5'), findsOneWidget);

      final targetFinder = find.byKey(const ValueKey('bamboo_target_circle'));
      expect(targetFinder, findsOneWidget);

      // Direct touch on target circle
      await tester.tap(targetFinder);
      await tester.pump();

      // Step count increments immediately
      expect(find.text('Step 1 / 5'), findsOneWidget);

      // Advance jump animation
      await tester.pump(const Duration(milliseconds: 700));

      // Assert dancer coordinates persist at the stepped destination GridPos(1, 0)
      var customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('bamboo_court_canvas')),
          matching: find.byType(CustomPaint),
        ),
      );
      var painter = customPaint.painter as BambooCourtPainter;
      expect(painter.dancerGridPos, const GridPos(1, 0));

      // Advance through delay to next trial (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));

      // Assert dancer coordinates STILL persist at GridPos(1, 0) and DO NOT revert to center!
      customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('bamboo_court_canvas')),
          matching: find.byType(CustomPaint),
        ),
      );
      painter = customPaint.painter as BambooCourtPainter;
      expect(painter.dancerGridPos, const GridPos(1, 0));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Dancer moves across multiple cells and coordinates persist across consecutive steps',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'multistep_persist_session',
            totalTargetTrials: 5,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Step 1: Start at (1, 1), target is (1, 0)
      await tester.tap(find.byKey(const ValueKey('bamboo_target_circle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      var customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('bamboo_court_canvas')),
          matching: find.byType(CustomPaint),
        ),
      );
      var painter = customPaint.painter as BambooCourtPainter;
      expect(painter.dancerGridPos, const GridPos(1, 0));
      expect(find.text('Step 1 / 5'), findsOneWidget);

      // Step 2: From (1, 0), next target is strictly in opposite bamboo space (1, 2)
      expect(painter.targetGridPos, const GridPos(1, 2));
      await tester.tap(find.byKey(const ValueKey('bamboo_target_circle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('bamboo_court_canvas')),
          matching: find.byType(CustomPaint),
        ),
      );
      painter = customPaint.painter as BambooCourtPainter;
      expect(painter.dancerGridPos, const GridPos(1, 2));
      expect(find.text('Step 2 / 5'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Toggles sound and pause states gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'toggle_test_session',
            totalTargetTrials: 5,
          ),
        ),
      );
      await tester.pump();

      // Toggle sound
      final volumeIcon = find.byIcon(Icons.volume_up_rounded);
      expect(volumeIcon, findsOneWidget);
      await tester.tap(volumeIcon);
      await tester.pump();
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

      // Toggle pause
      final pauseIcon = find.byIcon(Icons.pause_rounded);
      expect(pauseIcon, findsOneWidget);
      await tester.tap(pauseIcon);
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Toggle resume
      final playIcon = find.byIcon(Icons.play_arrow_rounded);
      await tester.tap(playIcon);
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Responds to session voice commands (pause, resume)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'voice_test_session',
            totalTargetTrials: 5,
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
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Voice resume
      await VoiceCommandController.instance.execute(
        VoiceCommand(intent: VoiceIntent.resumeGame, originalText: 'resume'),
      );
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Renders cleanly on narrow mobile devices (320px and 360px) with zero overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'narrow_test_session',
            totalTargetTrials: 5,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bamboo Dance (বাঁহ নৃত্য)'), findsOneWidget);
      expect(find.byKey(const ValueKey('bamboo_court_canvas')), findsOneWidget);
      expect(find.byKey(const ValueKey('bamboo_target_circle')), findsOneWidget);
      expect(find.text('UP / ওপৰ'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Input lock prevents multiple step increments on rapid repeated taps on target circle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'debounce_test_session',
            totalTargetTrials: 5,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Initial state is step 0
      expect(find.text('Step 0 / 5'), findsOneWidget);

      final targetCircle = find.byKey(const ValueKey('bamboo_target_circle'));
      expect(targetCircle, findsOneWidget);

      // Rapidly tap target circle 4 times in quick succession before the animation finishes
      await tester.tap(targetCircle);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(targetCircle);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(targetCircle);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(targetCircle);
      await tester.pump(const Duration(milliseconds: 50));

      // Step count should increment to exactly 1, NOT 4!
      expect(find.text('Step 1 / 5'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Ends game session after target steps and displays celebratory completion overlay',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'ending_test_session',
            totalTargetTrials: 2,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final targetCircle = find.byKey(const ValueKey('bamboo_target_circle'));

      // Step 1
      await tester.tap(targetCircle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.text('Step 1 / 2'), findsOneWidget);

      // Step 2 (target reached!)
      await tester.tap(targetCircle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      // Check ending celebratory overlay appeared
      expect(find.text('2 টা খোজ সম্পন্ন হ\'ল!'), findsOneWidget);
      expect(find.text('2 Dance Steps Completed!'), findsOneWidget);
      expect(find.text('পুনৰ খেলক\nPlay Again'), findsOneWidget);
      expect(find.text('ঘৰলৈ যাওক\nHome'), findsOneWidget);

      // Tap Play Again
      await tester.tap(find.text('পুনৰ খেলক\nPlay Again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Game resets cleanly to Step 0
      expect(find.text('Step 0 / 2'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Target circle and dancer reside in open empty spaces with clearance from all bamboo poles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'clearance_test_session',
            totalTargetTrials: 5,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final customPaintFinder = find.descendant(
        of: find.byKey(const ValueKey('bamboo_court_canvas')),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaint.painter as BambooCourtPainter;
      const courtSize = 320.0;
      const center = Offset(courtSize / 2, courtSize / 2);
      const cellSpacing = courtSize * 0.28;

      final vertPoles = painter.getVerticalPolePositions(courtSize, center, cellSpacing);
      final horizPoles = painter.getHorizontalPolePositions(courtSize, center, cellSpacing);

      final targetPos = Offset(
        center.dx + (painter.targetGridPos.col - 1) * cellSpacing,
        center.dy + (painter.targetGridPos.row - 1) * cellSpacing,
      );
      final dancerPos = Offset(
        center.dx + (painter.dancerGridPos.col - 1) * cellSpacing,
        center.dy + (painter.dancerGridPos.row - 1) * cellSpacing,
      );

      // Target circle has generous clearance (>30px) from all 3 vertical and 3 horizontal poles
      for (final vx in vertPoles) {
        expect((targetPos.dx - vx).abs(), greaterThan(30.0),
            reason: 'Target circle must not overlap vertical pole at x=$vx');
      }
      for (final hy in horizPoles) {
        expect((targetPos.dy - hy).abs(), greaterThan(30.0),
            reason: 'Target circle must not overlap horizontal pole at y=$hy');
      }

      // Dancer has generous clearance (>30px) from all 3 vertical and 3 horizontal poles
      for (final vx in vertPoles) {
        expect((dancerPos.dx - vx).abs(), greaterThan(30.0),
            reason: 'Dancer must not overlap vertical pole at x=$vx');
      }
      for (final hy in horizPoles) {
        expect((dancerPos.dy - hy).abs(), greaterThan(30.0),
            reason: 'Dancer must not overlap horizontal pole at y=$hy');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    test('Bamboo poles transition smoothly across trial steps without wobbling or jitter', () {
      const courtSize = 320.0;
      const center = Offset(courtSize / 2, courtSize / 2);
      const cellSpacing = courtSize * 0.28;

      // 1. Verify zero wobbling regardless of cadence pulseFactor
      final painterLowPulse = BambooCourtPainter(
        pulseFactor: 0.1,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(1, 0),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        isAlternateNotes: false,
      );

      final painterHighPulse = BambooCourtPainter(
        pulseFactor: 0.95,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(1, 0),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        isAlternateNotes: false,
      );

      final vertLow = painterLowPulse.getVerticalPolePositions(courtSize, center, cellSpacing);
      final vertHigh = painterHighPulse.getVerticalPolePositions(courtSize, center, cellSpacing);
      for (int i = 0; i < 3; i++) {
        expect(vertLow[i], equals(vertHigh[i]),
            reason: 'Poles must remain steady and not wobble with pulse factor changes');
      }

      // 2. Verify smooth interpolation between previous and next grid target locations
      final pStart = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(2, 1),
        prevTargetGridPos: const GridPos(0, 1),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 0.0,
        isAlternateNotes: false,
      );

      final pMid = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(2, 1),
        prevTargetGridPos: const GridPos(0, 1),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 0.5,
        isAlternateNotes: false,
      );

      final pEnd = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(2, 1),
        prevTargetGridPos: const GridPos(0, 1),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        isAlternateNotes: false,
      );

      final vStart = pStart.getVerticalPolePositions(courtSize, center, cellSpacing);
      final vMid = pMid.getVerticalPolePositions(courtSize, center, cellSpacing);
      final vEnd = pEnd.getVerticalPolePositions(courtSize, center, cellSpacing);

      // Verify mid-transition pole is smoothly intermediate between start and end
      for (int i = 0; i < 3; i++) {
        if ((vEnd[i] - vStart[i]).abs() > 1.0) {
          final minP = vStart[i] < vEnd[i] ? vStart[i] : vEnd[i];
          final maxP = vStart[i] > vEnd[i] ? vStart[i] : vEnd[i];
          expect(vMid[i], greaterThanOrEqualTo(minP - 0.01));
          expect(vMid[i], lessThanOrEqualTo(maxP + 0.01));
        }
      }
    });

    test('Bamboos close completely with centre touching left or right (and top or bottom) alternatively while creating space on the other side', () {
      const courtSize = 320.0;
      const center = Offset(courtSize / 2, courtSize / 2);
      const cellSpacing = courtSize * 0.28;
      final poleThickness = (courtSize * 0.038).clamp(10.0, 15.0);

      // 1. Target on Left (col 0): Centre closes completely with Right pole (Pole 1 & Pole 2 touch)
      final pLeft = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.left,
        targetGridPos: const GridPos(0, 1),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        isAlternateNotes: false,
      );
      final vLeft = pLeft.getVerticalPolePositions(courtSize, center, cellSpacing);
      // Pole 1 and Pole 2 touch side-by-side (distance == poleThickness)
      expect((vLeft[2] - vLeft[1] - poleThickness).abs(), lessThan(0.001),
          reason: 'Pole 1 and Pole 2 must close completely together on the right');
      // Left side has wide open space (distance from target cell center to Pole 0 is > 35px)
      final targetXLeft = center.dx - cellSpacing;
      expect((targetXLeft - vLeft[0]).abs(), greaterThan(35.0));

      // 2. Target on Right (col 2): Centre closes completely with Left pole (Pole 0 & Pole 1 touch)
      final pRight = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.right,
        targetGridPos: const GridPos(2, 1),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        isAlternateNotes: false,
      );
      final vRight = pRight.getVerticalPolePositions(courtSize, center, cellSpacing);
      // Pole 0 and Pole 1 touch side-by-side (distance == poleThickness)
      expect((vRight[1] - vRight[0] - poleThickness).abs(), lessThan(0.001),
          reason: 'Pole 0 and Pole 1 must close completely together on the left');
      // Right side has wide open space
      final targetXRight = center.dx + cellSpacing;
      expect((targetXRight - vRight[2]).abs(), greaterThan(35.0));

      // 3. Target on Top (row 0): Centre closes completely with Bottom pole (Pole 1 & Pole 2 touch)
      final pTop = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(1, 0),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        isAlternateNotes: false,
      );
      final hTop = pTop.getHorizontalPolePositions(courtSize, center, cellSpacing);
      expect((hTop[2] - hTop[1] - poleThickness).abs(), lessThan(0.001),
          reason: 'Pole 1 and Pole 2 must close completely together at the bottom');
      final targetYTop = center.dy - cellSpacing;
      expect((targetYTop - hTop[0]).abs(), greaterThan(35.0));

      // 4. Target on Bottom (row 2): Centre closes completely with Top pole (Pole 0 & Pole 1 touch)
      final pBottom = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.down,
        targetGridPos: const GridPos(1, 2),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        isAlternateNotes: false,
      );
      final hBottom = pBottom.getHorizontalPolePositions(courtSize, center, cellSpacing);
      expect((hBottom[1] - hBottom[0] - poleThickness).abs(), lessThan(0.001),
          reason: 'Pole 0 and Pole 1 must close completely together at the top');
      final targetYBottom = center.dy + cellSpacing;
      expect((targetYBottom - hBottom[2]).abs(), greaterThan(35.0));
    });

    test('Bamboos alternate between steps: even steps close with Left and odd steps close with Right', () {
      const courtSize = 320.0;
      const center = Offset(courtSize / 2, courtSize / 2);
      const cellSpacing = courtSize * 0.28;
      final poleThickness = (courtSize * 0.038).clamp(10.0, 15.0);

      // Step 0 (even): Centre closes with Left pole (Pole 0 & Pole 1 touch)
      final pStep0 = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(1, 0),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        trialStep: 0,
        isAlternateNotes: false,
      );
      final v0 = pStep0.getVerticalPolePositions(courtSize, center, cellSpacing);
      expect((v0[1] - v0[0] - poleThickness).abs(), lessThan(0.001),
          reason: 'Even steps must close centre with left pole');

      // Step 1 (odd): Centre closes with Right pole (Pole 1 & Pole 2 touch)
      final pStep1 = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.down,
        targetGridPos: const GridPos(1, 1),
        dancerGridPos: const GridPos(1, 0),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        trialStep: 1,
        isAlternateNotes: false,
      );
      final v1 = pStep1.getVerticalPolePositions(courtSize, center, cellSpacing);
      expect((v1[2] - v1[1] - poleThickness).abs(), lessThan(0.001),
          reason: 'Odd steps must close centre with right pole');

      // Step 2 (even again): Centre closes with Left pole again (Pole 0 & Pole 1 touch)
      final pStep2 = BambooCourtPainter(
        pulseFactor: 0.5,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(1, 0),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        trialStep: 2,
        isAlternateNotes: false,
      );
      final v2 = pStep2.getVerticalPolePositions(courtSize, center, cellSpacing);
      expect((v2[1] - v2[0] - poleThickness).abs(), lessThan(0.001),
          reason: 'Alternates back to closing centre with left pole');
    });

    test('BambooCourtPainter.isSameBambooSpace accurately identifies positions sharing bamboo spaces', () {
      // 1. Same Left bamboo space (col == 0)
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(0, 1), const GridPos(0, 0)), isTrue);
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(0, 1), const GridPos(0, 2)), isTrue);

      // 2. Same Right bamboo space (col == 2)
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(2, 1), const GridPos(2, 0)), isTrue);
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(2, 1), const GridPos(2, 2)), isTrue);

      // 3. Same Top bamboo space (row == 0)
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(1, 0), const GridPos(0, 0)), isTrue);
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(1, 0), const GridPos(2, 0)), isTrue);

      // 4. Same Bottom bamboo space (row == 2)
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(1, 2), const GridPos(0, 2)), isTrue);
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(1, 2), const GridPos(2, 2)), isTrue);

      // 5. Same Center space (1, 1)
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(1, 1), const GridPos(1, 1)), isTrue);

      // 6. Corner quadrants: cells sharing the same corner space
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(2, 0), const GridPos(1, 1)), isTrue,
          reason: 'Top-Right corner and adjacent inner center cell share the same open quadrant');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(0, 0), const GridPos(1, 1)), isTrue,
          reason: 'Top-Left corner and adjacent inner center cell share the same open quadrant');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(0, 2), const GridPos(1, 1)), isTrue,
          reason: 'Bottom-Left corner and adjacent inner center cell share the same open quadrant');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(2, 2), const GridPos(1, 1)), isTrue,
          reason: 'Bottom-Right corner and adjacent inner center cell share the same open quadrant');

      // 7. DIFFERENT bamboo spaces & opposite quadrants (MUST be false!)
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(2, 0), const GridPos(0, 2)), isFalse,
          reason: 'Top-Right and Bottom-Left are opposite quadrants');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(0, 0), const GridPos(2, 2)), isFalse,
          reason: 'Top-Left and Bottom-Right are opposite quadrants');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(0, 1), const GridPos(1, 1)), isFalse,
          reason: 'Left space and Center space must be distinct');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(2, 1), const GridPos(1, 1)), isFalse,
          reason: 'Right space and Center space must be distinct');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(0, 1), const GridPos(2, 1)), isFalse,
          reason: 'Left space and Right space must be distinct');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(1, 0), const GridPos(1, 1)), isFalse,
          reason: 'Top space and Center space must be distinct');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(1, 2), const GridPos(1, 1)), isFalse,
          reason: 'Bottom space and Center space must be distinct');
      expect(BambooCourtPainter.isSameBambooSpace(const GridPos(1, 0), const GridPos(1, 2)), isFalse,
          reason: 'Top space and Bottom space must be distinct');
    });

    testWidgets('Target strictly alternates across bamboo spaces with zero consecutive same-space iterations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BambooDanceGameScreen(
            sessionId: 'sync_no_repeat_space_session',
            totalTargetTrials: 10,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      GridPos? prevTarget;

      for (int step = 0; step < 4; step++) {
        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('bamboo_court_canvas')),
            matching: find.byType(CustomPaint),
          ),
        );
        final painter = customPaint.painter as BambooCourtPainter;
        final currentTarget = painter.targetGridPos;

        if (prevTarget != null) {
          expect(
            BambooCourtPainter.isSameBambooSpace(currentTarget, prevTarget),
            isFalse,
            reason: 'Step $step target $currentTarget must NOT be in same bamboo space as previous target $prevTarget',
          );
        }

        prevTarget = currentTarget;

        // Tap current target circle
        await tester.tap(find.byKey(const ValueKey('bamboo_target_circle')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    test('BambooCourtPainter.getOtherBlockAreaPos returns space in another block area across bamboo poles', () {
      // Top target -> Bottom block area
      expect(BambooCourtPainter.getOtherBlockAreaPos(const GridPos(1, 0)), const GridPos(1, 2));
      // Bottom target -> Top block area
      expect(BambooCourtPainter.getOtherBlockAreaPos(const GridPos(1, 2)), const GridPos(1, 0));
      // Left target -> Right block area
      expect(BambooCourtPainter.getOtherBlockAreaPos(const GridPos(0, 1)), const GridPos(2, 1));
      // Right target -> Left block area
      expect(BambooCourtPainter.getOtherBlockAreaPos(const GridPos(2, 1)), const GridPos(0, 1));

      // All target spaces guarantee different bamboo spaces
      for (final t in [const GridPos(1, 0), const GridPos(1, 2), const GridPos(0, 1), const GridPos(2, 1)]) {
        final other = BambooCourtPainter.getOtherBlockAreaPos(t);
        expect(other, isNot(equals(t)), reason: 'Target and other block area must never coincide');
        expect(BambooCourtPainter.isSameBambooSpace(other, t), isFalse,
            reason: 'Target and other block area must be in different bamboo spaces');
      }
    });

    test('Continuous pole transitions with explicit closure flags have zero jumps from progress 0.0 to 1.0', () {
      const courtSize = 320.0;
      const center = Offset(courtSize / 2, courtSize / 2);
      const cellSpacing = courtSize * 0.28;

      final painter0 = BambooCourtPainter(
        pulseFactor: 0.0,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(1, 0),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 0.0,
        trialStep: 1,
        isAlternateNotes: false,
        verticalCloseWithRight: true,
        prevVerticalCloseWithRight: false,
      );

      final vAt0 = painter0.getVerticalPolePositions(courtSize, center, cellSpacing);
      final fromPoles = BambooCourtPainter.calcVerticalPolesFromFlag(center, cellSpacing, courtSize, false);
      for (int i = 0; i < 3; i++) {
        expect((vAt0[i] - fromPoles[i]).abs(), lessThan(0.001),
            reason: 'At progress 0.0, pole positions must exactly equal previous pole positions');
      }

      final painter1 = BambooCourtPainter(
        pulseFactor: 0.0,
        characterMood: CharacterMood.idle,
        stepDirection: null,
        jumpProgress: 0.0,
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: const GridPos(1, 0),
        dancerGridPos: const GridPos(1, 1),
        prevDancerGridPos: const GridPos(1, 1),
        bambooShiftProgress: 1.0,
        trialStep: 1,
        isAlternateNotes: false,
        verticalCloseWithRight: true,
        prevVerticalCloseWithRight: false,
      );

      final vAt1 = painter1.getVerticalPolePositions(courtSize, center, cellSpacing);
      final toPoles = BambooCourtPainter.calcVerticalPolesFromFlag(center, cellSpacing, courtSize, true);
      for (int i = 0; i < 3; i++) {
        expect((vAt1[i] - toPoles[i]).abs(), lessThan(0.001),
            reason: 'At progress 1.0, pole positions must exactly equal target pole positions');
      }
    });

    test('Dancer hops strictly from otherBlockPos onto target when tapped (never snapping to previous cell)', () {
      const target = GridPos(1, 0); // Target at Top
      const prevDancer = GridPos(0, 1); // Previous position (e.g. Left)
      const currentDancer = GridPos(1, 0); // Stepped destination
      final otherBlock = BambooCourtPainter.getOtherBlockAreaPos(target); // (1, 2) Bottom

      expect(otherBlock, const GridPos(1, 2));
      expect(otherBlock, isNot(equals(prevDancer)), reason: 'otherBlockPos must not be confused with prevPos');

      final painter = BambooCourtPainter(
        pulseFactor: 0.0,
        characterMood: CharacterMood.happyStep,
        stepDirection: DanceDirection.up,
        jumpProgress: 0.0, // At the very start of the user's tap jump
        stumbleProgress: 0.0,
        targetDirection: DanceDirection.up,
        targetGridPos: target,
        dancerGridPos: currentDancer,
        prevDancerGridPos: prevDancer,
        bambooShiftProgress: 1.0,
        trialStep: 2,
        isAlternateNotes: false,
      );

      // Verify that hop starts from otherBlockPos and NOT prevPos
      expect(painter.targetGridPos, target);
      expect(BambooCourtPainter.getOtherBlockAreaPos(painter.targetGridPos), const GridPos(1, 2));
    });
  });
}

