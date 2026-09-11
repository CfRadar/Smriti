// lib/pages/caregiver/caregiver_analytics_tab.dart

import 'package:flutter/material.dart';
import '../../models/caregiver_models.dart';
import '../../services/caregiver_api_service.dart';
import '../../services/locale_service.dart';

class CaregiverAnalyticsTab extends StatefulWidget {
  const CaregiverAnalyticsTab({super.key});
  @override
  State<CaregiverAnalyticsTab> createState() =>
      _CaregiverAnalyticsTabState();
}

class _CaregiverAnalyticsTabState extends State<CaregiverAnalyticsTab> {
  static const Color _green = Color(0xFF214E3B);
  static const Color _muted = Color(0xFF6B7F74);

  AnalyticsSummary? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pid = await CaregiverApiService.instance.savedPatientId;
    if (pid != null) {
      _analytics = await CaregiverApiService.instance.fetchAnalytics(pid);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF214E3B)));
    }
    if (_analytics == null || (_analytics!.sevenDayTrend.isEmpty &&
        _analytics!.gameTypeBreakdown.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_rounded, size: 52, color: _muted),
            const SizedBox(height: 12),
            Text(context.tr('caregiver.noAnalytics'),
                style: const TextStyle(color: _muted, fontSize: 15)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('common.retry')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 7-day trend ─────────────────────────────────────────────────────
          if (_analytics!.sevenDayTrend.isNotEmpty) ...[
            _SectionHeader(title: context.tr('caregiver.sevenDayTrend')),
            const SizedBox(height: 12),
            Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: _TrendChart(
                  points: _analytics!.sevenDayTrend),
            ),
            const SizedBox(height: 8),
            // Legend
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: Color(0xFF214E3B), label: 'Cognitive'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFF4A7C59), label: 'Memory'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFF5F8FA3), label: 'Speech'),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // ── Game type breakdown ──────────────────────────────────────────────
          if (_analytics!.gameTypeBreakdown.isNotEmpty) ...[
            _SectionHeader(title: context.tr('caregiver.gameBreakdown')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: _analytics!.gameTypeBreakdown
                    .map((g) => _GameBar(item: g))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: Color(0xFF214E3B),
            fontSize: 15,
            fontWeight: FontWeight.w700));
  }
}

// ── Legend Dot ─────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7F74))),
      ],
    );
  }
}

// ── Trend Chart (CustomPainter, no external lib) ───────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});
  final List<TrendPoint> points;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.points);
  final List<TrendPoint> points;

  static const Color cogColor = Color(0xFF214E3B);
  static const Color memColor = Color(0xFF4A7C59);
  static const Color spColor = Color(0xFF5F8FA3);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final n = points.length;
    final w = size.width;
    final h = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = h * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    void drawLine(List<double> values, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final x = n == 1 ? w / 2 : i * w / (n - 1);
        final y = h * (1 - (values[i] / 100).clamp(0.0, 1.0));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);

      // Dots
      final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
      for (int i = 0; i < values.length; i++) {
        final x = n == 1 ? w / 2 : i * w / (n - 1);
        final y = h * (1 - (values[i] / 100).clamp(0.0, 1.0));
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
        canvas.drawCircle(
            Offset(x, y), 4, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke);
      }
    }

    drawLine(points.map((p) => p.cognitiveScore).toList(), cogColor);
    drawLine(points.map((p) => p.memoryRecallScore).toList(), memColor);
    drawLine(points.map((p) => p.speechFluencyScore).toList(), spColor);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.points != points;
}

// ── Game Bar ───────────────────────────────────────────────────────────────────

class _GameBar extends StatelessWidget {
  const _GameBar({required this.item});
  final GameTypeBreakdown item;

  static const List<Color> _colors = [
    Color(0xFF214E3B),
    Color(0xFF4A7C59),
    Color(0xFF5F8FA3),
    Color(0xFFB5651D),
    Color(0xFF7A6E9A),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = item.gameType.hashCode.abs() % _colors.length;
    final color = _colors[idx];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              item.gameType,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (item.avgScore / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.count}x',
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
