import 'package:flutter/material.dart';

import '../models/voice_command.dart';

typedef VoiceGameHandler = void Function(VoiceCommand command);
typedef VoiceRouteHandler = void Function();

class VoiceCommandController {
  VoiceCommandController._();

  static final VoiceCommandController instance = VoiceCommandController._();

  final ValueNotifier<VoiceCommand?> lastCommand =
      ValueNotifier<VoiceCommand?>(null);
  final Map<VoiceIntent, VoiceRouteHandler> _routeHandlers = {};
  final Map<String, VoiceRouteHandler> _gameRoutes = {};
  GlobalKey<NavigatorState>? _navigatorKey;
  VoiceGameHandler? _activeGameHandler;

  void attachNavigator(GlobalKey<NavigatorState>? navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  void registerRoute(VoiceIntent intent, VoiceRouteHandler handler) {
    _routeHandlers[intent] = handler;
  }

  void clearRoutes() {
    _routeHandlers.clear();
    _gameRoutes.clear();
  }

  void registerGameRoute(String gameName, VoiceRouteHandler handler) {
    _gameRoutes[_normalizeGameName(gameName)] = handler;
  }

  void registerGame(VoiceGameHandler? handler) {
    _activeGameHandler = handler;
  }

  void unregisterGame() {
    _activeGameHandler = null;
  }

  bool get hasActiveGame => _activeGameHandler != null;

  Future<void> execute(VoiceCommand command) async {
    lastCommand.value = command;
    debugPrint('[VoiceCommandController] Executing: ${command.intent} (game: ${command.gameName})');

    switch (command.intent) {
      case VoiceIntent.openGame:
        final gameName = command.gameName;
        if (gameName != null) {
          final normalized = _normalizeGameName(gameName);
          final handler = _gameRoutes[normalized];
          if (handler != null) {
            handler();
          } else if (normalized.contains('blink')) {
            final route = _routeHandlers[VoiceIntent.openBlinkingGame];
            if (route != null) {
              route();
            } else {
              _gameRoutes['blinking game']?.call();
            }
          } else if (normalized.contains('memory') ||
              normalized.contains('pattern')) {
            final route = _routeHandlers[VoiceIntent.openMemoryGame];
            if (route != null) {
              route();
            } else {
              _gameRoutes['pattern memory game']?.call();
            }
          } else if (normalized.contains('shanaba') ||
              normalized.contains('shanba') ||
              normalized.contains('kang') ||
              RegExp(r'\bking\b').hasMatch(normalized) ||
              normalized.contains('slide') ||
              normalized.contains('tactile')) {
            final route = _routeHandlers[VoiceIntent.openKingShanabaGame];
            if (route != null) {
              route();
            } else {
              _gameRoutes['king shanaba']?.call();
            }
          }
        }
        break;
      case VoiceIntent.openBlinkingGame:
      case VoiceIntent.openMemoryGame:
      case VoiceIntent.openKingShanabaGame:
      case VoiceIntent.goHome:
      case VoiceIntent.exitGame:
        if (command.intent == VoiceIntent.exitGame) {
          _routeHandlers[VoiceIntent.exitGame]?.call();
        } else {
          final handler = _routeHandlers[command.intent];
          if (handler != null) {
            handler();
          } else if (command.intent == VoiceIntent.openKingShanabaGame) {
            _gameRoutes['king shanaba']?.call();
          } else if (command.intent == VoiceIntent.openBlinkingGame) {
            _gameRoutes['blinking game']?.call();
          } else if (command.intent == VoiceIntent.openMemoryGame) {
            _gameRoutes['pattern memory game']?.call();
          }
        }
        break;
      case VoiceIntent.pauseGame:
      case VoiceIntent.resumeGame:
      case VoiceIntent.slideDisc:
      case VoiceIntent.tapNumber:
        if (command.intent == VoiceIntent.tapNumber &&
            command.parameter == null) {
          return;
        }
        _activeGameHandler?.call(command);
        break;
      case VoiceIntent.unknown:
        break;
    }
  }

  String _normalizeGameName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  NavigatorState? get navigator => _navigatorKey?.currentState;
}
