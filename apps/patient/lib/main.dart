import 'package:flutter/material.dart';
import 'games/blink_game.dart';

void main() {
  runApp(const SmritiApp());
}

class SmritiApp extends StatelessWidget {
  const SmritiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMRITI',
      theme: ThemeData(
        scaffoldBackgroundColor: LandingPage.ivory,
        colorScheme: ColorScheme.fromSeed(seedColor: LandingPage.darkGreen),
        fontFamily: 'Arial',
      ),
      home: const SplashPage(),
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

class GameHubPage extends StatelessWidget {
  const GameHubPage({super.key});

  static const Color ivory = Color(0xFFF8F5EC);
  static const Color darkGreen = Color(0xFF214E3B);
  static const Color green = Color(0xFF5F866D);
  static const Color lightGreen = Color(0xFFDCE8DA);
  static const Color cream = Color(0xFFEDE7D7);
  static const Color textGrey = Color(0xFF66736C);

  void _openBlinkGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BlinkGameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 34, 22, 40),
              sliver: SliverToBoxAdapter(child: _buildGamesSection(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.psychology_alt_rounded,
                color: Colors.white, size: 27),
          ),
          const SizedBox(width: 12),
          const Text(
            'SMRITI',
            style: TextStyle(
              color: darkGreen,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Accessibility settings',
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: lightGreen,
              fixedSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.tune_rounded, color: darkGreen, size: 25),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose an activity',
          style: TextStyle(
            color: darkGreen,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Small exercises for memory and attention.',
          style: TextStyle(color: textGrey, fontSize: 15),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 650 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 2 ? .84 : 1.05,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _gameCard(
                  context,
                  icon: Icons.grid_3x3_rounded,
                  title: 'Blink Memory',
                  isAvailable: true,
                  onTap: () => _openBlinkGame(context),
                ),
                _gameCard(
                  context,
                  icon: Icons.extension_rounded,
                  title: 'Game 2',
                ),
                _gameCard(
                  context,
                  icon: Icons.record_voice_over_rounded,
                  title: 'Game 3',
                ),
                _gameCard(
                  context,
                  icon: Icons.palette_rounded,
                  title: 'Game 4',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 25),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.favorite_rounded, color: green, size: 25),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'There is no rush. Go at your own pace.',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gameCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isAvailable = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: isAvailable,
      enabled: isAvailable,
      label: isAvailable ? '$title. Start game.' : '$title. Coming soon.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: isAvailable ? lightGreen : const Color(0xFFE5E1D7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isAvailable ? lightGreen : const Color(0xFFE3DED1),
              width: 1.5,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: isAvailable
                      ? darkGreen.withValues(alpha: .24)
                      : textGrey.withValues(alpha: .22),
                  size: 92,
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.white.withValues(alpha: .78),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isAvailable ? darkGreen : textGrey,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
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
      MaterialPageRoute(builder: (_) => const BlinkGameScreen()),
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
                      child: Text('Making care more human,\naccessible and meaningful.',
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
                      _feature(Icons.favorite_rounded, 'Compassionate', 'Care with empathy'),
                      const SizedBox(width: 14),
                      _feature(Icons.person_rounded, 'Personal', 'Built around you'),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _feature(Icons.shield_rounded, 'Trusted', 'Safe and reliable'),
                      const SizedBox(width: 14),
                      _feature(Icons.groups_rounded, 'Connected', 'Never alone'),
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
                    Text('It is how we make people feel - heard, supported and valued.',
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
                    const Text('Take the first step towards\nbetter, more connected care.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textGrey, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 20),
                    SizedBox(width: 180, child: _primaryButton(context, 'Play Memory Game', compact: true)),
                  ],
                ),
              ),
              const SizedBox(height: 45),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
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

  Widget _primaryButton(BuildContext context, String label, {bool compact = false}) =>
      SizedBox(
        width: compact ? null : double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: () => _openGame(context),
          icon: const Icon(Icons.arrow_forward_rounded, size: 19),
          label: Text(label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: compact ? green : darkGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
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
                          color: Colors.white.withValues(alpha: .75), shape: BoxShape.circle),
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

  Widget _iconTile(IconData icon, Color background, Color foreground) => Container(
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
                      color: darkGreen, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Color(0xFF7A8580), fontSize: 10)),
            ],
          ),
        ),
      );
}