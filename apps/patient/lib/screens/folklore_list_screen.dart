import 'dart:async';
import 'package:flutter/material.dart';

import '../main.dart' show buildSmoothGameRoute;
import '../models/folklore_story.dart';
import '../services/folklore_service.dart';
import '../widgets/folklore_theme.dart';
import 'folklore_reader_screen.dart';

class FolkloreListScreen extends StatefulWidget {
  const FolkloreListScreen({super.key});

  @override
  State<FolkloreListScreen> createState() => _FolkloreListScreenState();
}

class _FolkloreListScreenState extends State<FolkloreListScreen> {
  List<FolkloreStory> _stories = <FolkloreStory>[];
  bool _loading = true;
  int _selectedTabIndex = 0; // 0 = All Tales, 1..N = Specific story

  final ScrollController _tabsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _tabsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    final stories = await FolkloreService.instance.loadStories();
    if (!mounted) return;

    setState(() {
      _stories = stories;
      _loading = false;
    });
  }

  FolkloreStoryTheme get _activeTheme {
    if (_stories.isEmpty || _selectedTabIndex == 0) {
      return FolkloreStoryTheme.fallback;
    }
    final storyIndex = _selectedTabIndex - 1;
    if (storyIndex >= 0 && storyIndex < _stories.length) {
      return FolkloreStoryTheme.forStory(_stories[storyIndex]);
    }
    return FolkloreStoryTheme.fallback;
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _activeTheme;

    return Scaffold(
      backgroundColor: FolkloreStoryTheme.canvasColor,
      body: Stack(
        children: [
          // ── 1. Subtle, Minimalist Ambient Background Animation ─────────────
          Positioned.fill(
            child: StoryAmbientBackground(
              theme: activeTheme,
            ),
          ),

          // ── 2. Screen Content ──────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimalist Header
                _buildHeader(context),

                const SizedBox(height: 12),

                // Minimalist Story Tabs (Switches background animation)
                if (!_loading && _stories.isNotEmpty)
                  _buildStoryTabs(),

                const SizedBox(height: 14),

                // Stories List
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: FolkloreStoryTheme.sageGreen,
                          ),
                        )
                      : _stories.isEmpty
                          ? _buildEmptyState()
                          : _buildStoryList(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          // Clean back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FolkloreStoryTheme.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(10, 30, 58, 95),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: FolkloreStoryTheme.darkNavy,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Folklore',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FolkloreStoryTheme.darkNavy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tales & legends of Northeast India',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FolkloreStoryTheme.softSlate,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Subtle story counter pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: FolkloreStoryTheme.paleGreen,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.eco_rounded,
                  size: 13,
                  color: FolkloreStoryTheme.sageGreen,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_stories.length} Tales',
                  style: const TextStyle(
                    color: FolkloreStoryTheme.darkNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTabs() {
    final tabItems = <_TabItem>[
      const _TabItem(
        title: 'All Tales',
        icon: Icons.auto_stories_rounded,
      ),
      ..._stories.map(
        (s) => _TabItem(
          title: s.title,
          icon: FolkloreStoryTheme.forStory(s).icon,
        ),
      ),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        controller: _tabsScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          final item = tabItems[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? FolkloreStoryTheme.darkNavy
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? FolkloreStoryTheme.darkNavy
                      : FolkloreStoryTheme.cardBorder,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color.fromARGB(24, 30, 58, 95),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : FolkloreStoryTheme.softSlate,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : FolkloreStoryTheme.darkNavy,
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryList(BuildContext context) {
    final storiesToShow = _selectedTabIndex == 0
        ? _stories
        : [_stories[_selectedTabIndex - 1]];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 680 ? 680.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              itemCount: storiesToShow.length,
              itemBuilder: (context, index) {
                final story = storiesToShow[index];
                final storyTheme = FolkloreStoryTheme.forStory(story);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _MinimalistStoryCard(
                    story: story,
                    theme: storyTheme,
                    index: index,
                    onTap: () {
                      Navigator.of(context).push(
                        buildSmoothGameRoute(
                          FolkloreReaderScreen(story: story),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 44,
              color: FolkloreStoryTheme.softSlate,
            ),
            SizedBox(height: 16),
            Text(
              'No folklore stories available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FolkloreStoryTheme.darkNavy,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.title, required this.icon});
  final String title;
  final IconData icon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Clean, Minimalist Story Card (Harmonized with Smriti App Aesthetic)
// ─────────────────────────────────────────────────────────────────────────────
class _MinimalistStoryCard extends StatefulWidget {
  const _MinimalistStoryCard({
    required this.story,
    required this.theme,
    required this.index,
    required this.onTap,
  });

  final FolkloreStory story;
  final FolkloreStoryTheme theme;
  final int index;
  final VoidCallback onTap;

  @override
  State<_MinimalistStoryCard> createState() => _MinimalistStoryCardState();
}

class _MinimalistStoryCardState extends State<_MinimalistStoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_animController);

    Future.delayed(Duration(milliseconds: 50 + widget.index * 80), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final theme = widget.theme;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(_slide.value.dx * 40, 0),
            child: child,
          ),
        );
      },
      child: Semantics(
        button: true,
        label: story.title,
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: FolkloreStoryTheme.cardBorder,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(12, 30, 58, 95),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Cover Thumbnail
                      Container(
                        width: 76,
                        height: 96,
                        decoration: BoxDecoration(
                          color: FolkloreStoryTheme.paleGreen,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: FolkloreStoryTheme.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: story.imagePath != null
                              ? Image.asset(
                                  story.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(
                                      Icons.auto_stories_rounded,
                                      size: 30,
                                      color: FolkloreStoryTheme.darkNavy,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.auto_stories_rounded,
                                    size: 30,
                                    color: FolkloreStoryTheme.darkNavy,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Story details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FolkloreStoryTheme.darkNavy,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              story.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FolkloreStoryTheme.softSlate,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Tags
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _MinimalPill(
                                  icon: Icons.location_on_rounded,
                                  label: story.region,
                                  textColor: FolkloreStoryTheme.darkNavy,
                                  bgColor: FolkloreStoryTheme.paleGreen,
                                ),
                                _MinimalPill(
                                  icon: Icons.schedule_rounded,
                                  label: '~${theme.readingMinutes} min read',
                                  textColor: FolkloreStoryTheme.softSlate,
                                  bgColor: const Color(0xFFF5F7FB),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Divider
                  Container(
                    height: 1,
                    color: const Color(0xFFEDF2F0),
                  ),

                  const SizedBox(height: 12),

                  // Bottom action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Language tags
                      Wrap(
                        spacing: 6,
                        children: story.translations.values.take(3).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t.languageLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: FolkloreStoryTheme.darkNavy,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Read Story link
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read Story',
                            style: TextStyle(
                              color: FolkloreStoryTheme.darkNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: FolkloreStoryTheme.darkNavy,
                          ),
                        ],
                      ),
                    ],
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

class _MinimalPill extends StatelessWidget {
  const _MinimalPill({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
