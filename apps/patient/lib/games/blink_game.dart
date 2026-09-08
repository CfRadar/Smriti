// apps/patient/lib/games/blink_game.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:patient/controllers/voice_command_controller.dart';
import 'package:patient/models/voice_command.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GamePhase { targetDisplay, selection, feedback }

/// Difficulty configuration for levels 1 through 10
class BlinkDifficultyConfig {
  final int level;
  final int digitCount; // Number of digits (1, 2, 3, or 4)
  final int displayDurationMs; // Duration target number is shown
  final String description;

  const BlinkDifficultyConfig({
    required this.level,
    required this.digitCount,
    required this.displayDurationMs,
    required this.description,
  });

  /// Generates a random number matching the digit count constraint
  int generateNumber(Random random) {
    if (digitCount == 1) {
      return random.nextInt(9) + 1; // 1 - 9
    } else if (digitCount == 2) {
      return random.nextInt(90) + 10; // 10 - 99
    } else if (digitCount == 3) {
      return random.nextInt(900) + 100; // 100 - 999
    } else {
      return random.nextInt(9000) + 1000; // 1000 - 9999
    }
  }

  static const List<BlinkDifficultyConfig> levels = [
    BlinkDifficultyConfig(
      level: 1,
      digitCount: 1,
      displayDurationMs: 2800,
      description: '1 digit (1–9) • 2.8s display',
    ),
    BlinkDifficultyConfig(
      level: 2,
      digitCount: 1,
      displayDurationMs: 2200,
      description: '1 digit (1–9) • 2.2s display',
    ),
    BlinkDifficultyConfig(
      level: 3,
      digitCount: 2,
      displayDurationMs: 2500,
      description: '2 digits (10–99) • 2.5s display',
    ),
    BlinkDifficultyConfig(
      level: 4,
      digitCount: 2,
      displayDurationMs: 2100,
      description: '2 digits (10–99) • 2.1s display',
    ),
    BlinkDifficultyConfig(
      level: 5,
      digitCount: 2,
      displayDurationMs: 1800,
      description: '2 digits (10–99) • 1.8s display',
    ),
    BlinkDifficultyConfig(
      level: 6,
      digitCount: 3,
      displayDurationMs: 2200,
      description: '3 digits (100–999) • 2.2s display',
    ),
    BlinkDifficultyConfig(
      level: 7,
      digitCount: 3,
      displayDurationMs: 1800,
      description: '3 digits (100–999) • 1.8s display',
    ),
    BlinkDifficultyConfig(
      level: 8,
      digitCount: 3,
      displayDurationMs: 1500,
      description: '3 digits (100–999) • 1.5s display',
    ),
    BlinkDifficultyConfig(
      level: 9,
      digitCount: 4,
      displayDurationMs: 1800,
      description: '4 digits (1000–9999) • 1.8s display',
    ),
    BlinkDifficultyConfig(
      level: 10,
      digitCount: 4,
      displayDurationMs: 1400,
      description: '4 digits (1000–9999) • 1.4s display',
    ),
  ];

  static BlinkDifficultyConfig getForLevel(int level) {
    final clamped = level.clamp(1, 10);
    return levels[clamped - 1];
  }
}

/// Model capturing performance data for a single trial.
class TrialTelemetry {
  final String sessionId;
  final int trialNumber;
  final int level;
  final int digitCount;
  final int targetNumber;
  final int selectedNumber;
  final bool isCorrect;
  final int reactionTimeMs;
  final String timestamp;

  TrialTelemetry({
    required this.sessionId,
    required this.trialNumber,
    required this.level,
    required this.digitCount,
    required this.targetNumber,
    required this.selectedNumber,
    required this.isCorrect,
    required this.reactionTimeMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'trialNumber': trialNumber,
        'level': level,
        'digitCount': digitCount,
        'targetNumber': targetNumber,
        'selectedNumber': selectedNumber,
        'isCorrect': isCorrect,
        'reactionTimeMs': reactionTimeMs,
        'timestamp': timestamp,
      };
}

/// Service responsible for offline-first telemetry management.
class GameTelemetryService {
  final String endpointUrl;
  final http.Client _client;
  static const String _offlineCacheKey = 'smriti_blink_game_telemetry_queue';

  GameTelemetryService({
    this.endpointUrl = 'http://localhost:5000/api/games/session',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<void> sendTelemetry(TrialTelemetry telemetry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cachedQueue = prefs.getStringList(_offlineCacheKey) ?? [];

      final String jsonPayload = jsonEncode(telemetry.toJson());
      cachedQueue.add(jsonPayload);

      await prefs.setStringList(_offlineCacheKey, cachedQueue);
      await syncCachedTelemetry();
    } catch (e) {
      debugPrint('Error saving telemetry locally: $e');
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
      debugPrint('Error syncing telemetry queue: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

class BlinkGameScreen extends StatefulWidget {
  final String sessionId;
  final int totalTrials;

  const BlinkGameScreen({
    super.key,
    this.sessionId = 'session_blink_attention',
    this.totalTrials = 6,
  });

  static Future<List<Map<String, dynamic>>> getStoredMLSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList =
        prefs.getStringList('smriti_blink_ml_training_sessions') ?? [];
    return rawList
        .map((str) => jsonDecode(str) as Map<String, dynamic>)
        .toList();
  }

  @override
  State<BlinkGameScreen> createState() => _BlinkGameScreenState();
}

class _BlinkGameScreenState extends State<BlinkGameScreen> {
  // Theme Palette Definitions
  static const Color darkGreen = Color(0xFF214E3B);
  static const Color primarySage = Color(0xFF4A7C59);
  static const Color softBackground = Color(0xFFF8F5EC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFE0E8E1);
  static const Color textDark = Color(0xFF2C3E35);
  static const Color textGrey = Color(0xFF66736C);
  static const Color cream = Color(0xFFEDE7D7);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color alertSoftRed = Color(0xFFD32F2F);

  // Persistence keys
  static const String _prefKeyLevel = 'smriti_blink_game_level';
  static const String _prefKeyBestStreak = 'smriti_blink_game_best_streak';
  static const String _prefKeyMLSessions = 'smriti_blink_ml_training_sessions';

  final GameTelemetryService _telemetryService = GameTelemetryService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  bool _isPaused = false;
  late DateTime _sessionStartTime;
  late int _initialSessionLevel;
  int _currentLevel = 1;
  int _correctStreak = 0;
  int _bestStreak = 0;
  int _currentTrial = 1;
  int _completedCount = 0;
  int _correctCount = 0;

  GamePhase _currentPhase = GamePhase.targetDisplay;

  int _targetNumber = 0;
  List<int> _gridNumbers = [];

  Timer? _phaseTimer;
  DateTime? _selectionPhaseStartTime;
  int? _selectedTileNumber;

  final List<Map<String, dynamic>> _sessionTrialLogs = [];
  static const String _clickSoundAsset = 'audio/click.wav';

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
        case VoiceIntent.tapNumber:
          if (command.parameter != null) {
            tapNumber(command.parameter!);
          }
          break;
        default:
          break;
      }
    });

    // On mobile platforms, lowLatency mode utilizes SoundPool/AVAudioPlayer for instant SFX
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
    _phaseTimer?.cancel();
    _audioPlayer.dispose();
    _telemetryService.dispose();
    super.dispose();
  }

  void pauseGame() {
    if (!mounted || _isPaused) return;
    _phaseTimer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void resumeGame() {
    if (!mounted || !_isPaused) return;
    setState(() {
      _isPaused = false;
    });
    if (_currentPhase == GamePhase.targetDisplay) {
      _startTrial();
    }
  }

  void tapNumber(int number) {
    if (_currentPhase != GamePhase.selection || !_gridNumbers.contains(number)) {
      return;
    }
    _onTileSelected(number);
  }

  Future<void> _initGameSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getInt(_prefKeyLevel) ?? 1;
      final savedBestStreak = prefs.getInt(_prefKeyBestStreak) ?? 0;

      if (mounted) {
        setState(() {
          _currentLevel = savedLevel.clamp(1, 10);
          _initialSessionLevel = _currentLevel;
          _bestStreak = savedBestStreak;
        });
        _startTrial();
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      if (mounted) _startTrial();
    }
  }

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

  Future<void> _recordMLSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingSessions = prefs.getStringList(_prefKeyMLSessions) ?? [];

      final endTime = DateTime.now();
      final durationSeconds = endTime.difference(_sessionStartTime).inSeconds;

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
    } catch (e) {
      debugPrint('Error saving ML session data: $e');
    }
  }

  Future<void> _playClickSound({bool isError = false}) async {
    try {
      if (isError) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.alert);
      } else {
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource(_clickSoundAsset),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Click sound playback error: $e');
    }
  }

  BlinkDifficultyConfig get _currentConfig =>
      BlinkDifficultyConfig.getForLevel(_currentLevel);

  void _startTrial() {
    _phaseTimer?.cancel();

    final config = _currentConfig;
    final newTarget = config.generateNumber(_random);

    final Set<int> numbersSet = {newTarget};
    while (numbersSet.length < 9) {
      numbersSet.add(config.generateNumber(_random));
    }

    final shuffledList = numbersSet.toList()..shuffle(_random);

    setState(() {
      _targetNumber = newTarget;
      _gridNumbers = shuffledList;
      _currentPhase = GamePhase.targetDisplay;
      _selectedTileNumber = null;
    });

    // Display target for config duration
    _phaseTimer = Timer(Duration(milliseconds: config.displayDurationMs), () {
      if (!mounted) return;
      setState(() {
        _currentPhase = GamePhase.selection;
        _selectionPhaseStartTime = DateTime.now();
      });
    });
  }

  void _onTileSelected(int selectedVal) {
    if (_currentPhase != GamePhase.selection) return;

    final isCorrect = selectedVal == _targetNumber;
    _playClickSound(isError: !isCorrect);

    final now = DateTime.now();
    final reactionTimeMs = _selectionPhaseStartTime != null
        ? now.difference(_selectionPhaseStartTime!).inMilliseconds
        : 0;

    setState(() {
      _selectedTileNumber = selectedVal;
      _currentPhase = GamePhase.feedback;
      _completedCount++;
      if (isCorrect) {
        _correctCount++;
        _correctStreak++;
        if (_correctStreak > _bestStreak) {
          _bestStreak = _correctStreak;
        }
      } else {
        _correctStreak = 0;
      }
    });

    // Adaptive difficulty logic: promote after 2 correct, demote on error
    if (isCorrect) {
      if (_correctStreak >= 2) {
        if (_currentLevel < 10) {
          _currentLevel++;
          _correctStreak = 0;
        }
      }
    } else {
      if (_currentLevel > 1) {
        _currentLevel--;
      }
    }

    _savePreferences();

    final trialLog = {
      'trial_number': _currentTrial,
      'level': _currentLevel,
      'digit_count': _currentConfig.digitCount,
      'target_number': _targetNumber,
      'selected_number': selectedVal,
      'is_correct': isCorrect,
      'reaction_time_ms': reactionTimeMs,
      'timestamp': now.toUtc().toIso8601String(),
    };
    _sessionTrialLogs.add(trialLog);

    final telemetry = TrialTelemetry(
      sessionId: widget.sessionId,
      trialNumber: _currentTrial,
      level: _currentLevel,
      digitCount: _currentConfig.digitCount,
      targetNumber: _targetNumber,
      selectedNumber: selectedVal,
      isCorrect: isCorrect,
      reactionTimeMs: reactionTimeMs,
      timestamp: now.toUtc().toIso8601String(),
    );

    _telemetryService.sendTelemetry(telemetry);

    final delayMs = isCorrect ? 650 : 1100;
    _phaseTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      if (_currentTrial < widget.totalTrials) {
        setState(() {
          _currentTrial++;
        });
        _startTrial();
      } else {
        _recordMLSessionData();
        _showCompletionDialog();
      }
    });
  }

  void _restartSession() {
    _sessionStartTime = DateTime.now();
    _initialSessionLevel = _currentLevel;
    _sessionTrialLogs.clear();
    setState(() {
      _currentTrial = 1;
      _completedCount = 0;
      _correctCount = 0;
      _correctStreak = 0;
    });
    _startTrial();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: primarySage, size: 28),
            SizedBox(width: 10),
            Text(
              'Session Complete',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Level $_currentLevel • $_correctCount of ${widget.totalTrials} correct',
          style: const TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () {
              _playClickSound();
              Navigator.of(context).pop();
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Home',
              style: TextStyle(
                color: textGrey,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              _playClickSound();
              Navigator.of(context).pop();
              _restartSession();
            },
            child: const Text(
              'Play Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDifficultySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
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
                          final cfg = BlinkDifficultyConfig.getForLevel(lvl);
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
                              _startTrial();
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
                              'Level $lvl (${cfg.digitCount} Digit${cfg.digitCount > 1 ? 's' : ''})',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            subtitle: Text(
                              cfg.description,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: softBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Attention & Focus',
          style: TextStyle(
            color: textDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Difficulty Settings',
            icon: const Icon(Icons.tune_rounded, color: darkGreen),
            onPressed: _openDifficultySheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopStatusHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentPhase == GamePhase.targetDisplay
                        ? _buildTargetCard()
                        : _buildGridArea(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildFooterInstruction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.center_focus_strong_rounded,
                  color: primarySage, size: 22),
              const SizedBox(width: 8),
              Text(
                'Trial $_currentTrial / ${widget.totalTrials}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Done: $_completedCount',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primarySage,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _openDifficultySheet,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: primarySage.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primarySage.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: primarySage, size: 16),
                  const SizedBox(width: 3),
                  Text(
                    'Level $_currentLevel',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primarySage,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Row(
                    children: [
                      Icon(
                        _correctStreak >= 1
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 7,
                        color: primarySage,
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _correctStreak >= 2
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 7,
                        color: primarySage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard() {
    final digits = _currentConfig.digitCount;
    final fontSize = digits == 1
        ? 64.0
        : digits == 2
            ? 56.0
            : digits == 3
                ? 48.0
                : 40.0;

    return Container(
      key: const ValueKey('TargetCard'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primarySage, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Remember this number',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: primarySage.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$_targetNumber',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: primarySage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridArea() {
    return Container(
      key: const ValueKey('GridArea'),
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final number = _gridNumbers[index];
          return _buildFlippableTile(number);
        },
      ),
    );
  }

  Widget _buildFlippableTile(int number) {
    final isSelected = _selectedTileNumber == number;
    final isCorrect = number == _targetNumber;
    final targetAngle = isSelected ? pi : 0.0;

    return Semantics(
      button: _currentPhase == GamePhase.selection,
      enabled: _currentPhase == GamePhase.selection,
      label: 'Number $number',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: targetAngle, end: targetAngle),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        builder: (context, angle, child) {
          final isFrontFacing = angle.abs() % (2 * pi) < (pi / 2) ||
              angle.abs() % (2 * pi) > (3 * pi / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontFacing
                ? _buildTileFace(
                    number: number,
                    isSelected: false,
                    isCorrect: false,
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildTileFace(
                      number: number,
                      isSelected: true,
                      isCorrect: isCorrect,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTileFace({
    required int number,
    required bool isSelected,
    required bool isCorrect,
  }) {
    Color color = cardWhite;
    Color borderColor = borderGrey;
    Color textColor = textDark;
    Widget? icon;

    if (isSelected) {
      if (isCorrect) {
        color = successGreen.withValues(alpha: 0.15);
        borderColor = successGreen;
        textColor = successGreen;
        icon = const Icon(Icons.check_circle_rounded, color: successGreen, size: 20);
      } else {
        color = alertSoftRed.withValues(alpha: 0.15);
        borderColor = alertSoftRed;
        textColor = alertSoftRed;
        icon = const Icon(Icons.cancel_rounded, color: alertSoftRed, size: 20);
      }
    }

    final digits = _currentConfig.digitCount;
    final fontSize = digits == 1
        ? 28.0
        : digits == 2
            ? 24.0
            : digits == 3
                ? 19.0
                : 16.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _currentPhase == GamePhase.selection
            ? () => _onTileSelected(number)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 3.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              if (icon != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: icon,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterInstruction() {
    String message;
    IconData iconData;

    switch (_currentPhase) {
      case GamePhase.targetDisplay:
        message = 'Memorize the target number';
        iconData = Icons.visibility_rounded;
        break;
      case GamePhase.selection:
        message = 'Tap the tile matching your target';
        iconData = Icons.touch_app_rounded;
        break;
      case GamePhase.feedback:
        message = _selectedTileNumber == _targetNumber
            ? 'Correct! Next number...'
            : 'Next number...';
        iconData = Icons.refresh_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
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