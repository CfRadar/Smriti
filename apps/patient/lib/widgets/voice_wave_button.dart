import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/voice_service.dart';

class VoiceWaveButton extends StatefulWidget {
  const VoiceWaveButton({super.key});

  @override
  State<VoiceWaveButton> createState() => _VoiceWaveButtonState();
}

class _VoiceWaveButtonState extends State<VoiceWaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    VoiceService.instance.statusNotifier.addListener(_onVoiceStatusChanged);
    _syncAnimationState(VoiceService.instance.statusNotifier.value);
  }

  void _onVoiceStatusChanged() {
    if (!mounted) return;
    _syncAnimationState(VoiceService.instance.statusNotifier.value);
    setState(() {});
  }

  void _syncAnimationState(VoiceStatus status) {
    final isListening =
        status == VoiceStatus.listening || status == VoiceStatus.processing;
    if (isListening) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    VoiceService.instance.statusNotifier.removeListener(_onVoiceStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap(bool isListening) async {
    if (!VoiceService.instance.isEnabled) {
      await VoiceService.instance.setEnabled(true);
      return;
    }
    if (isListening) {
      await VoiceService.instance.setEnabled(false);
    } else {
      await VoiceService.instance.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VoiceStatus>(
      valueListenable: VoiceService.instance.statusNotifier,
      builder: (context, status, _) {
        final isListening =
            status == VoiceStatus.listening || status == VoiceStatus.processing;
        final isDisabled =
            !VoiceService.instance.isEnabled || status == VoiceStatus.disabled;

        return Semantics(
          button: true,
          label: isDisabled
              ? 'Voice Assistant deactivated. Tap to activate.'
              : (isListening
                  ? 'Voice listening active. Tap to deactivate.'
                  : 'Voice idle. Tap to speak.'),
          child: Tooltip(
            message: isDisabled
                ? 'Voice deactivated (Tap to activate)'
                : (isListening
                    ? 'Listening... (Tap to deactivate)'
                    : 'Voice idle (Tap to speak)'),
            child: InkWell(
              onTap: () => _handleTap(isListening),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isListening
                      ? const Color(0xFFE0F2FE)
                      : (isDisabled
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isListening
                        ? const Color(0xFF38BDF8)
                        : (isDisabled
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFCBD5E1)),
                    width: 1.5,
                  ),
                  boxShadow: isListening
                      ? [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.5),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isListening)
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(44, 44),
                              painter: _WaveFillPainter(
                                animationValue: _controller.value,
                                waveColor1: const Color(0xFF38BDF8),
                                waveColor2: const Color(0xFF0284C7),
                              ),
                            );
                          },
                        ),
                      Icon(
                        isListening
                            ? Icons.mic_rounded
                            : (isDisabled ? Icons.mic_off_rounded : Icons.mic_none_rounded),
                        color: isListening
                            ? Colors.white
                            : (isDisabled ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8)),
                        size: 22,
                        shadows: isListening
                            ? const [
                                Shadow(
                                  color: Color(0xFF0369A1),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ],
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

class _WaveFillPainter extends CustomPainter {
  final double animationValue;
  final Color waveColor1;
  final Color waveColor2;

  _WaveFillPainter({
    required this.animationValue,
    required this.waveColor1,
    required this.waveColor2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Fill level: oscillates smoothly around 70% of the box
    final fillLevel =
        height * (0.70 + 0.05 * math.sin(animationValue * 2 * math.pi));
    final waterY = height - fillLevel;

    // 1. Back wave (lighter, secondary phase)
    final backPaint = Paint()
      ..color = waveColor1.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, height);
    backPath.lineTo(0, waterY);

    for (double x = 0; x <= width; x++) {
      final y = waterY +
          3.5 *
              math.sin(
                  (x / width * 2 * math.pi) + (animationValue * 2 * math.pi));
      backPath.lineTo(x, y);
    }
    backPath.lineTo(width, height);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // 2. Front wave (gradient, primary phase)
    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [waveColor1, waveColor2],
      ).createShader(
          Rect.fromLTWH(0, waterY - 4, width, height - waterY + 4))
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    frontPath.moveTo(0, height);
    frontPath.lineTo(0, waterY);

    for (double x = 0; x <= width; x++) {
      final y = waterY +
          4.0 *
              math.sin((x / width * 2 * math.pi) -
                  (animationValue * 2 * math.pi) +
                  math.pi / 2);
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(width, height);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveFillPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
