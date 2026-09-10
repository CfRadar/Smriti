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
