import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/folklore_story.dart';

class FolkloreService {
  FolkloreService._();

  static final FolkloreService instance = FolkloreService._();

  static const String _defaultLanguage = 'en';

  Future<List<FolkloreStory>> loadStories() async {
    try {
      final text = await rootBundle.loadString('assets/research.txt');
      final parsed = _parseResearchText(text);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    } catch (_) {
      // Fall back gracefully if the file is not available in the build.
    }

    return const <FolkloreStory>[];
  }

  List<FolkloreStory> _parseResearchText(String rawText) {
    final blocks = _splitByStoryBlocks(rawText);
    final groupedStories = <String, _StoryDraft>{};
    String? lastEnglishTitle;

    for (final block in blocks) {
      final title = _extractTitle(block);
      if (title == null || title.isEmpty) {
        continue;
      }

      final isEnglishTitle = _isEnglishTitle(title);
      final key = _storyGroupKey(title, isEnglishTitle, lastEnglishTitle);

      final draft = groupedStories.putIfAbsent(
        key,
        () => _StoryDraft(
          title: isEnglishTitle ? title : (lastEnglishTitle ?? title),
          subtitle: _extractSubtitle(block),
          translations: <String, FolkloreTranslation>{},
        ),
      );

      if (isEnglishTitle) {
        lastEnglishTitle = title;
      }

      final translations = _extractTranslations(block, draft.title);
      for (final entry in translations.entries) {
        draft.translations[entry.key] = entry.value;
      }
    }

    final stories = groupedStories.values.map((draft) {
      final ordered = <String, FolkloreTranslation>{};
      final preferredOrder = <String>[_defaultLanguage, 'hi', 'as', 'bn', 'lus', 'mni', 'kh', 'ang', 'kar', 'mizo'];

      for (final key in preferredOrder) {
        if (draft.translations.containsKey(key)) {
          ordered[key] = draft.translations[key]!;
        }
      }

      for (final key in draft.translations.keys) {
        if (!ordered.containsKey(key)) {
          ordered[key] = draft.translations[key]!;
        }
      }

      return FolkloreStory(
        id: draft.title
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'-+'), '-')
            .replaceAll(RegExp(r'^-|-$'), ''),
        title: draft.title,
        subtitle: draft.subtitle,
        region: _detectRegion(draft.title, draft.subtitle),
        imagePath: _detectImagePath(draft.title),
        translations: ordered,
      );
    }).toList();

    return stories;
  }

  List<String> _splitByStoryBlocks(String rawText) {
    final lines = rawText.replaceAll('\r\n', '\n').split('\n');
    final blocks = <String>[];
    final active = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      final isStoryHeader = trimmed.startsWith('# ') && !trimmed.startsWith('## ') && !trimmed.startsWith('### ');

      if (isStoryHeader) {
        if (active.isNotEmpty) {
          blocks.add(active.toString().trim());
        }
        active.clear();
        active.writeln(trimmed);
        continue;
      }

      if (active.isNotEmpty || trimmed.isNotEmpty) {
        active.writeln(trimmed);
      }
    }

    if (active.isNotEmpty) {
      blocks.add(active.toString().trim());
    }

    return blocks;
  }

  String? _extractTitle(String block) {
    for (final line in block.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ') && !trimmed.startsWith('## ') && !trimmed.startsWith('### ')) {
        return trimmed.substring(2).trim();
      }
    }
    return null;
  }

  String _extractSubtitle(String block) {
    for (final line in block.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('## ')) {
        return trimmed.substring(3).trim();
      }
    }
    return 'Traditional folklore story';
  }

  Map<String, FolkloreTranslation> _extractTranslations(String block, String storyTitle) {
    final lines = block.split('\n');
    final translations = <String, FolkloreTranslation>{};
    String? currentLabel;
    final conversation = StringBuffer();
    String? currentMoral;

    void finalizeSection() {
      if (currentLabel == null || currentLabel.toUpperCase() == 'MORAL') {
        return;
      }

      final code = _languageCodeForLabel(currentLabel);
      final text = conversation.toString().trim();
      if (text.isEmpty) {
        return;
      }

      translations[code] = FolkloreTranslation(
        languageCode: code,
        languageLabel: _languageLabelForCode(code, currentLabel),
        title: storyTitle,
        story: text,
        moral: currentMoral?.trim(),
      );
    }

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.startsWith('### ')) {
        finalizeSection();
        final label = trimmed.substring(4).trim();
        if (label.toUpperCase() == 'MORAL') {
          currentLabel = 'MORAL';
          currentMoral = '';
        } else {
          currentLabel = label;
          currentMoral = null;
        }
        conversation.clear();
        continue;
      }

      if (currentLabel == null) {
        continue;
      }

      if (currentLabel.toUpperCase() == 'MORAL') {
        if (currentMoral == null || currentMoral.isEmpty) {
          currentMoral = trimmed;
        } else {
          currentMoral = '$currentMoral\n$trimmed';
        }
        continue;
      }

      if (trimmed.isEmpty) {
        if (conversation.isNotEmpty) {
          conversation.write('\n');
        }
        continue;
      }

      if (conversation.isNotEmpty) {
        conversation.write('\n');
      }
      conversation.write(trimmed);
    }

    finalizeSection();

    if (currentMoral != null && currentMoral.trim().isNotEmpty) {
      final moralText = currentMoral.trim();
      for (final code in translations.keys.toList()) {
        final existing = translations[code]!;
        if (existing.moral == null || existing.moral!.isEmpty) {
          translations[code] = FolkloreTranslation(
            languageCode: existing.languageCode,
            languageLabel: existing.languageLabel,
            title: existing.title,
            story: existing.story,
            moral: moralText,
          );
        }
      }
    }

    return translations;
  }

  String? _detectImagePath(String title) {
    final upper = title.toUpperCase();
    if (upper.contains('KHAMBA')) {
      return 'assets/images/khamba and tombi.jpg';
    }
    if (upper.contains('THLEN')) {
      return 'assets/images/u theln.jpg';
    }
    if (upper.contains('HUNCHIBILI')) {
      return 'assets/images/hunchibilli.jpg';
    }
    if (upper.contains('ORPHAN')) {
      return 'assets/images/orphan and giant.jpg';
    }
    return null;
  }

  bool _isEnglishTitle(String title) {
    return RegExp(r'^[A-Za-z0-9\s&/\-:()\.]').hasMatch(title) ||
        title.toUpperCase().contains('THE ') ||
        title.toUpperCase().contains('U ') ||
        title.toUpperCase().contains('KHAMBA') ||
        title.toUpperCase().contains('HUNCHIBILI');
  }

  String _storyGroupKey(String title, bool isEnglishTitle, String? lastEnglishTitle) {
    if (isEnglishTitle) {
      return title.trim().toUpperCase();
    }

    if (lastEnglishTitle != null) {
      return lastEnglishTitle.trim().toUpperCase();
    }

    return title.trim().toUpperCase();
  }

  String _detectRegion(String title, String subtitle) {
    final text = '$title\n$subtitle';
    for (final value in <String>[
      'Meghalaya',
      'Manipur',
      'Nagaland',
      'Assam',
      'Mizoram',
      'Tripura',
      'Arunachal',
      'Khasi',
      'Naga',
      'Karbi',
      'Bodo',
      'Mising',
      'Garo',
      'Lepcha',
      'Ao',
    ]) {
      if (text.contains(value)) {
        return value;
      }
    }

    return 'Northeast India';
  }

  String _languageCodeForLabel(String label) {
    final value = label.trim().toLowerCase();
    if (value.contains('english')) return 'en';
    if (value.contains('hindi')) return 'hi';
    if (value.contains('assam') || value.contains('assamese')) return 'as';
    if (value.contains('bengali') || value.contains('bangla')) return 'bn';
    if (value.contains('mizo') || value.contains('lus')) return 'lus';
    if (value.contains('meitei') || value.contains('manipuri') || value.contains('mni')) return 'mni';
    if (value.contains('khasi')) return 'kh';
    if (value.contains('angami')) return 'ang';
    if (value.contains('karbi')) return 'kar';
    if (value.contains('lepcha')) return 'lepcha';
    if (value.contains('mising')) return 'mising';
    if (value.contains('garo')) return 'garo';
    if (value.contains('ao')) return 'ao';
    return value.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  String _languageLabelForCode(String code, String fallback) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      case 'as':
        return 'অসমীয়া';
      case 'bn':
        return 'বাংলা';
      case 'lus':
      case 'mizo':
        return 'Mizo';
      case 'mni':
        return 'Meitei / Manipuri';
      case 'kh':
        return 'Khasi';
      case 'ang':
        return 'Angami';
      case 'kar':
        return 'Karbi';
      case 'lepcha':
        return 'Lepcha';
      case 'mising':
        return 'Mising';
      case 'garo':
        return 'Garo';
      case 'ao':
        return 'Ao';
      default:
        return fallback;
    }
  }

  @visibleForTesting
  static String normalizeTitle(String value) {
    return value.trim();
  }
}

class _StoryDraft {
  _StoryDraft({
    required this.title,
    required this.subtitle,
    required this.translations,
  });

  final String title;
  final String subtitle;
  final Map<String, FolkloreTranslation> translations;
}
