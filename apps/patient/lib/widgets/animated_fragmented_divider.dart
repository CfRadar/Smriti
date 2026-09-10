import 'package:flutter/material.dart';

class AnimatedFragmentedDivider extends StatefulWidget {
  const AnimatedFragmentedDivider({super.key});

  @override
  State<AnimatedFragmentedDivider> createState() =>
      _AnimatedFragmentedDividerState();
}

class _AnimatedFragmentedDividerState extends State<AnimatedFragmentedDivider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3360),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRect(
          child: Container(
            width: double.infinity,
            height: 12,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: CustomPaint(
              size: const Size(double.infinity, 4),
              painter: _FragmentedLinePainter(
                progress: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FragmentedLinePainter extends CustomPainter {
  final double progress;

  _FragmentedLinePainter({required this.progress});

  static const Color peachColor = Color(0xFFFFAB91);
  static const Color orangeColor = Color(0xFFFF7043);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double lineThickness = height.clamp(3.0, 4.0);

    // Each dash is 80% of the screen width, gap is 20% to give breathing room
    final double dashWidth = width * 0.80;
    final double dashGap = width * 0.20;
    final double period = dashWidth + dashGap;

    final Paint peachPaint = Paint()
      ..color = peachColor
      ..style = PaintingStyle.fill;

    final Paint orangePaint = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.fill;

    // Alternate between peach and orange, shifting left to right
    final double shift = progress * period;
    double x = -period + shift;

    int index = 0;
    while (x < width + period) {
      final bool isPeach = (index % 2 == 0);
      final Paint paint = isPeach ? peachPaint : orangePaint;

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          (height - lineThickness) / 2,
          dashWidth,
          lineThickness,
        ),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(rrect, paint);

      x += dashWidth + dashGap;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _FragmentedLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
