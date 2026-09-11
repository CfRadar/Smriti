// apps/patient/lib/widgets/game_completion_dialog.dart

import 'package:flutter/material.dart';
import 'package:patient/services/locale_service.dart';

/// Single metric stat item displayed in the 3-tile stats row of the dialog.
class GameCompletionMetric {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const GameCompletionMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });
}

/// Unified, senior-friendly game completion dialog matching the Smriti
/// deep forest green & soft ivory UI theme.
class GameCompletionDialog extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final int finalScore;
  final int bestScore;
  final List<GameCompletionMetric> metrics;
  final VoidCallback onHome;
  final VoidCallback onPlayAgain;
  final String? homeLabel;
  final String? playAgainLabel;

  // ── Palette aligned with Smriti UI (LandingPage / GameHubPage) ─────────────
  static const Color darkGreen = Color(0xFF214E3B);
  static const Color sageGreen = Color(0xFF5F866D);
  static const Color lightGreen = Color(0xFFDCE8DA);
  static const Color ivory = Color(0xFFF8F5EC);
  static const Color cream = Color(0xFFEDE7D7);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF66736C);
  static const Color borderSoft = Color(0xFFDCE8DA);
  static const Color dividerSoft = Color(0xFFE0D8C8);
  static const Color softPeach = Color(0xFFFDF0E7);

  // Soft accents for metric icons that harmonize with deep forest green
  static const Color accentAccuracy = Color(0xFF214E3B);
  static const Color accentSpeed = Color(0xFF5F866D);
  static const Color accentStreak = Color(0xFF214E3B);

  const GameCompletionDialog({
    super.key,
    this.title,
    this.subtitle,
    required this.finalScore,
    required this.bestScore,
    required this.metrics,
    required this.onHome,
    required this.onPlayAgain,
    this.homeLabel,
    this.playAgainLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? context.tr('gameplay.greatJob');
    final effectiveSubtitle = subtitle ?? context.tr('gameplay.activityCompleted');
    final effectiveHomeLabel = homeLabel ?? context.tr('gameplay.home');
    final effectivePlayAgainLabel = playAgainLabel ?? context.tr('gameplay.playAgain');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardWhite,
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Trophy Badge ─────────────────────────────────────────────
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: darkGreen,
                size: 38,
              ),
            ),
            const SizedBox(height: 14),

            // ── Title & Subtitle ────────────────────────────────────────────
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                effectiveTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                effectiveSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Score Card (Final Score & Best Score) ────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ivory,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSoft, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr('gameplay.finalScore'),
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$finalScore',
                            style: const TextStyle(
                              color: darkGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1.2, height: 32, color: dividerSoft),
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr('gameplay.bestScore'),
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$bestScore',
                            style: const TextStyle(
                              color: darkGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 3 Stat Tiles Row ────────────────────────────────────────────
            if (metrics.isNotEmpty)
              Row(
                children: [
                  for (int i = 0; i < metrics.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _buildMetricTile(context, metrics[i])),
                  ],
                ],
              ),
            const SizedBox(height: 22),

            // ── Action Buttons (Home & Play Again) ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkGreen,
                      backgroundColor: ivory,
                      side: const BorderSide(color: borderSoft, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        effectiveHomeLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: darkGreen,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.replay_rounded, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              effectivePlayAgainLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, GameCompletionMetric metric) {
    final effectiveIconColor = metric.iconColor ?? sageGreen;
    String localizedLabel = metric.label;
    if (metric.label == 'Accuracy') {
      localizedLabel = context.tr('gameplay.accuracy');
    } else if (metric.label == 'Avg Speed') {
      localizedLabel = context.tr('gameplay.avgSpeed');
    } else if (metric.label == 'Best Streak') {
      localizedLabel = context.tr('gameplay.bestStreak');
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: ivory,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSoft, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(metric.icon, size: 20, color: effectiveIconColor),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.value,
              style: const TextStyle(
                color: darkGreen,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              localizedLabel,
              style: const TextStyle(color: textGrey, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to display the [GameCompletionDialog] with non-dismissible
/// barrier and automatic navigation handling.
Future<void> showGameCompletionDialog({
  required BuildContext context,
  String? title,
  String? subtitle,
  required int finalScore,
  required int bestScore,
  required List<GameCompletionMetric> metrics,
  required VoidCallback onHome,
  required VoidCallback onPlayAgain,
  String? homeLabel,
  String? playAgainLabel,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogCtx) {
      return GameCompletionDialog(
        title: title,
        subtitle: subtitle,
        finalScore: finalScore,
        bestScore: bestScore,
        metrics: metrics,
        homeLabel: homeLabel,
        playAgainLabel: playAgainLabel,
        onHome: () {
          Navigator.of(dialogCtx).pop();
          onHome();
        },
        onPlayAgain: () {
          Navigator.of(dialogCtx).pop();
          onPlayAgain();
        },
      );
    },
  );
}
