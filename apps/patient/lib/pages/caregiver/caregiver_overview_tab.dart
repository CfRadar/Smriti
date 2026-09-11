// lib/pages/caregiver/caregiver_overview_tab.dart

import 'package:flutter/material.dart';
import '../../models/caregiver_models.dart';
import '../../services/caregiver_api_service.dart';
import '../../services/locale_service.dart';

class CaregiverOverviewTab extends StatefulWidget {
  const CaregiverOverviewTab({super.key});
  @override
  State<CaregiverOverviewTab> createState() => _CaregiverOverviewTabState();
}

class _CaregiverOverviewTabState extends State<CaregiverOverviewTab> {
  static const Color _green = Color(0xFF214E3B);
  static const Color _accent = Color(0xFF5F866D);
  static const Color _lightGreen = Color(0xFFDCE8DA);
  static const Color _muted = Color(0xFF6B7F74);

  AnalyticsSummary? _analytics;
  bool _loading = true;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _patientId = await CaregiverApiService.instance.savedPatientId;
    if (_patientId != null) {
      _analytics =
          await CaregiverApiService.instance.fetchAnalytics(_patientId!);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF214E3B)));
    }
    if (_analytics == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: _muted),
            const SizedBox(height: 12),
            Text(context.tr('caregiver.couldNotLoad'),
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

    final a = _analytics!;
    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Patient summary card ───────────────────────────────────────────
          _SectionCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: _lightGreen,
                  child: Icon(Icons.person_rounded,
                      color: Color(0xFF214E3B), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('caregiver.patientOverview'),
                          style: const TextStyle(
                              color: _green,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('ID: ${_patientId ?? "—"}',
                          style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  color: _accent,
                  onPressed: _load,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Adherence + sessions ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Adherence',
                  value: '${a.adherenceRate}%',
                  color: _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.sports_esports_outlined,
                  label: 'Sessions',
                  value: '${a.totalSessions}',
                  color: const Color(0xFF4A7C59),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Pending',
                  value: '${a.pendingReminders}',
                  color: const Color(0xFFB5651D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.task_alt_rounded,
                  label: 'Done',
                  value: '${a.acknowledgedReminders}',
                  color: const Color(0xFF2E7D55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Cognitive scores ───────────────────────────────────────────────
          Text(context.tr('caregiver.cognitiveScores'),
              style: const TextStyle(
                  color: _green,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              children: [
                _ScoreRow(
                    label: 'Cognitive',
                    score: a.avgCognitiveScore,
                    color: _green),
                const Divider(height: 20),
                _ScoreRow(
                    label: 'Memory Recall',
                    score: a.avgMemoryRecallScore,
                    color: const Color(0xFF4A7C59)),
                const Divider(height: 20),
                _ScoreRow(
                    label: 'Speech Fluency',
                    score: a.avgSpeechFluencyScore,
                    color: const Color(0xFF5F8FA3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(
      {required this.label, required this.score, required this.color});
  final String label;
  final int? score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (score ?? 0) / 100.0;
    return Row(
      children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(score != null ? '$score' : '–',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    );
  }
}
