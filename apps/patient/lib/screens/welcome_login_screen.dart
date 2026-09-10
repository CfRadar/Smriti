// lib/screens/welcome_login_screen.dart
// Entry portal matching Smriti's soothing ivory & forest green patient theme.

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
  // ── Smriti Patient Interface Design Tokens ────────────────────────────────
  static const Color _ivory = Color(0xFFF8F5EC);
  static const Color _darkGreen = Color(0xFF214E3B);
  static const Color _green = Color(0xFF5F866D);
  static const Color _lightGreen = Color(0xFFDCE8DA);
  static const Color _cream = Color(0xFFEDE7D7);
  static const Color _textGrey = Color(0xFF66736C);

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _isCaregiverLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
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
      backgroundColor: _ivory,
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
                  const SizedBox(height: 12),

                  // ── Brand Header ──────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: _lightGreen,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: _green.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _darkGreen.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.psychology_rounded,
                              color: _darkGreen,
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SMRITI',
                          style: TextStyle(
                            color: _darkGreen,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cognitive Care & Assisted Memory Companion',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Choose mode to begin:',
                      style: TextStyle(
                        color: _darkGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Card 1: Patient Mode ──────────────────────────────────
                  _RoleCard(
                    title: 'I am a Patient',
                    subtitle:
                        'Play daily brain-training games, listen to folklore stories, check reminders, and speak with your voice assistant.',
                    icon: Icons.sports_esports_rounded,
                    badgeText: 'Games & Voice Companion',
                    buttonLabel: 'Enter Patient Mode',
                    badgeBg: _lightGreen,
                    badgeColor: _darkGreen,
                    buttonColor: _darkGreen,
                    onTap: _navigateToPatient,
                  ),

                  const SizedBox(height: 18),

                  // ── Card 2: Caregiver Mode ────────────────────────────────
                  _RoleCard(
                    title: 'I am a Caregiver',
                    subtitle:
                        'Monitor cognitive recovery scores, set up voice reminders, and manage family photo memories.',
                    icon: Icons.health_and_safety_rounded,
                    badgeText: _isCaregiverLoggedIn
                        ? 'Caregiver Active • Tap to open'
                        : 'Caregiver Portal & Care',
                    buttonLabel: _isCaregiverLoggedIn
                        ? 'Open Caregiver Dashboard'
                        : 'Caregiver Sign In',
                    badgeBg: _cream,
                    badgeColor: _darkGreen,
                    buttonColor: _green,
                    onTap: _navigateToCaregiver,
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: _textGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'All data is stored locally with offline synchronization.',
                          style: TextStyle(
                            color: _textGrey.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Warm Light Role Card ─────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    required this.buttonLabel,
    required this.badgeBg,
    required this.badgeColor,
    required this.buttonColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final String buttonLabel;
  final Color badgeBg;
  final Color badgeColor;
  final Color buttonColor;
  final VoidCallback onTap;

  static const Color _darkGreen = Color(0xFF214E3B);
  static const Color _textGrey = Color(0xFF66736C);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: badgeBg,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: _darkGreen, size: 28),
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
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              color: _darkGreen,
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
                    color: _textGrey,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
