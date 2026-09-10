// apps/patient/lib/games/blink_game.dart
// Backward compatibility wrapper for PictureRecognitionGameScreen

export 'picture_recognition_game.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'picture_recognition_game.dart';

/// Legacy alias for PictureRecognitionGameScreen
class BlinkGameScreen extends StatelessWidget {
  final String sessionId;
  final int totalTrials;

  const BlinkGameScreen({
    super.key,
    this.sessionId = 'session_picture_recognition',
    this.totalTrials = 8,
  });

  static Future<List<Map<String, dynamic>>> getStoredMLSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList =
        prefs.getStringList('smriti_picture_game_telemetry_queue') ?? [];
    return rawList
        .map((str) => <String, dynamic>{'payload': str})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PictureRecognitionGameScreen(
      sessionId: sessionId,
      totalRounds: totalTrials,
    );
  }
}