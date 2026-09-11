with open(r"d:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart", 'r', encoding='utf-8') as f:
    text = f.read()

import re
en_part = text[text.find("'en': {"):text.find("'hi': {")]

keys_to_test = [
    'common.pts',
    'gameplay.step',
    'gameplay.doneCount',
    'gameplay.stage',
    'gameplay.danceStages',
    'games.bambooDance',
    'gameplay.toggleSoundTooltip',
    'gameplay.muteSound',
    'gameplay.enableSound',
    'gameplay.pauseGame',
    'gameplay.resumeGame',
    'gameplay.accuracy',
    'gameplay.avgSpeed',
    'gameplay.bestStreak',
    'gameplay.stepTargetHint',
    'gameplay.tapOnTarget',
    'gameplay.exitToHomeTooltip',
    'gameplay.bookmarkSaved',
    'gameplay.bookmarkRemoved',
    'folklore.bookmarkSaved',
    'folklore.bookmarkRemoved',
    'folklore.narrationInProgress',
    'folklore.readAloudStory',
    'folklore.narratingIn',
    'folklore.tapToListen',
    'karaoke.focusStage',
    'karaoke.allLyrics',
    'karaoke.karaokeBadge',
]

for k in keys_to_test:
    present = f"'{k}':" in en_part
    print(f"{k}: {'FOUND' if present else 'MISSING'}")
