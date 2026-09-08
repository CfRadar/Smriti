// apps/patient/lib/games/king_shanaba_game.dart
//
// Smriti Dementia-Care Platform - Cognitive Motor Stimulation Module
// Traditional Manipuri Tactile Sliding Game: "King Shanaba" (Kang Shanaba)
//
// Features:
// 1. Tangible, hittable physical target piece with realistic 2D rigid-body collision physics.
// 2. Momentum transfer: striker strikes the target, causing both to slide, recoil, spin, and bounce off court rails.
// 3. Northeast Indian chime pool (Bamboo bell, Meitei brass bell, Singing bowl, Golden gong) on target strike.
// 4. Smooth animated trial and session transitions.
// 5. Cohesive aesthetic blending traditional Manipuri wooden court with the Smriti pastel sage green palette.
// 6. Complete offline-first telemetry and voice command integration.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/voice_command_controller.dart';
import '../models/voice_command.dart';
import '../widgets/voice_status_indicator.dart';

// ============================================================================
// 1. TELEMETRY & ADAPTIVE DATA MODELS
// ============================================================================

/// Telemetry model capturing clinical & motor interaction metrics.
class ShanabaTrialTelemetry {
  final String sessionId;
  final String gameType;
  final int trialNumber;
  final double slideDistance;
  final int reactionTimeMs;
  final bool isCorrect;
  final String timestamp;
  final double targetTolerance;
  final double friction;
  final double initialVelocity;

  const ShanabaTrialTelemetry({
    required this.sessionId,
    this.gameType = 'king_shanaba',
    required this.trialNumber,
    required this.slideDistance,
    required this.reactionTimeMs,
    required this.isCorrect,
    required this.timestamp,
    required this.targetTolerance,
    required this.friction,
    required this.initialVelocity,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'gameType': gameType,
        'trialNumber': trialNumber,
        'slideDistance': double.parse(slideDistance.toStringAsFixed(2)),
        'reactionTimeMs': reactionTimeMs,
        'isCorrect': isCorrect,
        'timestamp': timestamp,
        'targetTolerance': double.parse(targetTolerance.toStringAsFixed(2)),
        'friction': double.parse(friction.toStringAsFixed(4)),
        'initialVelocity': double.parse(initialVelocity.toStringAsFixed(2)),
      };

  factory ShanabaTrialTelemetry.fromJson(Map<String, dynamic> json) =>
      ShanabaTrialTelemetry(
        sessionId: json['sessionId'] as String? ?? 'unknown_session',
        gameType: json['gameType'] as String? ?? 'king_shanaba',
        trialNumber: (json['trialNumber'] as num?)?.toInt() ?? 1,
        slideDistance: (json['slideDistance'] as num?)?.toDouble() ?? 0.0,
        reactionTimeMs: (json['reactionTimeMs'] as num?)?.toInt() ?? 0,
        isCorrect: json['isCorrect'] as bool? ?? false,
        timestamp:
            json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
        targetTolerance: (json['targetTolerance'] as num?)?.toDouble() ?? 50.0,
        friction: (json['friction'] as num?)?.toDouble() ?? 0.08,
        initialVelocity: (json['initialVelocity'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Offline-First Telemetry Service with persistent SharedPreferences queue.
class ShanabaTelemetryService {
  final String endpointUrl;
  final http.Client _client;
  static const String offlineCacheKey = 'smriti_shanaba_game_telemetry_queue';

  ShanabaTelemetryService({
    this.endpointUrl = 'http://localhost:5000/api/games/session',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Immediately caches to SharedPreferences, then asynchronously triggers sync.
  Future<void> logTrial(ShanabaTrialTelemetry telemetry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(offlineCacheKey) ?? [];
      queue.add(jsonEncode(telemetry.toJson()));
      await prefs.setStringList(offlineCacheKey, queue);

      // Asynchronous, non-blocking HTTP sync attempt
      unawaited(syncQueuedTelemetry());
    } catch (e) {
      debugPrint('[KingShanaba Telemetry] Local storage error: $e');
    }
  }

  /// Attempts to transmit buffered telemetry events; leaves unsent items intact.
  Future<void> syncQueuedTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(offlineCacheKey) ?? [];
      if (queue.isEmpty) return;

      final List<String> remainingQueue = [];

      for (final String rawJson in queue) {
        try {
          final response = await _client
              .post(
                Uri.parse(endpointUrl),
                headers: {'Content-Type': 'application/json'},
                body: rawJson,
              )
              .timeout(const Duration(seconds: 4));

          if (response.statusCode < 200 || response.statusCode >= 300) {
            remainingQueue.add(rawJson);
          }
        } catch (_) {
          // Network failure / server offline: keep telemetry safe in queue
          remainingQueue.add(rawJson);
        }
      }

      await prefs.setStringList(offlineCacheKey, remainingQueue);
    } catch (e) {
      debugPrint('[KingShanaba Telemetry] Sync error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Minimal Adaptive Difficulty Controller for dementia cognitive-motor therapy.
class ShanabaAdaptiveEngine {
  int consecutiveHits = 0;
  int consecutiveMisses = 0;
  int level = 1;

  // Base parameters
  double targetRadius = 56.0; // Large, elderly-friendly starting radius
  double friction = 0.080; // Natural wooden court deceleration

  /// Adaptive striker diameter: progressively smaller/shorter per level
  double get currentStrikerDiameter {
    switch (level) {
      case 1:
        return 72.0; // Easiest launch surface
      case 2:
        return 64.0;
      case 3:
        return 56.0;
      case 4:
        return 48.0;
      default:
        return 40.0; // Master challenge
    }
  }

  /// Adaptive target diameter: progressively smaller/shorter per level
  double get currentTargetDiameter {
    switch (level) {
      case 1:
        return 66.0; // High accessibility for seniors
      case 2:
        return 58.0;
      case 3:
        return 50.0;
      case 4:
        return 42.0;
      default:
        return 34.0; // High precision target
    }
  }

  void recordResult({required bool isHit, required int reactionTimeMs}) {
    if (isHit) {
      consecutiveHits++;
      consecutiveMisses = 0;

      if (consecutiveHits >= 2 && level < 5) {
        level++;
        consecutiveHits = 0;
        targetRadius = max(34.0, targetRadius - 5.0);
        friction = (friction + 0.004).clamp(0.06, 0.12);
      }
    } else {
      consecutiveMisses++;
      consecutiveHits = 0;

      if (consecutiveMisses >= 2 && level > 1) {
        level--;
        consecutiveMisses = 0;
        targetRadius = min(74.0, targetRadius + 6.0);
        friction = (friction - 0.005).clamp(0.06, 0.12);
      }
    }

    if (reactionTimeMs > 4500) {
      if (level > 1) level--;
      consecutiveMisses = 0;
      targetRadius = min(76.0, targetRadius + 4.0);
    }
  }

  String get difficultyLabel {
    switch (level) {
      case 1:
        return 'Gentle Pace';
      case 2:
        return 'Balanced';
      case 3:
        return 'Steady Focus';
      case 4:
        return 'Sharp Aim';
      default:
        return 'Master Court';
    }
  }
}

// ============================================================================
// 2. MAIN WIDGET ENTRY POINT
// ============================================================================

/// King Shanaba Game Widget.
/// Standalone drop-in widget for the Smriti dementia-care platform.
class KingShanabaGameScreen extends StatefulWidget {
  final String sessionId;
  final int totalTrials;
  final VoidCallback? onGameCompleted;

  const KingShanabaGameScreen({
    super.key,
    this.sessionId = 'session_shanaba_adaptive',
    this.totalTrials = 6,
    this.onGameCompleted,
  });

  @override
  State<KingShanabaGameScreen> createState() => _KingShanabaGameScreenState();
}

/// Compatibility alias
typedef KingShanabaGame = KingShanabaGameScreen;

class _KingShanabaGameScreenState extends State<KingShanabaGameScreen>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // SMRITI DESIGN SYSTEM PALETTE
  // --------------------------------------------------------------------------
  static const Color primarySage = Color(0xFF5F866D);
  static const Color darkGreen = Color(0xFF214E3B);
  static const Color lightGreen = Color(0xFFDCE8DA);
  static const Color softBackground = Color(0xFFF8F5EC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFE0E8E1);
  static const Color textDark = Color(0xFF214E3B);
  static const Color textGrey = Color(0xFF66736C);
  static const Color cream = Color(0xFFEDE7D7);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color goldAccent = Color(0xFFD4A373);

  // Asset paths
  static const String courtBoardAsset = 'assets/images/kang_court_board.jpg';
  static const String strikerDiscAsset = 'assets/images/kang_striker_disc.png';
  static const String targetMarkerAsset = 'assets/images/kang_target_marker.png';

  // Northeast Chime Pool
  static const List<String> _northeastChimePool = [
    'audio/northeast_chime_bamboo.wav',
    'audio/northeast_chime_brass.wav',
    'audio/northeast_chime_bowl.wav',
    'audio/northeast_chime_gong.wav',
  ];

  // --------------------------------------------------------------------------
  // STATE & SERVICES
  // --------------------------------------------------------------------------
  final ShanabaTelemetryService _telemetryService = ShanabaTelemetryService();
  final ShanabaAdaptiveEngine _adaptiveEngine = ShanabaAdaptiveEngine();
  final AudioPlayer _sfxAudioPlayer = AudioPlayer();
  final AudioPlayer _chimeAudioPlayer = AudioPlayer();
  final Random _random = Random();

  late AnimationController _physicsAnimationController;
  late AnimationController _trialTransitionController;

  // Game Progress
  int _currentTrial = 1;
  int _score = 0;
  int _hits = 0;
  bool _isSoundEnabled = true;
  bool _isPaused = false;
  bool _isGameOver = false;

  // Interaction & Trial States
  DateTime? _trialStartTime;
  int _lastReactionTimeMs = 0;
  bool _hasStartedInteraction = false;
  bool _isSliding = false;
  bool _isEvaluatingResult = false;
  String? _feedbackMessage;
  bool? _lastTrialSuccess;
  bool _hasHitTargetThisTrial = false;

  // Drag & Aim States
  bool _isAiming = false;
  Offset _aimStartOffset = Offset.zero;
  Offset _aimCurrentOffset = Offset.zero;

  // Dynamic adaptive dimensions: gets progressively shorter/smaller in each level
  double get strikerDiameter => _adaptiveEngine.currentStrikerDiameter;
  double get targetDiameter => _adaptiveEngine.currentTargetDiameter;

  // Physical Masses for Momentum Transfer
  static const double strikerMass = 1.30;
  static const double targetMass = 1.00;

  // Playable Inner Court Rail Bounds (keeping pieces safely inside inner court)
  static const double courtRailLeft = 0.14;
  static const double courtRailRight = 0.86;
  static const double courtRailTop = 0.12;
  static const double courtRailBottom = 0.88;

  // Court Coordinates (Normalized 0.0 to 1.0)
  static const Offset _defaultStrikerOrigin = Offset(0.50, 0.76);
  Offset _strikerPos = _defaultStrikerOrigin;
  Offset _targetPos = const Offset(0.50, 0.22);

  // Dynamic boundary getters taking disc radii into account
  double get _strikerRadiusNormX => (strikerDiameter / 2) / _courtSize.width;
  double get _strikerRadiusNormY => (strikerDiameter / 2) / _courtSize.height;
  double get _strikerMinX => courtRailLeft + _strikerRadiusNormX;
  double get _strikerMaxX => courtRailRight - _strikerRadiusNormX;
  double get _strikerMinY => courtRailTop + _strikerRadiusNormY;
  double get _strikerMaxY => courtRailBottom - _strikerRadiusNormY;

  double get _targetRadiusNormX => (targetDiameter / 2) / _courtSize.width;
  double get _targetRadiusNormY => (targetDiameter / 2) / _courtSize.height;
  double get _targetMinX => courtRailLeft + _targetRadiusNormX;
  double get _targetMaxX => courtRailRight - _targetRadiusNormX;
  double get _targetMinY => courtRailTop + _targetRadiusNormY;
  double get _targetMaxY => courtRailBottom - _targetRadiusNormY;

  // Physical Velocities
  Offset _strikerVelocity = Offset.zero;
  Offset _targetVelocity = Offset.zero;
  double _targetRotation = 0.0;
  double _accumulatedDistance = 0.0;
  double _initialReleaseSpeed = 0.0;

  // Collision ripple effect coordinates
  Offset? _impactRippleCenter;
  double _impactRippleRadius = 0.0;

  // Layout Viewport Cache
  Size _courtSize = const Size(360, 520);

  @override
  void initState() {
    super.initState();
    VoiceCommandController.instance.registerGame((command) {
      switch (command.intent) {
        case VoiceIntent.pauseGame:
          pauseGame();
          break;
        case VoiceIntent.resumeGame:
          resumeGame();
          break;
        case VoiceIntent.exitGame:
        case VoiceIntent.goHome:
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
          break;
        default:
          break;
      }
    });

    _initAudio();
    _setupAnimations();
    _resetTrial(immediate: true);
  }

  void _initAudio() {
    try {
      _sfxAudioPlayer.setPlayerMode(PlayerMode.lowLatency);
      _sfxAudioPlayer.setVolume(0.80);
      _chimeAudioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      _chimeAudioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('[KingShanaba Audio] Init warning: $e');
    }
  }

  void _setupAnimations() {
    _physicsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onPhysicsTick);

    _trialTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _trialTransitionController.forward(from: 1.0);
  }

  @override
  void dispose() {
    VoiceCommandController.instance.unregisterGame();
    _physicsAnimationController.dispose();
    _trialTransitionController.dispose();
    _sfxAudioPlayer.dispose();
    _chimeAudioPlayer.dispose();
    _telemetryService.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // AUDIO & NORTHEAST CHIME HELPERS
  // --------------------------------------------------------------------------
  Future<void> _playSlideSound() async {
    if (!_isSoundEnabled) return;
    try {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
      // Plays on dedicated SFX player without stopping the Northeast chime!
      await _sfxAudioPlayer.stop();
      await _sfxAudioPlayer.play(
        AssetSource('audio/click.wav'),
        volume: 0.65,
      );
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Plays a random melodious chime from the Northeast India musical chime pool
  Future<void> _playRandomNortheastChime() async {
    if (!_isSoundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      final chime = _northeastChimePool[_random.nextInt(_northeastChimePool.length)];
      // Dedicated chime audio player continues uninterrupted for its full duration
      await _chimeAudioPlayer.stop();
      await _chimeAudioPlayer.play(
        AssetSource(chime),
        volume: 1.0,
      );
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  Future<void> _playMissSound() async {
    if (!_isSoundEnabled) return;
    try {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  // --------------------------------------------------------------------------
  // GAMEPLAY ENGINE & TRIAL LIFECYCLE
  // --------------------------------------------------------------------------
  void _resetTrial({bool immediate = false}) {
    if (_currentTrial > widget.totalTrials) {
      setState(() {
        _isGameOver = true;
      });
      widget.onGameCompleted?.call();
      return;
    }

    // Dynamic placement of target: safely inside inner court rails
    final double targetX = 0.38 + (_random.nextDouble() * 0.24);
    final double targetY = 0.20 + (_random.nextDouble() * 0.08);

    setState(() {
      _strikerPos = _defaultStrikerOrigin;
      _targetPos = Offset(targetX, targetY);
      _strikerVelocity = Offset.zero;
      _targetVelocity = Offset.zero;
      _accumulatedDistance = 0.0;
      _initialReleaseSpeed = 0.0;
      _isSliding = false;
      _isEvaluatingResult = false;
      _isAiming = false;
      _feedbackMessage = null;
      _lastTrialSuccess = null;
      _hasHitTargetThisTrial = false;
      _impactRippleCenter = null;
      _impactRippleRadius = 0.0;
      _hasStartedInteraction = false;
      _trialStartTime = DateTime.now();
    });

    if (!immediate) {
      _trialTransitionController.forward(from: 0.0);
    }
  }

  void pauseGame() {
    if (_isPaused || _isGameOver) return;
    setState(() {
      _isPaused = true;
    });
  }

  void resumeGame() {
    if (!_isPaused || _isGameOver) return;
    setState(() {
      _isPaused = false;
    });
  }



  // --------------------------------------------------------------------------
  // TACTILE DRAG & GESTURE SYSTEM (Free Movement across Court)
  // --------------------------------------------------------------------------
  void _onCourtPanDown(DragDownDetails details) {
    if (_isSliding || _isEvaluatingResult || _isPaused || _isGameOver) return;

    if (!_hasStartedInteraction && _trialStartTime != null) {
      _lastReactionTimeMs =
          DateTime.now().difference(_trialStartTime!).inMilliseconds;
      _hasStartedInteraction = true;
    }

    final double touchNormX =
        (details.localPosition.dx / _courtSize.width).clamp(0.0, 1.0);
    final double touchNormY =
        (details.localPosition.dy / _courtSize.height).clamp(0.0, 1.0);
    final Offset touchNorm = Offset(touchNormX, touchNormY);

    final double distToStriker = sqrt(
      pow((touchNorm.dx - _strikerPos.dx) * _courtSize.width, 2) +
          pow((touchNorm.dy - _strikerPos.dy) * _courtSize.height, 2),
    );

    setState(() {
      _isAiming = true;
      _aimStartOffset = touchNorm;
      _aimCurrentOffset = touchNorm;

      // If user tapped directly elsewhere in the lower half of the court, move striker there
      if (distToStriker > 48.0 && touchNormY > 0.45) {
        _strikerPos = Offset(
          touchNormX.clamp(_strikerMinX, _strikerMaxX),
          touchNormY.clamp(0.45, _strikerMaxY),
        );
      }
    });
  }

  void _onCourtPanUpdate(DragUpdateDetails details) {
    if (_isSliding || _isEvaluatingResult || _isPaused || _isGameOver) return;

    final double normX =
        (details.localPosition.dx / _courtSize.width).clamp(0.0, 1.0);
    final double normY =
        (details.localPosition.dy / _courtSize.height).clamp(0.0, 1.0);

    setState(() {
      _aimCurrentOffset = Offset(normX, normY);

      final double pullY = _aimCurrentOffset.dy - _aimStartOffset.dy;

      // Allow dragging striker freely within inner court rails
      if (pullY < -0.05 && pullY > -0.45 && _strikerPos.dy > 0.35) {
        _strikerPos = Offset(
          (_strikerPos.dx + (details.delta.dx / _courtSize.width))
              .clamp(_strikerMinX, _strikerMaxX),
          (_strikerPos.dy + (details.delta.dy / _courtSize.height))
              .clamp(_strikerMinY, _strikerMaxY),
        );
      }
    });
  }

  void _onCourtPanEnd(DragEndDetails details) {
    if (_isSliding || _isEvaluatingResult || _isPaused || _isGameOver) return;

    final double pullDx = _aimCurrentOffset.dx - _aimStartOffset.dx;
    final double pullDy = _aimCurrentOffset.dy - _aimStartOffset.dy;

    final Offset velocityPx = details.velocity.pixelsPerSecond;
    double vx = velocityPx.dx / _courtSize.width;
    double vy = velocityPx.dy / _courtSize.height;

    // Pull-back slingshot mode
    if (pullDy > 0.04) {
      vx = -pullDx * 6.5;
      vy = -pullDy * 7.5;
    } else if (vy.abs() < 0.25 && pullDy < -0.04) {
      // Forward swipe
      vx = pullDx * 6.0;
      vy = pullDy * 7.0;
    }

    // Default gentle forward glide if soft release
    if (vy > -0.25) {
      final double dxToTarget = _targetPos.dx - _strikerPos.dx;
      final double dyToTarget = _targetPos.dy - _strikerPos.dy;
      final double dist = max(0.1, sqrt(dxToTarget * dxToTarget + dyToTarget * dyToTarget));
      vx = (dxToTarget / dist) * 0.75;
      vy = -1.15 - (_random.nextDouble() * 0.35);
    }

    vx = vx.clamp(-1.8, 1.8);
    vy = vy.clamp(-2.4, -0.4);

    _initialReleaseSpeed = sqrt((vx * vx) + (vy * vy));
    _strikerVelocity = Offset(vx, vy);

    setState(() {
      _isSliding = true;
      _isAiming = false;
      _feedbackMessage = null;
    });

    _playSlideSound();
    _physicsAnimationController.repeat();
  }

  void _onCourtPanCancel() {
    setState(() {
      _isAiming = false;
    });
  }

  // --------------------------------------------------------------------------
  // 2D RIGID-BODY ELASTIC COLLISION PHYSICS ENGINE
  // --------------------------------------------------------------------------
  void _onPhysicsTick() {
    if (!_isSliding) return;

    const double dt = 0.016;
    final double friction = _adaptiveEngine.friction;
    final double courtW = _courtSize.width;
    final double courtH = _courtSize.height;

    // 1. Advance striker position
    double nextS1x = _strikerPos.dx + (_strikerVelocity.dx * dt);
    double nextS1y = _strikerPos.dy + (_strikerVelocity.dy * dt);

    // 2. Advance target position
    double nextT2x = _targetPos.dx + (_targetVelocity.dx * dt);
    double nextT2y = _targetPos.dy + (_targetVelocity.dy * dt);

    double svX = _strikerVelocity.dx;
    double svY = _strikerVelocity.dy;
    double tvX = _targetVelocity.dx;
    double tvY = _targetVelocity.dy;

    // Convert to pixel space for physical collision check
    final double sPxX = nextS1x * courtW;
    final double sPxY = nextS1y * courtH;
    final double tPxX = nextT2x * courtW;
    final double tPxY = nextT2y * courtH;

    final double dx = tPxX - sPxX;
    final double dy = tPxY - sPxY;
    final double dist = sqrt((dx * dx) + (dy * dy));

    final double strikerRadiusPx = strikerDiameter / 2;
    final double targetRadiusPx = targetDiameter / 2;
    final double minDist = strikerRadiusPx + targetRadiusPx;

    // 3. Physical Elastic Collision Check
    if (dist < minDist && dist > 0.001) {
      // Normal and tangent unit vectors
      final double nx = dx / dist;
      final double ny = dy / dist;
      final double tx = -ny;
      final double ty = nx;

      // Project velocities onto normal & tangent vectors
      final double v1n = (svX * courtW) * nx + (svY * courtH) * ny;
      final double v1t = (svX * courtW) * tx + (svY * courtH) * ty;
      final double v2n = (tvX * courtW) * nx + (tvY * courtH) * ny;
      final double v2t = (tvX * courtW) * tx + (tvY * courtH) * ty;

      // Only resolve if closing towards each other
      if (v1n - v2n > 0) {
        const double restitution = 0.82; // Elastic bounce with satisfying tactile weight
        final double totalMass = strikerMass + targetMass;

        final double v1nAfter =
            ((strikerMass - restitution * targetMass) * v1n + (1 + restitution) * targetMass * v2n) / totalMass;
        final double v2nAfter =
            ((1 + restitution) * strikerMass * v1n + (targetMass - restitution * strikerMass) * v2n) / totalMass;

        // Convert back to velocity vectors
        svX = (v1nAfter * nx + v1t * tx) / courtW;
        svY = (v1nAfter * ny + v1t * ty) / courtH;
        tvX = (v2nAfter * nx + v2t * tx) / courtW;
        tvY = (v2nAfter * ny + v2t * ty) / courtH;

        // Separate bodies to prevent overlap
        final double overlap = minDist - dist;
        nextS1x -= (nx * (overlap * 0.5)) / courtW;
        nextS1y -= (ny * (overlap * 0.5)) / courtH;
        nextT2x += (nx * (overlap * 0.5)) / courtW;
        nextT2y += (ny * (overlap * 0.5)) / courtH;

        // Physical rotation impulse on hit
        _targetRotation += 0.85;

        // Trigger hit effect and Northeast Chime
        if (!_hasHitTargetThisTrial) {
          _hasHitTargetThisTrial = true;
          _impactRippleCenter = Offset(nextT2x, nextT2y);
          _playRandomNortheastChime();
        }
      }
    }

    // 4. Boundary rebounds for both Striker and Target off inner wooden court rails
    // Striker boundaries (stays safely inside the inner court)
    if (nextS1x <= _strikerMinX) {
      nextS1x = _strikerMinX;
      svX = svX.abs() * 0.65;
      _playSlideSound();
    } else if (nextS1x >= _strikerMaxX) {
      nextS1x = _strikerMaxX;
      svX = -svX.abs() * 0.65;
      _playSlideSound();
    }
    if (nextS1y <= _strikerMinY) {
      nextS1y = _strikerMinY;
      svY = svY.abs() * 0.55;
      _playSlideSound();
    } else if (nextS1y >= _strikerMaxY) {
      nextS1y = _strikerMaxY;
      svY = -svY.abs() * 0.55;
      _playSlideSound();
    }

    // Target boundaries (never touches or protrudes into outer frame)
    if (nextT2x <= _targetMinX) {
      nextT2x = _targetMinX;
      tvX = tvX.abs() * 0.60;
    } else if (nextT2x >= _targetMaxX) {
      nextT2x = _targetMaxX;
      tvX = -tvX.abs() * 0.60;
    }
    if (nextT2y <= _targetMinY) {
      nextT2y = _targetMinY;
      tvY = tvY.abs() * 0.55;
    } else if (nextT2y >= _targetMaxY) {
      nextT2y = _targetMaxY;
      tvY = -tvY.abs() * 0.55;
    }

    // 5. Friction Deceleration
    final double speedDecay = max(0.0, 1.0 - (friction * 28.0 * dt));
    svX *= speedDecay;
    svY *= speedDecay;
    tvX *= speedDecay;
    tvY *= speedDecay;

    final double stepDist = sqrt(
      pow((nextS1x - _strikerPos.dx) * courtW, 2) +
          pow((nextS1y - _strikerPos.dy) * courtH, 2),
    );
    _accumulatedDistance += stepDist;

    final double currentStrikerSpeed = sqrt((svX * svX) + (svY * svY));
    final double currentTargetSpeed = sqrt((tvX * tvX) + (tvY * tvY));

    // Expand ripple if active
    if (_impactRippleCenter != null) {
      _impactRippleRadius += 2.8;
      if (_impactRippleRadius > 45.0) {
        _impactRippleCenter = null;
        _impactRippleRadius = 0.0;
      }
    }

    setState(() {
      _strikerPos = Offset(nextS1x, nextS1y);
      _targetPos = Offset(nextT2x, nextT2y);
      _strikerVelocity = Offset(svX, svY);
      _targetVelocity = Offset(tvX, tvY);
    });

    // 6. Stop check when both pieces settle
    if (currentStrikerSpeed < 0.024 && currentTargetSpeed < 0.024) {
      _physicsAnimationController.stop();
      _isSliding = false;
      _evaluateTrialResult();
    }
  }

  void _evaluateTrialResult() {
    if (_isEvaluatingResult) return;
    _isEvaluatingResult = true;

    final double courtW = _courtSize.width;
    final double courtH = _courtSize.height;

    final double discPxX = _strikerPos.dx * courtW;
    final double discPxY = _strikerPos.dy * courtH;
    final double targetPxX = _targetPos.dx * courtW;
    final double targetPxY = _targetPos.dy * courtH;

    final double distanceToTarget = sqrt(
      pow(discPxX - targetPxX, 2) + pow(discPxY - targetPxY, 2),
    );

    final double tolerance = _adaptiveEngine.targetRadius;
    final bool isHit = _hasHitTargetThisTrial || (distanceToTarget <= tolerance);

    if (isHit) {
      _hits++;
      final int pointsGained = max(60, 120 - (distanceToTarget * 0.70).round());
      _score += pointsGained;
      _feedbackMessage = 'Chekphei Struck! Northeast Chime +$pointsGained';
      _lastTrialSuccess = true;
    } else {
      _lastTrialSuccess = false;
      if (discPxY > targetPxY + tolerance) {
        _feedbackMessage = 'A gentle push! Slide a little further';
      } else if (discPxY < targetPxY - tolerance) {
        _feedbackMessage = 'Good force! Try a softer touch';
      } else {
        _feedbackMessage = 'Close call! Keep your focus';
      }
      _playMissSound();
    }

    final int safeReactionTime =
        _lastReactionTimeMs > 0 ? _lastReactionTimeMs : 1200;

    _adaptiveEngine.recordResult(
      isHit: isHit,
      reactionTimeMs: safeReactionTime,
    );

    final telemetry = ShanabaTrialTelemetry(
      sessionId: widget.sessionId,
      trialNumber: _currentTrial,
      slideDistance: _accumulatedDistance,
      reactionTimeMs: safeReactionTime,
      isCorrect: isHit,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      targetTolerance: tolerance,
      friction: _adaptiveEngine.friction,
      initialVelocity: _initialReleaseSpeed,
    );

    _telemetryService.logTrial(telemetry);

    setState(() {});

    // Fluid session transition
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted || _isGameOver) return;
      setState(() {
        _currentTrial++;
      });
      _resetTrial();
    });
  }

  void _restartGame() {
    setState(() {
      _currentTrial = 1;
      _score = 0;
      _hits = 0;
      _isGameOver = false;
      _isPaused = false;
    });
    _resetTrial(immediate: true);
  }

  // --------------------------------------------------------------------------
  // USER INTERFACE
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatsHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.65, // Standard mobile phone portrait format (~9:14)
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _courtSize = Size(constraints.maxWidth, constraints.maxHeight);

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanDown: _onCourtPanDown,
                          onPanUpdate: _onCourtPanUpdate,
                          onPanEnd: _onCourtPanEnd,
                          onPanCancel: _onCourtPanCancel,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: cream,
                              borderRadius: BorderRadius.circular(26.0),
                              border: Border.all(
                                color: primarySage.withValues(alpha: 0.22),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: darkGreen.withValues(alpha: 0.10),
                                  blurRadius: 16.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24.0),
                              child: Stack(
                                fit: StackFit.expand,
                                clipBehavior: Clip.none,
                                children: [
                                  // 1. Court Background (blended into platform theme)
                                  _buildBlendedCourt(),

                                  // 2. Trajectory Aim Guide
                                  if (_isAiming && !_isSliding)
                                    CustomPaint(
                                      size: _courtSize,
                                      painter: _TrajectoryGuidePainter(
                                        discOrigin: _strikerPos,
                                        targetCenter: _targetPos,
                                        aimStart: _aimStartOffset,
                                        aimCurrent: _aimCurrentOffset,
                                      ),
                                    ),

                                  // 3. Dynamic Impact Wave Ripple
                                  if (_impactRippleCenter != null)
                                    Positioned(
                                      left: (_impactRippleCenter!.dx * _courtSize.width) - _impactRippleRadius,
                                      top: (_impactRippleCenter!.dy * _courtSize.height) - _impactRippleRadius,
                                      width: _impactRippleRadius * 2,
                                      height: _impactRippleRadius * 2,
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: goldAccent.withValues(alpha: 0.8),
                                              width: 2.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // 4. Physical Hittable Chekphei Target Piece
                                  _buildHittableTarget(),

                                  // 5. Authentic Kang Striker Disc
                                  _buildStrikerDisc(),

                                  // 6. Launch & Aim Cue
                                  if (!_isSliding && !_isEvaluatingResult && !_isAiming)
                                    _buildLaunchCue(),

                                  // 7. Subsession Intro Transition Banner
                                  if (!_isSliding && _feedbackMessage == null)
                                    _buildSubsessionTransitionBanner(),

                                  // 8. Trial Feedback Banner
                                  if (_feedbackMessage != null) _buildFeedbackBanner(),

                                  // 9. Pause Overlay
                                  if (_isPaused) _buildPauseOverlay(),

                                  // 10. Game Over Dialog
                                  if (_isGameOver) _buildGameOverDialog(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            _buildInstructionFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: softBackground,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 6.0,
      leadingWidth: 50.0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Center(
          child: IconButton(
            tooltip: 'Back to activities',
            style: IconButton.styleFrom(
              backgroundColor: lightGreen,
              fixedSize: const Size(38, 38),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded, color: darkGreen, size: 20),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.psychology_alt_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'King Shanaba',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Traditional Manipuri Kangshang',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 4.0),
            child: VoiceStatusIndicator(compact: true),
          ),
        ),
        IconButton(
          tooltip: _isSoundEnabled ? 'Mute Sound' : 'Enable Sound',
          style: IconButton.styleFrom(
            backgroundColor: lightGreen,
            fixedSize: const Size(38, 38),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(
            _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: darkGreen,
            size: 20.0,
          ),
          onPressed: () {
            setState(() {
              _isSoundEnabled = !_isSoundEnabled;
            });
          },
        ),
        const SizedBox(width: 4.0),
        IconButton(
          tooltip: _isPaused ? 'Resume' : 'Pause',
          style: IconButton.styleFrom(
            backgroundColor: lightGreen,
            fixedSize: const Size(38, 38),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(
            _isPaused ? Icons.play_arrow_rounded : Icons.pause_circle_outline_rounded,
            color: darkGreen,
            size: 20.0,
          ),
          onPressed: () {
            if (_isPaused) {
              resumeGame();
            } else {
              pauseGame();
            }
          },
        ),
        const SizedBox(width: 10.0),
      ],
    );
  }

  /// Blends the authentic traditional court image with softened contrast for the board
  Widget _buildBlendedCourt() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Authentic wooden board
        Image.asset(
          courtBoardAsset,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              size: _courtSize,
              painter: _ManipuriCourtFallbackPainter(
                targetCenter: _targetPos,
                courtSize: _courtSize,
              ),
            );
          },
        ),
        // 2. Subtle warm glaze over the board to soften harsh dark shadows without cloudiness
        Container(
          color: cream.withValues(alpha: 0.16),
        ),
        // 3. Soft border line defining court perimeter
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: primarySage.withValues(alpha: 0.20),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        // 4. Traditional inner court rail boundary markings
        CustomPaint(
          size: _courtSize,
          painter: _CourtInnerRailPainter(),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14.0, 6.0, 14.0, 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: primarySage.withValues(alpha: 0.22), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: _buildPill(
              icon: Icons.flag_rounded,
              label: 'Trial ${_currentTrial.clamp(1, widget.totalTrials)} / ${widget.totalTrials}',
              bgColor: lightGreen,
              textColor: darkGreen,
            ),
          ),
          const SizedBox(width: 6.0),
          Flexible(
            child: _buildPill(
              icon: Icons.speed_rounded,
              label: 'Lvl ${_adaptiveEngine.level}: ${_adaptiveEngine.difficultyLabel}',
              bgColor: Colors.white,
              textColor: darkGreen,
            ),
          ),
          const SizedBox(width: 6.0),
          Flexible(
            child: _buildPill(
              icon: Icons.stars_rounded,
              label: 'Score: $_score',
              bgColor: lightGreen,
              textColor: darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: textColor),
          const SizedBox(width: 4.0),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tangible, physical hittable Chekphei target piece with smooth subsession spring entrance
  Widget _buildHittableTarget() {
    final double pxX = (_targetPos.dx * _courtSize.width) - (targetDiameter / 2);
    final double pxY = (_targetPos.dy * _courtSize.height) - (targetDiameter / 2);

    return Positioned(
      left: pxX,
      top: pxY,
      width: targetDiameter,
      height: targetDiameter,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _trialTransitionController,
          builder: (context, child) {
            final double animVal = _trialTransitionController.value;
            // Smooth elastic/spring entrance curve when a new subsession begins
            final double scale = (Curves.easeOutBack.transform(animVal)).clamp(0.0, 1.15);
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: animVal.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Transform.rotate(
            angle: _targetRotation,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.30),
                    blurRadius: 7.0,
                    offset: const Offset(0, 3.0),
                  ),
                  if (_hasHitTargetThisTrial)
                    BoxShadow(
                      color: successGreen.withValues(alpha: 0.65),
                      blurRadius: 18.0,
                      spreadRadius: 3.0,
                    ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    targetMarkerAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0xFFA5D6A7), primarySage, Color(0xFF2E7D32)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.circle, color: goldAccent, size: 20),
                        ),
                      );
                    },
                  ),
                  // Subtle traditional enamelled brass bezel
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primarySage.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
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

  Widget _buildStrikerDisc() {
    final double pxX = (_strikerPos.dx * _courtSize.width) - (strikerDiameter / 2);
    final double pxY = (_strikerPos.dy * _courtSize.height) - (strikerDiameter / 2);

    return Positioned(
      left: pxX,
      top: pxY,
      width: strikerDiameter,
      height: strikerDiameter,
      child: IgnorePointer(
        child: AnimatedScale(
          scale: _isAiming ? 1.08 : (_isSliding ? 0.96 : 1.0),
          duration: const Duration(milliseconds: 140),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withValues(alpha: 0.35),
                  blurRadius: _isSliding ? 10.0 : 6.0,
                  offset: Offset(0, _isSliding ? 4.0 : 2.0),
                ),
                if (_isAiming)
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.70),
                    blurRadius: 14.0,
                    spreadRadius: 2.0,
                  ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  strikerDiscAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFE6D7C3), Color(0xFF6D4C41)],
                        ),
                        border: Border.all(color: goldAccent, width: 2.0),
                      ),
                    );
                  },
                ),
                // Subtle tactile lacquer rim ring
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: goldAccent.withValues(alpha: 0.55),
                      width: 1.5,
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

  /// Smooth floating transition indicator when a new subsession begins
  Widget _buildSubsessionTransitionBanner() {
    return Positioned(
      top: 18.0,
      left: 20.0,
      right: 20.0,
      child: AnimatedBuilder(
        animation: _trialTransitionController,
        builder: (context, child) {
          final double t = _trialTransitionController.value;
          // Smoothly slide in and fade in during first 35%, stay visible, fade out gracefully
          final double opacity = (t < 0.35 ? t / 0.35 : (t > 0.72 ? (1.0 - t) / 0.28 : 1.0)).clamp(0.0, 1.0);
          final double translateY = (1.0 - (t.clamp(0.0, 0.35) / 0.35)) * -14.0;

          if (opacity <= 0.02) return const SizedBox.shrink();

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Opacity(
              opacity: opacity,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withValues(alpha: 0.25),
                        blurRadius: 10.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_filled_rounded, size: 16.0, color: goldAccent),
                      const SizedBox(width: 6.0),
                      Text(
                        'Trial $_currentTrial of ${widget.totalTrials} • Aim & Strike',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLaunchCue() {
    final double baselineY = (_strikerPos.dy * _courtSize.height) + 42.0;

    return Positioned(
      left: 16.0,
      right: 16.0,
      top: baselineY.clamp(30.0, _courtSize.height - 50.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: primarySage.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.10),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe_up_rounded, size: 15.0, color: darkGreen),
              SizedBox(width: 5.0),
              Flexible(
                child: Text(
                  'Pull back to aim & strike',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner() {
    final bool isSuccess = _lastTrialSuccess == true;
    return Positioned(
      top: 18.0,
      left: 20.0,
      right: 20.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSuccess ? successGreen : cream,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 12.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.music_note_rounded : Icons.info_outline_rounded,
              color: isSuccess ? Colors.white : textDark,
              size: 22.0,
            ),
            const SizedBox(width: 10.0),
            Flexible(
              child: Text(
                _feedbackMessage ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isSuccess ? Colors.white : textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.record_voice_over_rounded, size: 14.0, color: darkGreen),
            SizedBox(width: 6.0),
            Flexible(
              child: Text(
                'Pull back to aim & strike • Voice: "pause", "resume", "exit"',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: darkGreen,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.50),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32.0),
          padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_filled_rounded,
                  size: 48.0, color: primarySage),
              const SizedBox(height: 12.0),
              const Text(
                'Game Paused',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Say "Resume" or tap below.',
                style: TextStyle(fontSize: 14.0, color: textGrey),
              ),
              const SizedBox(height: 18.0),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primarySage,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22.0, vertical: 12.0),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Resume Session',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
                ),
                onPressed: resumeGame,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverDialog() {
    final double accuracy =
        widget.totalTrials > 0 ? (_hits / widget.totalTrials) * 100 : 0.0;

    return Container(
      color: Colors.black.withValues(alpha: 0.50),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20.0,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.military_tech_rounded,
                size: 52.0,
                color: goldAccent,
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Session Complete!',
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4.0),
              const Text(
                'Your Manipuri tactile exercise has been recorded.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.0, color: textGrey),
              ),
              const SizedBox(height: 14.0),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Accuracy',
                      value: '${accuracy.toStringAsFixed(0)}%',
                      icon: Icons.track_changes_rounded,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Score',
                      value: '$_score',
                      icon: Icons.stars_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18.0),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: borderGrey, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/home', (route) => false);
                        }
                      },
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primarySage,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onPressed: _restartGame,
                      child: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: softBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.0, color: primarySage),
          const SizedBox(height: 3.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
                color: textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. CUSTOM PAINTERS: TRAJECTORY & WOODEN COURT FALLBACK
// ============================================================================

/// Dotted trajectory aim line rendered dynamically during touch & pull-back.
class _TrajectoryGuidePainter extends CustomPainter {
  final Offset discOrigin;
  final Offset targetCenter;
  final Offset aimStart;
  final Offset aimCurrent;

  _TrajectoryGuidePainter({
    required this.discOrigin,
    required this.targetCenter,
    required this.aimStart,
    required this.aimCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startX = discOrigin.dx * size.width;
    final double startY = discOrigin.dy * size.height;

    final double pullDx = aimCurrent.dx - aimStart.dx;
    final double pullDy = aimCurrent.dy - aimStart.dy;

    double endX;
    double endY;

    if (pullDy.abs() > 0.02 || pullDx.abs() > 0.02) {
      endX = startX - (pullDx * size.width * 2.2);
      endY = startY - (pullDy * size.height * 2.2);
    } else {
      endX = targetCenter.dx * size.width;
      endY = targetCenter.dy * size.height;
    }

    final double dx = endX - startX;
    final double dy = endY - startY;
    final double dist = sqrt((dx * dx) + (dy * dy));

    if (dist <= 1.0) return;

    final Paint dotPaint = Paint()
      ..color = const Color(0xFFD4A373).withValues(alpha: 0.85)
      ..strokeCap = StrokeCap.round;

    final double step = 16.0;
    final int count = (dist / step).clamp(2, 24).toInt();

    for (int i = 1; i <= count; i++) {
      final double progress = i / count;
      final double px = startX + (dx * progress);
      final double py = startY + (dy * progress);
      final double dotRadius = 2.5 + (progress * 1.5);
      canvas.drawCircle(Offset(px, py), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryGuidePainter oldDelegate) {
    return oldDelegate.discOrigin != discOrigin ||
        oldDelegate.aimCurrent != aimCurrent ||
        oldDelegate.targetCenter != targetCenter;
  }
}

/// Fallback wooden court painter if image asset is unavailable.
class _ManipuriCourtFallbackPainter extends CustomPainter {
  final Offset targetCenter;
  final Size courtSize;

  _ManipuriCourtFallbackPainter({
    required this.targetCenter,
    required this.courtSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect courtRect = Offset.zero & size;

    final Paint woodPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE2A860),
          Color(0xFFC78B43),
          Color(0xFFB07231),
        ],
      ).createShader(courtRect);

    canvas.drawRect(courtRect, woodPaint);

    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final Rect innerBounds = Rect.fromLTRB(
      size.width * 0.08,
      size.height * 0.06,
      size.width * 0.92,
      size.height * 0.94,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(innerBounds, const Radius.circular(16.0)),
        linePaint);

    // Center target line
    canvas.drawLine(
      Offset(innerBounds.left, targetCenter.dy * size.height),
      Offset(innerBounds.right, targetCenter.dy * size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ManipuriCourtFallbackPainter oldDelegate) {
    return oldDelegate.targetCenter != targetCenter;
  }
}

/// Renders subtle, soft court rail markings showing the authentic playable area
class _CourtInnerRailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double left = size.width * _KingShanabaGameScreenState.courtRailLeft;
    final double top = size.height * _KingShanabaGameScreenState.courtRailTop;
    final double right = size.width * _KingShanabaGameScreenState.courtRailRight;
    final double bottom = size.height * _KingShanabaGameScreenState.courtRailBottom;

    final Paint railPaint = Paint()
      ..color = const Color(0xFFEDE7D7).withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final RRect innerRail = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(14.0),
    );
    canvas.drawRRect(innerRail, railPaint);

    // Inner subtle guide line
    final Paint innerDashPaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final RRect innerGuide = RRect.fromRectAndRadius(
      Rect.fromLTRB(left + 3.0, top + 3.0, right - 3.0, bottom - 3.0),
      const Radius.circular(12.0),
    );
    canvas.drawRRect(innerGuide, innerDashPaint);

    // Subtle target zone baseline marking
    final Paint linePaint = Paint()
      ..color = const Color(0xFFEDE7D7).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(left + 10.0, size.height * 0.30),
      Offset(right - 10.0, size.height * 0.30),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
