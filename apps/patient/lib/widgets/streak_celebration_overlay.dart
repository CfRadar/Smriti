import 'dart:math';
import 'package:flutter/material.dart';
import 'daily_streak_badge.dart';

/// Overlay that animates the fire streak emoji from small to big in the center
/// of the screen, pauses, and then flies directly into its resting place
/// in the header.
/// If [isIceBreak] is true, it shows a frozen ice flame, cracks it with ice shatter
/// particles, and erupts into warm fire to signify reigniting the streak!
class StreakCelebrationOverlay extends StatefulWidget {
  final int streakCount;
  final GlobalKey targetKey;
  final VoidCallback onFinished;
  final bool isIceBreak;

  const StreakCelebrationOverlay({
    super.key,
    required this.streakCount,
    required this.targetKey,
    required this.onFinished,
    this.isIceBreak = false,
  });

  @override
  State<StreakCelebrationOverlay> createState() => _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<StreakCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _scaleInAnim;
  late final Animation<double> _fadeInAnim;

  late final AnimationController _flightCtrl;
  late final Animation<double> _flightAnim;

  late final AnimationController _emberCtrl;
  late final AnimationController _iceBreakCtrl;

  bool _isFlying = false;
  Offset? _targetCenter;

  @override
  void initState() {
    super.initState();

    _emberCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // 1. Enter animation: small to big in center with spring bounce
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleInAnim = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack),
    );
    _fadeInAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut),
    );

    // 2. Flight animation: from center to header
    _flightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _flightAnim = CurvedAnimation(parent: _flightCtrl, curve: Curves.easeInOutCubic);

    // 3. Ice break controller
    _iceBreakCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Run sequence
    _enterCtrl.forward().then((_) {
      if (!mounted) return;
      if (widget.isIceBreak) {
        // Run ice break sequence: frozen -> crack & shatter -> fire eruption
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          _iceBreakCtrl.forward().then((_) {
            if (!mounted) return;
            Future.delayed(const Duration(milliseconds: 900), () {
              if (!mounted) return;
              _computeTargetAndFly();
            });
          });
        });
      } else {
        // Normal celebration: pause and fly
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          _computeTargetAndFly();
        });
      }
    });
  }

  void _computeTargetAndFly() {
    final renderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      _targetCenter = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    } else {
      // Fallback: top right area
      final size = MediaQuery.of(context).size;
      _targetCenter = Offset(size.width - 90, 48);
    }

    setState(() => _isFlying = true);
    _flightCtrl.forward().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _flightCtrl.dispose();
    _emberCtrl.dispose();
    _iceBreakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height * 0.44);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dim backdrop during center presentation that fades out during flight
          AnimatedBuilder(
            animation: Listenable.merge([_enterCtrl, _flightCtrl]),
            builder: (context, _) {
              final bgOpacity = (_fadeInAnim.value * (1.0 - _flightAnim.value) * 0.55)
                  .clamp(0.0, 0.70);
              return Positioned.fill(
                child: IgnorePointer(
                  ignoring: _isFlying,
                  child: Container(
                    color: Colors.black.withValues(alpha: bgOpacity),
                  ),
                ),
              );
            },
          ),

          // Central flame card / flying flame
          AnimatedBuilder(
            animation: Listenable.merge([_enterCtrl, _flightCtrl, _emberCtrl, _iceBreakCtrl]),
            builder: (context, _) {
              Offset currentCenter = screenCenter;
              double currentScale = _scaleInAnim.value;
              double currentOpacity = _fadeInAnim.value;

              if (_isFlying && _targetCenter != null) {
                final t = _flightAnim.value;
                currentCenter = Offset(
                  lerpDouble(screenCenter.dx, _targetCenter!.dx, t)!,
                  lerpDouble(screenCenter.dy, _targetCenter!.dy, t)!,
                );
                // Shrink from ~1.0 down to header badge scale ~0.26
                currentScale = lerpDouble(1.0, 0.26, t)!;
              }

              final textOpacity = (1.0 - (_flightAnim.value * 2.5)).clamp(0.0, 1.0);

              // Ice break state computation
              final isCurrentlyFrozen = widget.isIceBreak && _iceBreakCtrl.value < 0.52;
              final iceShatterProgress = widget.isIceBreak
                  ? (_iceBreakCtrl.value >= 0.35 ? ((_iceBreakCtrl.value - 0.35) / 0.65) : 0.0)
                  : 0.0;

              return Positioned(
                left: currentCenter.dx - 130,
                top: currentCenter.dy - 145,
                width: 260,
                height: 290,
                child: Opacity(
                  opacity: currentOpacity,
                  child: Transform.scale(
                    scale: currentScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stack containing Vector Flame + Shattering Ice Shards + Eruption Flash
                        SizedBox(
                          width: 140,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Warm eruption flash when ice breaks
                              if (widget.isIceBreak && _iceBreakCtrl.value >= 0.45 && _iceBreakCtrl.value <= 0.85)
                                Opacity(
                                  opacity: (sin((_iceBreakCtrl.value - 0.45) / 0.40 * pi)).clamp(0.0, 1.0),
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Color(0xFFFFD54F),
                                          Color(0xFFFF7A29),
                                          Colors.transparent,
                                        ],
                                        stops: [0.0, 0.50, 1.0],
                                      ),
                                    ),
                                  ),
                                ),

                              // The Vector Flame (frozen or reignited)
                              CustomPaint(
                                size: const Size(140, 160),
                                painter: StreakFlamePainter(
                                  streakCount: widget.streakCount,
                                  emberPhase: _emberCtrl.value,
                                  showNumber: true,
                                  isFrozen: isCurrentlyFrozen,
                                ),
                              ),

                              // Flying Ice Shards during shatter phase
                              if (iceShatterProgress > 0.0 && iceShatterProgress < 1.0)
                                CustomPaint(
                                  size: const Size(140, 160),
                                  painter: _IceShatterPainter(progress: iceShatterProgress),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Label matching reference image / Ice break status
                        if (textOpacity > 0.05)
                          Opacity(
                            opacity: textOpacity,
                            child: Column(
                              children: [
                                Text(
                                  widget.isIceBreak
                                      ? (_iceBreakCtrl.value >= 0.52 ? 'STREAK REIGNITED!' : 'STREAK FROZEN')
                                      : (widget.streakCount == 1 ? 'DAY CONSISTENT' : 'DAYS CONSISTENT'),
                                  style: TextStyle(
                                    color: isCurrentlyFrozen ? const Color(0xFF80D8FF) : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.8,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCurrentlyFrozen
                                        ? const Color(0xFF00B0FF).withValues(alpha: 0.20)
                                        : const Color(0xFFFF9800).withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrentlyFrozen
                                          ? const Color(0xFF80D8FF).withValues(alpha: 0.60)
                                          : const Color(0xFFFFB74D).withValues(alpha: 0.60),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    widget.isIceBreak
                                        ? (_iceBreakCtrl.value >= 0.52
                                            ? 'Ice broken! New streak started.'
                                            : 'Breaking frozen streak...')
                                        : 'Daily Practice Active',
                                    style: TextStyle(
                                      color: isCurrentlyFrozen ? const Color(0xFFE0F7FA) : const Color(0xFFFFE082),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Dynamic ice shards flying radially outward when ice breaks
class _IceShatterPainter extends CustomPainter {
  final double progress; // 0.0 .. 1.0

  _IceShatterPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.55);

    // 8 distinct shards bursting out
    final shardAngles = [0.2, 0.9, 1.8, 2.5, 3.4, 4.2, 5.0, 5.8];
    final shardSizes = [10.0, 14.0, 9.0, 16.0, 11.0, 13.0, 8.0, 12.0];

    final shardPaint = Paint()
      ..color = const Color(0xFFE1F5FE).withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF00B0FF).withValues(alpha: (1.0 - progress).clamp(0.0, 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < shardAngles.length; i++) {
      final angle = shardAngles[i];
      final dist = (progress * 75.0) + 12.0;
      final shardCenter = Offset(
        center.dx + cos(angle) * dist,
        center.dy + sin(angle) * dist,
      );

      final s = shardSizes[i] * (1.0 - progress * 0.3);
      final shardPath = Path()
        ..moveTo(shardCenter.dx - s * 0.5, shardCenter.dy)
        ..lineTo(shardCenter.dx, shardCenter.dy - s * 0.7)
        ..lineTo(shardCenter.dx + s * 0.6, shardCenter.dy - s * 0.2)
        ..lineTo(shardCenter.dx + s * 0.3, shardCenter.dy + s * 0.6)
        ..lineTo(shardCenter.dx - s * 0.4, shardCenter.dy + s * 0.4)
        ..close();

      canvas.drawPath(shardPath, shardPaint);
      canvas.drawPath(shardPath, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IceShatterPainter old) => old.progress != progress;
}
