import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../controllers/voice_command_controller.dart';
import '../models/voice_command.dart';
import '../utils/voice_command_parser.dart';

enum VoiceStatus {
  initializing,
  listening,
  processing,
  error,
  disabled,
}

class VoiceService {
  VoiceService._();

  static final VoiceService instance = VoiceService._();

  static const String _commandLogKey = 'smriti_voice_command_log';
  static const int _maxStoredCommands = 50;

  final SpeechToText _speechToText = SpeechToText();
  final ValueNotifier<VoiceStatus> statusNotifier =
      ValueNotifier<VoiceStatus>(VoiceStatus.initializing);

  bool _initialized = false;
  bool _disposed = false;
  bool _processing = false;
  bool _restartScheduled = false;
  bool _starting = false;
  Timer? _restartTimer;

  Future<bool> initialize() async {
    if (_disposed || _initialized) {
      return _speechToText.isAvailable;
    }

    _initialized = true;
    statusNotifier.value = VoiceStatus.initializing;

    try {
      final available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'listening') {
            statusNotifier.value = VoiceStatus.listening;
            return;
          }

          if (status == 'done' || status == 'stopped' || status == 'notListening') {
            if (!_processing) {
              statusNotifier.value = VoiceStatus.listening;
              _scheduleListeningRestart();
            }
          }
        },
        onError: (error) {
          debugPrint('Voice recognition error: ${error.errorMsg}');
          statusNotifier.value = VoiceStatus.error;
        },
        debugLogging: false,
      );

      if (!available) {
        statusNotifier.value = VoiceStatus.disabled;
        return false;
      }

      final permissionGranted = await _speechToText.hasPermission;
      if (!permissionGranted) {
        statusNotifier.value = VoiceStatus.error;
        return false;
      }

      await startListening();
      return true;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      statusNotifier.value = VoiceStatus.error;
      return false;
    }
  }

  Future<void> startListening() async {
    _restartTimer?.cancel();
    _restartTimer = null;
    _restartScheduled = false;

    if (_disposed ||
        !_initialized ||
        !_speechToText.isAvailable ||
        _processing ||
        _starting ||
        _speechToText.isListening) {
      return;
    }

    _starting = true;
    try {
      final started = await _speechToText.listen(
        onResult: _handleResult,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 8),
          pauseFor: const Duration(seconds: 5),
          partialResults: false,
          cancelOnError: true,
        ),
      );

      // Some speech_to_text web builds return null even after starting the
      // browser recognizer. Only an explicit false means the start failed.
      if (started == false) {
        statusNotifier.value = VoiceStatus.error;
        return;
      }

      statusNotifier.value = VoiceStatus.listening;
    } catch (e) {
      debugPrint('Unable to start listening: $e');
      statusNotifier.value = VoiceStatus.error;
      if (e.toString().contains('InvalidStateError')) {
        await _speechToText.cancel();
        _scheduleListeningRestart();
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> stopListening() async {
    _restartTimer?.cancel();
    _restartTimer = null;
    _restartScheduled = false;

    if (_disposed || !_speechToText.isListening) {
      return;
    }

    try {
      await _speechToText.stop();
    } catch (e) {
      debugPrint('Unable to stop listening: $e');
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await stopListening();
    statusNotifier.dispose();
  }

  Future<void> _handleResult(SpeechRecognitionResult result) async {
    final recognizedText = result.recognizedWords.trim();
    if (recognizedText.isEmpty) {
      return;
    }

    _processing = true;
    statusNotifier.value = VoiceStatus.processing;

    try {
      final command = VoiceCommandParser.parse(
        recognizedText,
        confidence: result.confidence >= 0 ? result.confidence : 0.0,
      );

      await _logCommand(command);
      await VoiceCommandController.instance.execute(command);
    } finally {
      _processing = false;
      if (!_disposed) {
        _scheduleListeningRestart();
      }
    }
  }

  void _scheduleListeningRestart() {
    if (_disposed || _processing || _restartScheduled) {
      return;
    }

    _restartScheduled = true;
    _restartTimer = Timer(const Duration(milliseconds: 600), () async {
      _restartScheduled = false;
      _restartTimer = null;
      if (!_disposed && !_processing && !_speechToText.isListening) {
        await startListening();
      }
    });
  }

  Future<void> _logCommand(VoiceCommand command) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_commandLogKey) ?? <String>[];
      final payload = jsonEncode(command.toJson());
      existing.add(payload);

      if (existing.length > _maxStoredCommands) {
        existing.removeRange(0, existing.length - _maxStoredCommands);
      }

      await prefs.setStringList(_commandLogKey, existing);
    } catch (e) {
      debugPrint('Failed to store voice event metadata: $e');
    }
  }
}
