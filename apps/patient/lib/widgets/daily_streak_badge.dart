import 'dart:math';
import 'package:flutter/material.dart';
import '../services/streak_service.dart';

/// A reusable vector-painted flame matching the user's reference design:
/// dual-tongued flame with outer vermilion, middle golden amber, inner bright yellow core,
/// upward-floating glowing ember dots, and overlaid bold white count.
/// Supports [isFrozen] state where the fire turns into ice (cyan/blue crystal gradient).
class StreakFlamePainter extends CustomPainter {
  final int streakCount;
  final double emberPhase; // 0.0 .. 1.0 for drifting sparks
  final bool showNumber;
  final double numberScale;
  final bool isFrozen;

  const StreakFlamePainter({
    required this.streakCount,
    this.emberPhase = 0.0,
    this.showNumber = true,
    this.numberScale = 1.0,
    this.isFrozen = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Floating embers / bright sparks above the flame
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    _drawEmbers(canvas, w, h, sparkPaint);

    // 2. Outer Flame Path
    final outerPath = Path();
    outerPath.moveTo(w * 0.50, h * 0.94);
    // Left bottom curve to left flank
    outerPath.cubicTo(w * 0.12, h * 0.88, w * 0.06, h * 0.55, w * 0.24, h * 0.35);
    // Left flank sweeping to main high peak
    outerPath.cubicTo(w * 0.32, h * 0.22, w * 0.44, h * 0.10, w * 0.47, h * 0.04);
    // Peak tip curling slightly down into crevice
    outerPath.cubicTo(w * 0.48, h * 0.15, w * 0.50, h * 0.28, w * 0.53, h * 0.32);
    // Secondary right peak
    outerPath.cubicTo(w * 0.58, h * 0.22, w * 0.65, h * 0.15, w * 0.70, h * 0.14);
    // Right flank back down to base
    outerPath.cubicTo(w * 0.88, h * 0.32, w * 0.94, h * 0.56, w * 0.84, h * 0.80);
    outerPath.cubicTo(w * 0.76, h * 0.92, w * 0.62, h * 0.95, w * 0.50, h * 0.94);
    outerPath.close();

    // Outer flame fill: fiery reddish-orange gradient or frozen cyan gradient
    final outerColors = isFrozen
        ? const [Color(0xFF80D8FF), Color(0xFF00B0FF), Color(0xFF0277BD)]
        : const [Color(0xFFFF7A29), Color(0xFFFF5722), Color(0xFFE64A19)];

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: outerColors,
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, outerPaint);

    // Contour outline
    final outlineColor = isFrozen
        ? const Color(0xFF01579B).withValues(alpha: 0.75)
        : const Color(0xFFD84315).withValues(alpha: 0.60);
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, w * 0.035);
    canvas.drawPath(outerPath, outlinePaint);

    // 3. Middle Flame Path (golden amber or light frost)
    final midOffsetX = w * 0.03;
    final midPath = Path();
    midPath.moveTo(w * 0.50 + midOffsetX, h * 0.88);
    midPath.cubicTo(
      w * 0.22, h * 0.82,
      w * 0.20, h * 0.56,
      w * 0.32, h * 0.42,
    );
    midPath.cubicTo(
      w * 0.38, h * 0.32,
      w * 0.48, h * 0.22,
      w * 0.50 + midOffsetX, h * 0.18,
    );
    midPath.cubicTo(
      w * 0.52 + midOffsetX, h * 0.28,
      w * 0.56 + midOffsetX, h * 0.36,
      w * 0.60, h * 0.40,
    );
    midPath.cubicTo(
      w * 0.65, h * 0.32,
      w * 0.70, h * 0.26,
      w * 0.72, h * 0.26,
    );
    midPath.cubicTo(
      w * 0.84, h * 0.42,
      w * 0.86, h * 0.60,
      w * 0.78, h * 0.78,
    );
    midPath.cubicTo(
      w * 0.70, h * 0.88,
      w * 0.58 + midOffsetX, h * 0.89,
      w * 0.50 + midOffsetX, h * 0.88,
    );
    midPath.close();

    final midColors = isFrozen
        ? const [Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFF26C6DA)]
        : const [Color(0xFFFFD54F), Color(0xFFFFA000), Color(0xFFFF8F00)];

    final midPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: midColors,
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(midPath, midPaint);

    // 4. Inner Core Flame (bright warm yellow or pure frosty white)
    final innerPath = Path();
    innerPath.moveTo(w * 0.52, h * 0.82);
    innerPath.cubicTo(w * 0.34, h * 0.78, w * 0.35, h * 0.58, w * 0.44, h * 0.48);
    innerPath.cubicTo(w * 0.48, h * 0.40, w * 0.52, h * 0.32, w * 0.54, h * 0.30);
    innerPath.cubicTo(w * 0.58, h * 0.42, w * 0.68, h * 0.50, w * 0.66, h * 0.66);
    innerPath.cubicTo(w * 0.64, h * 0.76, w * 0.58, h * 0.82, w * 0.52, h * 0.82);
    innerPath.close();

    final innerColors = isFrozen
        ? const [Color(0xFFFFFFFF), Color(0xFFE1F5FE), Color(0xFFB3E5FC)]
        : const [Color(0xFFFFF9C4), Color(0xFFFFE082), Color(0xFFFFCA28)];

    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: innerColors,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);

    // 4b. Frost crystalline facets & fracture accents for frozen state
    if (isFrozen) {
      final frostPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.9, w * 0.025);
      final crack1 = Path()
        ..moveTo(w * 0.38, h * 0.45)
        ..lineTo(w * 0.48, h * 0.56)
        ..lineTo(w * 0.44, h * 0.70);
      final crack2 = Path()
        ..moveTo(w * 0.60, h * 0.36)
        ..lineTo(w * 0.54, h * 0.52)
        ..lineTo(w * 0.66, h * 0.66);
      canvas.drawPath(crack1, frostPaint);
      canvas.drawPath(crack2, frostPaint);
    }

    // 5. Overlaid bold streak number with crisp dark outline
    if (showNumber) {
      _drawNumber(canvas, w, h);
    }
  }

  void _drawEmbers(Canvas canvas, double w, double h, Paint paint) {
    // 3 animated sparks floating upward with sine drift
    final sparkConfigs = isFrozen
        ? [
            {'baseX': w * 0.22, 'baseY': h * 0.24, 'drift': -8.0, 'size': w * 0.045, 'color': const Color(0xFFE0F7FA)},
            {'baseX': w * 0.54, 'baseY': h * 0.08, 'drift': 6.0, 'size': w * 0.040, 'color': const Color(0xFFB2EBF2)},
            {'baseX': w * 0.78, 'baseY': h * 0.20, 'drift': 8.0, 'size': w * 0.036, 'color': const Color(0xFF80DEEA)},
          ]
        : [
            {'baseX': w * 0.22, 'baseY': h * 0.24, 'drift': -12.0, 'size': w * 0.045, 'color': const Color(0xFFFFD54F)},
            {'baseX': w * 0.54, 'baseY': h * 0.08, 'drift': 8.0, 'size': w * 0.038, 'color': const Color(0xFFFFE082)},
            {'baseX': w * 0.78, 'baseY': h * 0.20, 'drift': 10.0, 'size': w * 0.035, 'color': const Color(0xFFFFCA28)},
          ];

    for (int i = 0; i < sparkConfigs.length; i++) {
      final cfg = sparkConfigs[i];
      final p = (emberPhase + (i * 0.33)) % 1.0;
      final y = (cfg['baseY'] as double) - (p * h * 0.30);
      final x = (cfg['baseX'] as double) + sin(p * 2 * pi) * (cfg['drift'] as double);
      final opacity = (sin(p * pi)).clamp(0.0, 1.0);
      final r = (cfg['size'] as double) * (1.0 - p * 0.35);

      paint.color = (cfg['color'] as Color).withValues(alpha: opacity * 0.95);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawNumber(Canvas canvas, double w, double h) {
    final text = '$streakCount';
    final fontSize = (w * 0.52 * numberScale).clamp(11.0, 140.0);
    final strokeColor = isFrozen ? const Color(0xFF003865) : const Color(0xFF631802);

    // 1. Crisp dark outline text painter
    final strokeSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        fontFamily: 'Roboto',
        letterSpacing: -0.5,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.0, fontSize * 0.20)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = strokeColor,
      ),
    );
    final strokePainter = TextPainter(
      text: strokeSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    // 2. Crisp solid white fill text painter
    final fillSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        fontFamily: 'Roboto',
        letterSpacing: -0.5,
        color: Colors.white,
      ),
    );
    final fillPainter = TextPainter(
      text: fillSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    // Center aligned horizontally and vertically
    final textX = (w - fillPainter.width) / 2;
    final textY = (h - fillPainter.height) / 2;

    strokePainter.paint(canvas, Offset(textX, textY));
    fillPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant StreakFlamePainter old) {
    return old.streakCount != streakCount ||
        old.emberPhase != emberPhase ||
        old.showNumber != showNumber ||
        old.numberScale != numberScale ||
        old.isFrozen != isFrozen;
  }
}

/// Header Badge Widget showing the flame, streak count, and living glowing fire animation
class DailyStreakBadge extends StatefulWidget {
  final VoidCallback? onTap;

  const DailyStreakBadge({super.key, this.onTap});

  @override
  State<DailyStreakBadge> createState() => DailyStreakBadgeState();
}

class DailyStreakBadgeState extends State<DailyStreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  int _streak = 1;
  bool _isFrozen = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final isBroken = await StreakService.instance.isStreakBroken();
    final s = await StreakService.instance.getStreak();
    if (mounted) {
      setState(() {
        _streak = s;
        _isFrozen = isBroken;
      });
    }
  }

  /// Refreshes streak value from storage
  Future<void> refreshStreak() => _loadStreak();

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showStreakModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Container(
          color: const Color(0xFF1C1C1E),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Large Flame with overlaid number
                SizedBox(
                  width: 140,
                  height: 160,
                  child: CustomPaint(
                    painter: StreakFlamePainter(
                      streakCount: _streak,
                      emberPhase: 0.4,
                      showNumber: true,
                      isFrozen: _isFrozen,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isFrozen
                      ? 'STREAK FROZEN'
                      : (_streak == 1 ? 'DAY CONSISTENT' : 'DAYS CONSISTENT'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isFrozen ? const Color(0xFF80D8FF) : const Color(0xFFB0B0B0),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isFrozen
                          ? const Color(0xFF00B0FF).withValues(alpha: 0.40)
                          : const Color(0xFFFF7A29).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isFrozen ? Icons.ac_unit_rounded : Icons.bolt_rounded,
                        color: _isFrozen ? const Color(0xFF80D8FF) : const Color(0xFFFFB300),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isFrozen
                              ? 'Streak broken! Practice today to break the ice and reignite your flame!'
                              : 'Keep practicing daily to build mental agility!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: _isFrozen ? const Color(0xFF80D8FF) : const Color(0xFFFF9800),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        // Living breathing pulse
        final pulse = 1.0 + (sin(_animCtrl.value * 2 * pi) * 0.045);
        final tooltipMsg = _isFrozen
            ? 'Streak frozen - practice to break the ice'
            : '$_streak ${_streak == 1 ? "day" : "days"} consistent';

        return Tooltip(
          message: tooltipMsg,
          child: InkResponse(
            onTap: widget.onTap ?? _showStreakModal,
            radius: 22,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child: Transform.scale(
                  scale: pulse,
                  child: SizedBox(
                    width: 30,
                    height: 32,
                    child: CustomPaint(
                      painter: StreakFlamePainter(
                        streakCount: _streak,
                        emberPhase: _animCtrl.value,
                        showNumber: true,
                        isFrozen: _isFrozen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
