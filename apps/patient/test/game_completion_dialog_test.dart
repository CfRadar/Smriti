// apps/patient/test/game_completion_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/widgets/game_completion_dialog.dart';

void main() {
  testWidgets('GameCompletionDialog renders with deep forest green theme and correct scores',
      (WidgetTester tester) async {
    bool homePressed = false;
    bool playAgainPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameCompletionDialog(
            finalScore: 180,
            bestScore: 250,
            metrics: const [
              GameCompletionMetric(
                icon: Icons.check_circle_outline_rounded,
                label: 'Accuracy',
                value: '95%',
                iconColor: GameCompletionDialog.darkGreen,
              ),
              GameCompletionMetric(
                icon: Icons.speed_rounded,
                label: 'Avg Speed',
                value: '1.8s',
                iconColor: GameCompletionDialog.sageGreen,
              ),
              GameCompletionMetric(
                icon: Icons.local_fire_department_rounded,
                label: 'Best Streak',
                value: '6',
                iconColor: GameCompletionDialog.darkGreen,
              ),
            ],
            onHome: () => homePressed = true,
            onPlayAgain: () => playAgainPressed = true,
          ),
        ),
      ),
    );

    // Verify Title & Subtitle
    expect(find.text('Great Job!'), findsOneWidget);
    expect(find.text('Activity Completed'), findsOneWidget);

    // Verify Trophy icon
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

    // Verify Final & Best scores
    expect(find.text('FINAL SCORE'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('BEST SCORE'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);

    // Verify 3 metrics
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('Avg Speed'), findsOneWidget);
    expect(find.text('1.8s'), findsOneWidget);
    expect(find.text('Best Streak'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    // Verify Buttons and tap actions
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);

    await tester.tap(find.text('Home'));
    expect(homePressed, isTrue);

    await tester.tap(find.text('Play Again'));
    expect(playAgainPressed, isTrue);
  });
}
