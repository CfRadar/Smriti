// lib/data/karaoke_data.dart
//
// ════════════════════════════════════════════════════════════════════════════
// ALL KARAOKE TIMESTAMPS LIVE HERE.
// Edit this file to adjust any lyric timing.
// ════════════════════════════════════════════════════════════════════════════
//
// Timestamp guide:
//   • First 10 seconds = INTRO (no active lyric)
//   • First lyric starts at 10 000 ms
//   • Durations are proportional to line length
//     – Short line  ≈ 3 000–4 000 ms
//     – Medium line ≈ 4 000–5 500 ms
//     – Long line   ≈ 5 500–7 000 ms
//   • Repeated lines carry similar durations to their originals
//   • Slightly longer gaps are inserted at natural musical phrase breaks
// ════════════════════════════════════════════════════════════════════════════

import '../models/karaoke_song.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SONG 1 · "Moromor Dehi Oi" · Assamese Folk / Rakesh Reeyan
// ─────────────────────────────────────────────────────────────────────────────
//
// TO EDIT: change the Duration values below.
// Tip: milliseconds = seconds × 1000
//
const List<KaraokeLyric> moromorDehiOiLyrics = [
  // ── Verse 1 ────────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 10000),
    end:   Duration(milliseconds: 14800),
    text:  'Oo moromor deehi oi nejaabi duroloi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 14800),
    end:   Duration(milliseconds: 18500),
    text:  'Mone mon melisee tuloi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 18500),
    end:   Duration(milliseconds: 23300),
    text:  'Oo moromor deehi oi nejaabi anore hoi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 23300),
    end:   Duration(milliseconds: 27500),
    text:  'Nebhaabi nuwaaru tuke oi',
  ),

  // ── Bridge 1 ───────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 28500),   // slight pause after verse
    end:   Duration(milliseconds: 33000),
    text:  'Nelaage nelaage bohu jugoloi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 33000),
    end:   Duration(milliseconds: 37000),
    text:  'Aaxhaa bandhu ei jonomor',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 37000),
    end:   Duration(milliseconds: 41500),
    text:  'Nuwarileu kobi mukk ebarole',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 41500),
    end:   Duration(milliseconds: 45000),
    text:  'Misaa holeu xuni rom',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 45000),
    end:   Duration(milliseconds: 48500),
    text:  'Tuke saai moromot',
  ),

  // ── Chorus 1 ───────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 50000),   // musical pause before chorus
    end:   Duration(milliseconds: 54800),
    text:  'Oo moromor dehi oi nejaabi duroloi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 54800),
    end:   Duration(milliseconds: 58500),
    text:  'Mone mon melise tuloi',
  ),

  // ── Chorus 1 repeat ────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 59500),
    end:   Duration(milliseconds: 64300),
    text:  'Oo moromor dehi oi nejaabi duroloi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 64300),
    end:   Duration(milliseconds: 68500),
    text:  'Mone mon melise tuloi',
  ),

  // ── Verse 2 ────────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 70000),
    end:   Duration(milliseconds: 75000),
    text:  'Sokure aator hole monoru aator hobo',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 75000),
    end:   Duration(milliseconds: 79500),
    text:  'Buli koi hokoluwe hunisoo nee',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 79500),
    end:   Duration(milliseconds: 83500),
    text:  'Toiu ki aatori jaabi nee',
  ),

  // ── Verse 2 cont. ──────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 85000),
    end:   Duration(milliseconds: 90000),
    text:  'Bukure humajote rakhisu hojotone',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 90000),
    end:   Duration(milliseconds: 95500),
    text:  'Kekekoi bujaau tuke koo bhalpau kimaan',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 95500),
    end:   Duration(milliseconds: 99500),
    text:  'Nejaanu tuke kobole',
  ),

  // ── Bridge 2 ───────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 101000),
    end:   Duration(milliseconds: 105500),
    text:  'Oo nelaage nelaage bohu jugoloi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 105500),
    end:   Duration(milliseconds: 109500),
    text:  'Aaxa mathu ai jonomor',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 109500),
    end:   Duration(milliseconds: 114000),
    text:  'Oo nuwarileu kobi mukk ebarole',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 114000),
    end:   Duration(milliseconds: 118000),
    text:  'Misaa holeu huni lom tuke saai moromot',
  ),

  // ── Verse 3 ────────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 120000),
    end:   Duration(milliseconds: 124500),
    text:  'Bhukore emuthi bhaat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 124500),
    end:   Duration(milliseconds: 129000),
    text:  'Moromor ekhaari maat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 129000),
    end:   Duration(milliseconds: 135000),
    text:  'Taakei bisaari pau nijok jaanone',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 135000),
    end:   Duration(milliseconds: 140000),
    text:  'Taakei bisaari pau nijok',
  ),

  // ── Verse 3 cont. ──────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 141500),
    end:   Duration(milliseconds: 146000),
    text:  'Nejaanu morom ki',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 146000),
    end:   Duration(milliseconds: 150500),
    text:  'Morome bisaare ki',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 150500),
    end:   Duration(milliseconds: 156500),
    text:  'Jaanu mathu toie tu nijor bujone',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 156500),
    end:   Duration(milliseconds: 162000),
    text:  'Jaanu mathu toie tu nijor',
  ),

  // ── Outro ──────────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 164000),
    end:   Duration(milliseconds: 170000),
    text:  'Tuke loi rosisu hopun nojonaake',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 170000),
    end:   Duration(milliseconds: 175000),
    text:  'Aaxa murr ture hridoyot',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 175000),
    end:   Duration(milliseconds: 181000),
    text:  'Jodiu bukute ase bhoi nepaau buli',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 181000),
    end:   Duration(milliseconds: 186500),
    text:  'Tothapitu ishwarak khatisu',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 186500),
    end:   Duration(milliseconds: 193000),
    text:  'Paabole turei moroom',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SONG 2 · "Pak Pak Bihu Naam" · Assamese Bihu / Papon
// ─────────────────────────────────────────────────────────────────────────────
//
// Timestamps start at 10 s. Durations are proportional to line length.
//
const List<KaraokeLyric> pakPakBihuLyrics = [
  // ── Opening ────────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 10000),
    end:   Duration(milliseconds: 14500),
    text:  'Aeibeli bihuti ramoke jomoke',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 14500),
    end:   Duration(milliseconds: 19000),
    text:  'Nahor phool phulibor botor',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 19000),
    end:   Duration(milliseconds: 23000),
    text:  'Nahor phoolar gundhe paai',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 23000),
    end:   Duration(milliseconds: 27000),
    text:  'Lahorir tãtae naai',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 27000),
    end:   Duration(milliseconds: 32000),
    text:  'Gosokot bhaangi zaai zotor',
  ),

  // ── Chorus 1 ───────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 33500),
    end:   Duration(milliseconds: 37000),
    text:  'Paak paak paak',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 37000),
    end:   Duration(milliseconds: 43500),
    text:  'Chontok moriyoni mazuli jonaak baat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 43500),
    end:   Duration(milliseconds: 49000),
    text:  'Ifaale nesaabi xifaale maazote',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 49000),
    end:   Duration(milliseconds: 52500),
    text:  'Naasi thaak',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 52500),
    end:   Duration(milliseconds: 56000),
    text:  'Nasunot lagibo',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 56000),
    end:   Duration(milliseconds: 60500),
    text:  'Nasunot lagibo paak',
  ),

  // ── Chorus 2 ───────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 62000),
    end:   Duration(milliseconds: 66000),
    text:  'Paak paak paak paake o',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 66000),
    end:   Duration(milliseconds: 69500),
    text:  'Nasunot lagibo',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 69500),
    end:   Duration(milliseconds: 73000),
    text:  'Nasunot lagibo',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 73000),
    end:   Duration(milliseconds: 77500),
    text:  'Nasunot lagibo paak',
  ),

  // ── Verse 2 ────────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 79500),
    end:   Duration(milliseconds: 85000),
    text:  'Motamoh bisaari dib dib kore rongili o',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 85000),
    end:   Duration(milliseconds: 91000),
    text:  'Habiloi goisilu dib dib kore pomoli o',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 91000),
    end:   Duration(milliseconds: 97000),
    text:  'Habiloi goisilu dib dib kore pomoli o',
  ),

  // ── Dance section ──────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 99000),
    end:   Duration(milliseconds: 103500),
    text:  'Bhaluke bhaagile daale hei',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 103500),
    end:   Duration(milliseconds: 108500),
    text:  'Naas oi rongili takuri ghura di',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 108500),
    end:   Duration(milliseconds: 113000),
    text:  'Pokhili uraa di naas.',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 113000),
    end:   Duration(milliseconds: 118000),
    text:  'Naas oi rongili takuri ghura di',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 118000),
    end:   Duration(milliseconds: 122500),
    text:  'Pokhili uraa di naas.',
  ),

  // ── Verse 3 ────────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 124000),
    end:   Duration(milliseconds: 130000),
    text:  'Kehku kehkoli thunupaak kot tholi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 130000),
    end:   Duration(milliseconds: 135000),
    text:  'Thunukupaakot naai dhon',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 135000),
    end:   Duration(milliseconds: 140000),
    text:  'Naasonir naasibo mon',
  ),

  // ── Playful verse ──────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 141500),
    end:   Duration(milliseconds: 147000),
    text:  'Hoi bou olou lou hoi bou toloulou',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 147000),
    end:   Duration(milliseconds: 152000),
    text:  'Hoi bou sopai nahorere',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 152000),
    end:   Duration(milliseconds: 158000),
    text:  'Kuli ou baai, pindhita nai,',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 158000),
    end:   Duration(milliseconds: 163500),
    text:  'risippou sippou hu hu hei',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 163500),
    end:   Duration(milliseconds: 169000),
    text:  'Khao jodi khaa nekhaau jodi jaa',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 169000),
    end:   Duration(milliseconds: 174500),
    text:  'Ki koru bappeke saa...',
  ),

  // ── Storytelling verse ─────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 176500),
    end:   Duration(milliseconds: 182000),
    text:  'Moor ghor ipaarot toor ghor xipaarot',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 182000),
    end:   Duration(milliseconds: 187000),
    text:  'Maajote buwoti noi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 187000),
    end:   Duration(milliseconds: 193000),
    text:  'Soraai huwa hole uri golu heten',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 193000),
    end:   Duration(milliseconds: 197500),
    text:  'Duhaate dupaakhi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 197500),
    end:   Duration(milliseconds: 205000),
    text:  'Loiye mon zili, kotae',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 205000),
    end:   Duration(milliseconds: 211000),
    text:  'kande dapor duwaror',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 211000),
    end:   Duration(milliseconds: 217500),
    text:  'khili khili bengenaar paate',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 217500),
    end:   Duration(milliseconds: 224000),
    text:  'mon zili kotae kande dapor',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 224000),
    end:   Duration(milliseconds: 230000),
    text:  'duwaror khili khili bengenaar paat!',
  ),

  // ── Refrain 1 ──────────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 232000),
    end:   Duration(milliseconds: 238000),
    text:  'keteki soraaiye kaate xoru xuta,',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 238000),
    end:   Duration(milliseconds: 244000),
    text:  'moruwa patore zotor ki naas',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 244000),
    end:   Duration(milliseconds: 250000),
    text:  'soi modaror paane ki naas, soi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 250000),
    end:   Duration(milliseconds: 255500),
    text:  'modaror paan',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 255500),
    end:   Duration(milliseconds: 260000),
    text:  'soi modaror paan',
  ),

  // ── Harvest verse ──────────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 262000),
    end:   Duration(milliseconds: 268000),
    text:  'Saalot molongile zui solai paat,',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 268000),
    end:   Duration(milliseconds: 274000),
    text:  'habire kumura zui solai paat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 274000),
    end:   Duration(milliseconds: 278000),
    text:  'zui solai paat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 279500),
    end:   Duration(milliseconds: 285000),
    text:  'Habiye habiye zaauwe he',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 285000),
    end:   Duration(milliseconds: 290500),
    text:  'zui solai paat pepor maat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 290500),
    end:   Duration(milliseconds: 296500),
    text:  'o aaikon ulai maat zi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 296500),
    end:   Duration(milliseconds: 302000),
    text:  'hobo hoise xoriror gaat.',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 302000),
    end:   Duration(milliseconds: 307500),
    text:  'Ekathu bukate sela zuk',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 307500),
    end:   Duration(milliseconds: 312500),
    text:  'eruwai ruwa rubo lagibo',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 312500),
    end:   Duration(milliseconds: 317000),
    text:  'ruwa rubo lagibo',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 317000),
    end:   Duration(milliseconds: 322500),
    text:  'Toi naso naas, moi naasu naas,',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 322500),
    end:   Duration(milliseconds: 328000),
    text:  'oi moor logote aru ezoni',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 328000),
    end:   Duration(milliseconds: 334000),
    text:  'Kun naso naas oi kun naaso naas.',
  ),

  // ── Refrain 2 (repeat) ─────────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 336500),
    end:   Duration(milliseconds: 342500),
    text:  'keteki soraaiye kaate xoru xuta,',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 342500),
    end:   Duration(milliseconds: 348500),
    text:  'moruwa patore zotor ki naas',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 348500),
    end:   Duration(milliseconds: 354500),
    text:  'soi modaror paane ki naas, soi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 354500),
    end:   Duration(milliseconds: 360000),
    text:  'modaror paan',
  ),

  // ── Harvest verse repeat ───────────────────────────────────────────────────
  KaraokeLyric(
    start: Duration(milliseconds: 362000),
    end:   Duration(milliseconds: 368000),
    text:  'Saalot molongile zui solai paat,',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 368000),
    end:   Duration(milliseconds: 374000),
    text:  'habire kumura zui solai paat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 374000),
    end:   Duration(milliseconds: 378000),
    text:  'zui solai paat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 379500),
    end:   Duration(milliseconds: 385000),
    text:  'Habiye habiye zaauwe he',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 385000),
    end:   Duration(milliseconds: 390500),
    text:  'zui solai paat pepor maat',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 390500),
    end:   Duration(milliseconds: 396500),
    text:  'o aaikon ulai maat zi',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 396500),
    end:   Duration(milliseconds: 402000),
    text:  'hobo hoise xoriror gaat.',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 402000),
    end:   Duration(milliseconds: 407500),
    text:  'Ekathu bukate sela zuk',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 407500),
    end:   Duration(milliseconds: 412500),
    text:  'eruwai ruwa rubo lagibo',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 412500),
    end:   Duration(milliseconds: 417000),
    text:  'ruwa rubo lagibo',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 417000),
    end:   Duration(milliseconds: 422500),
    text:  'Toi naso naas, moi naasu naas,',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 422500),
    end:   Duration(milliseconds: 428000),
    text:  'oi moor logote aru ezoni',
  ),
  KaraokeLyric(
    start: Duration(milliseconds: 428000),
    end:   Duration(milliseconds: 435000),
    text:  'Kun naso naas oi kun naaso naas',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MASTER SONG LIST
// Add a third or fourth song here later.
// ─────────────────────────────────────────────────────────────────────────────
const List<KaraokeSong> karaokeSongs = [
  KaraokeSong(
    id: 'moromor_dehi_oi',
    title: 'Moromor Dehi Oi',
    culturalLabel: 'Assamese Folk • Rakesh Reeyan',
    audioAsset:
        'assets/audio/O Moromor Dehi Oi  Rakesh Reeyan  Assamese Full Clean Karaoke With Lyrics  HQ Clean Karaoke.mp3',
    lyrics: moromorDehiOiLyrics,
  ),
  KaraokeSong(
    id: 'pak_pak_bihu',
    title: 'Pak Pak Bihu Naam',
    culturalLabel: 'Assamese Bihu • Papon',
    audioAsset:
        'assets/audio/Pak Pak Bihu Naam Karaoke  Papon  Coke Studio  Mtv  Bihu Song  assamese karaoke  Eng lyrics.mp3',
    lyrics: pakPakBihuLyrics,
  ),
];
