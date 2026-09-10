import 'dart:math';
import 'package:flutter/material.dart';

/// A solid golden star icon that emits continuous upward sparkling trails
/// when there is an active/unseen reminder (stopping when seen/acknowledged),
/// and launches celebration particles toward itself when a reminder is ticked.
class AnimatedStarBadge extends StatefulWidget {
  final bool hasActiveReminder;
  final VoidCallback? onTap;

  const AnimatedStarBadge({
    super.key,
    this.hasActiveReminder = false,
    this.onTap,
  });

  // GlobalKey helper for backward compatibility
  static final GlobalKey<AnimatedStarBadgeState> globalKey =
      GlobalKey<AnimatedStarBadgeState>();

  @override
  AnimatedStarBadgeState createState() => AnimatedStarBadgeState();
}

class AnimatedStarBadgeState extends State<AnimatedStarBadge>
    with TickerProviderStateMixin {
  late final AnimationController _celebrateController;
  late final Animation<double> _fillAnim;
  late final AnimationController _trailController;

  // Celebration particles
  final List<_CelebrationParticle> _particles = [];
  OverlayEntry? _overlayEntry;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fillAnim = CurvedAnimation(parent: _celebrateController, curve: Curves.easeOut);

    // Continuous loop for upward-rising sparkle trails
    _trailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _celebrateController.dispose();
    _trailController.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  /// Call with the global position of the tick button to launch celebration.
  void celebrate(Offset sourceGlobal) {
    if (_filled) return;
    _filled = true;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Offset starGlobal = box != null && box.hasSize
        ? box.localToGlobal(box.size.center(Offset.zero))
        : sourceGlobal;

    _spawnParticleOverlay(sourceGlobal, starGlobal);
    _celebrateController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) {
          _celebrateController.reverse().then((_) {
            if (mounted) setState(() => _filled = false);
          });
        }
      });
    });
  }

  void _spawnParticleOverlay(Offset from, Offset to) {
    final random = Random();
    _particles
      ..clear()
      ..addAll(List.generate(18, (_) => _CelebrationParticle(from, to, random)));

    _overlayEntry = OverlayEntry(
      builder: (_) => _CelebrationParticleOverlay(
        particles: _particles,
        onDone: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.hasActiveReminder ? 'Reminders available' : 'Star badge',
      child: Tooltip(
        message: widget.hasActiveReminder ? 'View Reminders' : 'Star',
        child: InkResponse(
          onTap: widget.onTap,
          radius: 22,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_celebrateController, _trailController]),
                builder: (_, __) {
                  return CustomPaint(
                    size: const Size(32, 32),
                    painter: _SolidStarPainter(
                      hasActiveReminder: widget.hasActiveReminder,
                      trailProgress: _trailController.value,
                      celebrationFill: _fillAnim.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Solid Star & Trails Painter ─────────────────────────────────────────────

class _SolidStarPainter extends CustomPainter {
  final bool hasActiveReminder;
  final double trailProgress; // 0..1 loop
  final double celebrationFill;

  const _SolidStarPainter({
    required this.hasActiveReminder,
    required this.trailProgress,
    required this.celebrationFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 1.0);
    final outerRadius = size.width * 0.44;
    final innerRadius = outerRadius * 0.45;
    final starPath = _buildStarPath(center, outerRadius, innerRadius, 5);

    // 1. Draw rising sparkle trails up above when there is an active reminder
    if (hasActiveReminder) {
      _drawUpwardTrails(canvas, center, size);
    }

    // 2. Ambient soft glow shadow behind the star
    canvas.drawPath(
      starPath,
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: hasActiveReminder ? 0.45 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // 3. Solid Star Fill: rich vibrant gold / amber gradient
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFD54F), // Radiant gold top
          Color(0xFFFFB300), // Amber mid
          Color(0xFFFFA000), // Deep warm gold bottom
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, fillPaint);

    // 4. Crisp subtle outline
    final strokePaint = Paint()
      ..color = const Color(0xFFFF8F00).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(starPath, strokePaint);

    // 5. Specular highlight facet on top point
    final highlightPath = Path()
      ..moveTo(center.dx, center.dy - outerRadius)
      ..lineTo(center.dx + innerRadius * 0.5, center.dy - innerRadius * 0.6)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawUpwardTrails(Canvas canvas, Offset center, Size size) {
    // Generates 4 sparkling stardust particles drifting up above the star
    final trailConfigs = [
      {'startX': center.dx - 5.0, 'startY': center.dy - 10.0, 'drift': -7.0, 'size': 2.8},
      {'startX': center.dx + 0.0, 'startY': center.dy - 12.0, 'drift': 2.0, 'size': 3.4},
      {'startX': center.dx + 5.0, 'startY': center.dy - 9.0, 'drift': 6.0, 'size': 2.5},
      {'startX': center.dx - 2.0, 'startY': center.dy - 11.0, 'drift': -4.0, 'size': 3.0},
    ];

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < trailConfigs.length; i++) {
      final cfg = trailConfigs[i];
      final p = (trailProgress + (i * 0.25)) % 1.0;
      final y = (cfg['startY'] as double) - (p * 18.0); // Rises ~18px above the star
      final x = (cfg['startX'] as double) + sin(p * 2 * pi) * (cfg['drift'] as double);
      final opacity = (sin(p * pi)).clamp(0.0, 1.0);
      final r = (cfg['size'] as double) * (1.0 - (p * 0.4));

      // Golden sparkle color fading out
      paint.color = const Color(0xFFFFD54F).withValues(alpha: opacity * 0.95);
      canvas.drawCircle(Offset(x, y), r, paint);

      // Tiny cross shimmer on larger particle
      if (r > 2.2 && opacity > 0.4) {
        final shimmerPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.85)
          ..strokeWidth = 0.8;
        canvas.drawLine(Offset(x - r * 1.3, y), Offset(x + r * 1.3, y), shimmerPaint);
        canvas.drawLine(Offset(x, y - r * 1.3), Offset(x, y + r * 1.3), shimmerPaint);
      }
    }
  }

  Path _buildStarPath(Offset center, double outerR, double innerR, int points) {
    final path = Path();
    final step = pi / points;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = i * step - pi / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SolidStarPainter old) {
    return old.hasActiveReminder != hasActiveReminder ||
        old.trailProgress != trailProgress ||
        old.celebrationFill != celebrationFill;
  }
}

// ─── Celebration Particles ───────────────────────────────────────────────────

class _CelebrationParticle {
  final Offset start;
  final Offset end;
  final Color color;
  final double size;
  final double angle;
  final double speed;

  _CelebrationParticle(Offset from, Offset to, Random rnd)
      : start = from +
            Offset(
              (rnd.nextDouble() - 0.5) * 20,
              (rnd.nextDouble() - 0.5) * 20,
            ),
        end = to +
            Offset(
              (rnd.nextDouble() - 0.5) * 14,
              (rnd.nextDouble() - 0.5) * 14,
            ),
        color = [
          const Color(0xFFFFB300),
          const Color(0xFFFFD54F),
          const Color(0xFFFF8F00),
          const Color(0xFF81C784),
        ][rnd.nextInt(4)],
        size = 4 + rnd.nextDouble() * 5,
        angle = (rnd.nextDouble() - 0.5) * 0.6,
        speed = 0.65 + rnd.nextDouble() * 0.7;
}

class _CelebrationParticleOverlay extends StatefulWidget {
  final List<_CelebrationParticle> particles;
  final VoidCallback onDone;

  const _CelebrationParticleOverlay({required this.particles, required this.onDone});

  @override
  State<_CelebrationParticleOverlay> createState() =>
      _CelebrationParticleOverlayState();
}

class _CelebrationParticleOverlayState extends State<_CelebrationParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return IgnorePointer(
          child: Stack(
            children: widget.particles.map((p) {
              final t = (_ctrl.value / p.speed).clamp(0.0, 1.0);
              final ease = Curves.easeOut.transform(t);
              final x = lerpDouble(p.start.dx, p.end.dx, ease)!;
              final y = lerpDouble(p.start.dy, p.end.dy, ease)!;
              final opacity = (1 - t).clamp(0.0, 1.0);
              return Positioned(
                left: x - p.size / 2,
                top: y - p.size / 2,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: p.angle + _ctrl.value * 3,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
