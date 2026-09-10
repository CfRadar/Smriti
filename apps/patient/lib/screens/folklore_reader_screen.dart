import 'dart:async';

import 'package:flutter/material.dart';

import '../models/folklore_story.dart';
import '../services/folklore_read_aloud_service.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _readAloudController;
  late String _selectedLanguageCode;
  late final FolkloreReadAloudService _readAloudService;
  bool _ownsService = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = widget.story.defaultLanguageCode;
    if (widget.readAloudService != null) {
      _readAloudService = widget.readAloudService!;
    } else {
      _readAloudService = FolkloreReadAloudService();
      _ownsService = true;
    }
    _readAloudController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _readAloudController.dispose();
    if (_ownsService) {
      _readAloudService.dispose();
    } else {
      _readAloudService.stop();
    }
    super.dispose();
  }

  FolkloreTranslation get selectedTranslation =>
      widget.story.translations[_selectedLanguageCode] ?? widget.story.defaultTranslation;

  Future<void> _handleReadAloud() async {
    if (_isPlaying) {
      await _readAloudService.stop();
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stopped reading aloud.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1200),
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
        content: Text('Reading story aloud in $language...'),
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
              const SnackBar(
                content: Text('Finished reading story.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(milliseconds: 1200),
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
              const SnackBar(
                content: Text('Could not read aloud. Please check network connection.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(milliseconds: 1500),
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

  @override
  Widget build(BuildContext context) {
    final dark = const Color(0xFF1E3A5F);
    final textSoft = const Color(0xFF586A7A);
    final badge = const Color(0xFFEAF2EC);
    final accent = const Color(0xFF4C8D73);

    final available = widget.story.availableLanguageCodes;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F1E7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E3A5F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Folklore',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (available.length > 1)
            PopupMenuButton<String>(
              tooltip: 'Select language',
              icon: const Icon(Icons.language_rounded, color: Color(0xFF1E3A5F)),
              onSelected: (value) {
                if (_isPlaying) {
                  _readAloudService.stop();
                  _isPlaying = false;
                }
                setState(() {
                  _selectedLanguageCode = value;
                });
              },
              itemBuilder: (context) => available
                  .map(
                    (code) => PopupMenuItem<String>(
                      value: code,
                      child: Text(
                        widget.story.translations[code]!.languageLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 700 ? 700.0 : constraints.maxWidth;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedTranslation.title,
                                  style: const TextStyle(
                                    color: Color(0xFF1E3A5F),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.story.subtitle,
                                  style: TextStyle(
                                    color: textSoft,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: badge,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              selectedTranslation.languageLabel,
                              style: TextStyle(
                                color: dark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedBuilder(
                          animation: _readAloudController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isPlaying ? _readAloudController.value : 1.0,
                              child: child,
                            );
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: _handleReadAloud,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(31, 76, 141, 115),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color.fromARGB(90, 76, 141, 115)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                      color: accent,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isPlaying ? 'Stop Reading' : 'Read Aloud',
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: const Color(0xFFD9D3C7),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        selectedTranslation.story,
                        style: const TextStyle(
                          color: Color(0xFF2B3A4A),
                          fontSize: 17,
                          height: 1.8,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (selectedTranslation.moral != null && selectedTranslation.moral!.trim().isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Divider(height: 1),
                        const SizedBox(height: 18),
                        const Text(
                          'MORAL',
                          style: TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedTranslation.moral!,
                          style: const TextStyle(
                            color: Color(0xFF2B3A4A),
                            fontSize: 17,
                            height: 1.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
