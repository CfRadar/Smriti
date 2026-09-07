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
  }

  void registerGame(VoiceGameHandler? handler) {
    _activeGameHandler = handler;
  }

  void unregisterGame() {
    _activeGameHandler = null;
  }

  Future<void> execute(VoiceCommand command) async {
    lastCommand.value = command;

    switch (command.intent) {
      case VoiceIntent.openBlinkingGame:
      case VoiceIntent.openMemoryGame:
      case VoiceIntent.goHome:
        _routeHandlers[command.intent]?.call();
        break;
      case VoiceIntent.pauseGame:
      case VoiceIntent.resumeGame:
      case VoiceIntent.tapNumber:
        if (command.intent == VoiceIntent.tapNumber && command.parameter == null) {
          return;
        }
        _activeGameHandler?.call(command);
        break;
      case VoiceIntent.unknown:
        break;
    }
  }

  NavigatorState? get navigator => _navigatorKey?.currentState;
}
