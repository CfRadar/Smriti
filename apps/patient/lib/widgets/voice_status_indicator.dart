import 'package:flutter/material.dart';

import '../services/voice_service.dart';

class VoiceStatusIndicator extends StatelessWidget {
  const VoiceStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VoiceStatus>(
      valueListenable: VoiceService.instance.statusNotifier,
      builder: (context, status, _) {
        final data = _statusData(status);

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(data.icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      data.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _StatusData _statusData(VoiceStatus status) {
    switch (status) {
      case VoiceStatus.initializing:
        return _StatusData('Initializing voice', Icons.mic_none_rounded, Colors.orange.shade700);
      case VoiceStatus.listening:
        return _StatusData('Voice active', Icons.mic_rounded, Colors.green.shade700);
      case VoiceStatus.processing:
        return _StatusData('Processing command', Icons.record_voice_over_rounded, Colors.indigo.shade700);
      case VoiceStatus.error:
        return _StatusData('Voice unavailable', Icons.error_outline_rounded, Colors.red.shade700);
      case VoiceStatus.disabled:
        return _StatusData('Voice disabled', Icons.mic_off_rounded, Colors.grey.shade700);
    }
  }
}

class _StatusData {
  const _StatusData(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
