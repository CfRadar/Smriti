import 'dart:ui';

import 'package:flutter/material.dart';

import 'controllers/voice_command_controller.dart';
import 'games/blink_game.dart';
import 'games/bamboo_dance_game.dart';
import 'games/king_shanaba_game.dart';
import 'games/pattern_memory_game.dart';
import 'models/reminder_model.dart';
import 'models/voice_command.dart';
import 'services/reminder_service.dart';
import 'services/voice_service.dart';
import 'widgets/animated_fragmented_divider.dart';
import 'widgets/animated_star_badge.dart';
import 'widgets/voice_wave_button.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SmritiApp());
}

class SmritiApp extends StatefulWidget {
  const SmritiApp({super.key});

  @override
  State<SmritiApp> createState() => _SmritiAppState();
}

class _SmritiAppState extends State<SmritiApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VoiceCommandController.instance.attachNavigator(_navigatorKey);
    _registerVoiceRoutes();
    VoiceService.instance.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        VoiceService.instance.startListening();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        VoiceService.instance.stopListening();
        break;
    }
  }

  void _registerVoiceRoutes() {
    VoiceCommandController.instance.registerRoute(
      VoiceIntent.openBlinkingGame,
      () => _openRoute(const BlinkGameScreen()),
    );
    VoiceCommandController.instance.registerRoute(
      VoiceIntent.openMemoryGame,
      () => _openRoute(const PatternMemoryGameScreen()),
    );
    VoiceCommandController.instance.registerRoute(
      VoiceIntent.openKingShanabaGame,
      () => _openRoute(const KingShanabaGameScreen()),
    );
    for (final alias in [
      'blinking game',
      'blink game',
      'blinking',
      'blink',
      'blink memory',
    ]) {
      VoiceCommandController.instance.registerGameRoute(
        alias,
        () => _openRoute(const BlinkGameScreen()),
      );
    }
    for (final alias in [
      'pattern memory game',
      'pattern memory',
      'memory game',
      'memory',
    ]) {
      VoiceCommandController.instance.registerGameRoute(
        alias,
        () => _openRoute(const PatternMemoryGameScreen()),
      );
    }
    for (final alias in [
      'king shanaba',
      'king shanba',
      'king shan ba',
      'kang shanaba',
      'kang shanba',
      'kang shan ba',
      'king shanaba game',
      'king shanba game',
      'king shan ba game',
      'kang shanaba game',
      'kang shanba game',
      'king',
      'open king',
      'kang',
      'open kang',
      'shanaba',
      'shanba',
      'shan ba',
      'sliding game',
      'slide game',
      'sliding',
      'tactile game',
      'manipuri game',
      'third game',
      'game 3',
      'game three',
    ]) {
      VoiceCommandController.instance.registerGameRoute(
        alias,
        () => _openRoute(const KingShanabaGameScreen()),
      );
    }
    VoiceCommandController.instance.registerRoute(
      VoiceIntent.openBambooDanceGame,
      () => _openRoute(const BambooDanceGameScreen()),
    );
    for (final alias in [
      'bamboo dance',
      'bamboo dance game',
      'bamboo game',
      'bamboo',
      'dance game',
      'dance',
      'cheraw',
      'cheraw dance',
      'assam dance',
      'assamese dance',
      'বাঁহ নৃত্য',
      'বাঁহনৃত্য',
      'বাঁহ খেল',
      'বাঁহৰ নৃত্য',
      'बांस नृत्य',
      'बैम्बू डांस',
      'बैंबू डांस',
      'डांस गेम',
      'चौथा गेम',
      'fourth game',
      'game 4',
      'game four',
    ]) {
      VoiceCommandController.instance.registerGameRoute(
        alias,
        () => _openRoute(const BambooDanceGameScreen()),
      );
    }
    VoiceCommandController.instance.registerRoute(
      VoiceIntent.exitGame,
      () {
        final nav = _navigatorKey.currentState;
        if (nav != null) {
          nav.pushNamedAndRemoveUntil('/home', (route) => false);
          return;
        }
        final context = _navigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      },
    );
    VoiceCommandController.instance.registerRoute(
      VoiceIntent.goHome,
      () {
        final nav = _navigatorKey.currentState;
        if (nav != null) {
          nav.pushNamedAndRemoveUntil('/home', (route) => false);
          return;
        }
        final context = _navigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      },
    );
  }

  void _openRoute(Widget page) {
    final nav = _navigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => route.isFirst,
      );
      return;
    }
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    VoiceService.instance.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SMRITI',
      theme: ThemeData(
        scaffoldBackgroundColor: LandingPage.ivory,
        colorScheme: ColorScheme.fromSeed(seedColor: LandingPage.darkGreen),
        fontFamily: 'Arial',
      ),
      routes: {
        '/home': (context) => const GameHubPage(),
      },
      home: const SplashPage(),
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // { slides in from the left  (offset goes from -1.0 → 0.0 of screen width)
  late final Animation<double> _leftSlide;
  // } slides in from the right (offset goes from +1.0 → 0.0)
  late final Animation<double> _rightSlide;
  // Brackets fade out as they meet
  late final Animation<double> _bracketFade;
  // "S" + "mriti" fades / scales in
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  // Underline pops in
  late final Animation<double> _underlineFade;
  // Subtitle fades last
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _leftSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.52, curve: Curves.easeOutCubic),
      ),
    );
    _rightSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.52, curve: Curves.easeOutCubic),
      ),
    );
    _bracketFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.68, curve: Curves.easeIn),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.82, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.82, curve: Curves.easeOutBack),
      ),
    );
    _underlineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 0.92, curve: Curves.easeOut),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.84, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2800), _openGameHub);
  }

  void _openGameHub() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameHubPage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // matches main UI screenBg
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo area ──────────────────────────────────────────
                SizedBox(
                  width: 160,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // { bracket from the left
                      Opacity(
                        opacity: _bracketFade.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(_leftSlide.value * sw * 0.55, 0),
                          child: const Text(
                            '{',
                            style: TextStyle(
                              fontSize: 96,
                              height: 1,
                              color: Color(0xFF1E3A5F),
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ),
                      ),
                      // } bracket from the right
                      Opacity(
                        opacity: _bracketFade.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(_rightSlide.value * sw * 0.55, 0),
                          child: const Text(
                            '}',
                            style: TextStyle(
                              fontSize: 96,
                              height: 1,
                              color: Color(0xFF1E3A5F),
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ),
                      ),
                      // "S" emerges from the collision
                      Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: const Text(
                            'S',
                            style: TextStyle(
                              fontSize: 92,
                              height: 1,
                              color: Color(0xFF1E3A5F),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── "mriti" text ──────────────────────────────────────
                Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: const Text(
                      'mriti',
                      style: TextStyle(
                        color: Color(0xFF1E3A5F),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                        height: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Peach / pink underline (matches nav bar) ──────────
                Opacity(
                  opacity: _underlineFade.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFAB91),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 28,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF48FB1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── Subtitle ──────────────────────────────────────────
                Opacity(
                  opacity: _subtitleFade.value,
                  child: const Text(
                    'Care that feels like home.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8298AB),
                      fontSize: 16,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


class GameHubPage extends StatefulWidget {
  const GameHubPage({super.key});

  static const Color ivory = Color(0xFFF8F5EC);
  static const Color screenBg = Color(0xFFF0F4F8); // Harmonious cool sky-mist tint matching nav bar
  static const Color softPeach = Color(0xFFFDF0E7);
  static const Color darkGreen = Color(0xFF214E3B);
  static const Color green = Color(0xFF5F866D);
  static const Color lightGreen = Color(0xFFDCE8DA);
  static const Color cream = Color(0xFFEDE7D7);
  static const Color textGrey = Color(0xFF66736C);

  @override
  State<GameHubPage> createState() => _GameHubPageState();
}

class _GameHubPageState extends State<GameHubPage> {
  List<PatientReminder> _reminders = [];
  bool _loadingReminders = true;
  final bool _showRoutineSection = false;
  bool _showReminderOverlay = false;
  int _selectedTabIndex = 0;
  int _currentReminderIndex = 0;
  final GlobalKey _tickKey = GlobalKey();

  static final PatientReminder _dummyReminder = PatientReminder(
    id: '__dummy_water__',
    title: 'Drink Water',
    description: 'Stay hydrated — have a glass of water!',
    type: 'hydration',
    scheduledTime: DateTime.now(),
    isVoicePromptEnabled: false,
    status: 'pending',
  );

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _loadingReminders = true);
    try {
      final list = await ReminderService.instance.fetchReminders();
      if (mounted) {
        setState(() {
          // Prepend the dummy reminder so it always shows
          final withoutDummy = list.where((r) => r.id != _dummyReminder.id).toList();
          _reminders = [_dummyReminder, ...withoutDummy];
          _loadingReminders = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reminders = [_dummyReminder];
          _loadingReminders = false;
        });
      }
    }
  }

  Future<void> _acknowledgeReminder(PatientReminder reminder) async {
    await ReminderService.instance.acknowledgeReminder(reminder.id);
    if (mounted) {
      setState(() {
        _reminders = _reminders.map((r) {
          if (r.id == reminder.id) {
            return PatientReminder(
              id: r.id,
              title: r.title,
              description: r.description,
              type: r.type,
              scheduledTime: r.scheduledTime,
              repeat: r.repeat,
              isVoicePromptEnabled: r.isVoicePromptEnabled,
              voicePromptText: r.voicePromptText,
              status: 'acknowledged',
            );
          }
          return r;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Well done! ${reminder.title} marked completed.'),
          backgroundColor: GameHubPage.darkGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _speakReminder(PatientReminder reminder) {
    final promptText = reminder.voicePromptText ??
        'Time for your ${reminder.title}.';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameHubPage.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GameHubPage.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.record_voice_over_rounded,
                  color: GameHubPage.darkGreen, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Voice Reminder',
              style: TextStyle(
                color: GameHubPage.darkGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          promptText,
          style: const TextStyle(
            color: GameHubPage.darkGreen,
            fontSize: 18,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                color: GameHubPage.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openBlinkGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BlinkGameScreen()),
    );
  }

  void _openPatternGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PatternMemoryGameScreen()),
    );
  }

  void _openKingShanabaGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KingShanabaGameScreen()),
    );
  }

  void _openBambooDanceGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BambooDanceGameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingReminders = _reminders.where((r) => !r.isAcknowledged).toList();
    return Scaffold(
      backgroundColor: GameHubPage.screenBg,
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                const SliverToBoxAdapter(
                  child: AnimatedFragmentedDivider(),
                ),
                if (_showRoutineSection)
                  SliverToBoxAdapter(child: _buildRemindersSection()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
                  sliver: SliverToBoxAdapter(
                    child: _selectedTabIndex == 0
                        ? _buildGamesSection(context)
                        : _buildActivitiesScreen(),
                  ),
                ),
              ],
            ),
          ),
          if (_showReminderOverlay) _buildReminderOverlay(pendingReminders),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F9),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A5F).withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedTabIndex,
              onTap: (index) => setState(() => _selectedTabIndex = index),
              backgroundColor: Colors.transparent,
              selectedItemColor: GameHubPage.darkGreen,
              unselectedItemColor: const Color(0xFF7D8BA3),
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              selectedFontSize: 12,
              unselectedFontSize: 11,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: _bottomNavIcon(
                    icon: Icons.videogame_asset_rounded,
                    selected: _selectedTabIndex == 0,
                    selectedColor: const Color(0xFFE9F5D6),
                  ),
                  activeIcon: _bottomNavIcon(
                    icon: Icons.videogame_asset_rounded,
                    selected: true,
                    selectedColor: const Color(0xFFE9F5D6),
                  ),
                  label: 'Games',
                ),
                BottomNavigationBarItem(
                  icon: _bottomNavIcon(
                    icon: Icons.auto_awesome_rounded,
                    selected: _selectedTabIndex == 1,
                    selectedColor: const Color(0xFFEDE4F7),
                  ),
                  activeIcon: _bottomNavIcon(
                    icon: Icons.auto_awesome_rounded,
                    selected: true,
                    selectedColor: const Color(0xFFEDE4F7),
                  ),
                  label: 'Activities',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavIcon({
    required IconData icon,
    required bool selected,
    required Color selectedColor,
  }) {
    return AnimatedScale(
      scale: selected ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: GameHubPage.darkGreen.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: selected ? 24 : 22,
          color: selected ? GameHubPage.darkGreen : const Color(0xFF7D8BA3),
        ),
      ),
    );
  }

  Widget _buildActivitiesScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activities',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 26),
        _ActivityCard(
          delay: 80,
          icon: Icons.mic_rounded,
          title: 'Karaoke',
          subtitle: 'Enjoy a calm music moment.',
          accentColor: const Color(0xFF86D5E6),
          glowColor: const Color(0xFF52B5D8),
          photoTint: const Color(0xFFBFEAF8),
          photoHighlight: const Color(0xFF8ED7F4),
          illustration: const _MicrophoneIllustration(),
          onTap: () {},
        ),
        const SizedBox(height: 22),
        _ActivityCard(
          delay: 220,
          icon: Icons.auto_stories_rounded,
          title: 'Folk Stories',
          subtitle: 'Enjoy calm music and explore stories.',
          accentColor: const Color(0xFFEAC4F2),
          glowColor: const Color(0xFFD795E4),
          photoTint: const Color(0xFFE9D9F7),
          photoHighlight: const Color(0xFFD7B4EE),
          illustration: const _BookIllustration(),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildReminderOverlay(List<PatientReminder> reminders) {
    final visibleReminders = reminders.where((r) => !r.isAcknowledged).toList();
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: _showReminderOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: !_showReminderOverlay,
              child: GestureDetector(
                onTap: () => setState(() => _showReminderOverlay = false),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _showReminderOverlay ? 2.5 : 0.0,
                      sigmaY: _showReminderOverlay ? 2.5 : 0.0,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          top: _showReminderOverlay ? 70 : -420,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildReminderPopup(visibleReminders),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderPopup(List<PatientReminder> reminders) {
    if (_currentReminderIndex >= reminders.length) {
      _currentReminderIndex = 0;
    }
    final isEmpty = reminders.isEmpty;
    final reminder = isEmpty ? null : reminders[_currentReminderIndex];
    final timeStr = reminder != null
        ? DateFormat('h:mm a').format(reminder.scheduledTime)
        : '';
    final hasMultiple = reminders.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Color(0xFFFF7043),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Reminders',
                    style: TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _showReminderOverlay = false),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF1E3A5F)),
                  tooltip: 'Close reminders',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: GameHubPage.green, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No reminders right now. Everything looks good.',
                        style: TextStyle(
                          color: GameHubPage.darkGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _ReminderCard(
                reminder: reminder!,
                timeStr: timeStr,
                hasMultiple: hasMultiple,
                currentIndex: _currentReminderIndex,
                totalCount: reminders.length,
                tickKey: _tickKey,
                onPrev: _currentReminderIndex > 0
                    ? () => setState(() => _currentReminderIndex--)
                    : null,
                onNext: _currentReminderIndex < reminders.length - 1
                    ? () => setState(() => _currentReminderIndex++)
                    : null,
                onSpeak: reminder.isVoicePromptEnabled
                    ? () => _speakReminder(reminder)
                    : null,
                onDone: () {
                  final tickBox = _tickKey.currentContext
                      ?.findRenderObject() as RenderBox?;
                  final tickPos = tickBox != null
                      ? tickBox.localToGlobal(tickBox.size.center(Offset.zero))
                      : Offset.zero;
                  AnimatedStarBadge.globalKey.currentState
                      ?.celebrate(tickPos);
                  _acknowledgeReminder(reminder);
                },
                getTypeIcon: _getTypeIcon,
              ),
          ],
        ),
      ),
    );
  }

  void _openAccessibilitySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune_rounded, color: GameHubPage.darkGreen, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: GameHubPage.darkGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Accessibility & Voice preferences',
                      style: TextStyle(color: GameHubPage.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.record_voice_over_rounded, color: GameHubPage.green),
              title: const Text(
                'Voice Assistant',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: const Text('Tap to activate or deactivate voice commands.'),
              trailing: ValueListenableBuilder<VoiceStatus>(
                valueListenable: VoiceService.instance.statusNotifier,
                builder: (context, status, _) {
                  final active = VoiceService.instance.isEnabled &&
                      (status == VoiceStatus.listening ||
                          status == VoiceStatus.processing ||
                          status == VoiceStatus.initializing);

                  return Tooltip(
                    message: active
                        ? 'Tap to deactivate Voice Assistant'
                        : 'Tap to activate Voice Assistant',
                    child: InkWell(
                      onTap: () async {
                        await VoiceService.instance.setEnabled(!active);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? const Color(0xFF81C784) : const Color(0xFFCBD5E1),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: active
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active ? const Color(0xFF2E7D32) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              active ? 'Active' : 'Deactivated',
                              style: TextStyle(
                                color: active ? const Color(0xFF1B5E20) : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.volume_up_rounded, color: GameHubPage.green),
              title: Text('Routine Reminders'),
              subtitle: Text('Spoken audio reminders.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildSettingsButton(),
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitleWithUnderline(),
                const SizedBox(width: 8),
                _buildReminderButton(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedStarBadge(key: AnimatedStarBadge.globalKey),
                const SizedBox(width: 6),
                const VoiceWaveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderButton() {
    return Semantics(
      button: true,
      label: 'Reminders',
      child: Tooltip(
        message: 'Reminders',
        child: InkWell(
          onTap: () => setState(() => _showReminderOverlay = !_showReminderOverlay),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFCFE0ED),
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
              Icons.notifications_rounded,
              color: GameHubPage.darkGreen,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Semantics(
      button: true,
      label: 'Accessibility and settings',
      child: Tooltip(
        message: 'Settings',
        child: InkWell(
          onTap: () => _openAccessibilitySettings(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFCFE0ED),
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
              Icons.tune_rounded,
              color: GameHubPage.darkGreen,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWithUnderline() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Smriti',
          style: TextStyle(
            color: GameHubPage.darkGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Peach underline segment
            Container(
              width: 22,
              height: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xFFFFAB91), // Peach
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6), // Separated from between
            // Pink underline segment
            Container(
              width: 22,
              height: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xFFF48FB1), // Pink
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemindersSection() {
    final pendingReminders = _reminders.where((r) => !r.isAcknowledged).toList();
    final completedReminders = _reminders.where((r) => r.isAcknowledged).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Today\'s Routine',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: GameHubPage.darkGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: GameHubPage.green),
                tooltip: 'Refresh routine',
                onPressed: _loadReminders,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingReminders)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: GameHubPage.darkGreen),
              ),
            )
          else if (_reminders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GameHubPage.cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GameHubPage.lightGreen),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: GameHubPage.green, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No routine tasks right now. Relax and enjoy your day!',
                      style: TextStyle(
                        color: GameHubPage.darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...pendingReminders.map((reminder) => _reminderCard(reminder, isCompleted: false)),
            if (completedReminders.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...completedReminders.map((reminder) => _reminderCard(reminder, isCompleted: true)),
            ],
          ],
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication_rounded;
      case 'hydration':
        return Icons.water_drop_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'activity':
        return Icons.directions_walk_rounded;
      case 'appointment':
        return Icons.local_hospital_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  Widget _reminderCard(PatientReminder reminder, {required bool isCompleted}) {
    final timeStr = DateFormat('h:mm a').format(reminder.scheduledTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFEBE6D8) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? Colors.transparent : GameHubPage.lightGreen,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted ? GameHubPage.lightGreen.withValues(alpha: 0.5) : GameHubPage.lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getTypeIcon(reminder.type),
              color: isCompleted ? GameHubPage.textGrey : GameHubPage.darkGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    color: isCompleted ? GameHubPage.textGrey : GameHubPage.darkGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: GameHubPage.textGrey),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: GameHubPage.textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reminder.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: GameHubPage.textGrey, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (reminder.isVoicePromptEnabled && !isCompleted) ...[
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: GameHubPage.green, size: 26),
              tooltip: 'Listen to prompt',
              onPressed: () => _speakReminder(reminder),
            ),
          ],
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: isCompleted ? null : () => _acknowledgeReminder(reminder),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.transparent : GameHubPage.darkGreen,
              foregroundColor: isCompleted ? GameHubPage.textGrey : Colors.white,
              elevation: isCompleted ? 0 : 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.check_rounded,
                  size: 18,
                  color: isCompleted ? GameHubPage.green : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isCompleted ? 'Done' : 'Done',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isCompleted ? GameHubPage.green : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is coming soon!'),
        backgroundColor: GameHubPage.darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildGamesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Choose an activity',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1E3A5F),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2EAF2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_esports_rounded, size: 13, color: Color(0xFF1E3A5F)),
                  SizedBox(width: 4),
                  Text(
                    '6 Games',
                    style: TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 11,
          mainAxisSpacing: 11,
          childAspectRatio: 1.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _gameCard(
              context,
              icon: Icons.visibility_rounded,
              title: 'Blink Memory',
              gradientColors: const [Color(0xFFFFE0B2), Color(0xFFFFB74D)],
              iconColor: const Color(0xFFE65100),
              isAvailable: true,
              onTap: () => _openBlinkGame(context),
            ),
            _gameCard(
              context,
              icon: Icons.grid_view_rounded,
              title: 'Pattern Memory',
              gradientColors: const [Color(0xFFE1BEE7), Color(0xFFBA68C8)],
              iconColor: const Color(0xFF4A148C),
              isAvailable: true,
              onTap: () => _openPatternGame(context),
            ),
            _gameCard(
              context,
              icon: Icons.sports_esports_rounded,
              title: 'King Shanaba',
              gradientColors: const [Color(0xFFC8E6C9), Color(0xFF81C784)],
              iconColor: const Color(0xFF1B5E20),
              isAvailable: true,
              onTap: () => _openKingShanabaGame(context),
            ),
            _gameCard(
              context,
              icon: Icons.music_note_rounded,
              title: 'Bamboo Dance',
              gradientColors: const [Color(0xFFFFCDD2), Color(0xFFE57373)],
              iconColor: const Color(0xFFB71C1C),
              isAvailable: true,
              onTap: () => _openBambooDanceGame(context),
            ),
            _gameCard(
              context,
              icon: Icons.auto_stories_rounded,
              title: 'Story Recall',
              gradientColors: const [Color(0xFFBBDEFB), Color(0xFF64B5F6)],
              iconColor: const Color(0xFF0D47A1),
              isAvailable: false,
              onTap: () => _showComingSoon(context, 'Story Recall'),
            ),
            _gameCard(
              context,
              icon: Icons.spa_rounded,
              title: 'Mindful Breath',
              gradientColors: const [Color(0xFFF8BBD0), Color(0xFFF06292)],
              iconColor: const Color(0xFF880E4F),
              isAvailable: false,
              onTap: () => _showComingSoon(context, 'Mindful Breath'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gameCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
    required Color iconColor,
    bool isAvailable = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      enabled: true,
      label: isAvailable ? '$title. Play game.' : '$title. Coming soon.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8298AB), // Soft medium slate-blue grey
              width: 4.0, // Substantial wide border
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19.2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Playful Gradient Background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                ),

                // Playful Center Icon in white circular glass badge
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 34,
                      ),
                    ),
                  ),
                ),

                // Soon Tag for upcoming games
                if (!isAvailable)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, color: Colors.white, size: 9),
                          SizedBox(width: 3),
                          Text(
                            'Soon',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Translucent black overlay at bottom with large white curved font
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.54),
                    ),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        fontFamilyFallback: [
                          'sans-serif-rounded',
                          'Comfortaa',
                          'Sniglet',
                          'Comic Sans MS',
                          'Chalkboard SE',
                          'Fredoka One',
                          'cursive',
                        ],
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
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
}

class _ActivityCard extends StatefulWidget {
  final int delay;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color glowColor;
  final Color photoTint;
  final Color photoHighlight;
  final Widget illustration;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.delay,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.glowColor,
    required this.photoTint,
    required this.photoHighlight,
    required this.illustration,
    required this.onTap,
  });

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.16, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_controller);
    _scale = Tween<double>(begin: 0.96, end: 1.0).chain(
      CurveTween(curve: Curves.easeOutCubic),
    ).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(_slide.value.dx * 120, _slide.value.dy * 120),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: Semantics(
        button: true,
        label: widget.title,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(
                      widget.accentColor.withValues(alpha: 0.45),
                      Colors.white,
                    ),
                    widget.accentColor.withValues(alpha: 0.72),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.82),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _FloatingIcon(icon: widget.icon, color: widget.glowColor),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1E3A5F),
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF536A7B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 14,
                                color: Color(0xFF1E3A5F),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.title == 'Karaoke' ? 'Mood boost' : 'Story time',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1E3A5F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, right: 12, bottom: 10),
                      child: SlantedPhotoArea(
                        color: widget.photoTint,
                        highlightColor: widget.photoHighlight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      widget.photoTint,
                                      widget.photoHighlight,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 18,
                              right: 18,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, -8 + (1 - _fade.value) * 8),
                                    child: child,
                                  );
                                },
                                child: widget.illustration,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _FloatingIcon({required this.icon, required this.color});

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 + 4 * _controller.value),
          child: child,
        );
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.24),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 30,
        ),
      ),
    );
  }
}

class SlantedPhotoArea extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color highlightColor;

  const SlantedPhotoArea({
    super.key,
    required this.child,
    required this.color,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _SlantedPhotoClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, highlightColor],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SlantedPhotoClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.18, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.02, size.height);
    path.lineTo(0, size.height * 0.12);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MicrophoneIllustration extends StatelessWidget {
  const _MicrophoneIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            bottom: 12,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 14,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4C2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            right: 16,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE7A3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookIllustration extends StatelessWidget {
  const _BookIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 16,
            child: Transform.rotate(
              angle: -0.32,
              child: Container(
                width: 58,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFB284CF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            child: Transform.rotate(
              angle: 0.32,
              child: Container(
                width: 58,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFD59FE8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 26,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3C3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 26,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD9E8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const Color ivory = Color(0xFFF8F5EC);
  static const Color darkGreen = Color(0xFF214E3B);
  static const Color green = Color(0xFF5F866D);
  static const Color lightGreen = Color(0xFFDCE8DA);
  static const Color cream = Color(0xFFEDE7D7);
  static const Color textGrey = Color(0xFF66736C);

  void _openGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameHubPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Row(
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: darkGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.psychology_alt_rounded,
                          color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 10),
                    const Text('SMRITI',
                        style: TextStyle(
                            color: darkGreen,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Start memory game',
                      onPressed: () => _openGame(context),
                      style: IconButton.styleFrom(
                        backgroundColor: lightGreen,
                        fixedSize: const Size(43, 43),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: darkGreen, size: 25),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 38),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _badge('CARE  •  MEMORY  •  CONNECTION'),
                    const SizedBox(height: 20),
                    const Text('Care that feels\nlike home.',
                        style: TextStyle(
                            color: darkGreen,
                            fontSize: 43,
                            height: 1.08,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 17),
                    const Text(
                        'Thoughtful support for everyday life, designed around the people who matter most.',
                        style: TextStyle(
                            color: textGrey, fontSize: 15, height: 1.55)),
                    const SizedBox(height: 25),
                    _primaryButton(context, 'Get Started'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _heroVisual(),
              const SizedBox(height: 42),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    _iconTile(Icons.favorite_rounded, cream, green),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Text(
                          'Making care more human,\naccessible and meaningful.',
                          style: TextStyle(
                              color: darkGreen,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 42),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text('Why SMRITI?',
                    style: TextStyle(
                        color: darkGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 7),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text('Support that puts people first.',
                    style: TextStyle(color: textGrey, fontSize: 14)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    Row(children: [
                      _feature(Icons.favorite_rounded, 'Compassionate',
                          'Care with empathy'),
                      const SizedBox(width: 14),
                      _feature(
                          Icons.person_rounded, 'Personal', 'Built around you'),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _feature(
                          Icons.shield_rounded, 'Trusted', 'Safe and reliable'),
                      const SizedBox(width: 14),
                      _feature(
                          Icons.groups_rounded, 'Connected', 'Never alone'),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 45),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.all(27),
                decoration: BoxDecoration(
                    color: darkGreen, borderRadius: BorderRadius.circular(30)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.eco_rounded, color: lightGreen, size: 30),
                    SizedBox(height: 20),
                    Text('Care is not just\nwhat we do.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            height: 1.15,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 13),
                    Text(
                        'It is how we make people feel - heard, supported and valued.',
                        style: TextStyle(
                            color: lightGreen, fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const Text('Ready to begin?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: darkGreen,
                            fontSize: 27,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    const Text(
                        'Take the first step towards\nbetter, more connected care.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textGrey, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: 180,
                        child: _primaryButton(context, 'Play Memory Game',
                            compact: true)),
                  ],
                ),
              ),
              const SizedBox(height: 45),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
                color: cream,
                child: const Column(
                  children: [
                    Text('SMRITI',
                        style: TextStyle(
                            color: darkGreen,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    SizedBox(height: 8),
                    Text('Care  •  Memory  •  Connection',
                        style: TextStyle(color: textGrey, fontSize: 11)),
                    SizedBox(height: 18),
                    Text('© 2026 SMRITI. All rights reserved.',
                        style: TextStyle(color: textGrey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
            color: lightGreen, borderRadius: BorderRadius.circular(30)),
        child: Text(text,
            style: const TextStyle(
                color: darkGreen,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: .8)),
      );

  Widget _primaryButton(BuildContext context, String label,
          {bool compact = false}) =>
      SizedBox(
        width: compact ? null : double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: () => _openGame(context),
          icon: const Icon(Icons.arrow_forward_rounded, size: 19),
          label: Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: compact ? green : darkGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          ),
        ),
      );

  Widget _heroVisual() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          height: 285,
          width: double.infinity,
          decoration: BoxDecoration(
              color: lightGreen, borderRadius: BorderRadius.circular(30)),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -40,
                child: _circle(170, Colors.white.withValues(alpha: .25)),
              ),
              Positioned(
                bottom: -45,
                left: -35,
                child: _circle(130, cream.withValues(alpha: .5)),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .75),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.diversity_1_rounded,
                          size: 46, color: darkGreen),
                    ),
                    const SizedBox(height: 15),
                    const Text('Together through every moment',
                        style: TextStyle(
                            color: darkGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _circle(double size, Color color) => Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _iconTile(IconData icon, Color background, Color foreground) =>
      Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: foreground, size: 22),
      );

  Widget _feature(IconData icon, String title, String subtitle) => Expanded(
        child: Container(
          height: 145,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: .035),
                  blurRadius: 18,
                  offset: const Offset(0, 7)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconTile(icon, lightGreen, const Color(0xFF315D4F)),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                      color: darkGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                      const TextStyle(color: Color(0xFF7A8580), fontSize: 10)),
            ],
          ),
        ),
      );
}

// ─── _ReminderCard ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatefulWidget {
  final PatientReminder reminder;
  final String timeStr;
  final bool hasMultiple;
  final int currentIndex;
  final int totalCount;
  final GlobalKey tickKey;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onSpeak;
  final VoidCallback onDone;
  final IconData Function(String) getTypeIcon;

  const _ReminderCard({
    required this.reminder,
    required this.timeStr,
    required this.hasMultiple,
    required this.currentIndex,
    required this.totalCount,
    required this.tickKey,
    required this.onPrev,
    required this.onNext,
    required this.onSpeak,
    required this.onDone,
    required this.getTypeIcon,
  });

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.38)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.38, end: 0.85)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.85, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 35),
    ]).animate(_tickCtrl);
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    super.dispose();
  }

  void _onTickTap() {
    _tickCtrl.forward(from: 0).then((_) => widget.onDone());
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFAB91).withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Type icon
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.getTypeIcon(r.type),
              color: const Color(0xFFFF7043),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: const TextStyle(
                    color: Color(0xFF1E3A5F),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (r.description != null && r.description!.isNotEmpty)
                  Text(
                    r.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8298AB),
                      fontSize: 12.5,
                    ),
                  ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: Color(0xFFFF7043)),
                    const SizedBox(width: 3),
                    Text(
                      widget.timeStr,
                      style: const TextStyle(
                        color: Color(0xFFFF7043),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.hasMultiple) ...[
                      const SizedBox(width: 10),
                      _navChip(
                        icon: Icons.chevron_left_rounded,
                        enabled: widget.onPrev != null,
                        onTap: widget.onPrev,
                      ),
                      const SizedBox(width: 4),
                      _navChip(
                        icon: Icons.chevron_right_rounded,
                        enabled: widget.onNext != null,
                        onTap: widget.onNext,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Tick button with bounce animation ──
          GestureDetector(
            key: widget.tickKey,
            onTap: _onTickTap,
            child: AnimatedBuilder(
              animation: _scaleAnim,
              builder: (_, child) => Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A5F), Color(0xFF2D5A8E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navChip({
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF1E3A5F)),
        ),
      ),
    );
  }
}

