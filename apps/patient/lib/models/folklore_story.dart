import 'package:flutter/widgets.dart';

import '../services/locale_service.dart';

class FolkloreStory {
  const FolkloreStory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.region,
    required this.translations,
    this.imagePath,
  });

  final String id;
  final String title;
  final String subtitle;
  final String region;
  final Map<String, FolkloreTranslation> translations;
  final String? imagePath;

  String get defaultLanguageCode =>
      translations.containsKey('en') ? 'en' : translations.keys.first;

  FolkloreTranslation get defaultTranslation =>
      translations[defaultLanguageCode] ?? translations.values.first;

  List<String> get availableLanguageCodes => translations.keys.toList();

  String getLocalizedTitle(BuildContext context) {
    final cleanId = id.replaceAll('-', '_');
    // Map known id variants if needed
    final normalizedId = cleanId == 'the_orphan_and_the_giant' ? 'orphan_giant' : cleanId;
    final key = 'folklore.story_${normalizedId}_title';
    final val = context.tr(key);
    if (val.isNotEmpty && val != key) return val;

    final lang = LocaleService.instance.locale;
    if (translations.containsKey(lang)) {
      return translations[lang]!.title;
    }
    return title;
  }

  String getLocalizedSubtitle(BuildContext context) {
    final cleanId = id.replaceAll('-', '_');
    final normalizedId = cleanId == 'the_orphan_and_the_giant' ? 'orphan_giant' : cleanId;
    final key = 'folklore.story_${normalizedId}_subtitle';
    final val = context.tr(key);
    if (val.isNotEmpty && val != key) return val;
    return subtitle;
  }

  String getLocalizedRegion(BuildContext context) {
    final regLower = region.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final key = 'regions.$regLower';
    final val = context.tr(key);
    return (val.isNotEmpty && val != key) ? val : region;
  }
}

class FolkloreTranslation {
  const FolkloreTranslation({
    required this.languageCode,
    required this.languageLabel,
    required this.title,
    required this.story,
    this.moral,
  });

  final String languageCode;
  final String languageLabel;
  final String title;
  final String story;
  final String? moral;
}
