// lib/screens/welcome_login_screen.dart
// Entry portal offering role selection between Patient and Caregiver modes.

import 'package:flutter/material.dart';
import '../services/caregiver_api_service.dart';
import 'caregiver_login_screen.dart';
import 'caregiver_dashboard_screen.dart';
import '../main.dart';

class WelcomeLoginScreen extends StatefulWidget {
  const WelcomeLoginScreen({super.key});

  @override
  State<WelcomeLoginScreen> createState() => _WelcomeLoginScreenState();
}

class _WelcomeLoginScreenState extends State<WelcomeLoginScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF0D1F17);
  static const Color _green = Color(0xFF214E3B);
  static const Color _accent = Color(0xFF5F866D);
  static const Color _gold = Color(0xFFC89B3C);
  static const Color _ivory = Color(0xFFF8F5EC);
  static const Color _muted = Color(0xFF8A9E93);

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _isCaregiverLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _checkCaregiverAuth();
    _anim.forward();
  }

  Future<void> _checkCaregiverAuth() async {
    final loggedIn = await CaregiverApiService.instance.isLoggedIn;
    if (mounted) {
      setState(() => _isCaregiverLoggedIn = loggedIn);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _navigateToPatient() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameHubPage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  void _navigateToCaregiver() {
    if (_isCaregiverLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CaregiverDashboardScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CaregiverLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // ── Header branding ───────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_green, Color(0xFF346B52)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.psychology_rounded,
                              color: _ivory,
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'SMRITI',
                          style: TextStyle(
                            color: _ivory,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cognitive Care & Assisted Memory Companion',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  const Text(
                    'Choose your mode to continue:',
                    style: TextStyle(
                      color: _ivory,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Card 1: Patient Mode ──────────────────────────────────
                  _RoleOptionCard(
                    title: 'I am a Patient',
                    subtitle:
                        'Play daily brain-training games, listen to folklore, view reminders, and talk with your voice assistant.',
                    icon: Icons.sports_esports_rounded,
                    accentColor: const Color(0xFF4CAF50),
                    badgeText: 'Cognitive Games & Voice',
                    actionLabel: 'Enter Patient Mode',
                    onTap: _navigateToPatient,
                  ),

                  const SizedBox(height: 20),

                  // ── Card 2: Caregiver Mode ────────────────────────────────
                  _RoleOptionCard(
                    title: 'I am a Caregiver',
                    subtitle:
                        'Monitor cognitive recovery scores, schedule voice reminders, and manage family photo memories.',
                    icon: Icons.health_and_safety_rounded,
                    accentColor: _gold,
                    badgeText: _isCaregiverLoggedIn
                        ? 'Caregiver Active • Tap to open'
                        : 'Caregiver Portal & Monitoring',
                    actionLabel: _isCaregiverLoggedIn
                        ? 'Open Caregiver Dashboard'
                        : 'Caregiver Sign In',
                    onTap: _navigateToCaregiver,
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Text(
                      'All games and telemetry run locally with offline support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable role card widget ────────────────────────────────────────────────

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.badgeText,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String badgeText;
  final String actionLabel;
  final VoidCallback onTap;

  static const Color _cardBg = Color(0xFF162A1E);
  static const Color _ivory = Color(0xFFF8F5EC);
  static const Color _muted = Color(0xFF8A9E93);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: accentColor.withValues(alpha: 0.15),
        highlightColor: accentColor.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(icon, color: accentColor, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: const TextStyle(
                            color: _ivory,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
