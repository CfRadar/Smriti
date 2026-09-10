// apps/patient/lib/games/pattern_memory_game.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:patient/controllers/voice_command_controller.dart';
import 'package:patient/models/voice_command.dart';
import 'package:patient/widgets/animated_fragmented_divider.dart';
import 'package:patient/widgets/game_completion_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Game phases during a trial
enum PatternGamePhase {
  countdown,
  memorize,
  recall,
  feedback,
  completed,
}

/// Difficulty configuration for levels 1 through 10
class PatternDifficultyConfig {
  final int level;
  final int gridSize; // 3 -> 3x3 (9 tiles), 4 -> 4x4 (16 tiles), 5 -> 5x5 (25 tiles)
  final int patternCount; // Number of tiles to memorize
  final int displayDurationMs; // Memorization window in milliseconds
  final String description;

  const PatternDifficultyConfig({
    required this.level,
    required this.gridSize,
    required this.patternCount,
    required this.displayDurationMs,
    required this.description,
  });

  int get totalTiles => gridSize * gridSize;

  static const List<PatternDifficultyConfig> levels = [
    PatternDifficultyConfig(
      level: 1,
      gridSize: 3,
      patternCount: 3,
      displayDurationMs: 3600,
      description: '3 tiles in 3×3 grid',
    ),
    PatternDifficultyConfig(
      level: 2,
      gridSize: 3,
      patternCount: 4,
      displayDurationMs: 3300,
      description: '4 tiles in 3×3 grid',
    ),
    PatternDifficultyConfig(
      level: 3,
      gridSize: 3,
      patternCount: 5,
      displayDurationMs: 3000,
      description: '5 tiles in 3×3 grid',
    ),
    PatternDifficultyConfig(
      level: 4,
      gridSize: 4,
      patternCount: 4,
      displayDurationMs: 3200,
      description: '4 tiles in 4×4 grid',
    ),
    PatternDifficultyConfig(
      level: 5,
      gridSize: 4,
      patternCount: 5,
      displayDurationMs: 2900,
      description: '5 tiles in 4×4 grid',
    ),
    PatternDifficultyConfig(
      level: 6,
      gridSize: 4,
      patternCount: 6,
      displayDurationMs: 2600,
      description: '6 tiles in 4×4 grid',
    ),
    PatternDifficultyConfig(
      level: 7,
      gridSize: 4,
      patternCount: 7,
      displayDurationMs: 2400,
      description: '7 tiles in 4×4 grid',
    ),
    PatternDifficultyConfig(
      level: 8,
      gridSize: 5,
      patternCount: 6,
      displayDurationMs: 2500,
      description: '6 tiles in 5×5 grid',
    ),
    PatternDifficultyConfig(
      level: 9,
      gridSize: 5,
      patternCount: 7,
      displayDurationMs: 2200,
      description: '7 tiles in 5×5 grid',
    ),
    PatternDifficultyConfig(
      level: 10,
      gridSize: 5,
      patternCount: 8,
      displayDurationMs: 2000,
      description: '8 tiles in 5×5 grid',
    ),
  ];

  static PatternDifficultyConfig getForLevel(int level) {
    final clamped = level.clamp(1, 10);
    return levels[clamped - 1];
  }
}

/// Telemetry record for each trial
class PatternTrialTelemetry {
  final String sessionId;
  final int trialNumber;
  final int level;
  final int gridSize;
  final int patternCount;
  final bool isCorrect;
  final int reactionTimeMs;
  final String timestamp;

  PatternTrialTelemetry({
    required this.sessionId,
    required this.trialNumber,
    required this.level,
    required this.gridSize,
    required this.patternCount,
    required this.isCorrect,
    required this.reactionTimeMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'trialNumber': trialNumber,
        'level': level,
        'gridSize': gridSize,
        'patternCount': patternCount,
        'isCorrect': isCorrect,
        'reactionTimeMs': reactionTimeMs,
        'timestamp': timestamp,
      };
}

/// Offline-first telemetry service
class PatternGameTelemetryService {
  final String endpointUrl;
  final http.Client _client;
  static const String _offlineCacheKey = 'smriti_pattern_game_telemetry_queue';

  PatternGameTelemetryService({
    this.endpointUrl = 'http://localhost:5000/api/games/session',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<void> sendTelemetry(PatternTrialTelemetry telemetry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cachedQueue = prefs.getStringList(_offlineCacheKey) ?? [];
      cachedQueue.add(jsonEncode(telemetry.toJson()));
      await prefs.setStringList(_offlineCacheKey, cachedQueue);
      await syncCachedTelemetry();
    } catch (e) {
      debugPrint('Pattern telemetry save error: $e');
    }
  }

  Future<void> syncCachedTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cachedQueue = prefs.getStringList(_offlineCacheKey) ?? [];
      if (cachedQueue.isEmpty) return;

      List<String> remainingQueue = [];
      for (String rawJson in cachedQueue) {
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
        } catch (e) {
          remainingQueue.add(rawJson);
        }
      }
      await prefs.setStringList(_offlineCacheKey, remainingQueue);
    } catch (e) {
      debugPrint('Pattern telemetry sync error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Main Screen for the Pattern Memory Game
class PatternMemoryGameScreen extends StatefulWidget {
  final String sessionId;
  final int totalTrials;

  const PatternMemoryGameScreen({
    super.key,
    this.sessionId = 'session_pattern_memory',
    this.totalTrials = 6,
  });

  /// Static helper to retrieve all locally stored ML sessions for training
  static Future<List<Map<String, dynamic>>> getStoredMLSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList =
        prefs.getStringList('smriti_pattern_ml_training_sessions') ?? [];
    return rawList
        .map((str) => jsonDecode(str) as Map<String, dynamic>)
        .toList();
  }

  @override
  State<PatternMemoryGameScreen> createState() =>
      _PatternMemoryGameScreenState();
}

class _PatternMemoryGameScreenState extends State<PatternMemoryGameScreen>
    with TickerProviderStateMixin {
  // Theme Palette Definitions
  static const Color darkGreen = Color(0xFF214E3B);
  static const Color primarySage = Color(0xFF4A7C59);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFE0E8E1);
  static const Color textDark = Color(0xFF2C3E35);
  static const Color textGrey = Color(0xFF66736C);
  static const Color cream = Color(0xFFEDE7D7);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color darkRed = Color(0xFF6B2D2D); // Deep forest red matching darkGreen
  static const Color softRedBorder = Color(0xFF9E4D4D); // Soft warm red border matching primarySage
  static const Color screenBg = Color(0xFFF0F4F8);
  static const Color navBarBg = Color(0xFFEAF2F8); // Light blue nav surface matching Bamboo Dance
  static const Color primaryNavy = Color(0xFF1E293B);
  static const Color slateBorder = Color(0xFFE2E8F0);
  static const Color peachAccent = Color(0xFFEAA083);
  static const Color pinkAccent = Color(0xFFE89BA6);

  bool _isSoundEnabled = true;

  // Persistence keys
  static const String _prefKeyLevel = 'smriti_pattern_memory_level';
  static const String _prefKeyBestStreak = 'smriti_pattern_memory_best_streak';
  static const String _prefKeyHighScore = 'smriti_pattern_memory_high_score';
  static const String _prefKeyMLSessions = 'smriti_pattern_ml_training_sessions';

  // Services & Audio
  final PatternGameTelemetryService _telemetryService =
      PatternGameTelemetryService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  static const String _clickSoundAsset = 'audio/click.wav';

  // Game & Session State
  bool _isPaused = false;
  late DateTime _sessionStartTime;
  late int _initialSessionLevel;
  int _currentLevel = 1;
  int _correctStreak = 0;
  int _bestStreak = 0;
  int _highScore = 0;
  int _currentTrial = 1;
  int _completedCount = 0;
  int _correctCount = 0;
  int get _score => _correctCount * 30 * _currentLevel;

  PatternGamePhase _currentPhase = PatternGamePhase.countdown;
  int _countdownNumber = 3;

  // Pattern data
  Set<int> _targetTileIndices = {};
  final Set<int> _selectedTileIndices = {};
  final Set<int> _wrongTileIndices = {};
  int? _lastWrongTileIndex;

  Timer? _gameTimer;
  Timer? _recallTimer;
  DateTime? _recallStartTime;

  /// Relaxed recall duration for senior care (hidden, never displayed to prevent time anxiety)
  int get _relaxedRecallTimeoutSeconds {
    if (_currentConfig.gridSize >= 5) return 30;
    return 25;
  }

  // Detailed trial telemetry collected for ML model training
  final List<Map<String, dynamic>> _sessionTrialLogs = [];

  // Animation controller for progress countdown during memorization
  late AnimationController _progressController;

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
        default:
          break;
      }
    });

    _sessionStartTime = DateTime.now();
    _initialSessionLevel = 1;
    _progressController = AnimationController(vsync: this);

    // Audio setup
    if (!kIsWeb) {
      _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    }
    _audioPlayer.setSource(AssetSource(_clickSoundAsset)).catchError((e) {
      debugPrint('Audio pre-warm error: $e');
    });

    _telemetryService.syncCachedTelemetry();
    _initGameSession();
  }

  @override
  void dispose() {
    VoiceCommandController.instance.unregisterGame();
    _gameTimer?.cancel();
    _recallTimer?.cancel();
    _progressController.dispose();
    _audioPlayer.dispose();
    _telemetryService.dispose();
    super.dispose();
  }

  void pauseGame() {
    if (_isPaused) return;
    _gameTimer?.cancel();
    _recallTimer?.cancel();
    _progressController.stop();
    setState(() {
      _isPaused = true;
    });
  }

  void resumeGame() {
    if (!_isPaused) return;
    setState(() {
      _isPaused = false;
    });
    if (_currentPhase == PatternGamePhase.countdown ||
        _currentPhase == PatternGamePhase.memorize ||
        _currentPhase == PatternGamePhase.recall) {
      _startCountdown();
    }
  }

  /// Load persisted difficulty level and start the game session
  Future<void> _initGameSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getInt(_prefKeyLevel) ?? 1;
      final savedBestStreak = prefs.getInt(_prefKeyBestStreak) ?? 0;
      final savedHighScore = prefs.getInt(_prefKeyHighScore) ?? 0;

      if (mounted) {
        setState(() {
          _currentLevel = savedLevel.clamp(1, 10);
          _initialSessionLevel = _currentLevel;
          _bestStreak = savedBestStreak;
          _highScore = savedHighScore;
        });
        _startCountdown();
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      if (mounted) _startCountdown();
    }
  }

  /// Persist current difficulty level and streak
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyLevel, _currentLevel);
      if (_correctStreak > _bestStreak) {
        _bestStreak = _correctStreak;
        await prefs.setInt(_prefKeyBestStreak, _bestStreak);
      }
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  /// Store full session record with timestamp and ML features locally
  Future<void> _recordMLSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingSessions = prefs.getStringList(_prefKeyMLSessions) ?? [];

      final endTime = DateTime.now();
      final durationSeconds = endTime.difference(_sessionStartTime).inSeconds;

      // Compute reaction time stats
      final reactionTimes = _sessionTrialLogs
          .map((t) => t['reaction_time_ms'] as int? ?? 0)
          .where((rt) => rt > 0)
          .toList();

      final double avgRt = reactionTimes.isNotEmpty
          ? reactionTimes.reduce((a, b) => a + b) / reactionTimes.length
          : 0.0;
      final int minRt = reactionTimes.isNotEmpty
          ? reactionTimes.reduce(min)
          : 0;
      final int maxRt = reactionTimes.isNotEmpty
          ? reactionTimes.reduce(max)
          : 0;

      final sessionData = {
        'session_id': widget.sessionId,
        'start_time': _sessionStartTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'local_start_time': _sessionStartTime.toString(),
        'local_end_time': endTime.toString(),
        'duration_seconds': durationSeconds,
        'starting_level': _initialSessionLevel,
        'final_level': _currentLevel,
        'total_trials': widget.totalTrials,
        'completed_trials': _completedCount,
        'correct_trials': _correctCount,
        'accuracy_rate': widget.totalTrials > 0
            ? (_correctCount / widget.totalTrials)
            : 0.0,
        'average_reaction_time_ms': avgRt,
        'min_reaction_time_ms': minRt,
        'max_reaction_time_ms': maxRt,
        'max_streak': _bestStreak,
        'trials': _sessionTrialLogs,
      };

      existingSessions.add(jsonEncode(sessionData));
      await prefs.setStringList(_prefKeyMLSessions, existingSessions);
      debugPrint(
          'ML training session saved locally. Total stored: ${existingSessions.length}');
    } catch (e) {
      debugPrint('Error saving ML session data: $e');
    }
  }

  /// Crisp audio & haptic feedback on tile tap
  Future<void> _playTapSound({bool isError = false}) async {
    try {
      // Haptic feedback provides physical tactile response
      if (isError) {
        // Distinct vibration for wrong tile tap (firm impact + vibration pulse)
        HapticFeedback.heavyImpact();
        HapticFeedback.vibrate();
      } else {
        // Gentle subtle tap for correct guess
        HapticFeedback.lightImpact();
      }

      // If sound is turned off, strictly avoid any system click or audio asset playback
      if (!_isSoundEnabled) return;

      if (isError) {
        SystemSound.play(SystemSoundType.alert);
      } else {
        SystemSound.play(SystemSoundType.click);
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource(_clickSoundAsset),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Sound playback error: $e');
    }
  }

  PatternDifficultyConfig get _currentConfig =>
      PatternDifficultyConfig.getForLevel(_currentLevel);

  /// Phase 1: 3-2-1 gentle countdown before pattern shows
  void _startCountdown() {
    _gameTimer?.cancel();
    _recallTimer?.cancel();
    _progressController.stop();

    final config = _currentConfig;
    final totalTiles = config.totalTiles;

    // Pick random unique tiles for pattern ahead of time
    final Set<int> pattern = {};
    while (pattern.length < config.patternCount) {
      pattern.add(_random.nextInt(totalTiles));
    }

    setState(() {
      _targetTileIndices = pattern;
      _selectedTileIndices.clear();
      _wrongTileIndices.clear();
      _lastWrongTileIndex = null;
      _currentPhase = PatternGamePhase.countdown;
      _countdownNumber = 3;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownNumber > 1) {
        setState(() {
          _countdownNumber--;
        });
      } else {
        timer.cancel();
        _startMemorizePhase();
      }
    });
  }

  /// Phase 2: Memorize highlighted pattern tiles
  void _startMemorizePhase() {
    _gameTimer?.cancel();
    _recallTimer?.cancel();

    final config = _currentConfig;

    setState(() {
      _selectedTileIndices.clear();
      _wrongTileIndices.clear();
      _lastWrongTileIndex = null;
      _currentPhase = PatternGamePhase.memorize;
    });

    // Start progress countdown bar
    _progressController.duration =
        Duration(milliseconds: config.displayDurationMs);
    _progressController.forward(from: 0.0);

    _gameTimer = Timer(Duration(milliseconds: config.displayDurationMs), () {
      if (!mounted) return;
      _startRecallPhase();
    });
  }

  /// Phase 3: Recall - user taps the memorized tiles
  void _startRecallPhase() {
    _gameTimer?.cancel();
    _recallTimer?.cancel();
    _progressController.stop();

    setState(() {
      _currentPhase = PatternGamePhase.recall;
      _recallStartTime = DateTime.now();
      _selectedTileIndices.clear();
      _wrongTileIndices.clear();
      _lastWrongTileIndex = null;
    });

    // Hidden, relaxed solving timer for senior care (not displayed to prevent time anxiety)
    _recallTimer = Timer(Duration(seconds: _relaxedRecallTimeoutSeconds), () {
      if (!mounted || _currentPhase != PatternGamePhase.recall) return;
      _handleTrialCompletion(isSuccess: false, timedOut: true);
    });
  }

  /// User taps a tile in recall phase
  void _onTileTap(int index) {
    if (_currentPhase != PatternGamePhase.recall) return;
    if (_selectedTileIndices.contains(index)) return;
    if (_wrongTileIndices.contains(index)) return;

    final isCorrect = _targetTileIndices.contains(index);

    if (isCorrect) {
      _playTapSound(isError: false);
      setState(() {
        _selectedTileIndices.add(index);
      });

      // Check if all pattern tiles have been found
      if (_selectedTileIndices.length == _targetTileIndices.length) {
        _recallTimer?.cancel();
        _handleTrialCompletion(isSuccess: true);
      }
    } else {
      // Wrong tile tapped: provide distinct vibration & sound, highlight wrong tile in matching soft red,
      // and transition to feedback phase then advance to the next pattern!
      _playTapSound(isError: true);
      setState(() {
        _wrongTileIndices.add(index);
        _lastWrongTileIndex = index;
      });
      _recallTimer?.cancel();
      _handleTrialCompletion(isSuccess: false);
    }
  }

  /// Handle trial outcome & silent adaptive difficulty adjustment
  void _handleTrialCompletion({required bool isSuccess, bool timedOut = false}) {
    _gameTimer?.cancel();
    _recallTimer?.cancel();
    final now = DateTime.now();
    final reactionTimeMs = _recallStartTime != null
        ? now.difference(_recallStartTime!).inMilliseconds
        : 0;

    final bool isCleanSuccess = isSuccess && _wrongTileIndices.isEmpty;

    setState(() {
      _currentPhase = PatternGamePhase.feedback;
      _completedCount++;
      if (isCleanSuccess) {
        _correctCount++;
        _correctStreak++;
        if (_correctStreak > _bestStreak) {
          _bestStreak = _correctStreak;
        }
      } else if (isSuccess) {
        _correctCount++;
        _correctStreak = 0;
      } else {
        _correctStreak = 0;
      }
    });

    // Adaptive difficulty logic: promote after 2 clean correct, demote after unassisted error
    if (isCleanSuccess) {
      if (_correctStreak >= 2) {
        if (_currentLevel < 10) {
          _currentLevel++;
          _correctStreak = 0;
        }
      }
    } else if (!isSuccess) {
      if (_currentLevel > 1) {
        _currentLevel--;
      }
    }

    // Persist updated difficulty preset immediately
    _savePreferences();

    // Log detailed trial entry for ML model training
    final trialLog = {
      'trial_number': _currentTrial,
      'level': _currentLevel,
      'grid_size': _currentConfig.gridSize,
      'pattern_count': _currentConfig.patternCount,
      'target_indices': _targetTileIndices.toList(),
      'selected_indices': _selectedTileIndices.toList(),
      'wrong_indices': _wrongTileIndices.toList(),
      'is_correct': isSuccess,
      'is_clean_correct': isCleanSuccess,
      'timed_out': timedOut,
      'reaction_time_ms': reactionTimeMs,
      'timestamp': now.toUtc().toIso8601String(),
    };
    _sessionTrialLogs.add(trialLog);

    // Also send to telemetry service
    final telemetry = PatternTrialTelemetry(
      sessionId: widget.sessionId,
      trialNumber: _currentTrial,
      level: _currentLevel,
      gridSize: _currentConfig.gridSize,
      patternCount: _currentConfig.patternCount,
      isCorrect: isSuccess,
      reactionTimeMs: reactionTimeMs,
      timestamp: now.toUtc().toIso8601String(),
    );
    _telemetryService.sendTelemetry(telemetry);

    // Smooth transition to next trial or session conclusion
    final isFinalTrial = _currentTrial >= widget.totalTrials;
    final delayMs = isSuccess ? 800 : 1500;
    _gameTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;

      if (!isFinalTrial) {
        setState(() {
          _currentTrial++;
        });
        _startCountdown();
      } else {
        _gameTimer?.cancel();
        _recallTimer?.cancel();
        _progressController.stop();

        setState(() {
          _currentPhase = PatternGamePhase.completed;
          _targetTileIndices.clear();
          _selectedTileIndices.clear();
          _wrongTileIndices.clear();
          _lastWrongTileIndex = null;
        });

        _recordMLSessionData();
        _showCompletionDialog();
      }
    });
  }

  /// Reset session stats and continue from current difficulty preset
  void _restartSession() {
    _gameTimer?.cancel();
    _recallTimer?.cancel();
    _progressController.stop();

    _sessionStartTime = DateTime.now();
    _initialSessionLevel = _currentLevel;
    _sessionTrialLogs.clear();
    setState(() {
      _currentTrial = 1;
      _completedCount = 0;
      _correctCount = 0;
      _correctStreak = 0;
      _selectedTileIndices.clear();
      _wrongTileIndices.clear();
      _lastWrongTileIndex = null;
    });
    _startCountdown();
  }

  /// Unified game completion dialog matching the Smriti UI theme
  void _showCompletionDialog() async {
    _gameTimer?.cancel();
    _recallTimer?.cancel();
    _progressController.stop();
    final reactionTimes = _sessionTrialLogs
        .map((t) => t['reaction_time_ms'] as int? ?? 0)
        .where((rt) => rt > 0)
        .toList();
    final avgRt = reactionTimes.isNotEmpty
        ? (reactionTimes.reduce((a, b) => a + b) / reactionTimes.length).round()
        : 0;

    final accuracy = widget.totalTrials > 0
        ? ((_correctCount / widget.totalTrials) * 100).round()
        : 100;

    final sessionScore = _correctCount * 30 * _currentLevel;
    if (sessionScore > _highScore) {
      _highScore = sessionScore;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefKeyHighScore, _highScore);
      } catch (_) {}
    }

    if (!mounted) return;

    showGameCompletionDialog(
      context: context,
      finalScore: sessionScore,
      bestScore: _highScore,
      metrics: [
        GameCompletionMetric(
          icon: Icons.check_circle_outline_rounded,
          label: 'Accuracy',
          value: '$accuracy%',
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
        _playTapSound();
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      },
      onPlayAgain: () {
        _playTapSound();
        _restartSession();
      },
    );
  }

  /// Caregiver / manual difficulty picker bottom sheet
  void _openDifficultySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: Colors.white.withValues(alpha: 0.90),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Difficulty Preset (1–10)',
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: textGrey),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: 10,
                              itemBuilder: (context, index) {
                                final lvl = index + 1;
                                final cfg = PatternDifficultyConfig.getForLevel(lvl);
                                final isSelected = lvl == _currentLevel;

                                return ListTile(
                                  onTap: () {
                                    setSheetState(() {});
                                    setState(() {
                                      _currentLevel = lvl;
                                      _correctStreak = 0;
                                    });
                                    _savePreferences();
                                    Navigator.of(context).pop();
                                    _startCountdown();
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  tileColor: isSelected
                                      ? primarySage.withValues(alpha: 0.12)
                                      : null,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isSelected
                                        ? primarySage
                                        : borderGrey.withValues(alpha: 0.6),
                                    child: Text(
                                      '$lvl',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'Level $lvl (${cfg.gridSize}×${cfg.gridSize})',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: textDark,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${cfg.patternCount} tiles • ${(cfg.displayDurationMs / 1000).toStringAsFixed(1)}s',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: textGrey,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: primarySage,
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
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
                _buildAmbientDecorations(constraints),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(),
                    const AnimatedFragmentedDivider(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTopStatusHeader(),
                            const SizedBox(height: 8),
                            _buildPhaseBar(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Center(
                                child: LayoutBuilder(
                                  builder: (context, gridConstraints) {
                                    final available = min(
                                        gridConstraints.maxWidth, gridConstraints.maxHeight);
                                    final gridBoxSize =
                                        (available - 8).clamp(180.0, 360.0);

                                    return SizedBox(
                                      width: gridBoxSize,
                                      height: gridBoxSize,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _buildGridArea(),
                                          if (_currentPhase == PatternGamePhase.countdown)
                                            _buildCountdownOverlay(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildFooterInstruction(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isPaused) _buildPauseOverlay(),
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
            'Pattern Memory',
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
                  _audioPlayer.stop();
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
        // Pause / Resume button replacing setting option
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

  /// Top status header
  Widget _buildTopStatusHeader() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Trial progress
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology_rounded,
                  color: darkGreen, size: 18),
              const SizedBox(width: 6),
              Text(
                'Trial $_currentTrial / ${widget.totalTrials}',
                style: const TextStyle(
                  color: primaryNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($_completedCount)',
                style: const TextStyle(
                  color: primarySage,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // 2. Tappable Level badge
          InkWell(
            onTap: _openDifficultySheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                  const Icon(Icons.bolt_rounded, color: darkGreen, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    'Level $_currentLevel',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Row(
                    children: [
                      Icon(
                        _correctStreak >= 1
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 6,
                        color: darkGreen,
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _correctStreak >= 2
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 6,
                        color: darkGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

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
    );
  }

  /// Visual indicator bar
  Widget _buildPhaseBar() {
    return SizedBox(
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: _currentPhase == PatternGamePhase.memorize
            ? AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: 1.0 - _progressController.value,
                    backgroundColor: borderGrey.withValues(alpha: 0.6),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(primarySage),
                  );
                },
              )
            : _currentPhase == PatternGamePhase.recall
                ? LinearProgressIndicator(
                    value: _currentConfig.patternCount > 0
                        ? (_selectedTileIndices.length /
                            _currentConfig.patternCount)
                        : 0.0,
                    backgroundColor: borderGrey.withValues(alpha: 0.6),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(successGreen),
                  )
                : Container(color: Colors.transparent),
      ),
    );
  }

  /// Countdown overlay
  Widget _buildCountdownOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: cardWhite.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGrey, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Get Ready',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_countdownNumber',
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: primarySage,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Memorize the ${_currentConfig.patternCount} tiles',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: textGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// Adaptive Matrix Grid
  Widget _buildGridArea() {
    final config = _currentConfig;
    final gridSize = config.gridSize;
    final totalTiles = config.totalTiles;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: gridSize == 5 ? 8 : 10,
        mainAxisSpacing: gridSize == 5 ? 8 : 10,
      ),
      itemCount: totalTiles,
      itemBuilder: (context, index) {
        return _buildTile(index, gridSize);
      },
    );
  }

  /// Individual Tile Widget with 3D Card Flip Animation on Recall Tap
  Widget _buildTile(int index, int gridSize) {
    final isTarget = _targetTileIndices.contains(index);
    final isMemorizing = _currentPhase == PatternGamePhase.memorize;
    final isRecall = _currentPhase == PatternGamePhase.recall;
    final isFeedback = _currentPhase == PatternGamePhase.feedback;
    final isCompleted = _currentPhase == PatternGamePhase.completed;
    final isSelected = _selectedTileIndices.contains(index);
    final isWrongTap = _wrongTileIndices.contains(index);
    final double borderRadius = gridSize == 5 ? 10.0 : 14.0;

    // Target rotation angle (in radians)
    // Front face (0.0 rad) shows green target / wrong red / neutral card
    // Back face (pi rad) shows neutral blank state during recall
    double targetAngle = 0.0;
    if (isCompleted) {
      targetAngle = 0.0;
    } else if (isTarget) {
      if (isRecall && !isSelected) {
        targetAngle = pi; // Flipped to back face waiting for user tap
      } else {
        targetAngle = 0.0; // Flipped to front face during memorize, feedback, or when correctly tapped
      }
    } else {
      // Non-target tile
      if (isRecall && !isWrongTap) {
        targetAngle = pi; // Blank neutral state waiting for user tap
      } else {
        targetAngle = 0.0; // Front face (neutral white or error state)
      }
    }

    return Semantics(
      button: isRecall && !isCompleted,
      enabled: isRecall && !isCompleted,
      label: 'Tile ${index + 1}',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: targetAngle, end: targetAngle),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        builder: (context, angle, child) {
          final isFrontFacing = angle.abs() % (2 * pi) < (pi / 2) ||
              angle.abs() % (2 * pi) > (3 * pi / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D Perspective perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontFacing
                ? _buildFrontFace(
                    index: index,
                    borderRadius: borderRadius,
                    isMemorizing: isMemorizing,
                    isTarget: isTarget,
                    isSelected: isSelected,
                    isWrongTap: isWrongTap,
                    isFeedback: isFeedback,
                    isRecall: isRecall,
                    isCompleted: isCompleted,
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi), // Mirror correction for back face
                    alignment: Alignment.center,
                    child: _buildBackFace(
                      index: index,
                      borderRadius: borderRadius,
                      isRecall: isRecall,
                    ),
                  ),
          );
        },
      ),
    );
  }

  /// Front Face (Target pattern / Success / Error state / Clean completed)
  Widget _buildFrontFace({
    required int index,
    required double borderRadius,
    required bool isMemorizing,
    required bool isTarget,
    required bool isSelected,
    required bool isWrongTap,
    required bool isFeedback,
    required bool isRecall,
    required bool isCompleted,
  }) {
    Color tileColor = cardWhite;
    Border border = Border.all(color: borderGrey, width: 2.0);
    Widget? icon;

    if (isCompleted) {
      tileColor = cardWhite;
      border = Border.all(color: borderGrey, width: 2.0);
      icon = null;
    } else if (isMemorizing && isTarget) {
      tileColor = darkGreen;
      border = Border.all(color: primarySage, width: 3.0);
      icon = null;
    } else if (isSelected && isTarget) {
      tileColor = darkGreen;
      border = Border.all(color: primarySage, width: 3.0);
      icon = null;
    } else if (isWrongTap) {
      tileColor = darkRed;
      border = Border.all(color: softRedBorder, width: 3.0);
      icon = null; // Clean face with no cross mark
    } else if (isFeedback && isTarget && !isSelected) {
      tileColor = cream;
      border = Border.all(color: primarySage, width: 2.5);
      icon = null;
    }

    final bool canTap = isRecall && !isWrongTap && !isSelected && !isCompleted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? () => _onTileTap(index) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
            boxShadow: (isMemorizing && isTarget) || (isSelected && isTarget)
                ? [
                    BoxShadow(
                      color: darkGreen.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : isWrongTap
                    ? [
                        BoxShadow(
                          color: darkRed.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
          ),
          child: Center(
            child: icon ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  /// Back Face (Neutral blank state during recall waiting for tap)
  Widget _buildBackFace({
    required int index,
    required double borderRadius,
    required bool isRecall,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRecall ? () => _onTileTap(index) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderGrey, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Footer instruction
  Widget _buildFooterInstruction() {
    String message;
    IconData iconData;

    switch (_currentPhase) {
      case PatternGamePhase.countdown:
      case PatternGamePhase.memorize:
        message = 'Memorize the highlighted pattern';
        iconData = Icons.visibility_rounded;
        break;
      case PatternGamePhase.recall:
        final remaining =
            _currentConfig.patternCount - _selectedTileIndices.length;
        message = remaining > 0
            ? 'Tap the pattern tiles ($remaining left)'
            : 'Pattern completed!';
        iconData = Icons.touch_app_rounded;
        break;
      case PatternGamePhase.feedback:
        final isFinalTrial = _currentTrial >= widget.totalTrials;
        if (isFinalTrial) {
          message = 'Completing session...';
          iconData = Icons.emoji_events_rounded;
        } else if (_lastWrongTileIndex != null) {
          message = 'Reviewing pattern...';
          iconData = Icons.visibility_rounded;
        } else {
          message = 'Next pattern...';
          iconData = Icons.refresh_rounded;
        }
        break;
      case PatternGamePhase.completed:
        message = 'Game completed! Well done.';
        iconData = Icons.emoji_events_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: slateBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: darkGreen, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}