// lib/screens/welcome_login_screen.dart
// Clean role selection with slim bottom tiles matching the requested layout and Smriti's theme.

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
  static const Color _darkGreen = Color(0xFF214E3B);
  static const Color _darkBlue = Color(0xFF1E3A4B);
  static const Color _textGrey = Color(0xFF64748B);

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Hero Visual with gradient fade to screen background ───
            SizedBox(
              height: screenHeight * 0.38,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Scenic cultural backdrop
                  Image.asset(
                    'assets/images/kang_court_board_clean.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFDCE8DA), Color(0xFFF0F4F8)],
                        ),
                      ),
                    ),
                  ),

                  // Gradient overlay that smoothly fades into the screen background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x33F0F4F8),
                          Color(0xCCF0F4F8),
                          Color(0xFFF0F4F8),
                        ],
                        stops: [0.25, 0.55, 0.85, 1.0],
                      ),
                    ),
                  ),

                  // Brand name in top-left safe area
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          const Text(
                            'Smriti',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _darkBlue,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6A883),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 18,
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
                  ),
                ],
              ),
            ),

            // ── "Select Role" Title & Subtitle Section ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Role',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _darkBlue,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Select as Patient if you play cognitive games &\nselect Caregiver if it is care and monitoring',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: _textGrey,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Brand Emblem on right side (matching logo in reference screenshot)
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _darkGreen,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _darkGreen.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Color(0xFFF8F5EC),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Bottom Slim Tiles (matching reference layout) ───────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SlimRoleTile(
                    title: 'Patient',
                    borderColor: _darkGreen,
                    textColor: _darkGreen,
                    onTap: _navigateToPatient,
                  ),
                  const SizedBox(height: 14),
                  _SlimRoleTile(
                    title: 'Caregiver',
                    borderColor: _darkGreen,
                    textColor: _darkGreen,
                    onTap: _navigateToCaregiver,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slim Rounded Role Tile Component ─────────────────────────────────────────

class _SlimRoleTile extends StatefulWidget {
  const _SlimRoleTile({
    required this.title,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  State<_SlimRoleTile> createState() => _SlimRoleTileState();
}

class _SlimRoleTileState extends State<_SlimRoleTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.borderColor,
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.title,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
