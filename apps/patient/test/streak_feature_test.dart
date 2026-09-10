import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/main.dart';
import 'package:patient/services/streak_service.dart';
import 'package:patient/widgets/animated_star_badge.dart';
import 'package:patient/widgets/daily_streak_badge.dart';
import 'package:patient/widgets/streak_celebration_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with 1 for brand new user', () async {
      final s = await StreakService.instance.getStreak();
      expect(s, 1);
    });

    test('Detects broken streak when last active is older than yesterday', () async {
      final today = DateTime.now();
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      final dateStr =
          '${threeDaysAgo.year.toString().padLeft(4, '0')}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        'smriti_daily_streak_count': 5,
        'smriti_last_active_date': dateStr,
      });

      final isBroken = await StreakService.instance.isStreakBroken();
      expect(isBroken, isTrue);

      final newStreak = await StreakService.instance.getStreak();
      expect(newStreak, 1);

      final needsIceBreak = await StreakService.instance.shouldShowIceBreakAnimation();
      expect(needsIceBreak, isTrue);
    });

    test('Preserves and increments streak on consecutive days', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        'smriti_daily_streak_count': 4,
        'smriti_last_active_date': yesterdayStr,
      });

      final isBroken = await StreakService.instance.isStreakBroken();
      expect(isBroken, isFalse);

      final newStreak = await StreakService.instance.getStreak();
      expect(newStreak, 5);

      final needsIceBreak = await StreakService.instance.shouldShowIceBreakAnimation();
      expect(needsIceBreak, isFalse);
    });
  });

  group('Header Symmetry & Borderless Badge Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Header positions star on the left and streak on the right with symmetry',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: GameHubPage()));
      await tester.pump(const Duration(milliseconds: 100));

      final starFinder = find.byType(AnimatedStarBadge);
      final streakFinder = find.byType(DailyStreakBadge);
      final logoFinder = find.text('Smriti');

      expect(starFinder, findsOneWidget);
      expect(streakFinder, findsOneWidget);
      expect(logoFinder, findsOneWidget);

      final starCenter = tester.getCenter(starFinder);
      final streakCenter = tester.getCenter(streakFinder);
      final logoCenter = tester.getCenter(logoFinder);

      // Star is on the left of the logo
      expect(starCenter.dx, lessThan(logoCenter.dx));
      // Streak flame is on the right of the logo
      expect(streakCenter.dx, greaterThan(logoCenter.dx));

      final starWidget = tester.widget<AnimatedStarBadge>(starFinder);
      expect(starWidget, isNotNull);
      final streakWidget = tester.widget<DailyStreakBadge>(streakFinder);
      expect(streakWidget, isNotNull);
    });
  });

  group('Ice Break Celebration Tests', () {
    testWidgets('StreakCelebrationOverlay runs ice break animation without error',
        (WidgetTester tester) async {
      final targetKey = GlobalKey();
      bool onFinishedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 40,
                  right: 40,
                  child: SizedBox(key: targetKey, width: 30, height: 30),
                ),
                StreakCelebrationOverlay(
                  streakCount: 1,
                  targetKey: targetKey,
                  isIceBreak: true,
                  onFinished: () => onFinishedCalled = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Step 1: Initial frozen state
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('STREAK FROZEN'), findsOneWidget);

      // Finish enter animation (650ms total)
      await tester.pump(const Duration(milliseconds: 500));
      // Advance past Future.delayed(400ms)
      await tester.pump(const Duration(milliseconds: 450));
      // Advance iceBreakCtrl past 0.52 (900ms / 1400ms = 0.64)
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('STREAK REIGNITED!'), findsOneWidget);

      // Finish iceBreakCtrl (500ms remaining)
      await tester.pump(const Duration(milliseconds: 600));
      // Advance past post-icebreak delay (900ms)
      await tester.pump(const Duration(milliseconds: 950));
      // Advance flight animation (750ms)
      await tester.pump(const Duration(milliseconds: 800));
      expect(onFinishedCalled, isTrue);
    });
  });
}
