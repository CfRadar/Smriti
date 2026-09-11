import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/folklore_story.dart';

/// Minimalist visual configuration and ambient particle engine for each folklore story.
/// Aligned strictly with the app's calm, clean, minimalist design system:
/// Canvas: Color(0xFFF6F1E7), Navy: Color(0xFF1E3A5F), Sage: Color(0xFF4C8D73).
class FolkloreStoryTheme {
  const FolkloreStoryTheme({
    required this.storyKey,
    required this.displayName,
    required this.region,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.glowColor,
    required this.icon,
    required this.particleType,
    required this.readingMinutes,
  });

  final String storyKey;
  final String displayName;
  final String region;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color glowColor;
  final IconData icon;
  final FolkloreParticleType particleType;
  final int readingMinutes;

  /// Universal app canvas color (minimalist cream paper)
  static const Color canvasColor = Color(0xFFF6F1E7);
  static const Color darkNavy = Color(0xFF1E3A5F);
  static const Color softSlate = Color(0xFF536A7B);
  static const Color sageGreen = Color(0xFF4C8D73);
  static const Color paleGreen = Color(0xFFE5F2EB);
  static const Color cardBorder = Color(0xFFDEE7E1);

  /// Default theme
  static const FolkloreStoryTheme fallback = FolkloreStoryTheme(
    storyKey: 'default',
    displayName: 'All Tales',
    region: 'Northeast India',
    primaryColor: darkNavy,
    secondaryColor: sageGreen,
    accentColor: Color(0xFF7A9E8D),
    glowColor: Color(0x1F1E3A5F),
    icon: Icons.auto_stories_rounded,
    particleType: FolkloreParticleType.genericPetals,
    readingMinutes: 4,
  );

  /// Tailored theme for each story, keeping colors harmonious and minimalist
  static FolkloreStoryTheme forStory(FolkloreStory story) {
    return forKey(story.title);
  }

  static FolkloreStoryTheme forKey(String key) {
    final upper = key.toUpperCase();
    if (upper.contains('KHAMBA') || upper.contains('THOIBI') || upper.contains('MANIPUR')) {
      return const FolkloreStoryTheme(
        storyKey: 'khamba',
        displayName: 'Khamba & Thoibi',
        region: 'Manipur',
        primaryColor: darkNavy,
        secondaryColor: sageGreen,
        accentColor: Color(0xFF8C7382),
        glowColor: Color(0x1F1E3A5F),
        icon: Icons.favorite_rounded,
        particleType: FolkloreParticleType.lotusPetals,
        readingMinutes: 4,
      );
    }
    if (upper.contains('THLEN') || upper.contains('KHASI') || upper.contains('MEGHALAYA')) {
      return const FolkloreStoryTheme(
        storyKey: 'thlen',
        displayName: 'U Thlen',
        region: 'Meghalaya',
        primaryColor: darkNavy,
        secondaryColor: sageGreen,
        accentColor: Color(0xFF4C8D73),
        glowColor: Color(0x1F1E3A5F),
        icon: Icons.water_drop_rounded,
        particleType: FolkloreParticleType.mountainMist,
        readingMinutes: 5,
      );
    }
    if (upper.contains('HUNCHIBILI') || upper.contains('ANGAMI') || upper.contains('NAGA')) {
      return const FolkloreStoryTheme(
        storyKey: 'hunchibili',
        displayName: 'Hunchibili',
        region: 'Nagaland',
        primaryColor: darkNavy,
        secondaryColor: sageGreen,
        accentColor: Color(0xFFB58D54),
        glowColor: Color(0x1F1E3A5F),
        icon: Icons.wb_sunny_rounded,
        particleType: FolkloreParticleType.goldenMotes,
        readingMinutes: 4,
      );
    }
    if (upper.contains('ORPHAN') || upper.contains('GIANT') || upper.contains('KARBI')) {
      return const FolkloreStoryTheme(
        storyKey: 'orphan',
        displayName: 'Orphan & Giant',
        region: 'Assam',
        primaryColor: darkNavy,
        secondaryColor: sageGreen,
        accentColor: Color(0xFF5D7A99),
        glowColor: Color(0x1F1E3A5F),
        icon: Icons.stars_rounded,
        particleType: FolkloreParticleType.starlightEmbers,
        readingMinutes: 5,
      );
    }

    return fallback;
  }
}

enum FolkloreParticleType {
  lotusPetals,
  mountainMist,
  goldenMotes,
  starlightEmbers,
  genericPetals,
}

/// Subtle, whisper-soft ambient background animation for each story tab.
/// Renders at low opacity (0.04 - 0.12) against the clean minimalist canvas.
class StoryAmbientBackground extends StatefulWidget {
  const StoryAmbientBackground({
    super.key,
    required this.theme,
    this.child,
  });

  final FolkloreStoryTheme theme;
  final Widget? child;

  @override
  State<StoryAmbientBackground> createState() => _StoryAmbientBackgroundState();
}

class _StoryAmbientBackgroundState extends State<StoryAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_StoryParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _particles = List.generate(18, (i) => _StoryParticle(i));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FolkloreStoryTheme.canvasColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _MinimalistAmbientPainter(
                  progress: _controller.value,
                  theme: widget.theme,
                  particles: _particles,
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _StoryParticle {
  _StoryParticle(this.index) {
    final rand = math.Random(index * 997 + 13);
    x = rand.nextDouble();
    y = rand.nextDouble();
    speed = 0.25 + rand.nextDouble() * 0.45;
    size = 5.0 + rand.nextDouble() * 8.0;
    phase = rand.nextDouble() * math.pi * 2;
    rotation = rand.nextDouble() * math.pi;
    alpha = 0.08 + rand.nextDouble() * 0.14; // Ultra-subtle, minimalist opacity
  }

  final int index;
  late double x;
  late double y;
  late double speed;
  late double size;
  late double phase;
  late double rotation;
  late double alpha;
}

class _MinimalistAmbientPainter extends CustomPainter {
  _MinimalistAmbientPainter({
    required this.progress,
    required this.theme,
    required this.particles,
  });

  final double progress;
  final FolkloreStoryTheme theme;
  final List<_StoryParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme.particleType) {
      case FolkloreParticleType.lotusPetals:
        _paintLotusPetals(canvas, size);
        break;
      case FolkloreParticleType.mountainMist:
        _paintMountainMist(canvas, size);
        break;
      case FolkloreParticleType.goldenMotes:
        _paintGoldenMotes(canvas, size);
        break;
      case FolkloreParticleType.starlightEmbers:
        _paintStarlightEmbers(canvas, size);
        break;
      case FolkloreParticleType.genericPetals:
        _paintGenericPetals(canvas, size);
        break;
    }
  }

  /// Khamba & Thoibi: Subtle, quiet water ripple outlines and delicate petal outlines
  void _paintLotusPetals(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 2 subtle ripples near the bottom
    for (int r = 0; r < 2; r++) {
      final ringProgress = (progress + (r * 0.5)) % 1.0;
      final radius = 50.0 + ringProgress * (size.width * 0.4);
      final alpha = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.07;
      strokePaint.color = theme.primaryColor.withValues(alpha: alpha);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * (0.35 + r * 0.3), size.height * 0.8),
          width: radius * 1.8,
          height: radius * 0.4,
        ),
        strokePaint,
      );
    }

    // Subtle drifting petal outlines
    final fillPaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final curY = (p.y - progress * p.speed * 0.18) % 1.0;
      final px = p.x * size.width + math.sin(progress * math.pi * 2 + p.phase) * 14;
      final py = curY * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + progress * 0.6);

      final petalPath = Path();
      petalPath.moveTo(0, -p.size);
      petalPath.quadraticBezierTo(p.size * 0.5, 0, 0, p.size * 0.9);
      petalPath.quadraticBezierTo(-p.size * 0.5, 0, 0, -p.size);

      fillPaint.color = theme.primaryColor.withValues(alpha: p.alpha * 0.5);
      canvas.drawPath(petalPath, fillPaint);
      canvas.restore();
    }
  }

  /// U Thlen: Gentle translucent mist wisps and quiet droplets
  void _paintMountainMist(Canvas canvas, Size size) {
    final mistPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final mistX = ((progress * 0.1 + (i * 0.33)) % 1.0) * (size.width + 160) - 80;
      final mistY = size.height * (0.25 + i * 0.25);
      mistPaint.color = Colors.white.withValues(alpha: 0.18);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mistX, mistY),
          width: 200 + i * 40,
          height: 50 + i * 12,
        ),
        mistPaint,
      );
    }

    final dropPaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final curY = (p.y + progress * p.speed * 0.2) % 1.0;
      final px = p.x * size.width;
      final py = curY * size.height;

      dropPaint.color = theme.secondaryColor.withValues(alpha: p.alpha * 0.6);
      canvas.drawCircle(Offset(px, py), p.size * 0.3, dropPaint);
    }
  }

  /// Hunchibili: Soft sunbeam motes / delicate warm dust specks
  void _paintGoldenMotes(Canvas canvas, Size size) {
    final motePaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final curY = (p.y - progress * p.speed * 0.15) % 1.0;
      final curX = (p.x + math.sin(progress * math.pi * 2 + p.phase) * 0.03) % 1.0;
      final px = curX * size.width;
      final py = curY * size.height;

      final pulse = (0.6 + 0.4 * math.sin(progress * 4.0 + p.phase));
      motePaint.color = const Color(0xFFC49A45).withValues(alpha: p.alpha * 0.5 * pulse);
      canvas.drawCircle(Offset(px, py), p.size * 0.35, motePaint);
    }
  }

  /// Orphan & Giant: Delicate starlight specks
  void _paintStarlightEmbers(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final twinkle = (0.4 + 0.6 * math.sin(progress * 5.0 + p.phase)).abs();
      final px = p.x * size.width;
      final py = p.y * size.height;

      starPaint.color = theme.primaryColor.withValues(alpha: p.alpha * 0.45 * twinkle);
      canvas.drawCircle(Offset(px, py), p.size * 0.3, starPaint);
    }
  }

  /// Generic soft ambient motes
  void _paintGenericPetals(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final curY = (p.y - progress * p.speed * 0.15) % 1.0;
      final px = p.x * size.width;
      final py = curY * size.height;

      paint.color = theme.primaryColor.withValues(alpha: p.alpha * 0.35);
      canvas.drawCircle(Offset(px, py), p.size * 0.25, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinimalistAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
