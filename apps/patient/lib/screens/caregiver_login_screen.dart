// lib/screens/caregiver_login_screen.dart

import 'package:flutter/material.dart';
import '../services/caregiver_api_service.dart';
import 'caregiver_dashboard_screen.dart';

class CaregiverLoginScreen extends StatefulWidget {
  const CaregiverLoginScreen({super.key});

  @override
  State<CaregiverLoginScreen> createState() => _CaregiverLoginScreenState();
}

class _CaregiverLoginScreenState extends State<CaregiverLoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Colors ──────────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0D1F17);
  static const Color _card = Color(0xFF162A1E);
  static const Color _green = Color(0xFF214E3B);
  static const Color _accent = Color(0xFF5F866D);
  static const Color _ivory = Color(0xFFF8F5EC);
  static const Color _muted = Color(0xFF8A9E93);

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late final AnimationController _anim;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final err = await CaregiverApiService.instance.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CaregiverDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  // ── Logo ──────────────────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Color(0xFFF8F5EC), size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Caregiver Portal',
                    style: TextStyle(
                      color: _ivory,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to manage your patient',
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // ── Card ──────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: _accent.withOpacity(0.2), width: 1),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Field(
                            controller: _emailCtrl,
                            label: 'Email',
                            hint: 'your@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          _Field(
                            controller: _passCtrl,
                            label: 'Password',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _muted,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6)
                                    ? 'Password too short'
                                    : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B1919),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Color(0xFFFF6B6B), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                          color: Color(0xFFFF6B6B),
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _loading ? null : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: _green,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '← Back to role selection',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable field widget ────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  static const Color _accent = Color(0xFF5F866D);
  static const Color _muted = Color(0xFF8A9E93);
  static const Color _ivory = Color(0xFFF8F5EC);
  static const Color _fieldBg = Color(0xFF0D1F17);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: _ivory, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _muted.withOpacity(0.6), fontSize: 14),
            prefixIcon: Icon(icon, color: _accent, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: _fieldBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accent.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accent.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
