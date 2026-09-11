// lib/models/karaoke_song.dart
//
// Karaoke data models for the Smriti patient app.
// KaraokeLyric: a single lyric line with start/end timestamps.
// KaraokeSong:  the full song descriptor (id, title, audioAsset, lyrics).

import 'package:flutter/widgets.dart';

import '../services/locale_service.dart';

/// A single lyric line with its start and end playback positions.
///
/// Timestamps are intentionally stored as [Duration] so that
/// karaoke_data.dart can use readable millisecond literals.
class KaraokeLyric {
  final Duration start;
  final Duration end;
  final String text;

  const KaraokeLyric({
    required this.start,
    required this.end,
    required this.text,
  });
}

/// Full descriptor for a karaoke song.
///
/// [audioAsset] must match a path declared in pubspec.yaml `assets:`.
/// [lyrics] is the ordered list of [KaraokeLyric] lines.
class KaraokeSong {
  final String id;
  final String title;
  final String culturalLabel;
  final String audioAsset;
  final List<KaraokeLyric> lyrics;

  const KaraokeSong({
    required this.id,
    required this.title,
    required this.culturalLabel,
    required this.audioAsset,
    required this.lyrics,
  });

  String getLocalizedTitle(BuildContext context) {
    final key = 'karaoke.song_${id}_title';
    final val = context.tr(key);
    return (val.isNotEmpty && val != key) ? val : title;
  }

  String getLocalizedCulturalLabel(BuildContext context) {
    final key = 'karaoke.song_${id}_label';
    final val = context.tr(key);
    return (val.isNotEmpty && val != key) ? val : culturalLabel;
  }
}
