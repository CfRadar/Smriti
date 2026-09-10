// apps/patient/lib/games/bamboo_dance_game.dart
//
// Smriti Dementia-Care Platform - Cognitive & Motor Stimulation Module
// Traditional Assam Bamboo Dance: "Bamboo Dance"
//
// Features:
// 1. Top-down 2D bamboo court with 3 horizontal and 3 vertical poles intersecting
//    to form a 4x4 coordinate space with 9 central cell positions (3x3 grid layout).
// 2. Random & dynamic movement of bamboo poles each trial, opening up a spacious
//    empty cell where the target circle appears with generous clearance.
// 3. The dancer and target circle ALWAYS reside in open empty spaces, never overlapping
//    or intersected by any bamboo pole.
// 4. Direct touch interaction on the target circle over the interactive court canvas.
// 5. Persistent dancer location remaining at destination grid coordinates across steps.
// 6. Culturally accurate Assamese folk dancer in traditional Muga silk attire with Kingkhap motifs.
// 7. Authentic Cheraw bamboo dance background music loop.
// 8. Adaptive cognitive pacing and continuous rhythm gameplay.
// 9. Complete offline-first telemetry persistent queue in SharedPreferences.

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

// ============================================================================
// 1. GRID COORDINATES & GAMEPLAY ENUMS
// ============================================================================

/// Coordinate representation for cells in the 3x3 dance grid matrix.
/// [col]: 0 (left), 1 (center), 2 (right)
/// [row]: 0 (top), 1 (center), 2 (bottom)
class GridPos {
  final int col;
  final int row;

  const GridPos(this.col, this.row);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPos &&
          runtimeType == other.runtimeType &&
          col == other.col &&
          row == other.row;

  @override
  int get hashCode => col.hashCode ^ row.hashCode;

  @override
  String toString() => 'GridPos($col, $row)';
}

enum DanceDirection { up, left, down, right }

enum CharacterMood { idle, happyStep, recoverStumble, finishBow }

// ============================================================================
// 2. TELEMETRY & LOCAL STORAGE DATA MODELS
// ============================================================================

/// Clinical telemetry data captured for each rhythmic step interaction.
class BambooDanceTrialTelemetry {
  final String sessionId;
  final String gameType;
  final int trialNumber;
  final int stage;
  final String expectedDirection;
  final String actualDirection;
  final int reactionTimeMs;
  final bool isCorrect;
  final double rhythmAccuracy; // 0.0 to 1.0
  final String timestamp;
  final int bpm;
  final int timingWindowMs;

  const BambooDanceTrialTelemetry({
    required this.sessionId,
    this.gameType = 'bamboo_dance',
    required this.trialNumber,
    required this.stage,
    required this.expectedDirection,
    required this.actualDirection,
    required this.reactionTimeMs,
    required this.isCorrect,
    required this.rhythmAccuracy,
    required this.timestamp,
    required this.bpm,
    required this.timingWindowMs,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'gameType': gameType,
        'trialNumber': trialNumber,
        'stage': stage,
        'expectedDirection': expectedDirection,
        'actualDirection': actualDirection,
        'reactionTimeMs': reactionTimeMs,
        'isCorrect': isCorrect,
        'rhythmAccuracy': double.parse(rhythmAccuracy.toStringAsFixed(2)),
        'timestamp': timestamp,
        'bpm': bpm,
        'timingWindowMs': timingWindowMs,
      };

  factory BambooDanceTrialTelemetry.fromJson(Map<String, dynamic> json) =>
      BambooDanceTrialTelemetry(
        sessionId: json['sessionId'] as String? ?? 'unknown_session',
        gameType: json['gameType'] as String? ?? 'bamboo_dance',
        trialNumber: (json['trialNumber'] as num?)?.toInt() ?? 1,
        stage: (json['stage'] as num?)?.toInt() ?? 1,
        expectedDirection: json['expectedDirection'] as String? ?? 'up',
        actualDirection: json['actualDirection'] as String? ?? 'none',
        reactionTimeMs: (json['reactionTimeMs'] as num?)?.toInt() ?? 0,
        isCorrect: json['isCorrect'] as bool? ?? false,
        rhythmAccuracy:
            (json['rhythmAccuracy'] as num?)?.toDouble() ?? 0.5,
        timestamp:
            json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
        bpm: (json['bpm'] as num?)?.toInt() ?? 40,
        timingWindowMs: (json['timingWindowMs'] as num?)?.toInt() ?? 3000,
      );
}

/// Offline-first telemetry service with local SharedPreferences caching queue.
class BambooDanceTelemetryService {
  final String endpointUrl;
  final http.Client _client;
  static const String offlineCacheKey = 'smriti_bamboo_dance_telemetry_queue';

  BambooDanceTelemetryService({
    this.endpointUrl = 'http://localhost:5000/api/games/session',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Logs a trial record locally into SharedPreferences immediately, then attempts sync.
  Future<void> logTrial(BambooDanceTrialTelemetry telemetry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(offlineCacheKey) ?? [];
      queue.add(jsonEncode(telemetry.toJson()));
      await prefs.setStringList(offlineCacheKey, queue);
      unawaited(syncCachedTelemetry());
    } catch (e) {
      debugPrint('[BambooDanceTelemetry] Local cache error: $e');
    }
  }

  /// Attempts background sync of pending telemetry records without blocking the user.
  Future<void> syncCachedTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(offlineCacheKey) ?? [];
      if (queue.isEmpty) return;

      final remaining = <String>[];
      for (final raw in queue) {
        try {
          final res = await _client
              .post(
                Uri.parse(endpointUrl),
                headers: {'Content-Type': 'application/json'},
                body: raw,
              )
              .timeout(const Duration(seconds: 3));
          if (res.statusCode < 200 || res.statusCode >= 300) {
            remaining.add(raw);
          }
        } catch (_) {
          remaining.add(raw);
        }
      }
      await prefs.setStringList(offlineCacheKey, remaining);
    } catch (e) {
      debugPrint('[BambooDanceTelemetry] Sync error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

// ============================================================================
// 3. ADAPTIVE STAGE & DIFFICULTY ENGINE
// ============================================================================

/// Configuration parameters for a gameplay stage.
class BambooStageConfig {
  final int stageNumber;
  final String name;
  final String subtitle;
  final int bpm;
  final int timingWindowMs;
  final List<DanceDirection> availableDirections;
  final int trialsRequired;
  final bool isPatternMemory;

  const BambooStageConfig({
    required this.stageNumber,
    required this.name,
    required this.subtitle,
    required this.bpm,
    required this.timingWindowMs,
    required this.availableDirections,
    required this.trialsRequired,
    this.isPatternMemory = false,
  });

  static const List<BambooStageConfig> defaultStages = [
    // Stage 1: Familiarisation (Very slow, 1 direction: UP, alternate notes)
    BambooStageConfig(
      stageNumber: 1,
      name: 'Familiarisation',
      subtitle: 'Gentle Start',
      bpm: 38,
      timingWindowMs: 3400,
      availableDirections: [DanceDirection.up],
      trialsRequired: 4,
    ),
    // Stage 2: Simple Alternation (LEFT <-> RIGHT, alternate notes)
    BambooStageConfig(
      stageNumber: 2,
      name: 'Gentle Alternation',
      subtitle: 'Left-Right Shifts',
      bpm: 40,
      timingWindowMs: 3000,
      availableDirections: [DanceDirection.left, DanceDirection.right],
      trialsRequired: 5,
    ),
    // Stage 3: Four Directions (UP, DOWN, LEFT, RIGHT, all notes)
    BambooStageConfig(
      stageNumber: 3,
      name: 'Four Directions',
      subtitle: 'All Directions',
      bpm: 42,
      timingWindowMs: 2700,
      availableDirections: [
        DanceDirection.up,
        DanceDirection.right,
        DanceDirection.down,
        DanceDirection.left,
      ],
      trialsRequired: 6,
    ),
    // Stage 4: Rhythm Pattern (LEFT -> RIGHT -> LEFT -> RIGHT, all notes)
    BambooStageConfig(
      stageNumber: 4,
      name: 'Rhythm Pattern',
      subtitle: 'Rhythmic Tempo',
      bpm: 44,
      timingWindowMs: 2500,
      availableDirections: [
        DanceDirection.left,
        DanceDirection.right,
        DanceDirection.up,
        DanceDirection.down,
      ],
      trialsRequired: 6,
    ),
    // Stage 5: Pattern Memory (Short 2-3 step sequences, all notes)
    BambooStageConfig(
      stageNumber: 5,
      name: 'Pattern Memory',
      subtitle: 'Memory & Rhythm',
      bpm: 44,
      timingWindowMs: 2600,
      availableDirections: [
        DanceDirection.up,
        DanceDirection.down,
        DanceDirection.left,
        DanceDirection.right,
      ],
      trialsRequired: 6,
      isPatternMemory: true,
    ),
    // Stage 6: Adaptive Free Dance (Continuously adjusts, all notes)
    BambooStageConfig(
      stageNumber: 6,
      name: 'Cheraw Harmony',
      subtitle: 'Harmonious Flow',
      bpm: 46,
      timingWindowMs: 2400,
      availableDirections: [
        DanceDirection.up,
        DanceDirection.right,
        DanceDirection.down,
        DanceDirection.left,
      ],
      trialsRequired: 8,
    ),
  ];

  static BambooStageConfig getForStage(int stageNumber) {
    final index = (stageNumber - 1).clamp(0, defaultStages.length - 1);
    return defaultStages[index];
  }
}

/// Adaptive engine managing difficulty, stage transitions, and cognitive pace.
class BambooAdaptiveEngine {
  int currentStageNumber = 1;
  int consecutiveSuccesses = 0;
  int consecutiveMistakes = 0;
  int adaptiveBpm = 38;
  int adaptiveTimingWindowMs = 3400;

  bool get isAlternateNotes => currentStageNumber <= 2;

  BambooStageConfig get currentConfig =>
      BambooStageConfig.getForStage(currentStageNumber);

  void recordTrialResult({
    required bool isCorrect,
    required int reactionTimeMs,
  }) {
    if (isCorrect) {
      consecutiveSuccesses++;
      consecutiveMistakes = 0;
      if (reactionTimeMs < 1800 && adaptiveBpm < 48) {
        adaptiveBpm = min(48, adaptiveBpm + 1);
        adaptiveTimingWindowMs = max(2200, adaptiveTimingWindowMs - 50);
      }
    } else {
      consecutiveMistakes++;
      consecutiveSuccesses = 0;
      adaptiveBpm = max(36, adaptiveBpm - 1);
      adaptiveTimingWindowMs = min(3600, adaptiveTimingWindowMs + 100);
    }
  }

  bool shouldAdvanceStage(int trialsCompletedInCurrentStage) {
    return trialsCompletedInCurrentStage >= currentConfig.trialsRequired &&
        currentStageNumber < BambooStageConfig.defaultStages.length;
  }

  void advanceStage() {
    if (currentStageNumber < BambooStageConfig.defaultStages.length) {
      currentStageNumber++;
      final config = currentConfig;
      adaptiveBpm = config.bpm;
      adaptiveTimingWindowMs = config.timingWindowMs;
      consecutiveSuccesses = 0;
      consecutiveMistakes = 0;
    }
  }
}

// ============================================================================
// 4. MAIN GAME SCREEN
// ============================================================================

class BambooDanceGameScreen extends StatefulWidget {
  final String sessionId;
  final int totalTargetTrials;

  const BambooDanceGameScreen({
    super.key,
    this.sessionId = 'bamboo_dance_local',
    this.totalTargetTrials = 25,
  });

  @override
  State<BambooDanceGameScreen> createState() => _BambooDanceGameScreenState();
}

class _BambooDanceGameScreenState extends State<BambooDanceGameScreen>
    with TickerProviderStateMixin {
  // Adaptive engine and telemetry
  late final BambooAdaptiveEngine _engine;
  late final BambooDanceTelemetryService _telemetryService;

  // Animation controllers
  late final AnimationController _rhythmPulseController;
  late final AnimationController _characterJumpController;
  late final AnimationController _stumbleController;
  late final AnimationController _celebrationController;
  late final AnimationController _navIdleController;
  late final AnimationController _scorePopController;
  late final AnimationController _underlineController;

  // Audio players
  AudioPlayer? _bgMusicPlayer;
  AudioPlayer? _tapSoundPlayer;
  AudioPlayer? _bambooClackPlayer;
  bool _isSoundEnabled = true;

  // Session & state tracking
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _isTrialInputLocked = false;
  bool _isEndingOverlayVisible = false;
  int _totalTrialsRun = 0;
  int _stageTrialsRun = 0;
  int _correctStepsCount = 0;
  DateTime? _trialStartTime;

  // Grid coordinates & persistent dancer location
  GridPos _dancerGridPos = const GridPos(1, 1);
  GridPos _prevDancerGridPos = const GridPos(1, 1);
  GridPos _targetGridPos = const GridPos(1, 0);
  GridPos _prevTargetGridPos = const GridPos(1, 0);

  // Direct pole closure tracking for 100% continuous transitions without snap
  bool _verticalCloseWithRight = false;
  bool _prevVerticalCloseWithRight = false;
  bool _horizontalCloseWithBottom = true;
  bool _prevHorizontalCloseWithBottom = true;

  // Smooth bamboo sliding transition controller
  late final AnimationController _bambooShiftController;

  // Directions and cues
  DanceDirection _expectedDirection = DanceDirection.up;
  DanceDirection? _characterStepDirection;
  CharacterMood _characterMood = CharacterMood.idle;

  // Pattern memory queue
  List<DanceDirection> _memoryPatternQueue = [];
  int _memoryPatternIndex = 0;

  Timer? _nextTrialTimer;

  final Random _random = Random();

  // Palette constants matching Smriti Main UI Theme
  static const Color screenBg = Color(0xFFF0F4F8); // Sky-mist screen background
  static const Color navBarBg = Color(0xFFEAF2F8); // Light blue nav surface
  static const Color primaryNavy = Color(0xFF1E3A5F); // Main UI deep navy text & icons
  static const Color slateBorder = Color(0xFFCFE0ED); // Soft slate border
  static const Color textMuted = Color(0xFF667A8C); // Muted subtitles
  static const Color peachAccent = Color(0xFFFFAB91); // Signature peach
  static const Color pinkAccent = Color(0xFFF48FB1); // Signature pink
  static const Color orangeAccent = Color(0xFFFF7043); // Radiant orange
  static const Color lightBlue = Color(0xFFDFF0FA); // Light cadence pill

  @override
  void initState() {
    super.initState();
    _engine = BambooAdaptiveEngine();
    _telemetryService = BambooDanceTelemetryService();

    // Rhythmic opening/closing pulse controller timed to stage BPM
    final initialHalfPeriodMs = (30000 / _engine.adaptiveBpm).round();
    _rhythmPulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: initialHalfPeriodMs),
    )
      ..repeat(reverse: true)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _playBambooClapSound();
        }
      });

    // Smooth bamboo sliding shift transition controller (smooth easing, no wobbling)
    _bambooShiftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..value = 1.0;

    // Character smooth step/jump controller (lands and persists at destination)
    _characterJumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Character stumble wobble controller
    _stumbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // Ending celebration animation controller
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Continuous idle breathing & floating animation controller for nav & background
    _navIdleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // Score pop animation when step is successful
    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Moving peach & pink fragmented underline animation controller
    _underlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _initAudio();
    _registerVoiceCommands();
    _startNextTrial(initialDelay: const Duration(milliseconds: 400));
  }


  void _updatePulseDuration() {
    final halfPeriodMs =
        (30000 / _engine.adaptiveBpm).round().clamp(500, 1000);
    _rhythmPulseController.duration = Duration(milliseconds: halfPeriodMs);
  }

  void _initAudio() {
    try {
      _bgMusicPlayer = AudioPlayer();
      _tapSoundPlayer = AudioPlayer();
      _bambooClackPlayer = AudioPlayer();

      _bgMusicPlayer?.setReleaseMode(ReleaseMode.loop);
      _tapSoundPlayer?.setReleaseMode(ReleaseMode.stop);
      _bambooClackPlayer?.setReleaseMode(ReleaseMode.stop);
      _bambooClackPlayer?.setVolume(0.7);

      _startCherawMusic();
    } catch (e) {
      debugPrint('[BambooDance] Audio init fallback: $e');
    }
  }

  Future<void> _startCherawMusic() async {
    if (!_isSoundEnabled || _bgMusicPlayer == null) return;
    try {
      await _bgMusicPlayer?.setVolume(0.85);
      await _bgMusicPlayer?.play(AssetSource('audio/cheraw_dance_music.wav'));
    } catch (_) {}
  }

  void _registerVoiceCommands() {
    VoiceCommandController.instance.registerGame((command) {
      if (!mounted) return;
      switch (command.intent) {
        case VoiceIntent.pauseGame:
          _pauseGame();
          break;
        case VoiceIntent.resumeGame:
          _resumeGame();
          break;
        case VoiceIntent.goHome:
        case VoiceIntent.exitGame:
          Navigator.of(context).pop();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _playButtonTapSound() async {
    if (!_isSoundEnabled || _tapSoundPlayer == null) return;
    try {
      await _tapSoundPlayer?.stop();
      await _tapSoundPlayer?.play(AssetSource('audio/click.wav'));
    } catch (_) {}
  }

  Future<void> _playBambooClapSound() async {
    if (!_isSoundEnabled || _bambooClackPlayer == null) return;
    try {
      await _bambooClackPlayer?.stop();
      await _bambooClackPlayer?.play(AssetSource('audio/northeast_chime_bamboo.wav'));
    } catch (_) {}
  }

  void _startNextTrial({Duration initialDelay = Duration.zero}) {
    if (_isCompleted || !mounted) return;

    _nextTrialTimer?.cancel();
    if (initialDelay == Duration.zero) {
      _executeNextTrial();
    } else {
      _nextTrialTimer = Timer(initialDelay, _executeNextTrial);
    }
  }

  void _executeNextTrial() {
    if (!mounted || _isPaused || _isCompleted) return;
    _isTrialInputLocked = false;

    // Advance stage if trials met
    if (_engine.shouldAdvanceStage(_stageTrialsRun)) {
      _engine.advanceStage();
      _stageTrialsRun = 0;
      _updatePulseDuration();
    }

    final config = _engine.currentConfig;
    _prevTargetGridPos = _targetGridPos;
    _prevVerticalCloseWithRight = _verticalCloseWithRight;
    _prevHorizontalCloseWithBottom = _horizontalCloseWithBottom;

    _determineNextTarget(config);

    // Update pole target states based on new target
    if (_targetGridPos.col == 0) {
      _verticalCloseWithRight = true;
    } else if (_targetGridPos.col == 2) {
      _verticalCloseWithRight = false;
    } else {
      _verticalCloseWithRight = !_prevVerticalCloseWithRight;
    }

    if (_targetGridPos.row == 0) {
      _horizontalCloseWithBottom = true;
    } else if (_targetGridPos.row == 2) {
      _horizontalCloseWithBottom = false;
    } else {
      _horizontalCloseWithBottom = !_prevHorizontalCloseWithBottom;
    }

    _bambooShiftController.forward(from: 0.0);

    setState(() {
      _characterMood = CharacterMood.idle;
      _characterStepDirection = null;
    });

    _trialStartTime = DateTime.now();
  }


  void _determineNextTarget(BambooStageConfig config) {
    DanceDirection chosenDirection;
    GridPos targetPos;

    if (config.isPatternMemory) {
      if (_memoryPatternQueue.isEmpty ||
          _memoryPatternIndex >= _memoryPatternQueue.length) {
        _generateMemoryPattern();
      }
      final candidateDir = _memoryPatternQueue[_memoryPatternIndex];
      final candidatePos = _getAdjacentGridPos(_dancerGridPos, candidateDir);

      if (!_isDirectionValidFrom(_dancerGridPos, candidateDir) ||
          BambooCourtPainter.isSameBambooSpace(candidatePos, _prevTargetGridPos) ||
          BambooCourtPainter.isSameBambooSpace(candidatePos, _dancerGridPos)) {
        final valids = _getValidDirectionsFrom(_dancerGridPos);
        final differentSpaceValids = valids.where((d) {
          final pos = _getAdjacentGridPos(_dancerGridPos, d);
          return !BambooCourtPainter.isSameBambooSpace(pos, _prevTargetGridPos) &&
              !BambooCourtPainter.isSameBambooSpace(pos, _dancerGridPos);
        }).toList();

        if (differentSpaceValids.isNotEmpty) {
          chosenDirection = differentSpaceValids.first;
          targetPos = _getAdjacentGridPos(_dancerGridPos, chosenDirection);
        } else {
          final opposite = _getOppositeGridPos(_dancerGridPos);
          chosenDirection = _getDirectionTowards(_dancerGridPos, opposite);
          targetPos = opposite;
        }
      } else {
        chosenDirection = candidateDir;
        targetPos = candidatePos;
      }
    } else if (config.stageNumber == 1) {
      // Stage 1: Gentle vertical alternation strictly between Top (1, 0) <-> Bottom (1, 2)
      // Poles clap shut on previous space and open wide on opposite side.
      if (_dancerGridPos.row == 0) {
        chosenDirection = DanceDirection.down;
        targetPos = const GridPos(1, 2);
      } else {
        chosenDirection = DanceDirection.up;
        targetPos = const GridPos(1, 0);
      }
    } else if (config.stageNumber == 2) {
      // Stage 2: Gentle alternation strictly between Left (0, 1) <-> Right (2, 1)
      if (_dancerGridPos.col == 0) {
        chosenDirection = DanceDirection.right;
        targetPos = const GridPos(2, 1);
      } else {
        chosenDirection = DanceDirection.left;
        targetPos = const GridPos(0, 1);
      }
    } else if (config.stageNumber == 4) {
      // Stage 4: Rhythm sequence across strictly alternating bamboo spaces
      final preferred = [
        DanceDirection.left,
        DanceDirection.right,
        DanceDirection.up,
        DanceDirection.down,
      ];
      final valids = _getValidDirectionsFrom(_dancerGridPos);
      final differentSpaceValids = valids.where((d) {
        final pos = _getAdjacentGridPos(_dancerGridPos, d);
        return !BambooCourtPainter.isSameBambooSpace(pos, _prevTargetGridPos) &&
            !BambooCourtPainter.isSameBambooSpace(pos, _dancerGridPos);
      }).toList();

      DanceDirection? pick;
      for (int i = 0; i < preferred.length; i++) {
        final candidate = preferred[(_stageTrialsRun + i) % preferred.length];
        if (differentSpaceValids.contains(candidate)) {
          pick = candidate;
          break;
        }
      }
      if (pick != null) {
        chosenDirection = pick;
        targetPos = _getAdjacentGridPos(_dancerGridPos, chosenDirection);
      } else if (differentSpaceValids.isNotEmpty) {
        chosenDirection =
            differentSpaceValids[_random.nextInt(differentSpaceValids.length)];
        targetPos = _getAdjacentGridPos(_dancerGridPos, chosenDirection);
      } else {
        final opposite = _getOppositeGridPos(_dancerGridPos);
        chosenDirection = _getDirectionTowards(_dancerGridPos, opposite);
        targetPos = opposite;
      }
    } else {
      // Stages 3 & 6: Available directions strictly filtered so target is NEVER in the same bamboo space
      final valids = _getValidDirectionsFrom(_dancerGridPos)
          .where((d) => config.availableDirections.contains(d))
          .toList();

      final differentSpaceValids = valids.where((d) {
        final pos = _getAdjacentGridPos(_dancerGridPos, d);
        return !BambooCourtPainter.isSameBambooSpace(pos, _prevTargetGridPos) &&
            !BambooCourtPainter.isSameBambooSpace(pos, _dancerGridPos);
      }).toList();

      if (differentSpaceValids.isNotEmpty) {
        chosenDirection =
            differentSpaceValids[_random.nextInt(differentSpaceValids.length)];
        targetPos = _getAdjacentGridPos(_dancerGridPos, chosenDirection);
      } else {
        final opposite = _getOppositeGridPos(_dancerGridPos);
        chosenDirection = _getDirectionTowards(_dancerGridPos, opposite);
        targetPos = opposite;
      }
    }

    _expectedDirection = chosenDirection;
    _targetGridPos = targetPos;
  }

  GridPos _getOppositeGridPos(GridPos pos) {
    if (pos == const GridPos(2, 0)) return const GridPos(0, 2);
    if (pos == const GridPos(0, 2)) return const GridPos(2, 0);
    if (pos == const GridPos(0, 0)) return const GridPos(2, 2);
    if (pos == const GridPos(2, 2)) return const GridPos(0, 0);
    if (pos.col == 0) return GridPos(2, pos.row);
    if (pos.col == 2) return GridPos(0, pos.row);
    if (pos.row == 0) return GridPos(pos.col, 2);
    return GridPos(pos.col, 0);
  }

  DanceDirection _getDirectionTowards(GridPos from, GridPos to) {
    if (to == const GridPos(1, 0)) return DanceDirection.up;
    if (to == const GridPos(1, 2)) return DanceDirection.down;
    if (to == const GridPos(0, 1)) return DanceDirection.left;
    if (to == const GridPos(2, 1)) return DanceDirection.right;
    if (to.col > from.col) return DanceDirection.right;
    if (to.col < from.col) return DanceDirection.left;
    if (to.row > from.row) return DanceDirection.down;
    return DanceDirection.up;
  }

  bool _isDirectionValidFrom(GridPos pos, DanceDirection dir) {
    switch (dir) {
      case DanceDirection.up:
        return pos != const GridPos(1, 0);
      case DanceDirection.down:
        return pos != const GridPos(1, 2);
      case DanceDirection.left:
        return pos != const GridPos(0, 1);
      case DanceDirection.right:
        return pos != const GridPos(2, 1);
    }
  }

  List<DanceDirection> _getValidDirectionsFrom(GridPos pos) {
    final list = <DanceDirection>[];
    if (pos != const GridPos(1, 0)) list.add(DanceDirection.up);
    if (pos != const GridPos(1, 2)) list.add(DanceDirection.down);
    if (pos != const GridPos(0, 1)) list.add(DanceDirection.left);
    if (pos != const GridPos(2, 1)) list.add(DanceDirection.right);
    return list;
  }

  GridPos _getAdjacentGridPos(GridPos pos, DanceDirection dir) {
    switch (dir) {
      case DanceDirection.up:
        return const GridPos(1, 0);
      case DanceDirection.down:
        return const GridPos(1, 2);
      case DanceDirection.left:
        return const GridPos(0, 1);
      case DanceDirection.right:
        return const GridPos(2, 1);
    }
  }

  void _generateMemoryPattern() {
    final available = _engine.currentConfig.availableDirections;
    _memoryPatternQueue = [
      available[_random.nextInt(available.length)],
      available[_random.nextInt(available.length)],
    ];
    _memoryPatternIndex = 0;
  }

  /// Handles direct canvas touch interaction
  void _handleCourtTap(Offset localPos, Size courtSize) {
    if (_isPaused || _isCompleted || _isTrialInputLocked || _trialStartTime == null) return;

    final center = Offset(courtSize.width / 2, courtSize.height / 2);
    final cellSpacing = courtSize.width * 0.28;

    final targetOffset = Offset(
      center.dx + (_targetGridPos.col - 1) * cellSpacing,
      center.dy + (_targetGridPos.row - 1) * cellSpacing,
    );

    final dist = (localPos - targetOffset).distance;
    final hitRadius = max(44.0, cellSpacing * 0.55);

    if (dist <= hitRadius) {
      _processStep(isCorrect: true);
    } else {
      _processStep(isCorrect: false);
    }
  }

  void _processStep({required bool isCorrect}) {
    if (_isPaused || _isCompleted || _isTrialInputLocked || _trialStartTime == null) return;
    _isTrialInputLocked = true;

    HapticFeedback.lightImpact();
    _playButtonTapSound();

    final now = DateTime.now();
    final reactionTimeMs = now.difference(_trialStartTime!).inMilliseconds;

    _totalTrialsRun++;
    _stageTrialsRun++;
    if (isCorrect) {
      _correctStepsCount++;
      _scorePopController.forward(from: 0.0);
    }

    _engine.recordTrialResult(
      isCorrect: isCorrect,
      reactionTimeMs: reactionTimeMs,
    );
    _updatePulseDuration();

    final telemetry = BambooDanceTrialTelemetry(
      sessionId: widget.sessionId,
      trialNumber: _totalTrialsRun,
      stage: _engine.currentStageNumber,
      expectedDirection: _expectedDirection.name,
      actualDirection: isCorrect ? _expectedDirection.name : 'miss',
      reactionTimeMs: reactionTimeMs,
      isCorrect: isCorrect,
      rhythmAccuracy: 0.95,
      timestamp: now.toIso8601String(),
      bpm: _engine.adaptiveBpm,
      timingWindowMs: _engine.adaptiveTimingWindowMs,
    );
    _telemetryService.logTrial(telemetry);

    if (isCorrect) {
      setState(() {
        _characterMood = CharacterMood.happyStep;
        _characterStepDirection = _expectedDirection;
        _prevDancerGridPos = _dancerGridPos;
        _dancerGridPos = _targetGridPos; // DANCER PERSISTS AT DESTINATION!
      });
      _characterJumpController.forward(from: 0.0);

      if (_engine.currentConfig.isPatternMemory) {
        _memoryPatternIndex++;
      }
    } else {
      setState(() {
        _characterMood = CharacterMood.recoverStumble;
        _characterStepDirection = _expectedDirection;
      });
      _stumbleController.forward(from: 0.0);
    }

    if (_totalTrialsRun >= widget.totalTargetTrials) {
      _isCompleted = true;
      final nextDelayMs = isCorrect ? 900 : 700;
      _nextTrialTimer?.cancel();
      _nextTrialTimer = Timer(Duration(milliseconds: nextDelayMs), () {
        if (!mounted) return;
        _showEndingDisplay();
      });
      return;
    }

    final nextDelayMs = _engine.isAlternateNotes ? 1100 : 800;
    _nextTrialTimer?.cancel();
    _nextTrialTimer = Timer(Duration(milliseconds: nextDelayMs), () {
      if (!mounted || _isPaused || _isCompleted) return;
      _startNextTrial();
    });
  }

  void _showEndingDisplay() {
    setState(() {
      _characterMood = CharacterMood.happyStep;
      _isEndingOverlayVisible = true;
    });
    _bgMusicPlayer?.pause();
    _playEndingCelebrationSound();
    _celebrationController.forward(from: 0.0);
  }

  Future<void> _playEndingCelebrationSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _tapSoundPlayer?.stop();
      await _tapSoundPlayer?.play(AssetSource('audio/northeast_chime_bamboo.wav'));
    } catch (_) {}
  }

  void _restartGameSession() {
    setState(() {
      _totalTrialsRun = 0;
      _stageTrialsRun = 0;
      _correctStepsCount = 0;
      _isCompleted = false;
      _isEndingOverlayVisible = false;
      _isTrialInputLocked = false;
      _characterMood = CharacterMood.idle;
      _characterStepDirection = null;
      _dancerGridPos = const GridPos(1, 1);
      _prevDancerGridPos = const GridPos(1, 1);
      _targetGridPos = const GridPos(1, 0);
      _prevTargetGridPos = const GridPos(1, 0);
    });
    _bambooShiftController.value = 1.0;
    _celebrationController.reset();
    if (_isSoundEnabled) {
      _bgMusicPlayer?.resume();
    }
    _startNextTrial(initialDelay: const Duration(milliseconds: 300));
  }

  void _pauseGame() {
    setState(() {
      _isPaused = true;
      _rhythmPulseController.stop();
      _bgMusicPlayer?.pause();
    });
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
      _rhythmPulseController.repeat(reverse: true);
      if (_isSoundEnabled) {
        _bgMusicPlayer?.resume();
      }
    });
  }

  @override
  void dispose() {
    _nextTrialTimer?.cancel();
    VoiceCommandController.instance.unregisterGame();
    _rhythmPulseController.dispose();
    _bambooShiftController.dispose();
    _characterJumpController.dispose();
    _stumbleController.dispose();
    _celebrationController.dispose();
    _navIdleController.dispose();
    _scorePopController.dispose();
    _underlineController.dispose();
    _bgMusicPlayer?.dispose();
    _tapSoundPlayer?.dispose();
    _bambooClackPlayer?.dispose();
    _telemetryService.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // 1. Ambient aesthetic decorations to fill empty space with soothing visuals
                _buildAmbientDecorations(constraints),

                // 2. Main content column
                Column(
                  children: [
                    _buildTopBar(),
                    const AnimatedFragmentedDivider(),
                    // Expanded court maximizing screen real estate
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: LayoutBuilder(
                          builder: (context, courtConstraints) {
                            final courtSize = min(
                              courtConstraints.maxWidth,
                              courtConstraints.maxHeight,
                            );

                            return Center(
                              child: SizedBox(
                                width: courtSize,
                                height: courtSize,
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _rhythmPulseController,
                                    _bambooShiftController,
                                    _characterJumpController,
                                    _stumbleController,
                                  ]),
                                  builder: (context, _) {
                                    final center = Offset(courtSize / 2, courtSize / 2);
                                    final cellSpacing = courtSize * 0.28;
                                    final targetCenter = Offset(
                                      center.dx + (_targetGridPos.col - 1) * cellSpacing,
                                      center.dy + (_targetGridPos.row - 1) * cellSpacing,
                                    );
                                    final targetRadius =
                                        (courtSize * 0.08).clamp(26.0, 38.0);

                                    return Stack(
                                      children: [
                                        // 1. Interactive canvas court
                                        Positioned.fill(
                                          child: GestureDetector(
                                            key: const ValueKey('bamboo_court_canvas'),
                                            behavior: HitTestBehavior.opaque,
                                            onTapDown: (details) => _handleCourtTap(
                                              details.localPosition,
                                              Size(courtSize, courtSize),
                                            ),
                                            child: CustomPaint(
                                              size: Size(courtSize, courtSize),
                                              painter: BambooCourtPainter(
                                                pulseFactor: _rhythmPulseController.value,
                                                characterMood: _characterMood,
                                                stepDirection: _characterStepDirection,
                                                jumpProgress: _characterJumpController.value,
                                                stumbleProgress: _stumbleController.value,
                                                targetDirection: _expectedDirection,
                                                targetGridPos: _targetGridPos,
                                                prevTargetGridPos: _prevTargetGridPos,
                                                dancerGridPos: _dancerGridPos,
                                                prevDancerGridPos: _prevDancerGridPos,
                                                bambooShiftProgress: _bambooShiftController.value,
                                                trialStep: _totalTrialsRun,
                                                isAlternateNotes: _engine.isAlternateNotes,
                                                verticalCloseWithRight: _verticalCloseWithRight,
                                                prevVerticalCloseWithRight: _prevVerticalCloseWithRight,
                                                horizontalCloseWithBottom: _horizontalCloseWithBottom,
                                                prevHorizontalCloseWithBottom: _prevHorizontalCloseWithBottom,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // 2. Direct touch target circle widget
                                        Positioned(
                                          left: targetCenter.dx - targetRadius,
                                          top: targetCenter.dy - targetRadius,
                                          width: targetRadius * 2,
                                          height: targetRadius * 2,
                                          child: Semantics(
                                            button: true,
                                            label: 'Step target circle',
                                            child: GestureDetector(
                                              key: const ValueKey('bamboo_target_circle'),
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => _processStep(isCorrect: true),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.transparent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isEndingOverlayVisible)
                  _buildCelebratoryEndingDisplay(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Ambient floating pastel orbs to fill empty screen spaces harmoniously
  Widget _buildAmbientDecorations(BoxConstraints constraints) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _navIdleController,
          builder: (context, _) {
            final t = _navIdleController.value;
            final dy1 = sin(t * pi) * 10;
            final dy2 = cos(t * pi) * 12;

            return Stack(
              children: [
                // Top-right soft peach orb
                Positioned(
                  top: 70 + dy1,
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
                // Bottom-left soft pink orb
                Positioned(
                  bottom: 70 + dy2,
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
                // Center-left soft sky-blue mist orb
                Positioned(
                  top: constraints.maxHeight * 0.40 - dy1,
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
            );
          },
        ),
      ),
    );
  }

  /// Top Nav Bar with centered curved title, peach/pink underline, and compact non-overlapping controls
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
          // 1. Back button on the left
          _buildNavBackButton(),
          const SizedBox(width: 6),

          // 2. Centered Game Title with curved font + peach/pink fragmented underline
          Expanded(
            child: Center(
              child: _buildNavTitleWithUnderline(),
            ),
          ),
          const SizedBox(width: 6),

          // 3. Right: Sound, Pause/Play, Score counter (compact, guaranteed no overlap)
          _buildNavRightControls(),
        ],
      ),
    );
  }

  /// Centered game title in curved font with peach & pink fragmented line underline below
  Widget _buildNavTitleWithUnderline() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bamboo Dance',
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
          const SizedBox(height: 3),
          // Peach and pink fragmented line underline below it
          AnimatedBuilder(
            animation: _underlineController,
            builder: (context, _) {
              return SizedBox(
                width: 74,
                height: 3.5,
                child: CustomPaint(
                  painter: _UnderlineFragmentPainter(
                    progress: _underlineController.value,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Main UI style back button
  Widget _buildNavBackButton() {
    return Semantics(
      button: true,
      label: 'Exit to Home',
      child: Tooltip(
        message: 'Exit to Home',
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
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

  /// Right side controls: Sound toggle, Pause/Play toggle, and Score counter with animations
  Widget _buildNavRightControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sound toggle with idle breath + active animation
        _buildNavSoundButton(),
        const SizedBox(width: 4),
        // Pause / Play toggle with idle pulse & pause state indicator
        _buildNavPausePlayButton(),
        const SizedBox(width: 4),
        // Score counter on the nav right with idle float & pop on score
        _buildNavScoreBadge(),
      ],
    );
  }

  /// Sound toggle button with idle breath animation
  Widget _buildNavSoundButton() {
    return AnimatedBuilder(
      animation: _navIdleController,
      builder: (context, child) {
        final scale = _isSoundEnabled
            ? 1.0 + (_navIdleController.value * 0.05)
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Semantics(
        button: true,
        label: 'Toggle Sound',
        child: Tooltip(
          message: _isSoundEnabled ? 'Mute Sound' : 'Enable Sound',
          child: InkWell(
            onTap: () {
              setState(() {
                _isSoundEnabled = !_isSoundEnabled;
                if (_isSoundEnabled) {
                  _bgMusicPlayer?.setVolume(0.85);
                  _bgMusicPlayer?.resume();
                } else {
                  _bgMusicPlayer?.setVolume(0.0);
                }
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _isSoundEnabled ? const Color(0xFFE8F4FD) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isSoundEnabled
                      ? const Color(0xFFB3D7F5)
                      : slateBorder,
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
                _isSoundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: _isSoundEnabled ? primaryNavy : textMuted,
                size: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pause/Play button with idle pulse and paused aura indicator
  Widget _buildNavPausePlayButton() {
    return AnimatedBuilder(
      animation: _navIdleController,
      builder: (context, child) {
        final glow = _isPaused ? (0.3 + 0.5 * _navIdleController.value) : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              if (_isPaused)
                BoxShadow(
                  color: orangeAccent.withValues(alpha: glow),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: child,
        );
      },
      child: Semantics(
        button: true,
        label: _isPaused ? 'Resume Game' : 'Pause Game',
        child: Tooltip(
          message: _isPaused ? 'Resume' : 'Pause',
          child: InkWell(
            onTap: () {
              if (_isPaused) {
                _resumeGame();
              } else {
                _pauseGame();
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _isPaused ? const Color(0xFFFFF3E0) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isPaused ? orangeAccent : slateBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: _isPaused ? orangeAccent : primaryNavy,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Score counter on the nav right with idle floating & pop bounce on score
  Widget _buildNavScoreBadge() {
    final score = _correctStepsCount * 10;
    return AnimatedBuilder(
      animation: Listenable.merge([_navIdleController, _scorePopController]),
      builder: (context, child) {
        final popScale = Curves.elasticOut.transform(_scorePopController.value);
        final idleScale = 1.0 + (_navIdleController.value * 0.03);
        final scale = idleScale + (popScale * 0.20);

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF6EE), Color(0xFFFDEEF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _scorePopController.value > 0.05
                    ? orangeAccent
                    : peachAccent,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: peachAccent.withValues(
                    alpha: 0.20 + (_scorePopController.value * 0.30),
                  ),
                  blurRadius: 4 + (_scorePopController.value * 4),
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFF9800),
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: primaryNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Celebratory ending display dialog overlay celebrating session completion
  Widget _buildCelebratoryEndingDisplay() {
    final accuracyPercent = _totalTrialsRun > 0
        ? ((_correctStepsCount / _totalTrialsRun) * 100).round()
        : 100;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _celebrationController,
        builder: (context, child) {
          final animValue = CurvedAnimation(
            parent: _celebrationController,
            curve: Curves.easeOutBack,
          ).value;
          return Container(
            color: Colors.black.withValues(alpha: 0.5 * _celebrationController.value),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Transform.scale(
              scale: 0.85 + (0.15 * animValue),
              child: Opacity(
                opacity: _celebrationController.value.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: 360,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF0F4F8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: peachAccent,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryNavy.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: lightBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryNavy, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryNavy.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 38,
                    color: primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '🌸 CONGRATULATIONS 🌸',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.totalTargetTrials} Dance Steps Completed!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryNavy,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'You danced beautifully! Great for rhythm & memory.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: slateBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Steps',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_totalTrialsRun',
                          style: const TextStyle(
                            color: primaryNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 28, color: slateBorder),
                    Column(
                      children: [
                        const Text(
                          'Harmony',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$accuracyPercent%',
                          style: const TextStyle(
                            color: primaryNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 28, color: slateBorder),
                    Column(
                      children: [
                        const Text(
                          'Stage',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_engine.currentStageNumber} / 6',
                          style: const TextStyle(
                            color: primaryNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      label: const Text(
                        'Play Again',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _restartGameSession,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryNavy,
                        side: const BorderSide(color: primaryNavy, width: 1.8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.home_rounded, size: 20),
                      label: const Text(
                        'Home',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
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
}

/// Custom painter for the animated peach & pink fragmented underline below title
class _UnderlineFragmentPainter extends CustomPainter {
  final double progress;

  _UnderlineFragmentPainter({required this.progress});

  static const Color peachColor = Color(0xFFFFAB91);
  static const Color pinkColor = Color(0xFFF48FB1);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double lineThickness = height.clamp(3.0, 4.0);

    const double dashWidth = 34.0;
    const double dashGap = 8.0;
    const double period = dashWidth + dashGap;

    final Paint peachPaint = Paint()
      ..color = peachColor
      ..style = PaintingStyle.fill;

    final Paint pinkPaint = Paint()
      ..color = pinkColor
      ..style = PaintingStyle.fill;

    final double shift = progress * period;
    double x = -period + shift;

    int index = 0;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2.0)),
    );
    while (x < width + period) {
      final bool isPeach = (index % 2 == 0);
      final Paint paint = isPeach ? peachPaint : pinkPaint;

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          (height - lineThickness) / 2,
          dashWidth,
          lineThickness,
        ),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(rrect, paint);

      x += dashWidth + dashGap;
      index++;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UnderlineFragmentPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// 5. CUSTOM 2D PAINTER (3x3 BAMBOO MATRIX & PERSISTENT POSITION DANCER)
// ============================================================================

/// High-performance 2D Painter rendering:
/// 1. Assamese woven reed mat floor.
/// 2. 3 horizontal and 3 vertical bamboo poles dynamically & randomly moving,
///    opening wide empty spaces for the target and dancer.
/// 3. Dynamically aligned target circle pointer inside the open empty cell (no pole overlap).
/// 4. Assamese folk dancer persisting at stepped destination cell (no pole overlap).
class BambooCourtPainter extends CustomPainter {
  final double pulseFactor;
  final CharacterMood characterMood;
  final DanceDirection? stepDirection;
  final double jumpProgress; // 0.0 to 1.0 (smooth step/hop to target cell)
  final double stumbleProgress;
  final DanceDirection targetDirection;
  final GridPos targetGridPos;
  final GridPos prevTargetGridPos;
  final GridPos dancerGridPos;
  final GridPos prevDancerGridPos;
  final double bambooShiftProgress; // 0.0 to 1.0 smooth easing transition between steps
  final bool isAlternateNotes;

  final int trialStep;
  final bool? verticalCloseWithRight;
  final bool? prevVerticalCloseWithRight;
  final bool? horizontalCloseWithBottom;
  final bool? prevHorizontalCloseWithBottom;

  final Paint _matBgPaint = Paint()..color = Colors.white;
  final Paint _matPatternPaint = Paint()
    ..color = const Color(0xFFE4EDF5)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
  final Paint _matDotPaint = Paint()
    ..color = const Color(0xFFCFDFED)
    ..style = PaintingStyle.fill;
  final Paint _matBorderPaint = Paint()
    ..color = const Color(0xFFCFE0ED)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  final Paint _shadowPaint = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

  BambooCourtPainter({
    required this.pulseFactor,
    required this.characterMood,
    required this.stepDirection,
    required this.jumpProgress,
    required this.stumbleProgress,
    required this.targetDirection,
    required this.targetGridPos,
    this.prevTargetGridPos = const GridPos(1, 1),
    required this.dancerGridPos,
    required this.prevDancerGridPos,
    this.bambooShiftProgress = 1.0,
    this.trialStep = 0,
    required this.isAlternateNotes,
    this.verticalCloseWithRight,
    this.prevVerticalCloseWithRight,
    this.horizontalCloseWithBottom,
    this.prevHorizontalCloseWithBottom,
  });

  /// Determines whether two grid positions reside in the same bamboo space/quadrant.
  /// Used to ensure no simultaneous/consecutive iterations ever share the same bamboo space.
  static bool isSameBambooSpace(GridPos posA, GridPos posB) {
    if (posA == posB) return true;

    // Same vertical bamboo strip (both in Left column or both in Right column)
    if (posA.col == 0 && posB.col == 0) return true;
    if (posA.col == 2 && posB.col == 2) return true;

    // Same horizontal bamboo strip (both in Top row or both in Bottom row)
    if (posA.row == 0 && posB.row == 0) return true;
    if (posA.row == 2 && posB.row == 2) return true;

    // Same center cell
    if (posA.col == 1 && posA.row == 1 && posB.col == 1 && posB.row == 1) return true;

    // Sharing a corner quadrant (e.g. outer corner and adjacent inner cells of same space):
    // Top-Right corner (2, 0):
    if ((posA == const GridPos(2, 0) || posB == const GridPos(2, 0)) &&
        (posA.col >= 1 && posA.row <= 1 && posB.col >= 1 && posB.row <= 1)) {
      return true;
    }
    // Bottom-Left corner (0, 2):
    if ((posA == const GridPos(0, 2) || posB == const GridPos(0, 2)) &&
        (posA.col <= 1 && posA.row >= 1 && posB.col <= 1 && posB.row >= 1)) {
      return true;
    }
    // Top-Left corner (0, 0):
    if ((posA == const GridPos(0, 0) || posB == const GridPos(0, 0)) &&
        (posA.col <= 1 && posA.row <= 1 && posB.col <= 1 && posB.row <= 1)) {
      return true;
    }
    // Bottom-Right corner (2, 2):
    if ((posA == const GridPos(2, 2) || posB == const GridPos(2, 2)) &&
        (posA.col >= 1 && posA.row >= 1 && posB.col >= 1 && posB.row >= 1)) {
      return true;
    }

    return false;
  }

  /// Returns a safe empty cell located in another block area / opposite compartment across the bamboo poles.
  static GridPos getOtherBlockAreaPos(GridPos target) {
    if (target == const GridPos(1, 0)) return const GridPos(1, 2); // Top target -> Bottom block area
    if (target == const GridPos(1, 2)) return const GridPos(1, 0); // Bottom target -> Top block area
    if (target == const GridPos(0, 1)) return const GridPos(2, 1); // Left target -> Right block area
    if (target == const GridPos(2, 1)) return const GridPos(0, 1); // Right target -> Left block area
    if (target.row == 0) return GridPos(target.col, 2);
    if (target.row == 2) return GridPos(target.col, 0);
    if (target.col == 0) return GridPos(2, target.row);
    if (target.col == 2) return GridPos(0, target.row);
    return const GridPos(1, 2);
  }

  static GridPos getOpenQuadrantCorner(GridPos target, [int trialStep = 0]) {
    final bool closeWithRight;
    if (target.col == 0) {
      closeWithRight = true;
    } else if (target.col == 2) {
      closeWithRight = false;
    } else {
      closeWithRight = (trialStep % 2 == 1);
    }

    final bool closeWithBottom;
    if (target.row == 0) {
      closeWithBottom = true;
    } else if (target.row == 2) {
      closeWithBottom = false;
    } else {
      closeWithBottom = (trialStep % 2 == 1);
    }

    final openCol = closeWithRight ? 0 : 2;
    final openRow = closeWithBottom ? 0 : 2;

    return GridPos(openCol, openRow);
  }

  static List<double> _calcStaticVerticalPoles(
    GridPos target,
    GridPos dancer,
    Offset center,
    double S, [
    double courtSize = 320.0,
    int trialStep = 0,
  ]) {
    final poleThickness = (courtSize * 0.038).clamp(10.0, 15.0);
    // Authentic Bamboo Dance (Cheraw) Mechanics:
    // Vertical poles: Pole 0 (Left), Pole 1 (Centre), Pole 2 (Right).
    // Target on Left -> Right closes. Target on Right -> Left closes.
    // Target in Centre -> Alternates cleanly by trialStep without flinching when dancer moves.
    final bool closeWithRight;
    if (target.col == 0) {
      closeWithRight = true;
    } else if (target.col == 2) {
      closeWithRight = false;
    } else {
      closeWithRight = (trialStep % 2 == 1);
    }

    if (closeWithRight) {
      // Centre pole and Right pole close completely (touching side-by-side):
      return [
        center.dx - 1.48 * S,
        center.dx + 0.52 * S - poleThickness / 2,
        center.dx + 0.52 * S + poleThickness / 2,
      ];
    } else {
      // Centre pole and Left pole close completely (touching side-by-side):
      return [
        center.dx - 0.52 * S - poleThickness / 2,
        center.dx - 0.52 * S + poleThickness / 2,
        center.dx + 1.48 * S,
      ];
    }
  }

  static List<double> _calcStaticHorizontalPoles(
    GridPos target,
    GridPos dancer,
    Offset center,
    double S, [
    double courtSize = 320.0,
    int trialStep = 0,
  ]) {
    final poleThickness = (courtSize * 0.038).clamp(10.0, 15.0);
    // Horizontal poles: Pole 0 (Top), Pole 1 (Centre), Pole 2 (Bottom).
    // Target at Top -> Bottom closes. Target at Bottom -> Top closes.
    // Target in Centre -> Alternates cleanly by trialStep without flinching when dancer moves.
    final bool closeWithBottom;
    if (target.row == 0) {
      closeWithBottom = true;
    } else if (target.row == 2) {
      closeWithBottom = false;
    } else {
      closeWithBottom = (trialStep % 2 == 1);
    }

    if (closeWithBottom) {
      // Centre pole and Bottom pole close completely (touching side-by-side):
      return [
        center.dy - 1.48 * S,
        center.dy + 0.52 * S - poleThickness / 2,
        center.dy + 0.52 * S + poleThickness / 2,
      ];
    } else {
      // Centre pole and Top pole close completely (touching side-by-side):
      return [
        center.dy - 0.52 * S - poleThickness / 2,
        center.dy - 0.52 * S + poleThickness / 2,
        center.dy + 1.48 * S,
      ];
    }
  }

  static List<double> calcVerticalPolesFromFlag(
    Offset center,
    double S,
    double courtSize,
    bool closeWithRight,
  ) {
    final poleThickness = (courtSize * 0.038).clamp(10.0, 15.0);
    if (closeWithRight) {
      return [
        center.dx - 1.48 * S,
        center.dx + 0.52 * S - poleThickness / 2,
        center.dx + 0.52 * S + poleThickness / 2,
      ];
    } else {
      return [
        center.dx - 0.52 * S - poleThickness / 2,
        center.dx - 0.52 * S + poleThickness / 2,
        center.dx + 1.48 * S,
      ];
    }
  }

  static List<double> calcHorizontalPolesFromFlag(
    Offset center,
    double S,
    double courtSize,
    bool closeWithBottom,
  ) {
    final poleThickness = (courtSize * 0.038).clamp(10.0, 15.0);
    if (closeWithBottom) {
      return [
        center.dy - 1.48 * S,
        center.dy + 0.52 * S - poleThickness / 2,
        center.dy + 0.52 * S + poleThickness / 2,
      ];
    } else {
      return [
        center.dy - 0.52 * S - poleThickness / 2,
        center.dy - 0.52 * S + poleThickness / 2,
        center.dy + 1.48 * S,
      ];
    }
  }

  /// Computes the 3 vertical pole X coordinates ensuring the target and dancer
  /// cells are located in wide, completely open empty spaces without pole overlap.
  /// Smoothly transitions between alternating closed positions (Centre with Left <---> Centre with Right)
  /// as steps advance, completely avoiding wobbling, sudden jumps, or unexpected snaps.
  List<double> getVerticalPolePositions(double courtSize, Offset center, double S) {
    if (verticalCloseWithRight != null) {
      final fromPoles = calcVerticalPolesFromFlag(center, S, courtSize, prevVerticalCloseWithRight ?? verticalCloseWithRight!);
      final toPoles = calcVerticalPolesFromFlag(center, S, courtSize, verticalCloseWithRight!);
      if (bambooShiftProgress >= 1.0) {
        return toPoles;
      }
      final t = Curves.easeInOutCubic.transform(bambooShiftProgress.clamp(0.0, 1.0));
      return [
        fromPoles[0] + (toPoles[0] - fromPoles[0]) * t,
        fromPoles[1] + (toPoles[1] - fromPoles[1]) * t,
        fromPoles[2] + (toPoles[2] - fromPoles[2]) * t,
      ];
    }

    final toPoles = _calcStaticVerticalPoles(targetGridPos, dancerGridPos, center, S, courtSize, trialStep);
    if (bambooShiftProgress >= 1.0) {
      return toPoles;
    }
    final prevStep = trialStep > 0 ? trialStep - 1 : (trialStep + 1);
    final fromPoles = _calcStaticVerticalPoles(prevTargetGridPos, prevDancerGridPos, center, S, courtSize, prevStep);
    final t = Curves.easeInOutCubic.transform(bambooShiftProgress.clamp(0.0, 1.0));
    return [
      fromPoles[0] + (toPoles[0] - fromPoles[0]) * t,
      fromPoles[1] + (toPoles[1] - fromPoles[1]) * t,
      fromPoles[2] + (toPoles[2] - fromPoles[2]) * t,
    ];
  }

  /// Computes the 3 horizontal pole Y coordinates ensuring the target and dancer
  /// cells are located in wide, completely open empty spaces without pole overlap.
  /// Smoothly transitions between alternating closed positions (Centre with Top <---> Centre with Bottom)
  /// as steps advance, completely avoiding wobbling, sudden jumps, or unexpected snaps.
  List<double> getHorizontalPolePositions(double courtSize, Offset center, double S) {
    if (horizontalCloseWithBottom != null) {
      final fromPoles = calcHorizontalPolesFromFlag(center, S, courtSize, prevHorizontalCloseWithBottom ?? horizontalCloseWithBottom!);
      final toPoles = calcHorizontalPolesFromFlag(center, S, courtSize, horizontalCloseWithBottom!);
      if (bambooShiftProgress >= 1.0) {
        return toPoles;
      }
      final t = Curves.easeInOutCubic.transform(bambooShiftProgress.clamp(0.0, 1.0));
      return [
        fromPoles[0] + (toPoles[0] - fromPoles[0]) * t,
        fromPoles[1] + (toPoles[1] - fromPoles[1]) * t,
        fromPoles[2] + (toPoles[2] - fromPoles[2]) * t,
      ];
    }

    final toPoles = _calcStaticHorizontalPoles(targetGridPos, dancerGridPos, center, S, courtSize, trialStep);
    if (bambooShiftProgress >= 1.0) {
      return toPoles;
    }
    final prevStep = trialStep > 0 ? trialStep - 1 : (trialStep + 1);
    final fromPoles = _calcStaticHorizontalPoles(prevTargetGridPos, prevDancerGridPos, center, S, courtSize, prevStep);
    final t = Curves.easeInOutCubic.transform(bambooShiftProgress.clamp(0.0, 1.0));
    return [
      fromPoles[0] + (toPoles[0] - fromPoles[0]) * t,
      fromPoles[1] + (toPoles[1] - fromPoles[1]) * t,
      fromPoles[2] + (toPoles[2] - fromPoles[2]) * t,
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final courtRadius = size.width * 0.48;
    final cellSpacing = size.width * 0.28;
    final poleThickness = (size.width * 0.038).clamp(10.0, 15.0);

    // 1. Draw Assamese woven reed mat floor
    _drawWovenMat(canvas, center, courtRadius);

    // 2. Draw Target Circle dynamically aligned to open grid cell coordinates
    _drawTargetCircle(canvas, center, cellSpacing);

    // 3. Draw 3 horizontal poles and 3 vertical poles dynamically shifting to open empty spaces
    _drawBambooGrid(canvas, size, center, cellSpacing, poleThickness);

    // 4. Draw Traditional Assamese Dancer persisting at destination coordinates in open empty space
    _drawAssameseDancer(canvas, center, cellSpacing);
  }

  void _drawWovenMat(Canvas canvas, Offset center, double radius) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCircle(center: center, radius: radius),
      const Radius.circular(24),
    );

    // Subtle ambient shadow
    canvas.drawRRect(
      rect.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0xFF1E3A5F).withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Clean white play court base
    canvas.drawRRect(rect, _matBgPaint);

    // Subtle modern geometric grid
    const step = 24.0;
    final left = center.dx - radius;
    final right = center.dx + radius;
    final top = center.dy - radius;
    final bottom = center.dy + radius;

    canvas.save();
    canvas.clipRRect(rect);
    for (double x = left; x <= right; x += step) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), _matPatternPaint);
    }
    for (double y = top; y <= bottom; y += step) {
      canvas.drawLine(Offset(left, y), Offset(right, y), _matPatternPaint);
    }
    // Subtle dot accents at intersections
    for (double x = left; x <= right; x += step * 2) {
      for (double y = top; y <= bottom; y += step * 2) {
        canvas.drawCircle(Offset(x, y), 1.5, _matDotPaint);
      }
    }
    canvas.restore();

    // Elegant border
    canvas.drawRRect(rect, _matBorderPaint);
  }

  /// Draws target circle strictly inside its open empty space with clear margins,
  /// smoothly synchronized in lockstep with the bamboo shift transition as poles glide open.
  void _drawTargetCircle(Canvas canvas, Offset center, double cellSpacing) {
    final targetCenter = Offset(
      center.dx + (targetGridPos.col - 1) * cellSpacing,
      center.dy + (targetGridPos.row - 1) * cellSpacing,
    );

    final baseRadius = (cellSpacing * 0.32).clamp(18.0, 30.0);
    final pulseScale = 1.0 + (pulseFactor * 0.08);

    // Synchronize target appearance smoothly with bamboo shift progress:
    // As poles glide open (easeInOutCubic), the target smoothly blooms into the newly opened space
    final shiftT = Curves.easeInOutCubic.transform(bambooShiftProgress.clamp(0.0, 1.0));
    final entranceScale = 0.5 + (0.5 * shiftT);
    final entranceOpacity = shiftT.clamp(0.0, 1.0);
    final circleRadius = baseRadius * pulseScale * entranceScale;

    // Glowing target aura with peach & coral theme colors
    final glowPaint = Paint()
      ..color = const Color(0xFFFFAB91).withValues(alpha: 0.40 * entranceOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, circleRadius + 4.0, glowPaint);

    final fillPaint = Paint()
      ..color = const Color(0xFFFFE5DD).withValues(alpha: 0.70 * entranceOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, circleRadius, fillPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFF7043).withValues(alpha: 1.0 * entranceOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(targetCenter, circleRadius, borderPaint);

    // Concentric inner cue dot
    final dotPaint = Paint()
      ..color = const Color(0xFF1E3A5F).withValues(alpha: 1.0 * entranceOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, 4.5 * entranceScale, dotPaint);
  }

  /// Draws 3 horizontal poles and 3 vertical poles dividing the court into open spaces
  void _drawBambooGrid(
    Canvas canvas,
    Size size,
    Offset center,
    double cellSpacing,
    double poleThickness,
  ) {
    final poleLength = size.width * 0.94;
    final xs = getVerticalPolePositions(size.width, center, cellSpacing);
    final ys = getHorizontalPolePositions(size.height, center, cellSpacing);

    // 3 Vertical poles
    for (final x in xs) {
      _drawSingleBambooPole(
        canvas,
        start: Offset(x, center.dy - poleLength / 2),
        end: Offset(x, center.dy + poleLength / 2),
        thickness: poleThickness,
        isHorizontal: false,
      );
    }

    // 3 Horizontal poles
    for (final y in ys) {
      _drawSingleBambooPole(
        canvas,
        start: Offset(center.dx - poleLength / 2, y),
        end: Offset(center.dx + poleLength / 2, y),
        thickness: poleThickness,
        isHorizontal: true,
      );
    }

    // Golden clapping beat spark at pole intersections during rhythm peak
    if (pulseFactor > 0.82) {
      final sparkOpacity = ((pulseFactor - 0.82) / 0.18).clamp(0.0, 1.0);
      final sparkPaint = Paint()
        ..color = const Color(0xFFD4A359).withValues(alpha: sparkOpacity * 0.6)
        ..style = PaintingStyle.fill;
      for (final x in xs) {
        for (final y in ys) {
          canvas.drawCircle(Offset(x, y), poleThickness * 0.7, sparkPaint);
        }
      }
    }
  }

  void _drawSingleBambooPole(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required double thickness,
    required bool isHorizontal,
  }) {
    final rect = isHorizontal
        ? Rect.fromLTRB(start.dx, start.dy - thickness / 2, end.dx,
            end.dy + thickness / 2)
        : Rect.fromLTRB(start.dx - thickness / 2, start.dy,
            end.dx + thickness / 2, end.dy);

    // 1. Soft ground shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(2.5, 3.5)),
          Radius.circular(thickness / 2)),
      _shadowPaint,
    );

    // 2. Bamboo cylinder body gradient
    final gradient = LinearGradient(
      begin: isHorizontal ? Alignment.topCenter : Alignment.centerLeft,
      end: isHorizontal ? Alignment.bottomCenter : Alignment.centerRight,
      colors: const [
        Color(0xFF8DAA72),
        Color(0xFF6B8B4D),
        Color(0xFF4A6831),
      ],
    );

    final polePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(thickness / 2)),
      polePaint,
    );

    // 3. Bamboo nodes / joints
    final nodePaint = Paint()
      ..color = const Color(0xFF384F25)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final ringPaint = Paint()
      ..color = const Color(0xFFC8DC96)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const segmentCount = 4;
    for (int i = 1; i < segmentCount; i++) {
      final t = i / segmentCount;
      if (isHorizontal) {
        final x = start.dx + (end.dx - start.dx) * t;
        canvas.drawLine(
          Offset(x, rect.top),
          Offset(x, rect.bottom),
          nodePaint,
        );
        canvas.drawLine(
          Offset(x + 1.2, rect.top),
          Offset(x + 1.2, rect.bottom),
          ringPaint,
        );
      } else {
        final y = start.dy + (end.dy - start.dy) * t;
        canvas.drawLine(
          Offset(rect.left, y),
          Offset(rect.right, y),
          nodePaint,
        );
        canvas.drawLine(
          Offset(rect.left, y + 1.2),
          Offset(rect.right, y + 1.2),
          ringPaint,
        );
      }
    }
  }

  void _drawAssameseDancer(Canvas canvas, Offset courtCenter, double cellSpacing) {
    final targetPos = Offset(
      courtCenter.dx + (targetGridPos.col - 1) * cellSpacing,
      courtCenter.dy + (targetGridPos.row - 1) * cellSpacing,
    );
    final currentPos = Offset(
      courtCenter.dx + (dancerGridPos.col - 1) * cellSpacing,
      courtCenter.dy + (dancerGridPos.row - 1) * cellSpacing,
    );

    Offset dancerPosition = currentPos;
    double wobbleAngle = 0.0;
    double jumpScale = 1.0;
    double elevationY = 0.0;
    double groundShadowFactor = 1.0;

    // Safe empty space located strictly in another block area / opposite compartment
    // across the closed bamboo poles (never on the target)
    final otherBlock = getOtherBlockAreaPos(targetGridPos);
    final otherBlockPos = Offset(
      courtCenter.dx + (otherBlock.col - 1) * cellSpacing,
      courtCenter.dy + (otherBlock.row - 1) * cellSpacing,
    );

    if (characterMood == CharacterMood.happyStep) {
      // User tapped the target: dancer leaps from the other block area directly onto the target!
      final hopOrigin = otherBlockPos;
      if (jumpProgress < 0.6) {
        final t = jumpProgress / 0.6;
        final curve = Curves.easeOutQuad.transform(t);
        dancerPosition = Offset.lerp(hopOrigin, targetPos, curve)!;
        jumpScale = 1.0 + (sin(t * pi) * 0.28);
        elevationY = -36.0 * sin(t * pi);
        groundShadowFactor = 1.0 - (0.35 * sin(t * pi));
      } else {
        dancerPosition = targetPos;
        jumpScale = 1.0;
      }
    } else if (characterMood == CharacterMood.recoverStumble) {
      // Gentle friendly stumble wobble in the other block area
      final decay = (1.0 - stumbleProgress);
      wobbleAngle = sin(stumbleProgress * pi * 4) * 0.15 * decay;
      final wobbleX = sin(stumbleProgress * pi * 3) * 8.0 * decay;
      dancerPosition = Offset(otherBlockPos.dx + wobbleX, otherBlockPos.dy);
    } else if (bambooShiftProgress < 1.0) {
      // Bamboo Shift Transition: As bamboos slide underneath to new positions,
      // dancer performs a graceful 3D leap above the moving poles into the other block area!
      final t = Curves.easeInOutCubic.transform(bambooShiftProgress.clamp(0.0, 1.0));
      final hopCurve = sin(bambooShiftProgress.clamp(0.0, 1.0) * pi);
      elevationY = -52.0 * hopCurve;
      jumpScale = 1.0 + (0.38 * hopCurve);
      groundShadowFactor = 1.0 - (0.50 * hopCurve);
      final leapStart = currentPos;
      final basePos = Offset.lerp(leapStart, otherBlockPos, t)!;
      dancerPosition = basePos + Offset(0, elevationY);
    } else {
      // Between trials, dancer rests safely inside the other block area, clearly away from the target
      dancerPosition = otherBlockPos;
    }

    final dancerRadius = (cellSpacing * 0.30).clamp(24.0, 38.0);

    canvas.save();
    canvas.translate(dancerPosition.dx, dancerPosition.dy);
    if (jumpScale != 1.0) {
      canvas.scale(jumpScale, jumpScale);
    }
    if (wobbleAngle != 0.0) {
      canvas.rotate(wobbleAngle);
    }

    // A. Dancer shadow (stays anchored to the mat floor even during airborne jump)
    final shadowPaint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, (0.22 * groundShadowFactor).clamp(0.0, 0.22))
      ..style = PaintingStyle.fill;

    final shadowCenter = Offset(0, 10 - (elevationY / jumpScale));
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: dancerRadius * 1.8 * groundShadowFactor.clamp(0.65, 1.0),
        height: dancerRadius * 1.4 * groundShadowFactor.clamp(0.65, 1.0),
      ),
      shadowPaint,
    );

    // B. Traditional Assamese Attire:
    // Muga Silk Golden-Cream Body with Kingkhap / Gamosa Red Embroidered Borders
    final mugaSilkPaint = Paint()
      ..color = const Color(0xFFF0DEC0)
      ..style = PaintingStyle.fill;
    final bihuRedPaint = Paint()
      ..color = const Color(0xFFB33927)
      ..style = PaintingStyle.fill;

    // Body/Torso in Muga silk
    canvas.drawCircle(Offset.zero, dancerRadius, mugaSilkPaint);

    // Traditional Gamosa / Chador crossing drape
    final sashPath = Path()
      ..moveTo(-dancerRadius * 0.85, -dancerRadius * 0.2)
      ..lineTo(dancerRadius * 0.85, dancerRadius * 0.5)
      ..lineTo(dancerRadius * 0.65, dancerRadius * 0.85)
      ..lineTo(-dancerRadius * 0.65, 0.15)
      ..close();
    canvas.drawPath(sashPath, bihuRedPaint);

    // Red border ornament dots along sash
    final borderDotPaint = Paint()..color = const Color(0xFFFFD166);
    for (int i = 0; i < 4; i++) {
      final t = i / 3.0;
      final dotX = -dancerRadius * 0.7 + t * (dancerRadius * 1.4);
      final dotY = -dancerRadius * 0.05 + t * (dancerRadius * 0.6);
      canvas.drawCircle(Offset(dotX, dotY), 2.2, borderDotPaint);
    }

    // C. Traditional headwear & face
    final hairPaint = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawCircle(
      Offset(0, -dancerRadius * 0.7),
      dancerRadius * 0.45,
      hairPaint,
    );

    // Assamese red Kopou flower bun accent
    canvas.drawCircle(
      Offset(dancerRadius * 0.35, -dancerRadius * 0.85),
      dancerRadius * 0.22,
      bihuRedPaint,
    );

    // Face
    final facePaint = Paint()..color = const Color(0xFFFFDAB9);
    canvas.drawCircle(
      Offset(0, -dancerRadius * 0.5),
      dancerRadius * 0.38,
      facePaint,
    );

    // Auspicious Red Bindi/Tilak
    canvas.drawCircle(
      Offset(0, -dancerRadius * 0.58),
      2.0,
      bihuRedPaint,
    );

    // Gentle smiling eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF2E2E2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(-dancerRadius * 0.15, -dancerRadius * 0.50),
        width: 6,
        height: 4,
      ),
      pi,
      pi,
      false,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(dancerRadius * 0.15, -dancerRadius * 0.50),
        width: 6,
        height: 4,
      ),
      pi,
      pi,
      false,
      eyePaint,
    );

    // Warm smile
    final smilePaint = Paint()
      ..color = const Color(0xFF8B2500)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, -dancerRadius * 0.40),
        width: 10,
        height: 6,
      ),
      0,
      pi,
      false,
      smilePaint,
    );

    // Dancing arms / hands with traditional gold bangles (Gamkharu)
    final handPaint = Paint()..color = const Color(0xFFFFDAB9);
    final gamkharuPaint = Paint()..color = const Color(0xFFE2B053);

    // Left arm flourish
    canvas.drawCircle(
      Offset(-dancerRadius * 1.05, -dancerRadius * 0.1),
      dancerRadius * 0.22,
      handPaint,
    );
    canvas.drawCircle(
      Offset(-dancerRadius * 0.95, -dancerRadius * 0.1),
      dancerRadius * 0.12,
      gamkharuPaint,
    );

    // Right arm flourish
    canvas.drawCircle(
      Offset(dancerRadius * 1.05, -dancerRadius * 0.1),
      dancerRadius * 0.22,
      handPaint,
    );
    canvas.drawCircle(
      Offset(dancerRadius * 0.95, -dancerRadius * 0.1),
      dancerRadius * 0.12,
      gamkharuPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BambooCourtPainter oldDelegate) {
    return oldDelegate.pulseFactor != pulseFactor ||
        oldDelegate.characterMood != characterMood ||
        oldDelegate.stepDirection != stepDirection ||
        oldDelegate.jumpProgress != jumpProgress ||
        oldDelegate.stumbleProgress != stumbleProgress ||
        oldDelegate.targetDirection != targetDirection ||
        oldDelegate.targetGridPos != targetGridPos ||
        oldDelegate.prevTargetGridPos != prevTargetGridPos ||
        oldDelegate.dancerGridPos != dancerGridPos ||
        oldDelegate.prevDancerGridPos != prevDancerGridPos ||
        oldDelegate.bambooShiftProgress != bambooShiftProgress ||
        oldDelegate.trialStep != trialStep ||
        oldDelegate.isAlternateNotes != isAlternateNotes;
  }
}
