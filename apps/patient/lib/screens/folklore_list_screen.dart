import 'dart:async';

import 'package:flutter/material.dart';

import '../models/folklore_story.dart';
import '../services/folklore_service.dart';
import 'folklore_reader_screen.dart';

class FolkloreListScreen extends StatefulWidget {
  const FolkloreListScreen({super.key});

  @override
  State<FolkloreListScreen> createState() => _FolkloreListScreenState();
}

class _FolkloreListScreenState extends State<FolkloreListScreen> {
  final List<bool> _cardVisible = <bool>[];
  List<FolkloreStory> _stories = <FolkloreStory>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final stories = await FolkloreService.instance.loadStories();
    if (!mounted) return;

    setState(() {
      _stories = stories;
      _cardVisible.clear();
      _cardVisible.addAll(List<bool>.filled(stories.length, false));
      _loading = false;
    });

    for (var index = 0; index < stories.length; index++) {
      Future<void>.delayed(Duration(milliseconds: 100 + (index * 120)), () {
        if (!mounted) return;
        setState(() {
          _cardVisible[index] = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = const Color(0xFFF6F1E7);
    final dark = const Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Folklore',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4C8D73),
                ),
              )
            : _stories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            size: 52,
                            color: Color.fromARGB(153, 30, 58, 95),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No folklore stories available yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth > 700 ? 700.0 : constraints.maxWidth;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          32,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxWidth),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5F2EB),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.eco_rounded, color: Color(0xFF4C8D73)),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Stories from Northeast India',
                                            style: TextStyle(
                                              color: Color(0xFF1E3A5F),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ...List.generate(_stories.length, (index) {
                                    final story = _stories[index];
                                    final isVisible = index < _cardVisible.length ? _cardVisible[index] : true;

                                    return AnimatedOpacity(
                                      opacity: isVisible ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 420),
                                      curve: Curves.easeOutCubic,
                                      child: Transform.translate(
                                        offset: Offset(0, isVisible ? 0 : 18),
                                        child: AnimatedScale(
                                          scale: isVisible ? 1.0 : 0.96,
                                          duration: const Duration(milliseconds: 420),
                                          curve: Curves.easeOutCubic,
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 18),
                                            child: _FolkloreCard(
                                              story: story,
                                              accent: index.isEven ? const Color(0xFFE6D9B8) : const Color(0xFFE8D2F8),
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => FolkloreReaderScreen(story: story),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
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

class _FolkloreCard extends StatelessWidget {
  const _FolkloreCard({
    required this.story,
    required this.accent,
    required this.onTap,
  });

  final FolkloreStory story;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = const Color(0xFF1E3A5F);
    final softText = const Color(0xFF5F6F7A);
    final border = const Color(0xFFDEE7E1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(15, 30, 58, 95),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: story.imagePath != null
                    ? Image.asset(
                        story.imagePath!,
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 30,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 30,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: softText,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _InfoPill(icon: Icons.map_rounded, label: story.region),
                      _InfoPill(icon: Icons.translate_rounded, label: story.defaultTranslation.languageLabel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Read Story →',
                      style: TextStyle(
                        color: dark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF4C8D73)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
