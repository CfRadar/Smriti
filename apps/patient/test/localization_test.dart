import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patient/l10n/app_translations.dart';
import 'package:patient/services/locale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppTranslations Dictionary Integrity', () {
    const supportedLangs = ['en', 'hi', 'as', 'bn', 'lus', 'mni'];

    test('All 6 target languages are registered with metadata', () {
      expect(AppTranslations.languages.keys, containsAll(supportedLangs));
      for (final lang in supportedLangs) {
        expect(AppTranslations.languages[lang]?['name'], isNotNull);
        expect(AppTranslations.languages[lang]?['nativeName'], isNotNull);
      }
    });

    test('All 6 languages have complete and non-empty translation strings', () {
      final enKeys = AppTranslations.strings['en']!.keys.toSet();
      expect(enKeys.length, greaterThan(150));

      for (final lang in supportedLangs) {
        final langMap = AppTranslations.strings[lang];
        expect(langMap, isNotNull, reason: 'Language $lang map must exist');

        final langKeys = langMap!.keys.toSet();
        final missing = enKeys.difference(langKeys);
        expect(missing, isEmpty,
            reason: 'Language $lang is missing keys: $missing');

        for (final entry in langMap.entries) {
          expect(entry.value.trim(), isNotEmpty,
              reason: 'Key ${entry.key} in $lang must not be empty');
        }
      }
    });
  });

  group('LocaleService Functionality & Reactivity', () {
    test('Default locale is English', () async {
      final service = LocaleService.instance;
      await service.init();
      expect(service.locale, equals('en'));
      expect(service.currentLanguageName, equals('English'));
      expect(service.currentLanguageNativeName, equals('English'));
    });

    test('Switching locale updates state and notifies listeners', () async {
      final service = LocaleService.instance;
      bool notified = false;
      void listener() {
        notified = true;
      }

      service.addListener(listener);

      // Switch to Hindi
      await service.setLocale('hi');
      expect(service.locale, equals('hi'));
      expect(service.currentLanguageNativeName, equals('हिंदी'));
      expect(notified, isTrue);

      // Verify translations in Hindi
      expect(service.translate('nav.games'), equals('खेल'));
      expect(service.translate('common.close'), equals('बंद करें'));
      expect(service.translate('settings.language'), equals('भाषा'));

      // Switch to Assamese
      notified = false;
      await service.setLocale('as');
      expect(service.locale, equals('as'));
      expect(service.currentLanguageNativeName, equals('অসমীয়া'));
      expect(service.translate('nav.games'), equals('খেল'));
      expect(notified, isTrue);

      // Switch to Bengali
      await service.setLocale('bn');
      expect(service.locale, equals('bn'));
      expect(service.currentLanguageNativeName, equals('বাংলা'));
      expect(service.translate('nav.games'), equals('খেলা'));

      // Switch to Mizo
      await service.setLocale('lus');
      expect(service.locale, equals('lus'));
      expect(service.currentLanguageNativeName, equals('Mizo'));
      expect(service.translate('nav.games'), equals('Infiamnate'));

      // Switch to Manipuri
      await service.setLocale('mni');
      expect(service.locale, equals('mni'));
      expect(service.currentLanguageNativeName, equals('মৈতৈলোন্'));
      expect(service.translate('nav.games'), equals('শান-খোৎ'));

      // Reset back to English
      await service.setLocale('en');
      expect(service.locale, equals('en'));

      service.removeListener(listener);
    });

    test('Dynamic parameter interpolation works correctly', () async {
      final service = LocaleService.instance;

      // English count
      await service.setLocale('en');
      expect(service.translate('games.gameCount', {'count': '6'}),
          equals('6 Games'));

      // Hindi count
      await service.setLocale('hi');
      expect(service.translate('games.gameCount', {'count': '6'}),
          equals('6 खेल'));

      // Assamese count
      await service.setLocale('as');
      expect(service.translate('games.gameCount', {'count': '6'}),
          equals('6 টা খেল'));

      // Bengali count
      await service.setLocale('bn');
      expect(service.translate('games.gameCount', {'count': '6'}),
          equals('6টি খেলা'));

      // Reset to English
      await service.setLocale('en');
    });

    test('Gracefully handles unknown keys and fallback', () async {
      final service = LocaleService.instance;
      await service.setLocale('hi');

      // Key that doesn't exist anywhere returns the key itself
      expect(service.translate('non_existent_key_123'),
          equals('non_existent_key_123'));

      // Reset to English
      await service.setLocale('en');
    });

    test('All game strings and game completion dialogs translate across 6 languages', () async {
      final service = LocaleService.instance;

      const gameKeys = [
        'gameplay.finalScore',
        'gameplay.bestScore',
        'gameplay.home',
        'gameplay.playAgain',
        'gameplay.greatJob',
        'gameplay.activityCompleted',
        'gameplay.gamePaused',
        'gameplay.resumeSession',
        'gameplay.endSession',
        'gameplay.accuracy',
        'gameplay.avgSpeed',
        'gameplay.bestStreak',
        'gameplay.getReady',
        'gameplay.selectDifficulty',
        'gameplay.difficultySettings',
        'gameplay.chooseStartingChallenge',
        'gameplay.traditionalKang',
        'gameplay.tapOnTarget',
        'gameplay.danceStages',
        'games.pictureRecognition',
        'games.patternMemory',
        'games.kingShanaba',
        'games.bambooDance',
      ];

      for (final lang in ['en', 'hi', 'as', 'bn', 'lus', 'mni']) {
        await service.setLocale(lang);
        for (final k in gameKeys) {
          final translated = service.translate(k);
          expect(translated, isNotEmpty,
              reason: 'Key $k must be non-empty in language $lang');
          expect(translated, isNot(equals(k)),
              reason: 'Key $k must not fall back to its raw key name in $lang');
        }

        // Test dynamic parameter substitutions in games
        final roundText = service.translate('gameplay.round', {'round': '2', 'total': '5'});
        expect(roundText, contains('2'));
        expect(roundText, contains('5'));

        final levelText = service.translate('gameplay.level', {'level': '3'});
        expect(levelText, contains('3'));
      }

      await service.setLocale('en');
    });

    test('All 35 cultural image items and categories translate across 6 languages', () async {
      final service = LocaleService.instance;
      const sampleItemIds = [
        'animal_rhino',
        'animal_sangai',
        'animal_golden_langur',
        'animal_mithun',
        'animal_hornbill',
        'cloth_naga_headgear',
        'cloth_jaapi',
        'cloth_mizo_puan',
        'food_bhoot_jolokia',
        'food_assamese_thali',
        'item_cane_basket',
        'item_bell_metal',
        'item_majuli_mask',
        'item_bihu_dhol',
      ];

      for (final lang in ['en', 'hi', 'as', 'bn', 'lus', 'mni']) {
        await service.setLocale(lang);
        for (final id in sampleItemIds) {
          final nameKey = 'items.$id.name';
          final regionKey = 'items.$id.region';
          
          final name = service.translate(nameKey);
          final region = service.translate(regionKey);

          expect(name, isNotEmpty, reason: '$nameKey must be translated in $lang');
          expect(name, isNot(equals(nameKey)), reason: '$nameKey must not return raw key in $lang');
          expect(region, isNotEmpty, reason: '$regionKey must be translated in $lang');
          expect(region, isNot(equals(regionKey)), reason: '$regionKey must not return raw key in $lang');
        }

        // Verify cultural categories
        expect(service.translate('gameplay.categoryFauna'), isNotEmpty);
        expect(service.translate('gameplay.categoryAttire'), isNotEmpty);
        expect(service.translate('gameplay.categoryFood'), isNotEmpty);
        expect(service.translate('gameplay.categoryCraft'), isNotEmpty);

        // Verify game interaction messages
        expect(service.translate('gameplay.memorizePattern'), isNotEmpty);
        expect(service.translate('gameplay.patternCompleted'), isNotEmpty);
        expect(service.translate('gameplay.targetStruck', {'pts': '100'}), contains('100'));
      }

      await service.setLocale('en');
    });
  });
}
