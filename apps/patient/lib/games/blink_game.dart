// apps/patient/lib/games/blink_game.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing the phase of a single game trial.
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
/// Saves trial metrics to device memory first, then flushes them to the backend API.
class GameTelemetryService {
  final String endpointUrl;
  final http.Client _client;
  static const String _offlineCacheKey = 'smriti_blink_game_telemetry_queue';

  GameTelemetryService({
    this.endpointUrl = 'http://localhost:5000/api/games/session',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 1. Saves telemetry payload directly to phone/device memory first.
  /// 2. Automatically triggers background sync to the server.
  Future<void> sendTelemetry(TrialTelemetry telemetry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cachedQueue = prefs.getStringList(_offlineCacheKey) ?? [];

      final String jsonPayload = jsonEncode(telemetry.toJson());
      cachedQueue.add(jsonPayload);

      // Save to local device memory
      await prefs.setStringList(_offlineCacheKey, cachedQueue);
      debugPrint(' Telemetry saved to local storage. Total queued: ${cachedQueue.length}');

      // Attempt background network transmission
      await syncCachedTelemetry();
    } catch (e) {
      debugPrint('Error writing telemetry to local storage: $e');
    }
  }

  /// Transmits all unsent telemetry stored in local memory to the backend server.
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
            debugPrint(' Telemetry successfully synced to backend: $rawJson');
          } else {
            debugPrint(' Server error (${response.statusCode}). Keeping in local queue.');
            remainingQueue.add(rawJson);
          }
        } catch (e) {
          // Network timeout or unreachable host: keep in local memory
          debugPrint(' Offline or host unreachable. Kept in local queue.');
          remainingQueue.add(rawJson);
        }
      }

      // Update phone memory with only unsent logs
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
    this.totalTrials = 10,
  });

  @override
  State<BlinkGameScreen> createState() => _BlinkGameScreenState();
}

class _BlinkGameScreenState extends State<BlinkGameScreen> {
  // Theme Palette Definitions (Pastel Sage Green & Off-White)
  static const Color primarySage = Color(0xFF4A7C59);
  static const Color softBackground = Color(0xFFF8FAF7);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFE0E8E1);
  static const Color textDark = Color(0xFF2C3E35);

  final GameTelemetryService _telemetryService = GameTelemetryService();
  final Random _random = Random();

  GamePhase _currentPhase = GamePhase.targetDisplay;
  int _currentTrial = 1;
  int _completedCount = 0;

  int _targetNumber = 0;
  List<int> _gridNumbers = [];

  Timer? _phaseTimer;
  DateTime? _selectionPhaseStartTime;
  int? _selectedTileNumber;

  @override
  void initState() {
    super.initState();
    // Flush any pending logs from previous sessions on startup
    _telemetryService.syncCachedTelemetry();
    _startTrial();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _telemetryService.dispose();
    super.dispose();
  }

  /// Initiates a new trial sequence.
  void _startTrial() {
    _phaseTimer?.cancel();

    // 1. Generate target number (1-99)
    final newTarget = _random.nextInt(99) + 1;

    // 2. Generate 8 distinct random distractors (1-99) excluding the target
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

    // Target display duration: 2.5 seconds before showing selection grid
    _phaseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() {
        _currentPhase = GamePhase.selection;
        _selectionPhaseStartTime = DateTime.now();
      });
    });
  }

  /// Handles tile taps during the selection phase.
  void _onTileSelected(int selectedVal) {
    if (_currentPhase != GamePhase.selection) return;

    final now = DateTime.now();
    final reactionTimeMs = _selectionPhaseStartTime != null
        ? now.difference(_selectionPhaseStartTime!).inMilliseconds
        : 0;

    final isCorrect = selectedVal == _targetNumber;

    setState(() {
      _selectedTileNumber = selectedVal;
      _currentPhase = GamePhase.feedback;
    });

    // Construct telemetry event payload
    final telemetry = TrialTelemetry(
      sessionId: widget.sessionId,
      trialNumber: _currentTrial,
      targetNumber: _targetNumber,
      selectedNumber: selectedVal,
      isCorrect: isCorrect,
      reactionTimeMs: reactionTimeMs,
      timestamp: now.toUtc().toIso8601String(),
    );

    // Save to local storage first, then sync
    _telemetryService.sendTelemetry(telemetry);

    // Transition smoothly after a silent 500ms feedback pause
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
        title: const Text(
          'Session Complete',
          style: TextStyle(
            color: textDark,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Thank you for completing the attention exercise.',
          style: TextStyle(color: textDark, fontSize: 20),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primarySage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentTrial = 1;
                _completedCount = 0;
              });
              _startTrial();
            },
            child: const Text(
              'Restart',
              style: TextStyle(fontSize: 20, color: Colors.white),
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
            crossAxisAlignment: CrossAxisAlignment.stretch, //  Correct Flutter property
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
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
              color: primarySage.withOpacity(0.12),
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
                color: isSelected ? primarySage.withOpacity(0.2) : cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primarySage : borderGrey,
                  width: isSelected ? 2.5 : 1.5,
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