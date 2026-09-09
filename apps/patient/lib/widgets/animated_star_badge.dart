import 'dart:math';
import 'package:flutter/material.dart';

/// A star icon that can animate a bottom-to-top fill, and launch
/// particles from a source screen position toward itself.
class AnimatedStarBadge extends StatefulWidget {
  const AnimatedStarBadge({super.key});

  // Call this static helper to trigger the celebration from outside.
  static final GlobalKey<AnimatedStarBadgeState> globalKey =
      GlobalKey<AnimatedStarBadgeState>();

  @override
  AnimatedStarBadgeState createState() => AnimatedStarBadgeState();
}

class AnimatedStarBadgeState extends State<AnimatedStarBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fillAnim;

  // Particles
  final List<_Particle> _particles = [];
  OverlayEntry? _overlayEntry;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fillAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  /// Call with the global position of the tick button to launch celebration.
  void celebrate(Offset sourceGlobal) {
    if (_filled) return;
    _filled = true;

    // Get our own position for particles to target.
    final RenderBox? box =
        context.findRenderObject() as RenderBox?;
    final Offset starGlobal = box != null
        ? box.localToGlobal(box.size.center(Offset.zero))
        : sourceGlobal;

    _spawnParticleOverlay(sourceGlobal, starGlobal);
    _controller.forward(from: 0).then((_) {
      // Keep filled briefly, then gently fade back to empty star.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _controller.reverse().then((_) {
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
      ..addAll(List.generate(18, (_) => _Particle(from, to, random)));

    _overlayEntry = OverlayEntry(builder: (_) => _ParticleOverlay(
      particles: _particles,
      onDone: () {
        _overlayEntry?.remove();
        _overlayEntry = null;
      },
    ));
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: AnimatedBuilder(
        animation: _fillAnim,
        builder: (_, __) {
          return CustomPaint(
            painter: _StarPainter(fill: _fillAnim.value),
          );
        },
      ),
    );
  }
}

// ─── Star painter ─────────────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  final double fill; // 0..1

  const _StarPainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    final path = _starPath(center, radius, radius * 0.45, 5);

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFAB91)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    if (fill > 0) {
      // Clip fill from bottom to top
      canvas.save();
      final fillHeight = size.height * fill;
      canvas.clipRect(Rect.fromLTWH(
        0,
        size.height - fillHeight,
        size.width,
        fillHeight,
      ));
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFFF7043), Color(0xFFFFAB91)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  Path _starPath(Offset center, double outerR, double innerR, int points) {
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
  bool shouldRepaint(covariant _StarPainter old) => old.fill != fill;
}

// ─── Particle model ───────────────────────────────────────────────────────────

class _Particle {
  final Offset start;
  final Offset end;
  final Color color;
  final double size;
  final double angle; // drift
  final double speed; // 0.7..1.3 multiplier

  _Particle(Offset from, Offset to, Random rnd)
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
          const Color(0xFFFF7043),
          const Color(0xFFFFAB91),
          const Color(0xFFFFD54F),
          const Color(0xFFF48FB1),
        ][rnd.nextInt(4)],
        size = 4 + rnd.nextDouble() * 5,
        angle = (rnd.nextDouble() - 0.5) * 0.6,
        speed = 0.65 + rnd.nextDouble() * 0.7;
}

// ─── Particle overlay ─────────────────────────────────────────────────────────

class _ParticleOverlay extends StatefulWidget {
  final List<_Particle> particles;
  final VoidCallback onDone;
  const _ParticleOverlay({required this.particles, required this.onDone});

  @override
  State<_ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<_ParticleOverlay>
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
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
