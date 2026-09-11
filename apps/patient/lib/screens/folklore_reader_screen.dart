import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/folklore_story.dart';
import '../services/folklore_read_aloud_service.dart';
import '../services/locale_service.dart';
import '../widgets/folklore_theme.dart';

class FolkloreReaderScreen extends StatefulWidget {
  const FolkloreReaderScreen({
    super.key,
    required this.story,
    this.readAloudService,
  });

  final FolkloreStory story;
  final FolkloreReadAloudService? readAloudService;

  @override
  State<FolkloreReaderScreen> createState() => _FolkloreReaderScreenState();
}

class _FolkloreReaderScreenState extends State<FolkloreReaderScreen>
    with TickerProviderStateMixin {
  late String _selectedLanguageCode;
  late final FolkloreReadAloudService _readAloudService;
  late final FolkloreStoryTheme _storyTheme;

  bool _ownsService = false;
  bool _isPlaying = false;
  bool _isBookmarked = false;

  // Reading customization state
  double _fontSize = 17.5; // Scalable from 15.0 to 24.0

  // Scroll and progress tracking
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;

  // Audio equalizer animation
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _storyTheme = FolkloreStoryTheme.forKey(widget.story.title);
    final currentAppLocale = LocaleService.instance.locale;
    if (widget.story.translations.containsKey(currentAppLocale)) {
      _selectedLanguageCode = currentAppLocale;
    } else if (currentAppLocale == 'lus' && widget.story.translations.containsKey('mizo')) {
      _selectedLanguageCode = 'mizo';
    } else {
      _selectedLanguageCode = widget.story.defaultLanguageCode;
    }

    if (widget.readAloudService != null) {
      _readAloudService = widget.readAloudService!;
    } else {
      _readAloudService = FolkloreReadAloudService();
      _ownsService = true;
    }

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _scrollController.addListener(_updateReadingProgress);
  }

  void _updateReadingProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      if (_readingProgress != 1.0) setState(() => _readingProgress = 1.0);
      return;
    }
    final progress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    if ((progress - _readingProgress).abs() > 0.01) {
      setState(() {
        _readingProgress = progress;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateReadingProgress);
    _scrollController.dispose();
    _waveController.dispose();
    if (_ownsService) {
      _readAloudService.dispose();
    } else {
      _readAloudService.stop();
    }
    super.dispose();
  }

  FolkloreTranslation get selectedTranslation =>
      widget.story.translations[_selectedLanguageCode] ??
      widget.story.defaultTranslation;

  Future<void> _handleReadAloud() async {
    if (_isPlaying) {
      await _readAloudService.stop();
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('folklore.narrationPaused')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    final translation = selectedTranslation;
    final text = translation.moral != null && translation.moral!.trim().isNotEmpty
        ? '${translation.story}\n\n${translation.moral!}'
        : translation.story;
    final language = translation.languageLabel;
    final languageCode = translation.languageCode;

    setState(() {
      _isPlaying = true;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('folklore.readingAloud', {'language': language})),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ),
    );

    try {
      await _readAloudService.readAloud(
        text,
        language,
        languageCode: languageCode,
        onComplete: () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('folklore.finishedReading')),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1200),
              ),
            );
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('folklore.couldNotRead')),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1500),
              ),
            );
          }
        },
        onStateChanged: (playing) {
          if (mounted && _isPlaying != playing) {
            setState(() {
              _isPlaying = playing;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _showFontSizeModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(24, 30, 58, 95),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FolkloreStoryTheme.cardBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('folklore.readingTextSize'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FolkloreStoryTheme.darkNavy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: FolkloreStoryTheme.darkNavy,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('folklore.adjustFontSizeDesc'),
                      style: const TextStyle(
                        color: FolkloreStoryTheme.softSlate,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F7FB),
                            foregroundColor: FolkloreStoryTheme.darkNavy,
                          ),
                          onPressed: _fontSize > 15.0
                              ? () {
                                  setState(() => _fontSize = math.max(15.0, _fontSize - 1.5));
                                  setModalState(() {});
                                }
                              : null,
                          icon: const Icon(Icons.text_decrease_rounded, size: 20),
                        ),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 15.0,
                            max: 24.0,
                            divisions: 6,
                            label: '${_fontSize.toInt()} pt',
                            activeColor: FolkloreStoryTheme.sageGreen,
                            inactiveColor: FolkloreStoryTheme.cardBorder,
                            onChanged: (val) {
                              setState(() => _fontSize = val);
                              setModalState(() {});
                            },
                          ),
                        ),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F7FB),
                            foregroundColor: FolkloreStoryTheme.darkNavy,
                          ),
                          onPressed: _fontSize < 24.0
                              ? () {
                                  setState(() => _fontSize = math.min(24.0, _fontSize + 1.5));
                                  setModalState(() {});
                                }
                              : null,
                          icon: const Icon(Icons.text_increase_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: FolkloreStoryTheme.paleGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          context.tr('folklore.samplePreview', {'size': '${_fontSize.toInt()}'}),
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: _fontSize * 0.9,
                            color: FolkloreStoryTheme.darkNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableLanguages = widget.story.availableLanguageCodes;
    final theme = _storyTheme;

    return Scaffold(
      backgroundColor: FolkloreStoryTheme.canvasColor,
      body: Stack(
        children: [
          // ── 1. Subtle, Minimalist Ambient Particle Atmosphere ──────────────
          Positioned.fill(
            child: StoryAmbientBackground(theme: theme),
          ),

          // ── 2. Screen Content ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Minimalist App Bar
                _buildReaderAppBar(context, availableLanguages),

                // Subtle reading progress indicator
                LinearProgressIndicator(
                  value: _readingProgress,
                  backgroundColor: const Color(0xFFE5DFD4),
                  valueColor: const AlwaysStoppedAnimation<Color>(FolkloreStoryTheme.sageGreen),
                  minHeight: 2.0,
                ),

                // Main Reading Scrollview
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth > 700 ? 700.0 : constraints.maxWidth;

                      return SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 105),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Clean Story Header Card
                                _buildStoryHeaderCard(theme),

                                const SizedBox(height: 22),

                                // Subtle Divider
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: const Color(0xFFE2DDD2),
                                ),

                                const SizedBox(height: 22),

                                // Story Body with Classic Drop Cap
                                _buildStoryBody(),

                                // Clean Moral Card if present
                                if (selectedTranslation.moral != null &&
                                    selectedTranslation.moral!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _buildMoralCard(),
                                ],

                                const SizedBox(height: 28),

                                // Origin note
                                Center(
                                  child: Text(
                                    context.tr('folklore.oralTradition', {
                                      'region': widget.story.getLocalizedRegion(context),
                                    }),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: FolkloreStoryTheme.softSlate,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Floating Minimalist Audio Narration Bar ─────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _buildFloatingAudioBar(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderAppBar(BuildContext context, List<String> languages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FolkloreStoryTheme.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(10, 30, 58, 95),
                    blurRadius: 6,
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
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedTranslation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FolkloreStoryTheme.darkNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.story.getLocalizedRegion(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FolkloreStoryTheme.softSlate,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Bookmark Button
          IconButton(
            tooltip: _isBookmarked
                ? context.tr('folklore.bookmarked')
                : context.tr('folklore.bookmarkStory'),
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? FolkloreStoryTheme.sageGreen : FolkloreStoryTheme.darkNavy,
            ),
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBookmarked
                      ? context.tr('folklore.bookmarkSaved')
                      : context.tr('folklore.bookmarkRemoved')),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(milliseconds: 1100),
                ),
              );
            },
          ),

          // Language Selector
          if (languages.length > 1)
            PopupMenuButton<String>(
              tooltip: context.tr('settings.language'),
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FolkloreStoryTheme.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      size: 13,
                      color: FolkloreStoryTheme.sageGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedTranslation.languageLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: FolkloreStoryTheme.darkNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              onSelected: (value) {
                if (_isPlaying) {
                  _readAloudService.stop();
                  _isPlaying = false;
                }
                setState(() {
                  _selectedLanguageCode = value;
                });
              },
              itemBuilder: (context) => languages
                  .map(
                    (code) => PopupMenuItem<String>(
                      value: code,
                      child: Text(
                        widget.story.translations[code]!.languageLabel,
                        style: TextStyle(
                          color: code == _selectedLanguageCode
                              ? FolkloreStoryTheme.sageGreen
                              : FolkloreStoryTheme.darkNavy,
                          fontWeight: code == _selectedLanguageCode
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

          // Font Size Button
          IconButton(
            tooltip: context.tr('folklore.adjustFontSize'),
            icon: const Icon(
              Icons.format_size_rounded,
              color: FolkloreStoryTheme.darkNavy,
            ),
            onPressed: _showFontSizeModal,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryHeaderCard(FolkloreStoryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FolkloreStoryTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(10, 30, 58, 95),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (widget.story.imagePath != null)
            Container(
              width: 74,
              height: 94,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FolkloreStoryTheme.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  widget.story.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: FolkloreStoryTheme.paleGreen,
                    child: Center(
                      child: Icon(theme.icon, size: 28, color: FolkloreStoryTheme.darkNavy),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FolkloreStoryTheme.paleGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.story.getLocalizedRegion(context),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: FolkloreStoryTheme.darkNavy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('folklore.readingMinutes', {'minutes': theme.readingMinutes.toString()}),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FolkloreStoryTheme.softSlate,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    selectedTranslation.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FolkloreStoryTheme.darkNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.story.getLocalizedSubtitle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FolkloreStoryTheme.softSlate,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryBody() {
    final storyText = selectedTranslation.story.trim();
    if (storyText.isEmpty) return const SizedBox.shrink();

    final paragraphs = storyText.split(RegExp(r'\n\s*\n'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(paragraphs.length, (pIndex) {
        final paragraph = paragraphs[pIndex].trim();
        if (paragraph.isEmpty) return const SizedBox.shrink();

        // Opening paragraph with clean Drop Cap
        if (pIndex == 0 && paragraph.length > 2) {
          final firstLetter = paragraph[0];
          final restOfText = paragraph.substring(1);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Drop Cap
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: FolkloreStoryTheme.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    firstLetter,
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: FolkloreStoryTheme.darkNavy,
                      fontSize: _fontSize * 2.2,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    restOfText,
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: const Color(0xFF2B3A4A),
                      fontSize: _fontSize,
                      height: 1.85,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Standard paragraphs
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            paragraph,
            style: TextStyle(
              fontFamily: 'serif',
              color: const Color(0xFF2B3A4A),
              fontSize: _fontSize,
              height: 1.85,
              letterSpacing: 0.15,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMoralCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FolkloreStoryTheme.paleGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCEE3D7),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_rounded,
                size: 18,
                color: FolkloreStoryTheme.sageGreen,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('folklore.moralOfTale'),
                style: const TextStyle(
                  color: FolkloreStoryTheme.sageGreen,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            selectedTranslation.moral!,
            style: TextStyle(
              fontFamily: 'serif',
              color: FolkloreStoryTheme.darkNavy,
              fontSize: _fontSize,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAudioBar(FolkloreStoryTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: FolkloreStoryTheme.cardBorder,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(16, 30, 58, 95),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Play/Stop Button
              GestureDetector(
                onTap: _handleReadAloud,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? const Color(0xFFC44536)
                        : FolkloreStoryTheme.sageGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isPlaying
                                ? const Color(0xFFC44536)
                                : FolkloreStoryTheme.sageGreen)
                            .withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Title and narration status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isPlaying
                          ? context.tr('folklore.narrationInProgress')
                          : context.tr('folklore.readAloudStory'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FolkloreStoryTheme.darkNavy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isPlaying
                          ? context.tr('folklore.narratingIn', {
                              'language': selectedTranslation.languageLabel,
                            })
                          : context.tr('folklore.tapToListen'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FolkloreStoryTheme.softSlate,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Animated Sound Equalizer Waves
              _AnimatedSoundEqualizer(
                isPlaying: _isPlaying,
                controller: _waveController,
                color: _isPlaying
                    ? FolkloreStoryTheme.sageGreen
                    : const Color(0xFFD4DDD7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSoundEqualizer extends StatelessWidget {
  const _AnimatedSoundEqualizer({
    required this.isPlaying,
    required this.controller,
    required this.color,
  });

  final bool isPlaying;
  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * math.pi * 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final height = isPlaying
                ? 8.0 + (math.sin(t + i * 1.3).abs() * 14.0)
                : 6.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3.2,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
