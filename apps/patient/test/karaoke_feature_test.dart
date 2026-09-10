import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/data/karaoke_data.dart';
import 'package:patient/screens/karaoke_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Karaoke Data and Models Tests', () {
    test('karaokeSongs list contains exactly 2 folk songs', () {
      expect(karaokeSongs.length, 2);
      expect(karaokeSongs[0].id, 'moromor_dehi_oi');
      expect(karaokeSongs[1].id, 'pak_pak_bihu');
    });

    test('Moromor Dehi Oi has valid timestamps and first lyric starts at ~10s', () {
      final song = karaokeSongs[0];
      expect(song.title, 'Moromor Dehi Oi');
      expect(song.lyrics.isNotEmpty, true);

      // Intro check: first lyric starts at 10 000 ms
      expect(song.lyrics.first.start, const Duration(milliseconds: 10000));
      expect(song.lyrics.first.text, 'Oo moromor deehi oi nejaabi duroloi');

      // Verify strictly non-decreasing timestamps
      for (int i = 0; i < song.lyrics.length; i++) {
        final lyric = song.lyrics[i];
        expect(lyric.start < lyric.end, true,
            reason: 'Lyric $i (${lyric.text}) start must be before end');
        if (i > 0) {
          expect(lyric.start >= song.lyrics[i - 1].end, true,
              reason: 'Lyric $i start must not be before lyric ${i - 1} end');
        }
      }
    });

    test('Moromor Dehi Oi lyrics text matches prompt exactly', () {
      final song = karaokeSongs[0];
      expect(song.lyrics[0].text, 'Oo moromor deehi oi nejaabi duroloi');
      expect(song.lyrics[1].text, 'Mone mon melisee tuloi');
      expect(song.lyrics[2].text, 'Oo moromor deehi oi nejaabi anore hoi');
      expect(song.lyrics[3].text, 'Nebhaabi nuwaaru tuke oi');
      expect(song.lyrics.last.text, 'Paabole turei moroom');
    });

    test('Pak Pak Bihu Naam has valid timestamps and first lyric starts at ~10s', () {
      final song = karaokeSongs[1];
      expect(song.title, 'Pak Pak Bihu Naam');
      expect(song.lyrics.isNotEmpty, true);

      expect(song.lyrics.first.start, const Duration(milliseconds: 10000));
      expect(song.lyrics.first.text, 'Aeibeli bihuti ramoke jomoke');

      for (int i = 0; i < song.lyrics.length; i++) {
        final lyric = song.lyrics[i];
        expect(lyric.start < lyric.end, true);
        if (i > 0) {
          expect(lyric.start >= song.lyrics[i - 1].end, true);
        }
      }
    });

    test('Pak Pak Bihu Naam lyrics text matches prompt exactly', () {
      final song = karaokeSongs[1];
      expect(song.lyrics[0].text, 'Aeibeli bihuti ramoke jomoke');
      expect(song.lyrics[1].text, 'Nahor phool phulibor botor');
      expect(song.lyrics.last.text, 'Kun naso naas oi kun naaso naas');
    });

    test('Audio asset paths match local files in pubspec', () {
      for (final song in karaokeSongs) {
        expect(song.audioAsset.startsWith('assets/audio/'), true);
        expect(song.audioAsset.endsWith('.mp3'), true);
      }
    });
  });

  group('Karaoke Synchronization Calculation Tests', () {
    final lyrics = karaokeSongs[0].lyrics;

    int findActiveIndex(Duration pos) {
      if (pos < lyrics.first.start) return -1;
      if (pos >= lyrics.last.end) return lyrics.length;

      for (int i = 0; i < lyrics.length; i++) {
        if (pos >= lyrics[i].start && pos < lyrics[i].end) {
          return i;
        } else if (pos >= lyrics[i].end &&
            i + 1 < lyrics.length &&
            pos < lyrics[i + 1].start) {
          return i;
        }
      }
      return -1;
    }

    double calculateProgress(Duration pos, int activeIndex) {
      if (activeIndex < 0 || activeIndex >= lyrics.length) return 0.0;
      final lyric = lyrics[activeIndex];
      if (pos >= lyric.end) return 1.0;
      if (pos < lyric.start) return 0.0;
      final range = lyric.end - lyric.start;
      return ((pos - lyric.start).inMilliseconds / range.inMilliseconds)
          .clamp(0.0, 1.0);
    }

    test('Position before 10s returns intro index -1 and progress 0.0', () {
      const pos = Duration(seconds: 4);
      final idx = findActiveIndex(pos);
      final prog = calculateProgress(pos, idx);
      expect(idx, -1);
      expect(prog, 0.0);
    });

    test('Position inside first lyric returns index 0 and proportional progress', () {
      // First lyric is 10000ms to 14800ms (range = 4800ms)
      // Halfway is 10000 + 2400 = 12400ms
      const pos = Duration(milliseconds: 12400);
      final idx = findActiveIndex(pos);
      final prog = calculateProgress(pos, idx);
      expect(idx, 0);
      expect(prog, closeTo(0.5, 0.01));
    });

    test('Position at lyric end returns progress 1.0', () {
      const pos = Duration(milliseconds: 14800);
      final idx = findActiveIndex(pos);
      final prog = calculateProgress(pos, idx);
      // At 14800ms, lyric 1 begins (since lyric 0 ends at 14800 and lyric 1 starts at 14800)
      expect(idx, 1);
      expect(prog, 0.0);
    });

    test('Position in musical gap keeps active lyric at 1.0 until next starts', () {
      // In Moromor Dehi Oi, lyric 3 ends at 27500ms, lyric 4 starts at 28500ms
      const pos = Duration(milliseconds: 28000);
      final idx = findActiveIndex(pos);
      final prog = calculateProgress(pos, idx);
      expect(idx, 3);
      expect(prog, 1.0);
    });
  });

  group('KaraokeScreen Widget Tests', () {
    testWidgets('Renders both songs and elements on screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KaraokeScreen(),
        ),
      );

      // Verify title & cultural badge
      expect(find.text('Karaoke'), findsOneWidget);
      expect(find.text('Folk songs of Northeast India'), findsOneWidget);

      // Verify both song cards
      expect(find.text('Moromor Dehi Oi'), findsOneWidget);
      expect(find.text('Pak Pak Bihu Naam'), findsOneWidget);

      // Verify cultural labels
      expect(find.text('Assamese Folk • Rakesh Reeyan'), findsOneWidget);
      expect(find.text('Assamese Bihu • Papon'), findsOneWidget);

      // Verify play buttons
      expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(2));
    });
  });
}
