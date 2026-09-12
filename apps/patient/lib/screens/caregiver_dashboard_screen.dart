// lib/screens/caregiver_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../pages/caregiver/caregiver_overview_tab.dart';
import '../pages/caregiver/caregiver_reminders_tab.dart';
import '../pages/caregiver/caregiver_memories_tab.dart';
import '../pages/caregiver/caregiver_analytics_tab.dart';
import '../services/caregiver_api_service.dart';
import '../services/locale_service.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  static const Color _green = Color(0xFF214E3B);
  static const Color _accent = Color(0xFF5F866D);
  static const Color _ivory = Color(0xFFF8F5EC);

  int _tabIndex = 0;



  final List<Widget> _pages = const [
    CaregiverOverviewTab(),
    CaregiverRemindersTab(),
    CaregiverMemoriesTab(),
    CaregiverAnalyticsTab(),
  ];

  @override
  void initState() {
    super.initState();
    LocaleService.instance.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LocaleService.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('common.logout')),
        content: Text(context.tr('caregiver.logoutConfirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('common.cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('common.logout'),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await CaregiverApiService.instance.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabItem(icon: Icons.dashboard_rounded, label: context.tr('caregiver.overview')),
      _TabItem(icon: Icons.notifications_rounded, label: context.tr('caregiver.reminders')),
      _TabItem(icon: Icons.photo_library_rounded, label: context.tr('caregiver.memories')),
      _TabItem(icon: Icons.bar_chart_rounded, label: context.tr('caregiver.analytics')),
    ];

    return Scaffold(
      backgroundColor: _ivory,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: _ivory,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              context.tr('caregiver.portal'),
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF8F5EC)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: context.tr('common.logout'),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final active = _tabIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _tabIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? _green.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          color: active ? _green : const Color(0xFF9AAFA3),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active
                                ? _green
                                : const Color(0xFF9AAFA3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
