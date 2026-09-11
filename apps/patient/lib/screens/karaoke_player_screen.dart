// lib/screens/karaoke_player_screen.dart
//
// Full-screen, immersive karaoke player for the Smriti patient app.
//
// Architecture:
//   • audioplayers ^6.0.0 (already in pubspec.yaml) — NO new packages
//   • Audio position stream is THE SOLE source of truth for lyric sync
//   • Progressive highlight driven by position %, NOT a Timer
//   • AnimatedSwitcher for smooth lyric transitions (upward slide + scale + fade)
//   • Both Focused Stage Mode and Full Lyrics Mode with Auto-Scroll
//   • Respects user manual scrolling (does not fight gestures)
//   • Highly responsive on all screen sizes down to 320px width

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/karaoke_song.dart';

class KaraokePlayerScreen extends StatefulWidget {
  final KaraokeSong song;

  const KaraokePlayerScreen({super.key, required this.song});

  @override
  State<KaraokePlayerScreen> createState() => _KaraokePlayerScreenState();
}

class _KaraokePlayerScreenState extends State<KaraokePlayerScreen>
    with TickerProviderStateMixin {
  // ── Audio ──────────────────────────────────────────────────────────────────
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _isLoading = true;

  // Subscriptions
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _stateSub;

  // ── Lyric state ────────────────────────────────────────────────────────────
  int _activeLyricIndex = -1; // -1 = intro / no active lyric
  double _lyricProgress = 0.0; // 0.0–1.0 within the active lyric

  // ── Mode: Focused Stage vs Full Lyrics ─────────────────────────────────────
  bool _showFullLyrics = false;
  late final ScrollController _lyricsScrollCtrl;
  Timer? _userScrollTimer;
  bool _userIsScrolling = false;

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _bgController; // slow background shift
  late final AnimationController _pulseController; // play-button pulse
  late final AnimationController _particleCtrl; // floating particles

  // ── Seek slider drag ───────────────────────────────────────────────────────
  bool _isDragging = false;
  double _dragValue = 0.0;

  // ── Volume ────────────────────────────────────────────────────────────────
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _lyricsScrollCtrl = ScrollController();

    // Background gradient animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    // Play-button pulse (only runs while playing)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Particles
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player = AudioPlayer();

    // Allow audio during silence/phone-mute switch
    try {
      await _player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
    } catch (_) {}

    _positionSub = _player.onPositionChanged.listen(_onPosition);
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _completeSub = _player.onPlayerComplete.listen((_) => _onComplete());
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (_isPlaying && !_isCompleted) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.animateTo(0);
        }
      });
    });

    await _player.setVolume(_volume);
    await _player.setSource(AssetSource(
      widget.song.audioAsset.replaceFirst('assets/', ''),
    ));

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Audio position callback ────────────────────────────────────────────────
  void _onPosition(Duration pos) {
    if (!mounted) return;
    if (_isDragging) return;
    setState(() {
      _position = pos;
      _updateLyricState(pos);
    });
  }

  void _onComplete() {
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isCompleted = true;
      _position = _duration;
      _activeLyricIndex = widget.song.lyrics.length;
      _lyricProgress = 1.0;
    });
    _pulseController.stop();
    _pulseController.animateTo(0);
  }

  // ── Lyric sync (position is the SOLE source of truth) ─────────────────────
  void _updateLyricState(Duration pos) {
    final lyrics = widget.song.lyrics;
    if (lyrics.isEmpty) return;

    int newIndex = -1;
    double progress = 0.0;

    if (pos < lyrics.first.start) {
      // Intro period
      newIndex = -1;
      progress = 0.0;
    } else if (pos >= lyrics.last.end) {
      // After all lyrics finished
      newIndex = lyrics.length;
      progress = 1.0;
    } else {
      for (int i = 0; i < lyrics.length; i++) {
        if (pos >= lyrics[i].start && pos < lyrics[i].end) {
          newIndex = i;
          final range = lyrics[i].end - lyrics[i].start;
          if (range.inMilliseconds > 0) {
            final elapsed = pos - lyrics[i].start;
            progress = (elapsed.inMilliseconds / range.inMilliseconds)
                .clamp(0.0, 1.0);
          }
          break;
        } else if (pos >= lyrics[i].end &&
            i + 1 < lyrics.length &&
            pos < lyrics[i + 1].start) {
          // In a natural musical pause between line i and line i+1:
          // Keep line i visible at 100% until line i+1 starts, ensuring smooth transition
          newIndex = i;
          progress = 1.0;
          break;
        }
      }
    }

    _activeLyricIndex = newIndex;
    _lyricProgress = progress;

    if (_showFullLyrics && !_userIsScrolling && _lyricsScrollCtrl.hasClients) {
      _scrollToActiveLyric(newIndex);
    }
  }

  void _scrollToActiveLyric(int index) {
    if (index < 0 || index >= widget.song.lyrics.length) return;
    if (!_lyricsScrollCtrl.hasClients) return;
    const itemHeight = 76.0;
    final target = (index * itemHeight) - 100.0;
    final clamped =
        target.clamp(0.0, _lyricsScrollCtrl.position.maxScrollExtent);
    _lyricsScrollCtrl.animateTo(
      clamped,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _onUserScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      _userIsScrolling = true;
      _userScrollTimer?.cancel();
      _userScrollTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _userIsScrolling = false);
        }
      });
    }
  }

  void _onTapLyricLine(int index) {
    if (index < 0 || index >= widget.song.lyrics.length) return;
    _seekTo(widget.song.lyrics[index].start);
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Future<void> _playPause() async {
    if (_isCompleted) {
      await _restart();
      return;
    }
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
      _isCompleted = false;
    }
  }

  Future<void> _restart() async {
    await _player.seek(Duration.zero);
    if (mounted) {
      setState(() {
        _position = Duration.zero;
        _activeLyricIndex = -1;
        _lyricProgress = 0.0;
        _isCompleted = false;
      });
    }
    await _player.resume();
  }

  Future<void> _seekTo(Duration pos) async {
    final clampedPos = pos < Duration.zero
        ? Duration.zero
        : (_duration > Duration.zero && pos > _duration ? _duration : pos);

    await _player.seek(clampedPos);
    if (mounted) {
      setState(() {
        _position = clampedPos;
        _isCompleted = false;
        _updateLyricState(clampedPos);
      });
    }
  }

  // ── Slider helpers ─────────────────────────────────────────────────────────
  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _sliderMax =>
      _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;

  double get _sliderValue {
    if (_isDragging) return _dragValue;
    return _position.inMilliseconds.toDouble().clamp(0.0, _sliderMax);
  }

  @override
  void dispose() {
    _userScrollTimer?.cancel();
    _lyricsScrollCtrl.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    _particleCtrl.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated deep-space cultural background
          _KaraokeBg(controller: _bgController, size: size),

          // 2. Floating particles / equalizer orbs
          _FloatingParticles(controller: _particleCtrl, size: size),

          // 3. Main UI
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(context),
                const SizedBox(height: 4),

                // Mode toggle (Karaoke Focus vs All Lyrics)
                _buildModeToggle(),
                const SizedBox(height: 4),

                // Lyric stage (expands to fill remaining space)
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFB794F4)),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _showFullLyrics
                              ? _buildFullLyricsList()
                              : _buildFocusedLyricsStage(),
                        ),
                ),

                // Player controls at bottom
                _buildControls(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Row(
        children: [
          // Back button
          _GlassIconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Go Back',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.song.culturalLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // KARAOKE badge + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFB794F4).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFB794F4).withValues(alpha: 0.45)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic_rounded, color: Color(0xFFD6BCFA), size: 11),
                    SizedBox(width: 4),
                    Text(
                      'KARAOKE',
                      style: TextStyle(
                        color: Color(0xFFD6BCFA),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_fmt(_position)} / ${_fmt(_duration)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE TOGGLE (Karaoke Focus vs All Lyrics)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillTab(
            title: 'Focus Stage',
            icon: Icons.mic_rounded,
            isSelected: !_showFullLyrics,
            onTap: () => setState(() => _showFullLyrics = false),
          ),
          _buildPillTab(
            title: 'All Lyrics',
            icon: Icons.format_list_bulleted_rounded,
            isSelected: _showFullLyrics,
            onTap: () {
              setState(() => _showFullLyrics = true);
              if (_activeLyricIndex >= 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToActiveLyric(_activeLyricIndex);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB794F4).withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFFB794F4).withValues(alpha: 0.6),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFFE9D5FF) : Colors.white60,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FOCUSED LYRIC STAGE (PREV / CURRENT / NEXT)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFocusedLyricsStage() {
    final lyrics = widget.song.lyrics;
    final activeIdx = _activeLyricIndex;

    final prevText = (activeIdx > 0 && activeIdx <= lyrics.length)
        ? lyrics[activeIdx - 1].text
        : null;
    final currLyric = (activeIdx >= 0 && activeIdx < lyrics.length)
        ? lyrics[activeIdx]
        : null;
    final nextText = (activeIdx >= 0 && activeIdx + 1 < lyrics.length)
        ? lyrics[activeIdx + 1].text
        : (activeIdx == -1 && lyrics.isNotEmpty)
            ? lyrics[0].text
            : null;

    final bool isIntro = activeIdx == -1;
    final bool isFinished = _isCompleted || activeIdx >= lyrics.length;

    return Column(
      key: const ValueKey('focus_stage'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // Previous lyric
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.3),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          child: prevText != null && !isIntro
              ? Padding(
                  key: ValueKey('prev_${activeIdx}_$prevText'),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    prevText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : const SizedBox(key: ValueKey('prev_empty'), height: 22),
        ),

        const SizedBox(height: 24),

        // Current lyric (main visual focus)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                  CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: isFinished
              ? _buildCompletedText()
              : isIntro
                  ? _buildIntroText(lyrics.isNotEmpty ? lyrics[0].text : null)
                  : currLyric != null
                      ? _buildCurrentLyric(currLyric, activeIdx)
                      : const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),

        // Next lyric
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          child: nextText != null && !isFinished
              ? Padding(
                  key: ValueKey('next_${activeIdx}_$nextText'),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    nextText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : const SizedBox(key: ValueKey('next_empty'), height: 22),
        ),

        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildIntroText(String? firstLyric) {
    return Column(
      key: const ValueKey('intro_stage'),
      children: [
        _GlowingMusicIcon(),
        const SizedBox(height: 16),
        Text(
          'Intro…',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Lyrics start in ~10 seconds',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (firstLyric != null) ...[
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.queue_music_rounded,
                    color: Color(0xFFB794F4), size: 14),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Up next: $firstLyric',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD6BCFA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedText() {
    return Container(
      key: const ValueKey('completed_stage'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration_rounded,
              color: Color(0xFFF6E05E), size: 36),
          const SizedBox(height: 10),
          const Text(
            'Song Finished!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wonderful singing • Tap Replay to sing again',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CURRENT LYRIC with progressive highlight
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCurrentLyric(KaraokeLyric lyric, int index) {
    const highlightColor = Color(0xFFE9D5FF);
    const dimColor = Color(0xFF7A8DBF);
    final progress = _lyricProgress;

    return Container(
      key: ValueKey('curr_${index}_${lyric.text}'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glow card around active lyric
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: const Color(0xFFB794F4).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9F7AEA).withValues(alpha: 0.25),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _ProgressiveHighlightText(
                text: lyric.text,
                progress: progress,
                highlightColor: highlightColor,
                dimColor: dimColor,
              ),
            ),
          ),

          const SizedBox(height: 12),
          _LyricProgressBar(progress: progress),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FULL SCROLLABLE LYRICS LIST (Requirement 9)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFullLyricsList() {
    final lyrics = widget.song.lyrics;
    return NotificationListener<ScrollNotification>(
      onNotification: (notif) {
        _onUserScroll(notif);
        return false;
      },
      child: ListView.builder(
        key: const ValueKey('full_lyrics_list'),
        controller: _lyricsScrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        itemCount: lyrics.length,
        itemBuilder: (context, index) {
          final lyric = lyrics[index];
          final isActive = index == _activeLyricIndex;
          final isPast = _activeLyricIndex > index;

          return GestureDetector(
            onTap: () => _onTapLyricLine(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isActive
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFB794F4).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.06),
                  width: isActive ? 1.5 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF9F7AEA).withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Timestamp tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFB794F4).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _fmt(lyric.start),
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFFD6BCFA)
                                : Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF68D391).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_rounded,
                                  size: 10, color: Color(0xFF68D391)),
                              SizedBox(width: 3),
                              Text(
                                'SINGING',
                                style: TextStyle(
                                  color: Color(0xFF68D391),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.play_circle_outline_rounded,
                        size: 16,
                        color: isActive
                            ? const Color(0xFFB794F4)
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Lyric text
                  Text(
                    lyric.text,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : isPast
                              ? Colors.white.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.8),
                      fontSize: isActive ? 16.5 : 14.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _lyricProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFB794F4)),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PLAYER CONTROLS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildControls() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Seek slider ────────────────────────────────────────────
              _buildSeekSlider(),
              const SizedBox(height: 4),

              // ── Time labels ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(_isDragging
                          ? Duration(milliseconds: _dragValue.toInt())
                          : _position),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _fmt(_duration),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Buttons row (Fitted to ensure 0 overflow on narrow screens)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Volume
                    _buildVolumeControl(),
                    const SizedBox(width: 14),

                    // Restart
                    _GlassIconBtn(
                      icon: Icons.replay_rounded,
                      size: 22,
                      tooltip: 'Restart Song',
                      onTap: _restart,
                    ),
                    const SizedBox(width: 14),

                    // Play / Pause — large pulsing
                    _buildPlayButton(),
                    const SizedBox(width: 14),

                    // Seek +10s
                    _GlassIconBtn(
                      icon: Icons.forward_10_rounded,
                      size: 22,
                      tooltip: 'Forward 10s',
                      onTap: () =>
                          _seekTo(_position + const Duration(seconds: 10)),
                    ),
                    const SizedBox(width: 14),

                    // Lyrics Toggle: Focus vs Full List
                    _GlassIconBtn(
                      icon: _showFullLyrics
                          ? Icons.center_focus_strong_rounded
                          : Icons.lyrics_rounded,
                      size: 22,
                      tooltip: _showFullLyrics
                          ? 'Show Focus Stage'
                          : 'Show All Lyrics',
                      isActive: _showFullLyrics,
                      onTap: () {
                        setState(() {
                          _showFullLyrics = !_showFullLyrics;
                        });
                        if (_showFullLyrics && _activeLyricIndex >= 0) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToActiveLyric(_activeLyricIndex);
                          });
                        }
                      },
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

  Widget _buildSeekSlider() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: const Color(0xFFB794F4),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
        thumbColor: Colors.white,
        overlayColor: const Color(0xFFB794F4).withValues(alpha: 0.25),
      ),
      child: Slider(
        value: _sliderValue,
        min: 0.0,
        max: _sliderMax,
        onChangeStart: (v) {
          setState(() {
            _isDragging = true;
            _dragValue = v;
          });
        },
        onChanged: (v) {
          setState(() {
            _dragValue = v;
            _updateLyricState(Duration(milliseconds: v.toInt()));
          });
        },
        onChangeEnd: (v) {
          setState(() {
            _isDragging = false;
            _dragValue = v;
          });
          _seekTo(Duration(milliseconds: v.toInt()));
        },
      ),
    );
  }

  Widget _buildPlayButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _isPlaying
            ? 1.0 + 0.06 * sin(_pulseController.value * 2 * pi)
            : 1.0;
        final glow = _isPlaying
            ? 0.35 + 0.15 * sin(_pulseController.value * 2 * pi)
            : 0.15;

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9F7AEA), Color(0xFF6B46C1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9F7AEA).withValues(alpha: glow),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : IconButton(
                    onPressed: _playPause,
                    icon: Icon(
                      _isCompleted
                          ? Icons.replay_rounded
                          : _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    padding: EdgeInsets.zero,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildVolumeControl() {
    return PopupMenuButton<double>(
      tooltip: 'Volume',
      color: const Color(0xFF1A2744),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (v) async {
        setState(() => _volume = v);
        await _player.setVolume(v);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          enabled: false,
          child: Text('Volume',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        ...[1.0, 0.75, 0.5, 0.25].map(
          (v) => PopupMenuItem<double>(
            value: v,
            child: Row(
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  color:
                      _volume == v ? const Color(0xFFB794F4) : Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(v * 100).toInt()}%',
                  style: TextStyle(
                    color: _volume == v
                        ? const Color(0xFFB794F4)
                        : Colors.white,
                    fontWeight: _volume == v
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.20), width: 1),
        ),
        child: Icon(
          _volume > 0.5
              ? Icons.volume_up_rounded
              : _volume > 0
                  ? Icons.volume_down_rounded
                  : Icons.volume_off_rounded,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESSIVE HIGHLIGHT TEXT (ShaderMask + clamping safe against asserts)
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressiveHighlightText extends StatelessWidget {
  final String text;
  final double progress; // 0.0 – 1.0
  final Color highlightColor;
  final Color dimColor;

  const _ProgressiveHighlightText({
    required this.text,
    required this.progress,
    required this.highlightColor,
    required this.dimColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Dim base layer
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: dimColor,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.35,
            letterSpacing: 0.3,
          ),
        ),

        // Highlight overlay clipped to progress fraction
        if (p > 0.0)
          p >= 1.0
              ? Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: highlightColor,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(
                        color: Color(0xFFB794F4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                )
              : ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    final stop1 = p.clamp(0.0, 0.99);
                    final stop2 = (p + 0.01).clamp(0.0, 1.0);
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [stop1, stop2],
                      colors: [highlightColor, Colors.transparent],
                    ).createShader(bounds);
                  },
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: highlightColor,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

        // Extra glowing pulse at full line completion
        if (p > 0.94)
          Opacity(
            opacity: ((p - 0.94) / 0.06).clamp(0.0, 1.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 23,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: 0.3,
                shadows: const [
                  Shadow(
                    color: Color(0xFFD6BCFA),
                    blurRadius: 22,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thin progress bar below current lyric
// ─────────────────────────────────────────────────────────────────────────────
class _LyricProgressBar extends StatelessWidget {
  final double progress;
  const _LyricProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth * 0.55;
      return Container(
        width: w,
        height: 3.5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: 3.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [Color(0xFFB794F4), Color(0xFF9F7AEA)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB794F4).withValues(alpha: 0.60),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated deep-space background
// ─────────────────────────────────────────────────────────────────────────────
class _KaraokeBg extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _KaraokeBg({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                    const Color(0xFF0B0F2A), const Color(0xFF1A0E2E), t)!,
                Color.lerp(
                    const Color(0xFF16213E), const Color(0xFF0F1E3A), t)!,
                Color.lerp(
                    const Color(0xFF0F3460), const Color(0xFF1A1048), t)!,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _BgStarPainter(t),
            size: size,
          ),
        );
      },
    );
  }
}

class _BgStarPainter extends CustomPainter {
  final double t;
  _BgStarPainter(this.t);

  static final List<_Star> _stars = List.generate(55, (i) {
    final r = Random(i * 7 + 13);
    return _Star(
      x: r.nextDouble(),
      y: r.nextDouble(),
      radius: 0.5 + r.nextDouble() * 1.5,
      phase: r.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final alpha = (0.15 +
              0.55 * (0.5 + 0.5 * sin((t + s.phase) * 2 * pi)))
          .clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_BgStarPainter old) => old.t != t;
}

class _Star {
  final double x, y, radius, phase;
  const _Star(
      {required this.x,
      required this.y,
      required this.radius,
      required this.phase});
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating music note / orb particles
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingParticles extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _FloatingParticles({required this.controller, required this.size});

  static final _rng = Random(42);
  static final List<_Particle> _particles = List.generate(12, (i) {
    return _Particle(
      x: _rng.nextDouble(),
      startY: 0.7 + _rng.nextDouble() * 0.3,
      speed: 0.06 + _rng.nextDouble() * 0.08,
      radius: 2.5 + _rng.nextDouble() * 4.0,
      phase: _rng.nextDouble(),
      isNote: i % 3 == 0,
    );
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _ParticlePainter(controller.value, _particles),
          size: size,
        );
      },
    );
  }
}

class _Particle {
  final double x, startY, speed, radius, phase;
  final bool isNote;
  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.radius,
    required this.phase,
    required this.isNote,
  });
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;
  _ParticlePainter(this.t, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = ((t + p.phase) % 1.0);
      final y = (p.startY - progress * p.speed * 8) * size.height;
      if (y < -20) continue;
      final alpha =
          (0.08 + 0.22 * sin(progress * pi)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFFB794F4).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, y),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Glowing music icon for intro state
// ─────────────────────────────────────────────────────────────────────────────
class _GlowingMusicIcon extends StatefulWidget {
  @override
  State<_GlowingMusicIcon> createState() => _GlowingMusicIconState();
}

class _GlowingMusicIconState extends State<_GlowingMusicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final glow = 0.20 + 0.35 * _ctrl.value;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9F7AEA).withValues(alpha: 0.18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB794F4).withValues(alpha: glow),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.music_note_rounded,
              color: Color(0xFFD6BCFA), size: 36),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable glass icon button
// ─────────────────────────────────────────────────────────────────────────────
class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;
  final bool isActive;

  const _GlassIconBtn({
    required this.icon,
    required this.onTap,
    this.size = 18,
    this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFB794F4).withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFB794F4).withValues(alpha: 0.60)
                    : Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFFE9D5FF) : Colors.white,
              size: size,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
