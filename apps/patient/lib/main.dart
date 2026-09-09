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
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: .9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2200), _openGameHub);
  }

  void _openGameHub() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameHubPage(),
        transitionDuration: const Duration(milliseconds: 550),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EC),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFF214E3B),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.psychology_alt_rounded,
                      color: Colors.white, size: 42),
                ),
                const SizedBox(height: 22),
                const Text(
                  'SMRITI',
                  style: TextStyle(
                    color: Color(0xFF214E3B),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Care that feels like home.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF66736C),
                    fontSize: 17,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
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
  bool _reminderExpanded = true;
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
      // Always show bottom sheet – shows 'No reminders' when empty and expanded
      bottomSheet: _buildReminderBottomSheet(pendingReminders),
      body: SafeArea(
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
              sliver: SliverToBoxAdapter(child: _buildGamesSection(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderBottomSheet(List<PatientReminder> reminders) {
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle / toggle bar ──────────────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _reminderExpanded = !_reminderExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? const Color(0xFFF0F4F8)
                          : const Color(0xFFFFECE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEmpty
                          ? Icons.notifications_off_rounded
                          : Icons.notifications_rounded,
                      color: isEmpty
                          ? const Color(0xFF8298AB)
                          : const Color(0xFFFF7043),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEmpty
                          ? 'No reminders'
                          : (_reminderExpanded ? 'Reminder' : reminder!.title),
                      style: TextStyle(
                        color: isEmpty
                            ? const Color(0xFF8298AB)
                            : const Color(0xFF1E3A5F),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isEmpty && hasMultiple)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentReminderIndex + 1}/${reminders.length}',
                        style: const TextStyle(
                          color: Color(0xFFFF7043),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  // Animated arrow – hidden when empty
                  if (!isEmpty)
                    AnimatedRotation(
                      turns: _reminderExpanded ? 0.0 : 0.5,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF8298AB),
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Expanded content (hidden when no reminders or collapsed) ──
          if (!isEmpty)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: _reminderExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: _ReminderCard(
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
                    // Get tick button global position before acknowledging
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
              ),
              secondChild: const SizedBox(height: 4),
            ),
        ],
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
              title: const Text('Voice Assistant'),
              subtitle: const Text('Tap the wave button on top-right to speak commands.'),
              trailing: ValueListenableBuilder<VoiceStatus>(
                valueListenable: VoiceService.instance.statusNotifier,
                builder: (context, status, _) {
                  final active = status == VoiceStatus.listening || status == VoiceStatus.processing;
                  return Chip(
                    label: Text(
                      active ? 'Active' : 'Idle',
                      style: TextStyle(
                        color: active ? Colors.green.shade800 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: active ? Colors.green.shade50 : Colors.grey.shade100,
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
          // Title always perfectly centered
          _buildTitleWithUnderline(),

          // Settings on the far left
          Align(
            alignment: Alignment.centerLeft,
            child: _buildSettingsButton(),
          ),

          // Star + voice on the far right
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Choose an activity',
              style: TextStyle(
                color: Color(0xFF1E3A5F),
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
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

