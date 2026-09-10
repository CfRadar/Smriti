import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
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
  static const String _voiceEnabledKey = 'smriti_voice_assistant_enabled';
  static const int _maxStoredCommands = 50;

  final SpeechToText _speechToText = SpeechToText();
  final ValueNotifier<VoiceStatus> statusNotifier =
      ValueNotifier<VoiceStatus>(VoiceStatus.initializing);

  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  bool _initialized = false;
  bool _disposed = false;
  bool _processing = false;
  bool _restartScheduled = false;
  bool _starting = false;
  bool _permissionGranted = false;
  bool _speechAvailable = false;
  Timer? _restartTimer;

  /// User-facing activation/deactivation of the voice assistant.
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_voiceEnabledKey, enabled);
    } catch (e) {
      debugPrint('Failed to save voice enabled state: $e');
    }

    if (!enabled) {
      _restartTimer?.cancel();
      _restartTimer = null;
      _restartScheduled = false;
      try {
        if (_speechToText.isListening) {
          await _speechToText.stop();
        }
      } catch (e) {
        debugPrint('Error stopping speech recognizer on deactivate: $e');
      }
      statusNotifier.value = VoiceStatus.disabled;
    } else {
      statusNotifier.value = VoiceStatus.initializing;
      await startListening();
    }
  }

  static bool isPermissionDeniedError(String? errorMessage) {
    final normalized = (errorMessage ?? '').toLowerCase();
    return normalized.contains('permission') ||
        normalized.contains('not-allowed') ||
        normalized.contains('not allowed') ||
        normalized.contains('denied') ||
        normalized.contains('microphone');
  }

  static VoiceStatus resolveSpeechStatus({
    required String speechStatus,
    required bool isProcessing,
    required bool isPermissionGranted,
    required bool isSpeechAvailable,
  }) {
    if (isProcessing) {
      return VoiceStatus.processing;
    }

    if (!isSpeechAvailable) {
      return VoiceStatus.disabled;
    }

    if (!isPermissionGranted) {
      return VoiceStatus.error;
    }

    switch (speechStatus) {
      case 'listening':
        return VoiceStatus.listening;
      case 'done':
      case 'stopped':
      case 'notListening':
        return VoiceStatus.listening;
      default:
        return VoiceStatus.initializing;
    }
  }

  Future<bool> initialize() async {
    if (_disposed || _initialized) {
      return _speechToText.isAvailable && _permissionGranted;
    }

    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_voiceEnabledKey) ?? true;
    } catch (_) {}

    if (!_isEnabled) {
      statusNotifier.value = VoiceStatus.disabled;
    } else {
      statusNotifier.value = VoiceStatus.initializing;
    }

    try {
      final available = await _speechToText.initialize(
        onStatus: (status) {
          if (!_isEnabled) {
            statusNotifier.value = VoiceStatus.disabled;
            return;
          }

          if (!_processing && !_permissionGranted) {
            statusNotifier.value = VoiceStatus.error;
            return;
          }

          final nextStatus = resolveSpeechStatus(
            speechStatus: status,
            isProcessing: _processing,
            isPermissionGranted: _permissionGranted,
            isSpeechAvailable: _speechAvailable,
          );

          if (nextStatus == VoiceStatus.listening &&
              (status == 'done' || status == 'stopped' || status == 'notListening')) {
            if (!_processing && _isEnabled) {
              _scheduleListeningRestart();
            }
          }

          if (status == 'listening') {
            statusNotifier.value = VoiceStatus.listening;
            return;
          }

          if (status == 'done' || status == 'stopped' || status == 'notListening') {
            if (!_processing && _permissionGranted && _isEnabled) {
              statusNotifier.value = VoiceStatus.listening;
            }
          }
        },
        onError: (error) {
          debugPrint('Voice recognition error: ${error.errorMsg}');
          if (isPermissionDeniedError(error.errorMsg)) {
            _permissionGranted = false;
          }
          statusNotifier.value = VoiceStatus.error;
        },
        debugLogging: false,
      );

      _speechAvailable = available;
      if (!available) {
        _permissionGranted = false;
        statusNotifier.value = VoiceStatus.disabled;
        return false;
      }

      final hasPermission = await _speechToText.hasPermission;
      if (!hasPermission) {
        final microphonePermission = await Permission.microphone.request();
        _permissionGranted = microphonePermission.isGranted;
        if (!_permissionGranted) {
          statusNotifier.value = VoiceStatus.error;
          return false;
        }
      } else {
        _permissionGranted = true;
      }

      if (_isEnabled) {
        await startListening();
      } else {
        statusNotifier.value = VoiceStatus.disabled;
      }
      return true;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      _permissionGranted = false;
      statusNotifier.value = VoiceStatus.error;
      return false;
    }
  }

  Future<void> startListening() async {
    _restartTimer?.cancel();
    _restartTimer = null;
    _restartScheduled = false;

    if (!_isEnabled) {
      statusNotifier.value = VoiceStatus.disabled;
      return;
    }

    if (!_permissionGranted) {
      statusNotifier.value = VoiceStatus.error;
      return;
    }

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
        try {
          await _speechToText.cancel();
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!_disposed && _isEnabled && !_processing && !_speechToText.isListening) {
          _scheduleListeningRestart();
        }
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

      debugPrint('[VoiceService] Heard: "$recognizedText" -> ${command.intent} (game: ${command.gameName})');
      await _logCommand(command);
      await VoiceCommandController.instance.execute(command);
    } catch (e) {
      debugPrint('[VoiceService] Error handling voice result: $e');
    } finally {
      _processing = false;
      if (!_disposed) {
        _scheduleListeningRestart();
      }
    }
  }

  void _scheduleListeningRestart() {
    if (!_isEnabled || _disposed || _processing || _restartScheduled || _starting) {
      return;
    }

    _restartScheduled = true;
    _restartTimer = Timer(const Duration(milliseconds: 600), () async {
      _restartScheduled = false;
      _restartTimer = null;
      if (!_disposed && !_processing && !_starting && !_speechToText.isListening) {
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
