// lib/services/locale_service.dart

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';

/// Centralized localization service providing reactive language switching,
/// persistence, and string translation across the entire Smriti application.
class LocaleService extends ChangeNotifier {
  LocaleService._internal();

  /// Singleton instance of LocaleService
  static final LocaleService instance = LocaleService._internal();

  static const String _prefKeyLanguage = 'smriti_selected_language_code';

  String _locale = 'en';

  /// Currently active ISO language code (e.g. 'en', 'hi', 'as', 'bn', 'lus', 'mni')
  String get locale => _locale;

  /// Current language details
  Map<String, String> get currentLanguageInfo =>
      AppTranslations.languages[_locale] ?? AppTranslations.languages['en']!;

  /// Current language display name
  String get currentLanguageName => currentLanguageInfo['name'] ?? 'English';

  /// Current language native script name
  String get currentLanguageNativeName =>
      currentLanguageInfo['nativeName'] ?? 'English';

  /// List of all supported language definitions
  List<Map<String, String>> get supportedLanguages =>
      AppTranslations.languages.entries
          .map((e) => {
                'code': e.key,
                'name': e.value['name'] ?? e.key,
                'nativeName': e.value['nativeName'] ?? e.key,
              })
          .toList();

  /// Initializes the service by loading persisted user language preference
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKeyLanguage);
      if (savedCode != null && AppTranslations.languages.containsKey(savedCode)) {
        _locale = savedCode;
      }
    } catch (_) {
      _locale = 'en';
    }
  }

  /// Changes the current app language and notifies all listeners across the app
  Future<void> setLocale(String languageCode) async {
    if (!AppTranslations.languages.containsKey(languageCode)) return;
    if (_locale == languageCode) return;

    _locale = languageCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLanguage, languageCode);
    } catch (_) {}
  }

  /// Translates a given key with optional dynamic variable interpolation
  /// e.g. translate('games.gameCount', {'count': '6'})
  String translate(String key, [Map<String, String>? params]) {
    // 1. Look up in current locale
    String? translation = AppTranslations.strings[_locale]?[key];

    // 2. Fallback to English if not found
    if (translation == null || translation.isEmpty) {
      translation = AppTranslations.strings['en']?[key];
    }

    // 3. Fallback to key itself if not found anywhere
    if (translation == null) {
      return key;
    }

    // 4. Interpolate parameters: {param_name} -> param_value
    if (params != null && params.isNotEmpty) {
      var result = translation;
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue);
      });
      return result;
    }

    return translation;
  }
}

/// Convenience extension for calling `context.tr('key')` anywhere in the widget tree.
extension TranslationContextExtension on BuildContext {
  String tr(String key, [Map<String, String>? params]) =>
      LocaleService.instance.translate(key, params);
}
