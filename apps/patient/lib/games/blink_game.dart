// apps/patient/lib/games/blink_game.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum GamePhase { targetDisplay, selection, feedback }

/// Model capturing performance data for a single trial.
class TrialTelemetry {
  final String sessionId;
  final int trialNumber;
  final int targetNumber;
  final int selectedNumber;
  final bool isCorrect;
  final int reactionTimeMs;
  final String timestamp;

  TrialTelemetry({
    required this.sessionId,
    required this.trialNumber,
    required this.targetNumber,
    required this.selectedNumber,
    required this.isCorrect,
    required this.reactionTimeMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'trialNumber': trialNumber,
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

  /// Saves telemetry payload directly to device memory first.
  Future<void> sendTelemetry(TrialTelemetry telemetry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cachedQueue = prefs.getStringList(_offlineCacheKey) ?? [];

      final String jsonPayload = jsonEncode(telemetry.toJson());
      cachedQueue.add(jsonPayload);

      await prefs.setStringList(_offlineCacheKey, cachedQueue);
      debugPrint(' Telemetry saved locally. Total queued: ${cachedQueue.length}');

      await syncCachedTelemetry();
    } catch (e) {
      debugPrint('Error saving telemetry locally: $e');
    }
  }

  /// Flushes local queue to backend.
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

          if (response.statusCode >= 200 && response.statusCode < 300) {
            debugPrint(' Telemetry synced: $rawJson');
          } else {
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
    this.sessionId = 'session_123456',
    this.totalTrials = 5,
  });

  @override
  State<BlinkGameScreen> createState() => _BlinkGameScreenState();
}

class _BlinkGameScreenState extends State<BlinkGameScreen> {
  // Theme Palette Definitions
  static const Color primarySage = Color(0xFF4A7C59);
  static const Color softBackground = Color(0xFFF8FAF7);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFE0E8E1);
  static const Color textDark = Color(0xFF2C3E35);

  final GameTelemetryService _telemetryService = GameTelemetryService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  GamePhase _currentPhase = GamePhase.targetDisplay;
  int _currentTrial = 1;
  int _completedCount = 0;

  int _targetNumber = 0;
  List<int> _gridNumbers = [];

  Timer? _phaseTimer;
  DateTime? _selectionPhaseStartTime;
  int? _selectedTileNumber;

  // Local audio asset bundled for zero-latency, cross-platform playback (Phone & Web)
  static const String _clickSoundAsset = 'audio/click.wav';

  @override
  void initState() {
    super.initState();
    // On mobile platforms, lowLatency mode utilizes SoundPool/AVAudioPlayer for instant SFX
    if (!kIsWeb) {
      _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    }
    // Pre-warm the audio source so first tap has 0ms latency on both web and mobile
    _audioPlayer.setSource(AssetSource(_clickSoundAsset)).catchError((e) {
      debugPrint('Audio pre-warm error: $e');
    });

    _telemetryService.syncCachedTelemetry();
    _startTrial();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _audioPlayer.dispose();
    _telemetryService.dispose();
    super.dispose();
  }

  /// Plays crisp, snappy game-like click sound & tactile feedback on widget tap
  Future<void> _playClickSound() async {
    try {
      // Tactile physical feedback for mobile (light haptic & system click)
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);

      // Instant local audio playback for both Phone and Web
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource(_clickSoundAsset),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Click sound playback error: $e');
    }
  }

  void _startTrial() {
    _phaseTimer?.cancel();

    final newTarget = _random.nextInt(99) + 1;
    final Set<int> numbersSet = {newTarget};
    while (numbersSet.length < 9) {
      numbersSet.add(_random.nextInt(99) + 1);
    }

    final shuffledList = numbersSet.toList()..shuffle(_random);

    setState(() {
      _targetNumber = newTarget;
      _gridNumbers = shuffledList;
      _currentPhase = GamePhase.targetDisplay;
      _selectedTileNumber = null;
    });

    // Display target for 2.5s before revealing grid
    _phaseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() {
        _currentPhase = GamePhase.selection;
        _selectionPhaseStartTime = DateTime.now();
      });
    });
  }

  void _onTileSelected(int selectedVal) {
    if (_currentPhase != GamePhase.selection) return;

    // Play crisp click sound instantly on user tap
    _playClickSound();

    final now = DateTime.now();
    final reactionTimeMs = _selectionPhaseStartTime != null
        ? now.difference(_selectionPhaseStartTime!).inMilliseconds
        : 0;

    final isCorrect = selectedVal == _targetNumber;

    setState(() {
      _selectedTileNumber = selectedVal;
      _currentPhase = GamePhase.feedback;
    });

    final telemetry = TrialTelemetry(
      sessionId: widget.sessionId,
      trialNumber: _currentTrial,
      targetNumber: _targetNumber,
      selectedNumber: selectedVal,
      isCorrect: isCorrect,
      reactionTimeMs: reactionTimeMs,
      timestamp: now.toUtc().toIso8601String(),
    );

    // Save locally first
    _telemetryService.sendTelemetry(telemetry);

    // Smooth 500ms visual feedback window
    _phaseTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_currentTrial < widget.totalTrials) {
        setState(() {
          _currentTrial++;
          _completedCount++;
        });
        _startTrial();
      } else {
        setState(() {
          _completedCount++;
        });
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primarySage.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: primarySage,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Session Complete',
              style: TextStyle(
                color: textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Great job! Thank you for completing the attention & focus exercise.',
          style: TextStyle(color: textDark, fontSize: 16, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actionsOverflowButtonSpacing: 10,
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: textDark,
              side: const BorderSide(color: borderGrey, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              _playClickSound();
              Navigator.of(context).pop(); // Dismiss dialog
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop(); // Return to Home
              }
            },
            icon: const Icon(Icons.home_rounded, size: 20, color: primarySage),
            label: const Text(
              'Back to Home',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primarySage,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              _playClickSound();
              Navigator.of(context).pop();
              setState(() {
                _currentTrial = 1;
                _completedCount = 0;
              });
              _startTrial();
            },
            icon: const Icon(Icons.replay_rounded, size: 20, color: Colors.white),
            label: const Text(
              'Play Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: softBackground,
        elevation: 0,
        title: const Text(
          'Attention & Focus',
          style: TextStyle(
            color: textDark,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              _buildControlFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trial $_currentTrial / ${widget.totalTrials}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          Text(
            'Completed: $_completedCount',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: primarySage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard() {
    return Container(
      key: const ValueKey('TargetCard'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380, maxHeight: 380),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primarySage, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Remember this number',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            decoration: BoxDecoration(
              color: primarySage.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$_targetNumber',
              style: const TextStyle(
                fontSize: 64,
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
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final number = _gridNumbers[index];
          final isSelected = _selectedTileNumber == number;

          return InkWell(
            onTap: _currentPhase == GamePhase.selection
                ? () => _onTileSelected(number)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? primarySage.withValues(alpha: 0.2)
                    : cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primarySage : borderGrey,
                  width: isSelected ? 3.0 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primarySage : textDark,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlFooter() {
    final isTargetPhase = _currentPhase == GamePhase.targetDisplay;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          isTargetPhase
              ? 'Memorize the target number...'
              : 'Tap the tile matching your target',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: textDark,
          ),
        ),
      ),
    );
  }
}