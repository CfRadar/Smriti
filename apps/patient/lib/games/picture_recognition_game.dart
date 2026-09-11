// apps/patient/lib/games/picture_recognition_game.dart

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
import 'package:patient/services/locale_service.dart';
import 'package:patient/widgets/animated_fragmented_divider.dart';
import 'package:patient/widgets/game_completion_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Categories for North East India cultural assets
enum CulturalCategory {
  animals,
  clothing,
  food,
  items,
}

/// Phases for Picture Recognition gameplay
enum PictureGamePhase {
  targetDisplay, // Step 1: Item to be found is prominently displayed first
  guessing, // Step 2: 3x3 grid guessing phase with maximized playing area
}

/// Represents an authentic North East India cultural asset
class GameItem {
  final String id;
  final String name;
  final String regionalName;
  final String region;
  final CulturalCategory category;
  final String assetPath;

  const GameItem({
    required this.id,
    required this.name,
    required this.regionalName,
    required this.region,
    required this.category,
    required this.assetPath,
  });

  String get categoryLabel {
    switch (category) {
      case CulturalCategory.animals:
        return 'Fauna';
      case CulturalCategory.clothing:
        return 'Traditional Attire';
      case CulturalCategory.food:
        return 'Delicacy';
      case CulturalCategory.items:
        return 'Craft & Heritage';
    }
  }

  String localizedName(BuildContext context) {
    final key = 'items.$id.name';
    final translated = context.tr(key);
    return (translated != key && translated.isNotEmpty) ? translated : name;
  }

  String localizedSubtitle(BuildContext context) {
    final key = 'items.$id.region';
    final translated = context.tr(key);
    if (translated != key && translated.isNotEmpty) {
      return '$regionalName • $translated';
    }
    return '$regionalName • $region';
  }

  String localizedCategory(BuildContext context) {
    switch (category) {
      case CulturalCategory.animals:
        return context.tr('gameplay.categoryFauna');
      case CulturalCategory.clothing:
        return context.tr('gameplay.categoryAttire');
      case CulturalCategory.food:
        return context.tr('gameplay.categoryFood');
      case CulturalCategory.items:
        return context.tr('gameplay.categoryCraft');
    }
  }

  /// All 36 North East India Cultural Assets across 4 categories
  static const List<GameItem> catalog = [
    // ── Animals & Wildlife (8 items) ──────────────────────────────────
    GameItem(
      id: 'animal_rhino',
      name: 'One-Horned Rhino',
      regionalName: 'গঁড় (Gorh)',
      region: 'Assam (Kaziranga)',
      category: CulturalCategory.animals,
      assetPath: 'assets/images/animals/tile000.png',
    ),
    GameItem(
      id: 'animal_sangai',
      name: 'Sangai Deer',
      regionalName: 'চাঙাই (Sangai)',
      region: 'Manipur (Keibul Lamjao)',
      category: CulturalCategory.animals,
      assetPath: 'assets/images/animals/tile001.png',
    ),
    GameItem(
      id: 'animal_golden_langur',
      name: 'Golden Langur',
      regionalName: 'সোণালী বান্দৰ',
      region: 'Assam & Bodoland',
      category: CulturalCategory.animals,
      assetPath: 'assets/images/animals/tile002.png',
    ),
    GameItem(
      id: 'animal_mithun',
      name: 'Mithun (Gayal)',
      regionalName: 'মিথুন (Mithun)',
      region: 'Nagaland & Arunachal',
      category: CulturalCategory.animals,
      assetPath: 'assets/images/animals/tile003.png',
    ),
    GameItem(
      id: 'animal_hornbill',
      name: 'Great Hornbill',
      regionalName: 'ধনেশ পক্ষী (Dhanesh)',
      region: 'Arunachal & Nagaland',
      category: CulturalCategory.animals,
      assetPath: 'assets/images/animals/tile004.png',
    ),
    GameItem(
      id: 'animal_hoolock_gibbon',
      name: 'Hoolock Gibbon',
      regionalName: 'হলৌ বান্দৰ (Hoolock)',
      region: 'Assam & Hoollongapar',
      category: CulturalCategory.animals,
      assetPath: 'assets/images/animals/tile005.png',
    ),
    GameItem(
      id: 'animal_black_bear',
      name: 'Himalayan Bear',
      regionalName: 'হিমালয়ৰ ভালুক',
      region: 'Arunachal Pradesh',
      category: CulturalCategory.animals,
      assetPath: 'assets/images/animals/tile006.png',
    ),
    GameItem(
      id: 'animal_serow_takin',
      name: 'Takin / Serow',
      regionalName: 'টাকিন (Takin)',
      region: 'Mizoram & Sikkim',
      category: CulturalCategory.animals,
      assetPath: 'assets/images/animals/tile008.png',
    ),

    // ── Traditional Clothing & Textiles (8 items) ─────────────────────
    GameItem(
      id: 'cloth_naga_headgear',
      name: 'Naga Headgear',
      regionalName: 'নগা মুকুট',
      region: 'Nagaland',
      category: CulturalCategory.clothing,
      assetPath: 'assets/images/cloth/tile000.png',
    ),
    GameItem(
      id: 'cloth_jaapi',
      name: 'Assamese Jaapi',
      regionalName: 'জাপি (Jaapi)',
      region: 'Assam',
      category: CulturalCategory.clothing,
      assetPath: 'assets/images/cloth/tile001.png',
    ),
    GameItem(
      id: 'cloth_mizo_puan',
      name: 'Mizo Puan Textile',
      regionalName: 'Puan Chei',
      region: 'Mizoram',
      category: CulturalCategory.clothing,
      assetPath: 'assets/images/cloth/tile002.png',
    ),
    GameItem(
      id: 'cloth_tribal_dress',
      name: 'Tribal Festive Attire',
      regionalName: 'জনগোষ্ঠীয় সাজ',
      region: 'North East India',
      category: CulturalCategory.clothing,
      assetPath: 'assets/images/cloth/tile003.png',
    ),
    GameItem(
      id: 'cloth_loin_loom',
      name: 'Traditional Loin Loom',
      regionalName: 'কঁকাল তাঁত (Loom)',
      region: 'Nagaland & Manipur',
      category: CulturalCategory.clothing,
      assetPath: 'assets/images/cloth/tile004.png',
    ),
    GameItem(
      id: 'cloth_mekhela_chador',
      name: 'Mekhela Chador',
      regionalName: 'মেখেলা চাদৰ',
      region: 'Assam Silk',
      category: CulturalCategory.clothing,
      assetPath: 'assets/images/cloth/tile005.png',
    ),
    GameItem(
      id: 'cloth_tsungkotepsu',
      name: 'Naga Warrior Shawl',
      regionalName: 'Tsungkotepsu Shawl',
      region: 'Nagaland (Ao Naga)',
      category: CulturalCategory.clothing,
      assetPath: 'assets/images/cloth/tile006.png',
    ),
    GameItem(
      id: 'cloth_cheraw_costume',
      name: 'Mizo Folk Costume',
      regionalName: 'Cheraw Costume',
      region: 'Mizoram',
      category: CulturalCategory.clothing,
      assetPath: 'assets/images/cloth/tile007.png',
    ),

    // ── Foods & Delicacies (10 items) ─────────────────────────────────
    GameItem(
      id: 'food_bhoot_jolokia',
      name: 'Bhoot Jolokia',
      regionalName: 'ভোট জলকীয়া (Ghost Pepper)',
      region: 'Assam & Nagaland',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile000.png',
    ),
    GameItem(
      id: 'food_assamese_thali',
      name: 'Assamese Thali',
      regionalName: 'অসমীয়া কাঁহী (Thali)',
      region: 'Assam',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile001.png',
    ),
    GameItem(
      id: 'food_jadoh',
      name: 'Jadoh Rice',
      regionalName: 'Ja Doh (Khasi Rice)',
      region: 'Meghalaya',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile002.png',
    ),
    GameItem(
      id: 'food_smoked_pork',
      name: 'Smoked Pork Delicacy',
      regionalName: 'ধোঁৱাচঙীয়া মাংস',
      region: 'Nagaland',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile003.png',
    ),
    GameItem(
      id: 'food_steamed_momos',
      name: 'Steamed Momos',
      regionalName: 'মমো (Momos)',
      region: 'Sikkim & Arunachal',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile004.png',
    ),
    GameItem(
      id: 'food_galho',
      name: 'Galho Stew',
      regionalName: 'Galho Rice Stew',
      region: 'Nagaland',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile006.png',
    ),
    GameItem(
      id: 'food_bamboo_curry',
      name: 'Bamboo Shoot Curry',
      regionalName: 'বাঁহ গাজৰ তৰকাৰী',
      region: 'Assam (Khorisa)',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile007.png',
    ),
    GameItem(
      id: 'food_bamboo_pickle',
      name: 'Fermented Bamboo Pickle',
      regionalName: 'বাঁহ গাজৰ আচাৰ',
      region: 'Manipur & Assam',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile008.png',
    ),
    GameItem(
      id: 'food_poita_bhat',
      name: 'Poita Bhat Feast',
      regionalName: 'পঁইতা ভাত (Poita Bhat)',
      region: 'Assam',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile009.png',
    ),
    GameItem(
      id: 'food_steamed_feast',
      name: 'Bamboo Steamed Meal',
      regionalName: 'বাঁহত সিজোৱা আহাৰ',
      region: 'Mizoram & Tripura',
      category: CulturalCategory.food,
      assetPath: 'assets/images/food/tile010.png',
    ),

    // ── Unique Items & Heritage Crafts (10 items) ─────────────────────
    GameItem(
      id: 'item_cane_basket',
      name: 'Cane & Bamboo Basket',
      regionalName: 'বাঁহ-বেতৰ ডলা (Basket)',
      region: 'Assam & Tripura',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile000.png',
    ),
    GameItem(
      id: 'item_terracotta_birds',
      name: 'Asharikandi Clay Birds',
      regionalName: 'আশাৰীকান্দি টেৰাকোটা চৰাই',
      region: 'Assam (Dhubri)',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile001.png',
    ),
    GameItem(
      id: 'item_bell_metal',
      name: 'Sarthebari Bell',
      regionalName: 'কাঁহৰ ঘণ্টা (Bell Metal)',
      region: 'Assam (Sarthebari)',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile002.png',
    ),
    GameItem(
      id: 'item_vaibel_pipe',
      name: 'Bamboo Vaibel Pipe',
      regionalName: 'Mizo Vaibel (Pipe)',
      region: 'Mizoram',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile003.png',
    ),
    GameItem(
      id: 'item_brass_utensils',
      name: 'Kansa Brass Bowls',
      regionalName: 'কাঁহ-পিতলৰ বাটি-কাঁহী',
      region: 'Assam',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile004.png',
    ),
    GameItem(
      id: 'item_root_bridge',
      name: 'Living Root Bridge',
      regionalName: 'Jingkieng Jri',
      region: 'Meghalaya (Cherrapunji)',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile005.png',
    ),
    GameItem(
      id: 'item_majuli_mask',
      name: 'Majuli Traditional Mask',
      regionalName: 'মাজুলীৰ মুখা (Mukha)',
      region: 'Assam (Majuli)',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile006.png',
    ),
    GameItem(
      id: 'item_naga_spear',
      name: 'Naga Warrior Spear',
      regionalName: 'নগা যাঠি (Warrior Spear)',
      region: 'Nagaland',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile008.png',
    ),
    GameItem(
      id: 'item_bihu_dhol',
      name: 'Assamese Bihu Dhol',
      regionalName: 'বিহু ঢোল (Dhol Drum)',
      region: 'Assam',
      category: CulturalCategory.items,
      assetPath: 'assets/images/items/tile009.png',
    ),
  ];
}

/// Adaptive game difficulty configuration
class AdaptiveDifficultyConfig {
  final int level;
  final int targetCount; // 1 (L1-3), 2 (L4-7), 3 (L8+)
  final double timeAllowanceSecondsPerTarget;
  final String title;

  const AdaptiveDifficultyConfig({
    required this.level,
    required this.targetCount,
    required this.timeAllowanceSecondsPerTarget,
    required this.title,
  });

  double get totalAllowedSeconds => targetCount * timeAllowanceSecondsPerTarget;

  static AdaptiveDifficultyConfig getForLevel(int level) {
    final clamped = level.clamp(1, 15);
    int targets;
    double allowance;
    String desc;

    if (clamped <= 3) {
      targets = 1;
      allowance = 8.0;
      desc = 'Single Target • 8.0s';
    } else if (clamped <= 7) {
      targets = 2;
      allowance = 6.0;
      desc = 'Dual Targets • 6.0s/item';
    } else if (clamped <= 10) {
      targets = 3;
      allowance = 4.5;
      desc = 'Triple Targets • 4.5s/item';
    } else {
      targets = 3;
      allowance = 3.5;
      desc = 'Triple Targets • 3.5s/item';
    }

    return AdaptiveDifficultyConfig(
      level: clamped,
      targetCount: targets,
      timeAllowanceSecondsPerTarget: allowance,
      title: desc,
    );
  }

  String getLocalizedTitle(BuildContext context) {
    if (level <= 3) {
      return context.tr('gameplay.diffSingleTargetDesc', {'time': '8.0'});
    } else if (level <= 7) {
      return context.tr('gameplay.diffDualTargetDesc', {'time': '6.0'});
    } else if (level <= 10) {
      return context.tr('gameplay.diffTripleTargetDesc', {'time': '4.5'});
    } else {
      return context.tr('gameplay.diffTripleTargetDesc', {'time': '3.5'});
    }
  }
}

/// Single trial round telemetry
class PictureTrialTelemetry {
  final String sessionId;
  final int roundNumber;
  final int level;
  final int targetCount;
  final List<String> targetItemIds;
  final List<String> selectedItemIds;
  final bool isSuccess;
  final int responseTimeMs;
  final double scoreMultiplier;
  final String timestamp;

  PictureTrialTelemetry({
    required this.sessionId,
    required this.roundNumber,
    required this.level,
    required this.targetCount,
    required this.targetItemIds,
    required this.selectedItemIds,
    required this.isSuccess,
    required this.responseTimeMs,
    required this.scoreMultiplier,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'roundNumber': roundNumber,
        'level': level,
        'gameType': 'object_recognition',
        'cognitiveDomain': 'visuospatial',
        'targetCount': targetCount,
        'targetItemIds': targetItemIds,
        'selectedItemIds': selectedItemIds,
        'isSuccess': isSuccess,
        'responseTimeMs': responseTimeMs,
        'scoreMultiplier': scoreMultiplier,
        'timestamp': timestamp,
      };
}

/// Offline-first telemetry service
class PictureGameTelemetryService {
  final String endpointUrl;
  final http.Client _client;
  static const String _offlineCacheKey = 'smriti_picture_game_telemetry_queue';

  PictureGameTelemetryService({
    this.endpointUrl = 'http://localhost:5000/api/games/session',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<void> sendTelemetry(PictureTrialTelemetry telemetry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(_offlineCacheKey) ?? [];
      queue.add(jsonEncode(telemetry.toJson()));
      await prefs.setStringList(_offlineCacheKey, queue);
      await syncCachedTelemetry();
    } catch (e) {
      debugPrint('Error saving picture game telemetry locally: $e');
    }
  }

  Future<void> syncCachedTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(_offlineCacheKey) ?? [];
      if (queue.isEmpty) return;

      List<String> remaining = [];
      for (String item in queue) {
        try {
          final res = await _client
              .post(
                Uri.parse(endpointUrl),
                headers: {'Content-Type': 'application/json'},
                body: item,
              )
              .timeout(const Duration(seconds: 4));

          if (res.statusCode < 200 || res.statusCode >= 300) {
            remaining.add(item);
          }
        } catch (_) {
          remaining.add(item);
        }
      }
      await prefs.setStringList(_offlineCacheKey, remaining);
    } catch (e) {
      debugPrint('Error syncing picture game telemetry: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Main Screen for Adaptive Picture Recognition Game
class PictureRecognitionGameScreen extends StatefulWidget {
  final String sessionId;
  final int totalRounds;

  const PictureRecognitionGameScreen({
    super.key,
    this.sessionId = 'session_picture_recognition',
    this.totalRounds = 8,
  });

  @override
  State<PictureRecognitionGameScreen> createState() =>
      _PictureRecognitionGameScreenState();
}

class _PictureRecognitionGameScreenState
    extends State<PictureRecognitionGameScreen>
    with SingleTickerProviderStateMixin {
  // ── Palette aligned with Homepage / GameHubPage ────────────────────────
  static const Color screenBg = Color(0xFFF0F4F8); // Sky-mist
  static const Color ivory = Color(0xFFF8F5EC); // Soft ivory card background
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color darkGreen = Color(0xFF214E3B);
  static const Color primarySage = Color(0xFF5F866D);
  static const Color lightGreen = Color(0xFFDCE8DA);
  static const Color peachAccent = Color(0xFFFFAB91);
  static const Color pinkAccent = Color(0xFFF48FB1);
  static const Color textDark = Color(0xFF1E3A5F);
  static const Color textGrey = Color(0xFF66736C);
  static const Color borderGrey = Color(0xFFCFE0ED);
  static const Color navBarBg = Color(0xFFEAF2F8); // Light blue nav surface matching Bamboo Dance
  static const Color primaryNavy = Color(0xFF1E293B);
  static const Color slateBorder = Color(0xFFE2E8F0);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color alertRed = Color(0xFFD32F2F);

  bool _isSoundEnabled = true;

  // Persistence keys
  static const String _prefKeyLevel = 'smriti_picture_game_level';
  static const String _prefKeyHighScore = 'smriti_picture_game_high_score';
  static const String _prefKeyBestStreak = 'smriti_picture_game_best_streak';

  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PictureGameTelemetryService _telemetryService =
      PictureGameTelemetryService();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Game state
  PictureGamePhase _currentPhase = PictureGamePhase.targetDisplay;
  bool _isPaused = false;
  bool _isRoundActive = false;
  bool _isGameOver = false;

  int _currentLevel = 1;
  int _currentRound = 1;
  int _score = 0;
  int _highScore = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _consecutiveCorrectRounds = 0;

  // Metrics
  int _totalCorrectSelections = 0;
  int _totalMistakes = 0;
  final List<int> _roundResponseTimesMs = [];

  // Round grid setup
  List<GameItem> _currentGridItems = [];
  List<GameItem> _currentTargetItems = [];
  final Set<String> _foundTargetIds = {};
  String? _wrongTappedItemId;

  // Timers
  Timer? _displayPhaseTimer;
  Timer? _hiddenTimer;
  final Stopwatch _roundStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _registerVoiceCommands();
    _initAudio();
    _telemetryService.syncCachedTelemetry();
    _loadPreferencesAndStart();
  }

  @override
  void dispose() {
    VoiceCommandController.instance.unregisterGame();
    _displayPhaseTimer?.cancel();
    _hiddenTimer?.cancel();
    _roundStopwatch.stop();
    _shakeController.dispose();
    _audioPlayer.dispose();
    _telemetryService.dispose();
    super.dispose();
  }

  void _initAudio() {
    if (!kIsWeb) {
      _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    }
  }

  Future<void> _playSfx(bool correct) async {
    try {
      HapticFeedback.lightImpact();
      if (!_isSoundEnabled) return;
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/click.wav'), volume: 0.7);
    } catch (_) {}
  }

  void _registerVoiceCommands() {
    VoiceCommandController.instance.registerGame((command) {
      if (!mounted) return;
      switch (command.intent) {
        case VoiceIntent.pauseGame:
          pauseGame();
          break;
        case VoiceIntent.resumeGame:
          resumeGame();
          break;
        case VoiceIntent.tapNumber:
          if (_currentPhase == PictureGamePhase.guessing &&
              command.parameter != null) {
            final idx = command.parameter! - 1;
            if (idx >= 0 && idx < _currentGridItems.length) {
              _onTileTapped(_currentGridItems[idx]);
            }
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> _loadPreferencesAndStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getInt(_prefKeyLevel) ?? 1;
      final savedHighScore = prefs.getInt(_prefKeyHighScore) ?? 0;
      final savedBestStreak = prefs.getInt(_prefKeyBestStreak) ?? 0;

      if (!mounted) return;
      setState(() {
        _currentLevel = savedLevel.clamp(1, 15);
        _highScore = savedHighScore;
        _bestStreak = savedBestStreak;
      });
    } catch (_) {}

    _startRound();
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyLevel, _currentLevel);
      if (_score > _highScore) {
        _highScore = _score;
        await prefs.setInt(_prefKeyHighScore, _highScore);
      }
      if (_streak > _bestStreak) {
        _bestStreak = _streak;
        await prefs.setInt(_prefKeyBestStreak, _bestStreak);
      }
    } catch (_) {}
  }

  void pauseGame() {
    if (!mounted || _isPaused) return;
    _displayPhaseTimer?.cancel();
    _hiddenTimer?.cancel();
    _roundStopwatch.stop();
    setState(() => _isPaused = true);
  }

  void resumeGame() {
    if (!mounted || !_isPaused) return;
    setState(() => _isPaused = false);

    if (_currentPhase == PictureGamePhase.targetDisplay) {
      // Resume target display countdown
      _displayPhaseTimer =
          Timer(const Duration(milliseconds: 2500), _beginGuessingPhase);
    } else if (_currentPhase == PictureGamePhase.guessing && _isRoundActive) {
      _roundStopwatch.start();
      final config = AdaptiveDifficultyConfig.getForLevel(_currentLevel);
      final elapsed = _roundStopwatch.elapsedMilliseconds;
      final remainingMs = (config.totalAllowedSeconds * 1000).round() - elapsed;

      if (remainingMs > 0) {
        _hiddenTimer =
            Timer(Duration(milliseconds: remainingMs), _onTimerExpired);
      } else {
        _onTimerExpired();
      }
    }
  }

  /// Begins a new Picture Recognition Round (Step 1: Target Display)
  void _startRound() {
    if (!mounted) return;
    _displayPhaseTimer?.cancel();
    _hiddenTimer?.cancel();
    _roundStopwatch.reset();

    final config = AdaptiveDifficultyConfig.getForLevel(_currentLevel);
    final allItems = List<GameItem>.from(GameItem.catalog)..shuffle(_random);

    // Pick K target items (1 for L1-3, 2 for L4-7, 3 for L8+)
    final targetCount = config.targetCount.clamp(1, 3);
    final targets = allItems.take(targetCount).toList();

    // Fill remaining 9 - K slots with distractor items (No duplicates)
    final distractors =
        allItems.skip(targetCount).take(9 - targetCount).toList();

    // Combine & shuffle the 9 grid items
    final gridItems = [...targets, ...distractors]..shuffle(_random);

    setState(() {
      _currentPhase = PictureGamePhase.targetDisplay;
      _isRoundActive = false;
      _wrongTappedItemId = null;
      _foundTargetIds.clear();
      _currentTargetItems = targets;
      _currentGridItems = gridItems;
    });

    // Display target(s) for 3.0 seconds, then auto-advance to guessing phase
    // (User can also tap "I'm Ready / Start" to advance immediately)
    _displayPhaseTimer =
        Timer(const Duration(milliseconds: 3200), _beginGuessingPhase);
  }

  /// Transitions to Step 2: Guessing Grid Phase
  void _beginGuessingPhase() {
    if (!mounted || _isPaused || _isGameOver) return;
    _displayPhaseTimer?.cancel();

    final config = AdaptiveDifficultyConfig.getForLevel(_currentLevel);

    setState(() {
      _currentPhase = PictureGamePhase.guessing;
      _isRoundActive = true;
    });

    _roundStopwatch.reset();
    _roundStopwatch.start();
    final allowedMs = (config.totalAllowedSeconds * 1000).round();
    _hiddenTimer = Timer(Duration(milliseconds: allowedMs), _onTimerExpired);
  }

  /// Invoked strictly in background if hidden internal timer runs out
  void _onTimerExpired() {
    if (!mounted || !_isRoundActive || _isPaused) return;

    _roundStopwatch.stop();
    _isRoundActive = false;

    // Trigger subtle miss shake
    _shakeController.forward(from: 0.0);
    HapticFeedback.lightImpact();

    setState(() {
      _streak = 0;
      _consecutiveCorrectRounds = 0;
      _totalMistakes += 1;
    });

    _logRoundTelemetry(isSuccess: false);

    // Auto transition to next round after subtle feedback
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _advanceRound(success: false);
    });
  }

  void _onTileTapped(GameItem item) {
    if (!_isRoundActive || _isPaused || _currentPhase != PictureGamePhase.guessing) {
      return;
    }

    final isTarget = _currentTargetItems.any((t) => t.id == item.id);

    if (isTarget) {
      if (_foundTargetIds.contains(item.id)) return; // Already tapped

      _playSfx(true);
      setState(() {
        _foundTargetIds.add(item.id);
        _totalCorrectSelections += 1;
      });

      // Check if all targets found for this round
      if (_foundTargetIds.length >= _currentTargetItems.length) {
        _onRoundCompletedSuccessfully();
      }
    } else {
      // Incorrect distractor tapped
      _playSfx(false);
      _shakeController.forward(from: 0.0);
      setState(() {
        _wrongTappedItemId = item.id;
        _streak = 0;
        _consecutiveCorrectRounds = 0;
        _totalMistakes += 1;
      });

      // Clear red wrong indicator after brief pulse
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _wrongTappedItemId == item.id) {
          setState(() => _wrongTappedItemId = null);
        }
      });
    }
  }

  void _onRoundCompletedSuccessfully() {
    _hiddenTimer?.cancel();
    _roundStopwatch.stop();
    _isRoundActive = false;

    final elapsedMs = _roundStopwatch.elapsedMilliseconds;
    _roundResponseTimesMs.add(elapsedMs);

    // Speed multiplier: < 2.0s = 1.5x, < 3.5s = 1.25x
    double speedMultiplier = 1.0;
    if (elapsedMs < 2000) {
      speedMultiplier = 1.5;
    } else if (elapsedMs < 3500) {
      speedMultiplier = 1.25;
    }

    final baseAward = 100 * _currentTargetItems.length;
    final roundPoints =
        (baseAward * speedMultiplier * (1 + _currentLevel * 0.1)).round();

    setState(() {
      _score += roundPoints;
      _streak += 1;
      if (_streak > _bestStreak) _bestStreak = _streak;
      if (_score > _highScore) _highScore = _score;
      _consecutiveCorrectRounds += 1;
    });

    _logRoundTelemetry(isSuccess: true, multiplier: speedMultiplier);

    // Adaptive difficulty: Advance level after 2 consecutive clean rounds
    if (_consecutiveCorrectRounds >= 2) {
      _consecutiveCorrectRounds = 0;
      _currentLevel = (_currentLevel + 1).clamp(1, 15);
    }

    _savePreferences();

    // Transition smoothly to next round
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _advanceRound(success: true);
    });
  }

  void _advanceRound({required bool success}) {
    if (_currentRound >= widget.totalRounds) {
      _endGame();
    } else {
      setState(() {
        _currentRound += 1;
      });
      _startRound();
    }
  }

  void _logRoundTelemetry({required bool isSuccess, double multiplier = 1.0}) {
    final telemetry = PictureTrialTelemetry(
      sessionId: widget.sessionId,
      roundNumber: _currentRound,
      level: _currentLevel,
      targetCount: _currentTargetItems.length,
      targetItemIds: _currentTargetItems.map((e) => e.id).toList(),
      selectedItemIds: _foundTargetIds.toList(),
      isSuccess: isSuccess,
      responseTimeMs: _roundStopwatch.elapsedMilliseconds,
      scoreMultiplier: multiplier,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );
    _telemetryService.sendTelemetry(telemetry);
  }

  void _endGame() {
    _displayPhaseTimer?.cancel();
    _hiddenTimer?.cancel();
    _roundStopwatch.stop();
    _savePreferences();

    setState(() {
      _isRoundActive = false;
      _isGameOver = true;
    });

    _showGameOverSummary();
  }

  void _restartGame() {
    Navigator.of(context, rootNavigator: true).pop();
    setState(() {
      _currentRound = 1;
      _score = 0;
      _streak = 0;
      _totalCorrectSelections = 0;
      _totalMistakes = 0;
      _roundResponseTimesMs.clear();
      _isGameOver = false;
    });
    _startRound();
  }

  void _openDifficultySheet() {
    pauseGame();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: Colors.white.withValues(alpha: 0.90),
              child: StatefulBuilder(
                builder: (sheetContext, setSheetState) {
                  return SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: borderGrey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('gameplay.selectDifficulty'),
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('gameplay.chooseStartingChallenge'),
                      style: const TextStyle(color: textGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.builder(
                        itemCount: 12,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final lvl = index + 1;
                          final cfg = AdaptiveDifficultyConfig.getForLevel(lvl);
                          final isSelected = lvl == _currentLevel;

                          return ListTile(
                            onTap: () {
                              setSheetState(() {});
                              setState(() {
                                _currentLevel = lvl;
                                _streak = 0;
                                _consecutiveCorrectRounds = 0;
                              });
                              _savePreferences();
                              Navigator.of(ctx).pop();
                              resumeGame();
                              _startRound();
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            tileColor: isSelected
                                ? lightGreen.withValues(alpha: 0.4)
                                : null,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  isSelected ? darkGreen : borderGrey,
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
                              '${context.tr('gameplay.level', {'level': '$lvl'})} (${cfg.targetCount} Target${cfg.targetCount > 1 ? 's' : ''})',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            subtitle: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                cfg.getLocalizedTitle(context),
                                style: const TextStyle(
                                    fontSize: 12, color: textGrey),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: darkGreen,
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
).then((_) {
  if (_isPaused && !_isGameOver) {
    resumeGame();
  }
});
}

  void _showGameOverSummary() {
    final totalAttempts = _totalCorrectSelections + _totalMistakes;
    final accuracy = totalAttempts > 0
        ? ((_totalCorrectSelections / totalAttempts) * 100).round()
        : 100;

    final avgTimeMs = _roundResponseTimesMs.isNotEmpty
        ? (_roundResponseTimesMs.reduce((a, b) => a + b) /
                _roundResponseTimesMs.length)
            .round()
        : 0;

    showGameCompletionDialog(
      context: context,
      finalScore: _score,
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
          value: '${(avgTimeMs / 1000).toStringAsFixed(1)}s',
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
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      },
      onPlayAgain: _restartGame,
    );
  }

  // ── UI BUILD METHOD ───────────────────────────────────────────────────

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
                  children: [
                    _buildTopBar(),
                    const AnimatedFragmentedDivider(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                        child: Column(
                          children: [
                            // Header status row (Score, Level, Streak)
                            _buildHeaderStats(),

                            const SizedBox(height: 8),

                            // Main Interactive Area
                            Expanded(
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 320),
                                  child: _currentPhase == PictureGamePhase.targetDisplay
                                      ? _buildTargetDisplayPhase()
                                      : AnimatedBuilder(
                                          animation: _shakeAnimation,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(_shakeAnimation.value, 0),
                                              child: child,
                                            );
                                          },
                                          child: _buildInteractiveGrid(),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Bottom control bar
                            _buildBottomControls(),
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
      label: context.tr('gameplay.exitToHomeTooltip'),
      child: Tooltip(
        message: context.tr('gameplay.exitToHomeTooltip'),
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
          Text(
            context.tr('games.pictureRecognition'),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
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
        // Sound toggle button
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
              Text(
                context.tr('gameplay.gamePaused'),
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                context.tr('gameplay.pauseVoiceHint'),
                style: const TextStyle(fontSize: 14.0, color: textGrey),
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
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.tr('gameplay.resumeSession'),
                    style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
                  ),
                ),
                onPressed: resumeGame,
              ),
              const SizedBox(height: 10.0),
              TextButton.icon(
                onPressed: _openDifficultySheet,
                icon: const Icon(Icons.tune_rounded, size: 18, color: textGrey),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.tr('gameplay.difficultySettings'),
                    style: const TextStyle(fontSize: 13.0, color: textGrey, fontWeight: FontWeight.w600),
                  ),
                ),
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

  Widget _buildHeaderStats() {
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
          // 1. Round tracker
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.style_rounded, size: 18, color: darkGreen),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.tr('gameplay.round', {
                        'round': '$_currentRound',
                        'total': '${widget.totalRounds}',
                      }),
                      style: const TextStyle(
                        color: primaryNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Tappable Level badge
          InkWell(
            onTap: _openDifficultySheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  const Icon(Icons.bolt_rounded, size: 14, color: darkGreen),
                  const SizedBox(width: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.tr('gameplay.level', {'level': '$_currentLevel'}),
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.tr('common.pts'),
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Target Display Phase Widget
  /// Prominently showcases the item(s) to be found before the guessing grid appears
  Widget _buildTargetDisplayPhase() {
    final count = _currentTargetItems.length;
    final promptTitle = count == 1
        ? context.tr('gameplay.findItem')
        : (count == 2
            ? context.tr('gameplay.findBothItems')
            : context.tr('gameplay.findAll3Items'));

    return LayoutBuilder(
      key: const ValueKey('TargetDisplayPhase'),
      builder: (context, constraints) {
        final availableH = constraints.maxHeight;
        final isCompact = availableH < 440;
        final isVeryCompact = availableH < 380;
        final cardImageSize = isVeryCompact
            ? 85.0
            : (isCompact ? 108.0 : (availableH * 0.28).clamp(115.0, 150.0));

        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: isVeryCompact ? 2 : (isCompact ? 4 : 8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isVeryCompact ? 8 : (isCompact ? 12 : 16),
            ),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderGrey, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: textDark.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header prompt badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isVeryCompact ? 3 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded,
                          size: isVeryCompact ? 14 : 16, color: darkGreen),
                      const SizedBox(width: 5),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            promptTitle,
                            style: TextStyle(
                              color: darkGreen,
                              fontSize: isVeryCompact ? 12 : 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isVeryCompact ? 3 : 5),
                Text(
                  context.tr('gameplay.rememberAndRecognize'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: isVeryCompact ? 11 : 12,
                  ),
                ),
                SizedBox(height: isVeryCompact ? 8 : (isCompact ? 10 : 14)),

                // Large Target Item Showcase Cards
                if (count == 1) ...[
                  _buildSingleTargetDisplay(_currentTargetItems.first, cardImageSize, isCompact),
                ] else ...[
                  _buildMultiTargetDisplay(_currentTargetItems, cardImageSize * 0.85, isCompact),
                ],

                SizedBox(height: isVeryCompact ? 8 : (isCompact ? 10 : 14)),

                // "I'm Ready / Start" Action Button
                ElevatedButton(
                  onPressed: _beginGuessingPhase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isVeryCompact ? 20 : 26,
                      vertical: isVeryCompact ? 7 : (isCompact ? 9 : 11),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr('gameplay.imReady'),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: isVeryCompact ? 13 : 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: isVeryCompact ? 16 : 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleTargetDisplay(GameItem item, double size, bool isCompact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color: ivory,
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(
              color: primarySage.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: textDark.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Image.asset(
            item.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded,
                  size: 36, color: borderGrey),
            ),
          ),
        ),
        SizedBox(height: isCompact ? 6 : 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.localizedName(context),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textDark,
              fontSize: isCompact ? 17 : 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.localizedSubtitle(context),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primarySage,
              fontSize: isCompact ? 11.5 : 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiTargetDisplay(List<GameItem> items, double size, bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return Container(
          width: (size * 1.1).clamp(88.0, 115.0),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: ivory,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primarySage.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: (size * 0.78).clamp(60.0, 85.0),
                height: (size * 0.78).clamp(60.0, 85.0),
                child: Image.asset(
                  item.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    size: 26,
                    color: borderGrey,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.localizedName(context),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Step 2: 3x3 Grid of Interactive Image Cards
  /// Banner widget is REMOVED to maximize playing space, block size, and image scale
  Widget _buildInteractiveGrid() {
    return LayoutBuilder(
      key: const ValueKey('InteractiveGridPhase'),
      builder: (context, constraints) {
        // Take maximum square area available in the viewport
        final availableDim = min(constraints.maxWidth, constraints.maxHeight);
        // Generous safe size so tiles never overflow into lower controls
        final gridSide = availableDim.clamp(180.0, 520.0);

        return SizedBox(
          width: gridSide,
          height: gridSide,
          child: GridView.builder(
            itemCount: _currentGridItems.length,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final item = _currentGridItems[index];
              final isFound = _foundTargetIds.contains(item.id);
              final isWrong = _wrongTappedItemId == item.id;

              return _buildGridCard(item, isFound: isFound, isWrong: isWrong);
            },
          ),
        );
      },
    );
  }

  Widget _buildGridCard(GameItem item,
      {required bool isFound, required bool isWrong}) {
    Color borderColor = borderGrey;
    double borderWidth = 2.0;
    Color cardBg = ivory; // Theme background ensures transparent illustration sits directly on theme
    List<BoxShadow> shadows = [
      BoxShadow(
        color: textDark.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

    if (isFound) {
      borderColor = successGreen;
      borderWidth = 3.5;
      cardBg = lightGreen.withValues(alpha: 0.65);
      shadows = [
        BoxShadow(
          color: successGreen.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ];
    } else if (isWrong) {
      borderColor = alertRed;
      borderWidth = 3.5;
      cardBg = const Color(0xFFFFEBEE);
      shadows = [
        BoxShadow(
          color: alertRed.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ];
    }

    return Semantics(
      button: true,
      label: '${item.localizedName(context)}, ${item.localizedCategory(context)} from ${item.localizedSubtitle(context)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTileTapped(item),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            // Minimal padding so images expand to fill the large card block
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: shadows,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cultural Item Image (Transparent PNG directly on theme background)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Image.asset(
                      item.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 36,
                            color: borderGrey,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Success checkmark badge overlay
                if (isFound)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Error cross badge overlay
                if (isWrong)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: alertRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Clean bottom bar (Zero intrusive timer bars or countdown clocks)
  Widget _buildBottomControls() {
    final count = _currentTargetItems.length;
    final remaining = count - _foundTargetIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGrey, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Balanced empty spacer (bottom pause button removed to unify with top bar pause)
          const SizedBox(width: 48),

          // Cultural context or remaining target counter pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: ivory,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderGrey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentPhase == PictureGamePhase.targetDisplay
                      ? Icons.lightbulb_outline_rounded
                      : Icons.search_rounded,
                  size: 15,
                  color: primarySage,
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _currentPhase == PictureGamePhase.targetDisplay
                          ? context.tr('gameplay.memorizeItem')
                          : (count == 1
                              ? context.tr('gameplay.findItem')
                              : '$remaining / $count'),
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // End game button
          IconButton(
            tooltip: context.tr('gameplay.endSession'),
            icon: const Icon(Icons.stop_circle_outlined,
                color: alertRed, size: 26),
            onPressed: _endGame,
          ),
        ],
      ),
    );
  }
}
