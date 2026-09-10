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
import '../widgets/animated_fragmented_divider.dart';
import '../widgets/game_completion_dialog.dart';

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



/// Traditional Manipuri Kang obstacle piece (Kangkhun / Guard Piece)
class ShanabaObstacle {
  Offset position; // Normalized coordinates (0.0 to 1.0)
  final double radius;
  final bool isMoving;
  double velocityX;
  final double minX;
  final double maxX;

  ShanabaObstacle({
    required this.position,
    this.radius = 13.0,
    this.isMoving = false,
    this.velocityX = 0.22,
    this.minX = 0.16,
    this.maxX = 0.84,
  });
}

/// Minimal Adaptive Difficulty Controller for dementia cognitive-motor therapy.
class ShanabaAdaptiveEngine {
  int consecutiveHits = 0;
  int consecutiveMisses = 0;
  int level = 1;

  // Base parameters
  double targetRadius = 26.0; // Clean, properly proportioned target hit tolerance
  double friction = 0.080; // Natural wooden court deceleration

  /// Adaptive striker diameter: sleek authentic dimensions
  double get currentStrikerDiameter {
    switch (level) {
      case 1:
        return 42.0; // Friendly launch surface
      case 2:
        return 38.0;
      case 3:
        return 35.0;
      case 4:
        return 32.0;
      default:
        return 29.0; // Master challenge
    }
  }

  /// Adaptive target diameter: sleek authentic Chekphei coin
  double get currentTargetDiameter {
    switch (level) {
      case 1:
        return 30.0;
      case 2:
        return 26.0;
      case 3:
        return 23.0;
      case 4:
        return 21.0;
      default:
        return 19.0;
    }
  }

  void recordResult({required bool isHit, required int reactionTimeMs}) {
    if (isHit) {
      consecutiveHits++;
      consecutiveMisses = 0;

      if (consecutiveHits >= 2 && level < 5) {
        level++;
        consecutiveHits = 0;
        targetRadius = max(18.0, targetRadius - 2.5);
        friction = (friction + 0.003).clamp(0.06, 0.11);
      }
    } else {
      consecutiveMisses++;
      consecutiveHits = 0;

      if (consecutiveMisses >= 2 && level > 1) {
        level--;
        consecutiveMisses = 0;
        targetRadius = min(32.0, targetRadius + 3.0);
        friction = (friction - 0.004).clamp(0.06, 0.11);
      }
    }

    if (reactionTimeMs > 4500) {
      if (level > 1) level--;
      consecutiveMisses = 0;
      targetRadius = min(34.0, targetRadius + 2.5);
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
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF214E3B);
  static const Color textGrey = Color(0xFF66736C);
  static const Color cream = Color(0xFFEDE7D7);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color goldAccent = Color(0xFFD4A373);
  static const Color screenBg = Color(0xFFF0F4F8);
  static const Color navBarBg = Color(0xFFEAF2F8); // Light blue nav surface matching Bamboo Dance
  static const Color primaryNavy = Color(0xFF1E293B);
  static const Color slateBorder = Color(0xFFE2E8F0);
  static const Color peachAccent = Color(0xFFEAA083);
  static const Color pinkAccent = Color(0xFFE89BA6);

  // Pleasant Sound Asset (replaces the 4 previous chimes)
  static const String pleasantSoundAsset = 'audio/pleasant_chime.wav';

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
  late AnimationController _patrolAnimationController;

  // Game Progress
  static const String _prefKeyHighScore = 'smriti_king_shanaba_high_score';
  static const String _prefKeyLevel = 'smriti_king_shanaba_level';
  int _currentTrial = 1;
  int _score = 0;
  int _hits = 0;
  int _highScore = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  final List<int> _reactionTimes = [];
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

  // Traditional Obstacle Pieces (Kangkhun Guard Discs)
  List<ShanabaObstacle> _obstacles = [];

  // Dynamic adaptive dimensions: gets progressively shorter/smaller in each level
  double get strikerDiameter => _adaptiveEngine.currentStrikerDiameter;
  double get targetDiameter => _adaptiveEngine.currentTargetDiameter;

  // Physical Masses for Momentum Transfer
  static const double strikerMass = 1.30;
  static const double targetMass = 1.00;

  // Playable Inner Court Rail Bounds (maximizing playable court area)
  static const double courtRailLeft = 0.05;
  static const double courtRailRight = 0.95;
  static const double courtRailTop = 0.04;
  static const double courtRailBottom = 0.95;

  // Court Coordinates (Normalized 0.0 to 1.0)
  static const Offset _defaultStrikerOrigin = Offset(0.50, 0.88);
  Offset _strikerPos = _defaultStrikerOrigin;
  Offset _targetPos = const Offset(0.50, 0.13);

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
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        final savedLevel = prefs.getInt(_prefKeyLevel) ?? 1;
        setState(() {
          _highScore = prefs.getInt(_prefKeyHighScore) ?? 0;
          _adaptiveEngine.level = savedLevel.clamp(1, 5);
        });
      }
    });
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

    // Continuous 60fps patrol loop: obstacles move smoothly at all times (before, during & after aim)
    _patrolAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onPatrolTick)..repeat();
  }

  void _onPatrolTick() {
    if (!mounted || _isPaused || _isGameOver) return;
    bool hasMoving = false;
    for (int i = 0; i < _obstacles.length; i++) {
      if (_obstacles[i].isMoving) {
        hasMoving = true;
        break;
      }
    }
    if (!hasMoving) return;

    const double dt = 0.016;
    for (int i = 0; i < _obstacles.length; i++) {
      final obs = _obstacles[i];
      if (obs.isMoving) {
        double nx = obs.position.dx + (obs.velocityX * dt);
        if (nx <= obs.minX) {
          nx = obs.minX;
          obs.velocityX = obs.velocityX.abs();
        } else if (nx >= obs.maxX) {
          nx = obs.maxX;
          obs.velocityX = -obs.velocityX.abs();
        }
        obs.position = Offset(nx, obs.position.dy);
      }
    }

    // While not sliding, trigger frame render so moving obstacle glides smoothly in real-time
    if (!_isSliding) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    VoiceCommandController.instance.unregisterGame();
    _patrolAnimationController.dispose();
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

  /// Plays a soothing, pleasant sound when target is struck
  Future<void> _playPleasantSound() async {
    if (!_isSoundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      await _chimeAudioPlayer.stop();
      await _chimeAudioPlayer.play(
        AssetSource(pleasantSoundAsset),
        volume: 0.85,
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
  // GAMEPLAY ENGINE & SESSION LIFECYCLE
  // --------------------------------------------------------------------------
  /// Generates randomized, strategically positioned Kangkhun guard obstacles.
  /// Guaranteed mathematically doable: always leaves an open, intuitive corridor
  /// or clear bankable ricochet path to the target piece.
  List<ShanabaObstacle> _generateDoableObstacles(
    int level, {
    required Offset targetPos,
    required Offset strikerPos,
  }) {
    final List<ShanabaObstacle> list = [];

    // Calculate where the straight aim ray from striker to target passes mid-court (y ~ 0.48)
    const double midY = 0.48;
    final double spanY = targetPos.dy - strikerPos.dy;
    final double t = spanY.abs() > 0.001 ? (midY - strikerPos.dy) / spanY : 0.5;
    final double centerLineX = (strikerPos.dx + t * (targetPos.dx - strikerPos.dx)).clamp(0.20, 0.80);

    if (level <= 1) {
      // Level 1: 1 Gentle Flank Guard.
      // Placed far out on the opposite flank from the target line, leaving the central direct lane completely open (>100px)
      final bool placeOnLeft = centerLineX > 0.50;
      final double flankX = placeOnLeft
          ? 0.18 + (_random.nextDouble() * 0.10) // 0.18 .. 0.28
          : 0.72 + (_random.nextDouble() * 0.10); // 0.72 .. 0.82
      final double obsY = 0.42 + (_random.nextDouble() * 0.12);
      list.add(ShanabaObstacle(
        position: Offset(flankX, obsY),
        radius: 12.0,
      ));
    } else if (level == 2) {
      // Level 2: 1 Guard piece off-center with guaranteed clear direct lane (>80px clearance)
      final bool placeOnLeft = _random.nextBool();
      double obsX = placeOnLeft
          ? centerLineX - (0.22 + _random.nextDouble() * 0.08)
          : centerLineX + (0.22 + _random.nextDouble() * 0.08);
      obsX = obsX.clamp(0.18, 0.82);
      final double obsY = 0.40 + (_random.nextDouble() * 0.14);
      list.add(ShanabaObstacle(
        position: Offset(obsX, obsY),
        radius: 12.5,
      ));
    } else if (level == 3) {
      // Level 3: "The Gateway" - 2 Guards creating a visible opening aligned with the target
      // Left and right guards positioned with a guaranteed 85px-105px clearance corridor
      const double corridorHalfWidth = 0.14; // ~28% of court width
      final double leftX = (centerLineX - corridorHalfWidth - (_random.nextDouble() * 0.08)).clamp(0.16, 0.36);
      final double rightX = (centerLineX + corridorHalfWidth + (_random.nextDouble() * 0.08)).clamp(0.64, 0.84);
      final double leftY = 0.38 + (_random.nextDouble() * 0.12);
      final double rightY = 0.42 + (_random.nextDouble() * 0.12);
      list.add(ShanabaObstacle(position: Offset(leftX, leftY), radius: 13.0));
      list.add(ShanabaObstacle(position: Offset(rightX, rightY), radius: 13.0));
    } else if (level == 4) {
      // Level 4: Staggered Challenge with dual routes (Direct corridor + Ricochet rail)
      final double x1 = (centerLineX - 0.13).clamp(0.22, 0.42);
      final double y1 = 0.36 + (_random.nextDouble() * 0.08);
      final double x2 = (centerLineX + 0.17).clamp(0.58, 0.78);
      final double y2 = 0.52 + (_random.nextDouble() * 0.08);
      list.add(ShanabaObstacle(position: Offset(x1, y1), radius: 13.5));
      list.add(ShanabaObstacle(position: Offset(x2, y2), radius: 13.5));
    } else {
      // Level 5 (Master Court): 1 Stationary Flank Guard + 1 Smooth Patrol Guard
      // The patrol guard moves continuously across mid-court (y ~ 0.52), challenging timing & rhythm
      final bool staticOnLeft = centerLineX > 0.50;
      final double staticX = staticOnLeft
          ? 0.22 + (_random.nextDouble() * 0.08)
          : 0.70 + (_random.nextDouble() * 0.08);
      list.add(ShanabaObstacle(
        position: Offset(staticX, 0.36),
        radius: 13.0,
      ));

      list.add(ShanabaObstacle(
        position: const Offset(0.50, 0.52),
        radius: 13.0,
        isMoving: true,
        minX: 0.26,
        maxX: 0.74,
        velocityX: 0.22,
      ));
    }
    return list;
  }

  void _resetTrial({bool immediate = false}) {
    if (_currentTrial > widget.totalTrials) {
      if (_score > _highScore) {
        _highScore = _score;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(_prefKeyHighScore, _highScore);
          prefs.setInt(_prefKeyLevel, _adaptiveEngine.level);
        });
      }
      setState(() {
        _isGameOver = true;
      });
      widget.onGameCompleted?.call();
      return;
    }

    // Dynamic placement of target: safely along the top Chei target line
    final double targetX = 0.28 + (_random.nextDouble() * 0.44);
    final double targetY = 0.11 + (_random.nextDouble() * 0.05);
    final Offset newTargetPos = Offset(targetX, targetY);

    // Generate randomized, mathematically doable obstacles tailored to this round's target position
    final List<ShanabaObstacle> newObstacles = _generateDoableObstacles(
      _adaptiveEngine.level,
      targetPos: newTargetPos,
      strikerPos: _defaultStrikerOrigin,
    );

    setState(() {
      _strikerPos = _defaultStrikerOrigin;
      _targetPos = newTargetPos;
      _obstacles = newObstacles;
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
  // TACTILE DRAG & GESTURE SYSTEM (Pure Manual Aiming - No Auto Aim)
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

    setState(() {
      _isAiming = true;
      _aimStartOffset = touchNorm;
      _aimCurrentOffset = touchNorm;

      // Allow choosing launch station along the baseline if tapped near the bottom
      if (touchNormY > 0.74) {
        _strikerPos = Offset(
          touchNormX.clamp(_strikerMinX, _strikerMaxX),
          _defaultStrikerOrigin.dy,
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
    });
  }

  void _onCourtPanEnd(DragEndDetails details) {
    if (_isSliding || _isEvaluatingResult || _isPaused || _isGameOver) return;

    final double courtW = _courtSize.width;
    final double courtH = _courtSize.height;

    // 1. Calculate drag displacement directly in screen pixels
    final double dragPxX = (_aimCurrentOffset.dx - _aimStartOffset.dx) * courtW;
    final double dragPxY = (_aimCurrentOffset.dy - _aimStartOffset.dy) * courtH;
    final double dragDistPx = sqrt(dragPxX * dragPxX + dragPxY * dragPxY);

    // Cancel if tap had insufficient drag motion (NO AUTO-AIM)
    if (dragDistPx < 8.0) {
      setState(() {
        _isAiming = false;
      });
      return;
    }

    // 2. Slingshot launch direction in screen pixels
    double launchDirPxX;
    double launchDirPxY;

    if (dragPxY > 0.0) {
      // Slingshot pull-back: pulling downward launches upward into the court
      launchDirPxX = -dragPxX;
      launchDirPxY = -dragPxY;
    } else {
      // Forward flick / push
      launchDirPxX = dragPxX;
      launchDirPxY = dragPxY;
    }

    final double launchDist = sqrt(launchDirPxX * launchDirPxX + launchDirPxY * launchDirPxY);
    if (launchDist > 0.001) {
      launchDirPxX /= launchDist;
      launchDirPxY /= launchDist;
    }

    // Ensure the shot always launches upward into the court (negative Y in screen pixels)
    if (launchDirPxY >= -0.15) {
      launchDirPxY = -0.15;
      final double reNorm = sqrt(launchDirPxX * launchDirPxX + launchDirPxY * launchDirPxY);
      launchDirPxX /= reNorm;
      launchDirPxY /= reNorm;
    }

    // 3. Generous physical launch speed in screen pixels per second
    final double speedPxPerSec = (dragDistPx * 18.0).clamp(courtH * 1.8, courtH * 4.6);

    // 4. Set striker velocity in normalized coordinates for exact dt integration
    final double vx = (launchDirPxX * speedPxPerSec) / courtW;
    final double vy = (launchDirPxY * speedPxPerSec) / courtH;

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

        // Trigger hit effect and pleasant sound
        if (!_hasHitTargetThisTrial) {
          _hasHitTargetThisTrial = true;
          _impactRippleCenter = Offset(nextT2x, nextT2y);
          _playPleasantSound();
        }
      }
    }

    // 3.5. Obstacle (Kangkhun) Rigid Collision (Striker & Target)
    for (final obs in _obstacles) {
      final double obsPxX = obs.position.dx * courtW;
      final double obsPxY = obs.position.dy * courtH;

      // 3.5.1 Striker vs Obstacle
      final double odx = sPxX - obsPxX;
      final double ody = sPxY - obsPxY;
      final double odist = sqrt((odx * odx) + (ody * ody));
      final double minObsDist = strikerRadiusPx + obs.radius;

      if (odist < minObsDist && odist > 0.001) {
        final double onx = odx / odist;
        final double ony = ody / odist;
        final double vDotN = (svX * courtW) * onx + (svY * courtH) * ony;

        if (vDotN < 0) {
          const double restitution = 0.85;
          final double newVn = -vDotN * restitution;
          final double deltaVn = newVn - vDotN;

          svX += (deltaVn * onx) / courtW;
          svY += (deltaVn * ony) / courtH;

          final double overlap = minObsDist - odist;
          nextS1x += (onx * overlap) / courtW;
          nextS1y += (ony * overlap) / courtH;

          _playSlideSound();
        }
      }

      // 3.5.2 Target vs Obstacle (prevents struck target from passing through or overlapping obstacles)
      final double todx = tPxX - obsPxX;
      final double tody = tPxY - obsPxY;
      final double todist = sqrt((todx * todx) + (tody * tody));
      final double minTargetObsDist = targetRadiusPx + obs.radius;

      if (todist < minTargetObsDist && todist > 0.001) {
        final double tonx = todx / todist;
        final double tony = tody / todist;
        final double tvDotN = (tvX * courtW) * tonx + (tvY * courtH) * tony;

        if (tvDotN < 0) {
          const double restitution = 0.80;
          final double newTvN = -tvDotN * restitution;
          final double deltaTvN = newTvN - tvDotN;

          tvX += (deltaTvN * tonx) / courtW;
          tvY += (deltaTvN * tony) / courtH;

          final double toverlap = minTargetObsDist - todist;
          nextT2x += (tonx * toverlap) / courtW;
          nextT2y += (tony * toverlap) / courtH;

          _targetRotation += 0.45;
          _playSlideSound();
        }
      }
    }

    // 4. Boundary rebounds for both Striker and Target off inner wooden court rails
    // Striker boundaries (stays safely inside the inner court)
    if (nextS1x <= _strikerMinX) {
      nextS1x = _strikerMinX;
      svX = svX.abs(); // Pure specular bounce matching trajectory guide!
      _playSlideSound();
    } else if (nextS1x >= _strikerMaxX) {
      nextS1x = _strikerMaxX;
      svX = -svX.abs(); // Pure specular bounce matching trajectory guide!
      _playSlideSound();
    }
    if (nextS1y <= _strikerMinY) {
      nextS1y = _strikerMinY;
      svY = svY.abs() * 0.70;
      _playSlideSound();
    } else if (nextS1y >= _strikerMaxY) {
      nextS1y = _strikerMaxY;
      svY = -svY.abs() * 0.70;
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

    // 5. Friction Deceleration: natural polished court glide
    final double speedDecay = max(0.0, 1.0 - (friction * 13.0 * dt));
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
    if (currentStrikerSpeed < 0.032 && currentTargetSpeed < 0.032) {
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
      _currentStreak++;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
      final int pointsGained = max(60, 120 - (distanceToTarget * 0.70).round());
      _score += pointsGained;
      _feedbackMessage = 'Target Struck! +$pointsGained';
      _lastTrialSuccess = true;
    } else {
      _currentStreak = 0;
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
    _reactionTimes.add(safeReactionTime);

    _adaptiveEngine.recordResult(
      isHit: isHit,
      reactionTimeMs: safeReactionTime,
    );

    // Persist the level whenever the adaptive engine updates it
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_prefKeyLevel, _adaptiveEngine.level);
    });

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
      _currentStreak = 0;
      _bestStreak = 0;
      _reactionTimes.clear();
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
      backgroundColor: screenBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                _buildAmbientDecorations(constraints),
                Column(
                  children: [
                    _buildTopBar(),
                    const AnimatedFragmentedDivider(),
                    _buildStatsHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, courtBox) {
                              final double courtHeight = courtBox.maxHeight;
                              final double maxCourtWidth = min(courtBox.maxWidth, courtHeight * 0.62);

                              return SizedBox(
                                width: maxCourtWidth,
                                height: courtHeight,
                                child: LayoutBuilder(
                                  builder: (context, courtConstraints) {
                                    _courtSize = Size(courtConstraints.maxWidth, courtConstraints.maxHeight);

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
                                          color: cardWhite,
                                          borderRadius: BorderRadius.circular(24.0),
                                          border: Border.all(
                                            color: slateBorder,
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryNavy.withValues(alpha: 0.06),
                                              blurRadius: 14.0,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(22.0),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            clipBehavior: Clip.none,
                                            children: [
                                              // 1. Minimal Themed Court Playing Area
                                              _buildMinimalThemedCourt(),

                                              // 2. Trajectory Aim Guide
                                              if (_isAiming && !_isSliding)
                                                CustomPaint(
                                                  size: _courtSize,
                                                  painter: _TrajectoryGuidePainter(
                                                    discOrigin: _strikerPos,
                                                    targetCenter: _targetPos,
                                                    aimStart: _aimStartOffset,
                                                    aimCurrent: _aimCurrentOffset,
                                                    strikerDiameter: strikerDiameter,
                                                    obstacles: _obstacles,
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

                                              // 4. Traditional Obstacle Pieces (Kangkhun Guards)
                                              for (final obs in _obstacles) _buildObstacle(obs),

                                              // 5. Physical Hittable Chekphei Target Piece
                                              _buildHittableTarget(),

                                              // 6. Authentic Kang Striker Disc
                                              _buildStrikerDisc(),

                                              // 7. Subsession Intro Transition Banner
                                              if (!_isSliding && _feedbackMessage == null)
                                                _buildSubsessionTransitionBanner(),

                                              // 9. Trial Feedback Banner
                                              if (_feedbackMessage != null) _buildFeedbackBanner(),

                                              // 10. Pause Overlay
                                              if (_isPaused) _buildPauseOverlay(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    _buildInstructionFooter(),
                  ],
                ),
                if (_isGameOver) Positioned.fill(child: _buildGameOverDialog()),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Top Nav Bar matching Bamboo Dance game reference
  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: navBarBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavBackButton(),
          const SizedBox(width: 6),
          Expanded(
            child: Center(
              child: _buildNavTitleWithUnderline(),
            ),
          ),
          const SizedBox(width: 6),
          _buildNavRightControls(),
        ],
      ),
    );
  }

  Widget _buildNavBackButton() {
    return Semantics(
      button: true,
      label: 'Exit to Home',
      child: Tooltip(
        message: 'Exit to Home',
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: slateBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: primaryNavy,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTitleWithUnderline() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'King Shanaba',
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: primaryNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              fontFamily: 'Caveat',
              letterSpacing: 0.3,
            ),
          ),
          const Text(
            'Traditional Manipuri Kangshang',
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: textGrey,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 3.5,
                decoration: BoxDecoration(
                  color: peachAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 28,
                height: 3.5,
                decoration: BoxDecoration(
                  color: pinkAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavRightControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sound toggle button with edge lighting effect
        Semantics(
          button: true,
          label: 'Toggle Sound',
          child: Tooltip(
            message: _isSoundEnabled ? 'Mute' : 'Unmute',
            child: InkWell(
              onTap: () {
                setState(() {
                  _isSoundEnabled = !_isSoundEnabled;
                });
                if (!_isSoundEnabled) {
                  _sfxAudioPlayer.stop();
                  _chimeAudioPlayer.stop();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _isSoundEnabled ? const Color(0xFFE8F4FD) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSoundEnabled ? const Color(0xFFB3D7F5) : slateBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (_isSoundEnabled)
                      BoxShadow(
                        color: const Color(0xFF90CAF9).withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                  ],
                ),
                child: Icon(
                  _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _isSoundEnabled ? primaryNavy : const Color(0xFF94A3B8),
                  size: 19,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Pause / Play toggle
        Semantics(
          button: true,
          label: 'Pause or Resume Game',
          child: Tooltip(
            message: _isPaused ? 'Resume' : 'Pause',
            child: InkWell(
              onTap: () {
                if (_isPaused) {
                  resumeGame();
                } else {
                  pauseGame();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _isPaused ? const Color(0xFFFFF3E0) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPaused ? const Color(0xFFFFAB91) : slateBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: _isPaused ? const Color(0xFFE65100) : primaryNavy,
                  size: 19,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmbientDecorations(BoxConstraints constraints) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: 70,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      peachAccent.withValues(alpha: 0.18),
                      peachAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 70,
              left: -35,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      pinkAccent.withValues(alpha: 0.16),
                      pinkAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.40,
              left: -25,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF90CAF9).withValues(alpha: 0.18),
                      const Color(0xFF90CAF9).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Minimal themed court playing area
  Widget _buildMinimalThemedCourt() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Sleek minimal gradient playing surface
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFBFDFB),
                Color(0xFFF1F6F2),
              ],
            ),
          ),
        ),
        // 2. Minimalist inner boundary rails and subtle alignment markings
        CustomPaint(
          size: _courtSize,
          painter: _MinimalThemedCourtPainter(targetCenter: _targetPos),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14.0, 4.0, 14.0, 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: slateBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          // 1. Round tracker
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_esports_rounded,
                  size: 18, color: darkGreen),
              const SizedBox(width: 6),
              Text(
                'Round ${_currentTrial.clamp(1, widget.totalTrials)} / ${widget.totalTrials}',
                style: const TextStyle(
                  color: primaryNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // 2. Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: darkGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: darkGreen.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 14, color: darkGreen),
                const SizedBox(width: 3),
                Text(
                  'Level ${_adaptiveEngine.level}',
                  style: const TextStyle(
                    color: darkGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 3. Unified Points box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.65),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFF57C00),
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    color: primaryNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 2),
                const Text(
                  'pts',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  /// Minimal, elegant Manipuri Chekphei target disc (no cartoon icons)
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
                gradient: const RadialGradient(
                  center: Alignment(-0.25, -0.30),
                  radius: 0.85,
                  colors: [
                    Color(0xFFFF8A65),
                    Color(0xFFE64A19),
                    Color(0xFFBF360C),
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE64A19).withValues(alpha: 0.35),
                    blurRadius: 7.0,
                    offset: const Offset(0, 2.5),
                  ),
                  if (_hasHitTargetThisTrial)
                    BoxShadow(
                      color: successGreen.withValues(alpha: 0.80),
                      blurRadius: 16.0,
                      spreadRadius: 2.5,
                    ),
                ],
              ),
              child: Center(
                child: Container(
                  width: targetDiameter * 0.50,
                  height: targetDiameter * 0.50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: targetDiameter * 0.22,
                      height: targetDiameter * 0.22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
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
                  color: darkGreen.withValues(alpha: 0.30),
                  blurRadius: _isSliding ? 10.0 : 6.0,
                  offset: Offset(0, _isSliding ? 4.0 : 2.0),
                ),
                if (_isAiming)
                  BoxShadow(
                    color: primarySage.withValues(alpha: 0.55),
                    blurRadius: 14.0,
                    spreadRadius: 2.5,
                  ),
              ],
            ),
            child: MinimalStrikerDisc(diameter: strikerDiameter),
          ),
        ),
      ),
    );
  }

  /// Traditional Manipuri Kangkhun guard obstacle piece with authentic craftsmanship
  Widget _buildObstacle(ShanabaObstacle obstacle) {
    final double pxX = (obstacle.position.dx * _courtSize.width) - obstacle.radius;
    final double pxY = (obstacle.position.dy * _courtSize.height) - obstacle.radius;
    final double diameter = obstacle.radius * 2;

    return Positioned(
      left: pxX,
      top: pxY,
      width: diameter,
      height: diameter,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.25, -0.30),
              radius: 0.85,
              colors: [
                Color(0xFF8D6E63), // Rich teak tone
                Color(0xFF4E342E), // Deep dark wood
                Color(0xFF2E1C14), // Polished Kang wood grain
              ],
              stops: [0.0, 0.65, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFFD4A373), // Authentic turned brass inlay rim
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 6.0,
                offset: const Offset(0, 3.0),
              ),
              BoxShadow(
                color: const Color(0xFFD4A373).withValues(alpha: 0.20),
                blurRadius: 3.0,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: diameter * 0.48,
              height: diameter * 0.48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4A373).withValues(alpha: 0.85),
                  width: 1.1,
                ),
              ),
              child: Center(
                child: Container(
                  width: diameter * 0.20,
                  height: diameter * 0.20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD4A373), // Brass center pin
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Smooth floating transition indicator when a new subsession begins
  Widget _buildSubsessionTransitionBanner() {
    return Positioned(
      top: 14.0,
      left: 10.0,
      right: 10.0,
      child: AnimatedBuilder(
        animation: _trialTransitionController,
        builder: (context, child) {
          final double t = _trialTransitionController.value;
          final double opacity = (t < 0.35 ? t / 0.35 : (t > 0.72 ? (1.0 - t) / 0.28 : 1.0)).clamp(0.0, 1.0);
          final double translateY = (1.0 - (t.clamp(0.0, 0.35) / 0.35)) * -14.0;

          if (opacity <= 0.02) return const SizedBox.shrink();

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Opacity(
              opacity: opacity,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_filled_rounded, size: 15.0, color: goldAccent),
                        const SizedBox(width: 5.0),
                        Text(
                          'Round $_currentTrial of ${widget.totalTrials} • Aim & Strike',
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
          color: cardWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: slateBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: primaryNavy.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.record_voice_over_rounded, size: 14.0, color: darkGreen),
              SizedBox(width: 6.0),
              Text(
                'Pull back to aim & strike • Voice: "pause", "resume", "exit"',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: darkGreen,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
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
    final int avgRt = _reactionTimes.isNotEmpty
        ? (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length)
            .round()
        : 1200;

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: GameCompletionDialog(
              finalScore: _score,
              bestScore: max(_highScore, _score),
              metrics: [
                GameCompletionMetric(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Accuracy',
                  value: '${accuracy.round()}%',
                  iconColor: GameCompletionDialog.darkGreen,
                ),
                GameCompletionMetric(
                  icon: Icons.speed_rounded,
                  label: 'Avg Speed',
                  value: '${(avgRt / 1000).toStringAsFixed(1)}s',
                  iconColor: GameCompletionDialog.sageGreen,
                ),
                GameCompletionMetric(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Best Streak',
                  value: '$_bestStreak',
                  iconColor: GameCompletionDialog.darkGreen,
                ),
              ],
              onHome: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false);
                }
              },
              onPlayAgain: _restartGame,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. CUSTOM PAINTERS: COMPLETE TRAJECTORY & MINIMAL TRADITIONAL KANGSHANG COURT
// ============================================================================

/// Complete trajectory aim line rendered dynamically during touch & pull-back.
/// Full predictive trajectory with wall bank reflection, obstacle hazard detection, power tension ring, and ZERO auto-aim.
class _TrajectoryGuidePainter extends CustomPainter {
  final Offset discOrigin;
  final Offset targetCenter;
  final Offset aimStart;
  final Offset aimCurrent;
  final double strikerDiameter;
  final List<ShanabaObstacle> obstacles;

  _TrajectoryGuidePainter({
    required this.discOrigin,
    required this.targetCenter,
    required this.aimStart,
    required this.aimCurrent,
    this.strikerDiameter = 36.0,
    this.obstacles = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double courtW = size.width;
    final double courtH = size.height;

    final double startX = discOrigin.dx * courtW;
    final double startY = discOrigin.dy * courtH;

    // 1. Calculate drag vector directly in screen pixels
    final double dragPxX = (aimCurrent.dx - aimStart.dx) * courtW;
    final double dragPxY = (aimCurrent.dy - aimStart.dy) * courtH;
    final double dragDistPx = sqrt(dragPxX * dragPxX + dragPxY * dragPxY);

    // Dynamic Pull Power Ring around striker (Tactile motor feedback)
    final double power = (dragDistPx / (courtH * 0.16)).clamp(0.0, 1.0);
    final double ringRadius = (strikerDiameter / 2) + 6.0;

    final Paint powerTrackPaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(Offset(startX, startY), ringRadius, powerTrackPaint);

    if (power > 0.04) {
      final Paint powerArcPaint = Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF5F866D),
            Color(0xFFD4A373),
            Color(0xFFE06D53),
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(startX, startY), radius: ringRadius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.8;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(startX, startY), radius: ringRadius),
        -pi / 2,
        power * 2 * pi,
        false,
        powerArcPaint,
      );
    }

    // If user has not pulled enough, draw minimal idle aiming indicator (NO AUTO-AIM)
    if (dragDistPx < 8.0) {
      final Paint idleDotPaint = Paint()
        ..color = const Color(0xFF5F866D).withValues(alpha: 0.40)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(startX, startY - ringRadius - 6.0), 2.2, idleDotPaint);
      canvas.drawCircle(Offset(startX, startY - ringRadius - 13.0), 1.8, idleDotPaint);
      return;
    }

    // 2. Launch direction vector in screen pixels (100% identical to _onCourtPanEnd)
    double launchDirPxX;
    double launchDirPxY;

    if (dragPxY > 0.0) {
      launchDirPxX = -dragPxX;
      launchDirPxY = -dragPxY;
    } else {
      launchDirPxX = dragPxX;
      launchDirPxY = dragPxY;
    }

    final double launchDist = sqrt(launchDirPxX * launchDirPxX + launchDirPxY * launchDirPxY);
    if (launchDist <= 0.001) return;
    launchDirPxX /= launchDist;
    launchDirPxY /= launchDist;

    // Ensure trajectory projects towards the top of the court
    if (launchDirPxY >= -0.15) {
      launchDirPxY = -0.15;
      final double reNorm = sqrt(launchDirPxX * launchDirPxX + launchDirPxY * launchDirPxY);
      launchDirPxX /= reNorm;
      launchDirPxY /= reNorm;
    }

    // Exact physical boundary limits for the striker's center (matching physics _strikerMinX / maxX)
    final double strikerRadiusPx = strikerDiameter / 2;
    final double minBounceX = (courtW * _KingShanabaGameScreenState.courtRailLeft) + strikerRadiusPx;
    final double maxBounceX = (courtW * _KingShanabaGameScreenState.courtRailRight) - strikerRadiusPx;
    final double topRailY = (courtH * _KingShanabaGameScreenState.courtRailTop) + strikerRadiusPx;

    final Paint guideDotPaint = Paint()
      ..color = const Color(0xFFD4A373).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final Paint bounceDotPaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Complete Trajectory with full predictive raycast & bank bounce
    double currX = startX;
    double currY = startY;
    double curDirX = launchDirPxX;
    double curDirY = launchDirPxY;
    bool hasBounced = false;

    const double stepSize = 12.5;
    const int maxSteps = 60; // Generous length reaching the Chei target line

    for (int step = 1; step <= maxSteps; step++) {
      currX += curDirX * stepSize;
      currY += curDirY * stepSize;

      // Stop if reached top rail
      if (currY <= topRailY) break;

      // 1. Check obstacle collision: highlight warning halo on obstacle if trajectory intersects it
      bool hitObstacle = false;
      for (final obs in obstacles) {
        final double obsPxX = obs.position.dx * courtW;
        final double obsPxY = obs.position.dy * courtH;
        final double distToObs = sqrt(pow(currX - obsPxX, 2) + pow(currY - obsPxY, 2));
        final double minDist = strikerRadiusPx + obs.radius;

        if (distToObs <= minDist) {
          // Obstacle danger halo indicating collision
          canvas.drawCircle(
            Offset(obsPxX, obsPxY),
            obs.radius + 5.0,
            Paint()
              ..color = const Color(0xFFE06D53).withValues(alpha: 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
          hitObstacle = true;
          break;
        }
      }

      if (hitObstacle) {
        // Draw terminal impact mark and stop guide ray
        canvas.drawCircle(
          Offset(currX, currY),
          strikerRadiusPx * 0.7,
          Paint()
            ..color = const Color(0xFFE06D53).withValues(alpha: 0.70)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        break;
      }

      // 2. Wall bounce check for left and right court rails
      if (!hasBounced) {
        if (currX <= minBounceX) {
          currX = minBounceX;
          curDirX = curDirX.abs(); // Pure specular reflection matching physics
          hasBounced = true;
          // Bank contact point halo marker
          canvas.drawCircle(
            Offset(currX, currY),
            5.0,
            Paint()
              ..color = const Color(0xFFD4A373)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        } else if (currX >= maxBounceX) {
          currX = maxBounceX;
          curDirX = -curDirX.abs(); // Pure specular reflection matching physics
          hasBounced = true;
          // Bank contact point halo marker
          canvas.drawCircle(
            Offset(currX, currY),
            5.0,
            Paint()
              ..color = const Color(0xFFD4A373)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        }
      }

      final double progress = step / maxSteps;
      final double dotRadius = (hasBounced ? 2.4 : 2.8) * (1.0 - (progress * 0.28));
      canvas.drawCircle(
        Offset(currX, currY),
        max(1.4, dotRadius),
        hasBounced ? bounceDotPaint : guideDotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryGuidePainter oldDelegate) {
    if (oldDelegate.discOrigin != discOrigin ||
        oldDelegate.aimCurrent != aimCurrent ||
        oldDelegate.aimStart != aimStart ||
        oldDelegate.targetCenter != targetCenter ||
        oldDelegate.strikerDiameter != strikerDiameter ||
        oldDelegate.obstacles.length != obstacles.length) {
      return true;
    }
    for (int i = 0; i < obstacles.length; i++) {
      if (oldDelegate.obstacles[i].position != obstacles[i].position) {
        return true;
      }
    }
    return false;
  }
}

/// Renders a minimal, authentic Manipuri Kangshang playing court with clean, serene markings
class _MinimalThemedCourtPainter extends CustomPainter {
  final Offset targetCenter;

  _MinimalThemedCourtPainter({required this.targetCenter});

  @override
  void paint(Canvas canvas, Size size) {
    final double left = size.width * _KingShanabaGameScreenState.courtRailLeft;
    final double top = size.height * _KingShanabaGameScreenState.courtRailTop;
    final double right = size.width * _KingShanabaGameScreenState.courtRailRight;
    final double bottom = size.height * _KingShanabaGameScreenState.courtRailBottom;

    // 1. Subtle, serene court floor grain lines (Authentic polished timber court)
    final Paint grainPaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.035)
      ..strokeWidth = 1.0;
    for (double gx = left + 22.0; gx < right; gx += 26.0) {
      canvas.drawLine(Offset(gx, top + 8.0), Offset(gx, bottom - 8.0), grainPaint);
    }

    // 2. Primary outer court rail perimeter (Rounded rectangle)
    final Paint outerRailPaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final RRect outerRail = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(16.0),
    );
    canvas.drawRRect(outerRail, outerRailPaint);

    // 3. Subtle inner rail line
    final Paint innerRailPaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final RRect innerRail = RRect.fromRectAndRadius(
      Rect.fromLTRB(left + 3.5, top + 3.5, right - 3.5, bottom - 3.5),
      const Radius.circular(13.0),
    );
    canvas.drawRRect(innerRail, innerRailPaint);

    // 4. Traditional Corner Brackets (Kangshang Corner Accents)
    final Paint cornerPaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    const double bracketLen = 12.0;

    // Top-Left
    canvas.drawLine(Offset(left + 4.0, top + 14.0), Offset(left + 4.0, top + 14.0 + bracketLen), cornerPaint);
    canvas.drawLine(Offset(left + 14.0, top + 4.0), Offset(left + 14.0 + bracketLen, top + 4.0), cornerPaint);
    // Top-Right
    canvas.drawLine(Offset(right - 4.0, top + 14.0), Offset(right - 4.0, top + 14.0 + bracketLen), cornerPaint);
    canvas.drawLine(Offset(right - 14.0, top + 4.0), Offset(right - 14.0 - bracketLen, top + 4.0), cornerPaint);
    // Bottom-Left
    canvas.drawLine(Offset(left + 4.0, bottom - 14.0), Offset(left + 4.0, bottom - 14.0 - bracketLen), cornerPaint);
    canvas.drawLine(Offset(left + 14.0, bottom - 4.0), Offset(left + 14.0 + bracketLen, bottom - 4.0), cornerPaint);
    // Bottom-Right
    canvas.drawLine(Offset(right - 4.0, bottom - 14.0), Offset(right - 4.0, bottom - 14.0 - bracketLen), cornerPaint);
    canvas.drawLine(Offset(right - 14.0, bottom - 4.0), Offset(right - 14.0 - bracketLen, bottom - 4.0), cornerPaint);

    // 5. Chei Target Line (Top scoring zone)
    final double cheiY = size.height * 0.13;
    final Paint cheiPaint = Paint()
      ..color = const Color(0xFFD4A373).withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(left + 10.0, cheiY), Offset(right - 10.0, cheiY), cheiPaint);

    // Chei zone boundary tick marks
    canvas.drawLine(Offset(left + 18.0, cheiY - 5.0), Offset(left + 18.0, cheiY + 5.0), cheiPaint);
    canvas.drawLine(Offset(right - 18.0, cheiY - 5.0), Offset(right - 18.0, cheiY + 5.0), cheiPaint);

    // Subtle target landing aura on court floor
    final Offset targetPixelCenter = Offset(
      targetCenter.dx * size.width,
      targetCenter.dy * size.height,
    );
    final Paint targetZonePaint = Paint()
      ..color = const Color(0xFFD4A373).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(targetPixelCenter, 22.0, targetZonePaint);
    canvas.drawCircle(
      targetPixelCenter,
      36.0,
      Paint()
        ..color = const Color(0xFF5F866D).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 6. Lamjel Half-Court Line (Center dividing line)
    final Paint midLinePaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const double dashWidth = 6.0;
    const double dashSpace = 5.0;
    final double midY = size.height * 0.50;
    double startX = left + 16.0;
    final double endX = right - 16.0;
    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, midY),
        Offset(min(startX + dashWidth, endX), midY),
        midLinePaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Center court diamond emblem
    final double midX = size.width * 0.50;
    final Path diamond = Path()
      ..moveTo(midX, midY - 4.5)
      ..lineTo(midX + 4.5, midY)
      ..lineTo(midX, midY + 4.5)
      ..lineTo(midX - 4.5, midY)
      ..close();
    canvas.drawPath(
      diamond,
      Paint()
        ..color = const Color(0xFF5F866D).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 7. Khanglen Striker Baseline (Launch stations at bottom)
    final double baselineY = size.height * 0.88;
    final Paint baselinePaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(left + 14.0, baselineY),
      Offset(right - 14.0, baselineY),
      baselinePaint,
    );

    // Traditional Kang launch station pips (Left, Center, Right)
    final Paint stationDotPaint = Paint()
      ..color = const Color(0xFF5F866D).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.50, baselineY), 2.5, stationDotPaint);
    canvas.drawCircle(Offset(size.width * 0.32, baselineY), 2.0, stationDotPaint);
    canvas.drawCircle(Offset(size.width * 0.68, baselineY), 2.0, stationDotPaint);

    // 8. Bank Rail Cushion Indicators (Left & Right rebound surfaces)
    final Paint cushionPaint = Paint()
      ..color = const Color(0xFFD4A373).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(left + 6.0, top + 40.0), Offset(left + 6.0, bottom - 40.0), cushionPaint);
    canvas.drawLine(Offset(right - 6.0, top + 40.0), Offset(right - 6.0, bottom - 40.0), cushionPaint);
  }

  @override
  bool shouldRepaint(covariant _MinimalThemedCourtPainter oldDelegate) {
    return oldDelegate.targetCenter != targetCenter;
  }
}

/// Minimal, elegant Manipuri Kang Striker Disc
class MinimalStrikerDisc extends StatelessWidget {
  final double diameter;

  const MinimalStrikerDisc({super.key, this.diameter = 36.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.25, -0.30),
          radius: 0.85,
          colors: [
            Color(0xFF3F6E55),
            Color(0xFF234B36),
            Color(0xFF142F21),
          ],
          stops: [0.0, 0.65, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFDCE8DA),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142F21).withValues(alpha: 0.35),
            blurRadius: 6.0,
            offset: const Offset(0, 3.0),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: diameter * 0.52,
          height: diameter * 0.52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD4A373).withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Container(
              width: diameter * 0.22,
              height: diameter * 0.22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFE082),
                    Color(0xFFD4A373),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compatibility alias
typedef KangStrikerDisc = MinimalStrikerDisc;
