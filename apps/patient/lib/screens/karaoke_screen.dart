// lib/screens/karaoke_screen.dart
//
// Song-list screen that opens from Activities → Karaoke.
// Shows the 2 locally available Assamese folk songs.
// Tapping a song navigates to KaraokePlayerScreen.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/karaoke_data.dart';
import '../main.dart' show buildSmoothGameRoute;
import '../models/karaoke_song.dart';
import 'karaoke_player_screen.dart';

class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({super.key});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ────────────────────────────────
          _AnimatedBg(controller: _bgController),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                  child: Row(
                    children: [
                      _GlassBack(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Karaoke',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              'Folk songs of Northeast India',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // KARAOKE badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'KARAOKE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),

                const SizedBox(height: 16),

                // Song list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: karaokeSongs.length,
                    itemBuilder: (context, index) {
                      return _SongCard(
                        song: karaokeSongs[index],
                        index: index,
                        onTap: () {
                          Navigator.of(context).push(
                            buildSmoothGameRoute(
                              KaraokePlayerScreen(song: karaokeSongs[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated background: slowly shifting deep gradient with floating shapes
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF0D1B2A),
                  const Color(0xFF1A0E2E),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF1A2744),
                  const Color(0xFF2D1459),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF0F3460),
                  const Color(0xFF16213E),
                  t,
                )!,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass back button
// ─────────────────────────────────────────────────────────────────────────────
class _GlassBack extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBack({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Song card with entrance animation + press scale
// ─────────────────────────────────────────────────────────────────────────────
class _SongCard extends StatefulWidget {
  final KaraokeSong song;
  final int index;
  final VoidCallback onTap;

  const _SongCard({
    required this.song,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<_SongCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _pressed = false;

  static const List<List<Color>> _gradients = [
    [Color(0xFF6B35A8), Color(0xFF3A1F6B), Color(0xFF1A0E35)],
    [Color(0xFF1A6B4A), Color(0xFF0D3D2A), Color(0xFF051A12)],
  ];

  static const List<Color> _accentColors = [
    Color(0xFFB794F4),
    Color(0xFF68D391),
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_entrance);

    _timer = Timer(Duration(milliseconds: 80 + widget.index * 160), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[widget.index % _gradients.length];
    final accent = _accentColors[widget.index % _accentColors.length];

    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: SlideTransition(
            position: _slide,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.975 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: _buildCardBody(gradient, accent),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody(List<Color> gradient, Color accent) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.55),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left: icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.music_note_rounded, color: accent, size: 34),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.music_note_rounded,
                            color: accent.withValues(alpha: 0.35), size: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right: text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cultural label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.song.culturalLabel,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Song title
                      Text(
                        widget.song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Lyric count
                      Row(
                        children: [
                          Icon(Icons.format_list_bulleted_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.55)),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.song.lyrics.length} lines',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Play button
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accent.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: accent,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
