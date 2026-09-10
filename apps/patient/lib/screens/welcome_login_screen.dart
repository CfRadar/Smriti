// lib/screens/welcome_login_screen.dart
// Role selection matching the exact Smriti activity hub theme.

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

class _WelcomeLoginScreenState extends State<WelcomeLoginScreen> {
  static const Color _screenBg = Color(0xFFF0F4F8);
  static const Color _darkBlue = Color(0xFF1E3A4B);

  bool _isCaregiverLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkCaregiverAuth();
  }

  Future<void> _checkCaregiverAuth() async {
    final loggedIn = await CaregiverApiService.instance.isLoggedIn;
    if (mounted) {
      setState(() => _isCaregiverLoggedIn = loggedIn);
    }
  }

  void _navigateToPatient() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameHubPage(),
        transitionDuration: const Duration(milliseconds: 350),
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
      backgroundColor: _screenBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header matching the screenshot ─────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Smriti',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _darkBlue,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6A883),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 20,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF48FB1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Section Title Bar ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose a role',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _darkBlue,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 13,
                          color: _darkBlue,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '2 Roles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _darkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── 2-Role Cards Grid (matching game cards design) ────────────
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // 1. Patient Card (Soft Mint Green)
                  _RoleCard(
                    title: 'Patient',
                    icon: Icons.sports_esports_rounded,
                    gradientColors: const [
                      Color(0xFFC8E6C9),
                      Color(0xFF81C784),
                    ],
                    iconColor: const Color(0xFF1B5E20),
                    onTap: _navigateToPatient,
                  ),

                  // 2. Caregiver Card (Soft Lavender)
                  _RoleCard(
                    title: 'Caregiver',
                    icon: Icons.health_and_safety_rounded,
                    gradientColors: const [
                      Color(0xFFE1BEE7),
                      Color(0xFFBA68C8),
                    ],
                    iconColor: const Color(0xFF4A148C),
                    onTap: _navigateToCaregiver,
                  ),
                ],
              ),

              const Spacer(),

              // ── Gentle footer hint ─────────────────────────────────────────
              Center(
                child: Text(
                  'Tap a role to enter the app',
                  style: TextStyle(
                    color: const Color(0xFF7D8BA3).withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Game Card Style Role Component ───────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white,
              width: 2.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19.2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient Body
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradientColors,
                    ),
                  ),
                ),

                // Center Icon in circular glass pill
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.iconColor.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 34,
                      ),
                    ),
                  ),
                ),

                // Translucent dark bottom bar with one-word label
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.54),
                    ),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
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
