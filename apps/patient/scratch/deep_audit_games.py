import re, os

games = [
    'lib/games/picture_recognition_game.dart',
    'lib/games/pattern_memory_game.dart',
    'lib/games/king_shanaba_game.dart',
    'lib/games/bamboo_dance_game.dart',
    'lib/widgets/game_completion_dialog.dart'
]

out_lines = []
for g in games:
    with open(g, 'r', encoding='utf-8') as f:
        text = f.read()
    
    out_lines.append(f"\n==================== {g} ====================")
    matches = re.findall(r"'([^'\n\r]{2,})'|\"([^\"\n\r]{2,})\"", text)
    strings = []
    for m in matches:
        s = m[0] or m[1]
        if (
            not s.startswith('assets/')
            and not s.startswith('package:')
            and not s.startswith('http')
            and not s.startswith('smriti_')
            and not s.startswith('gameplay.')
            and not s.startswith('common.')
            and not s.startswith('settings.')
            and not s.startswith('nav.')
            and not s.startswith('dashboard.')
            and not s.startswith('caregiver.')
            and not s.startswith('folklore.')
            and not s.startswith('karaoke.')
            and not s.startswith('activities.')
            and not s.startswith('welcome.')
            and not s.startswith('voice.')
            and not s.endswith('.dart')
            and not s.endswith('.png')
            and not s.endswith('.jpg')
            and not s.endswith('.mp3')
            and not s.endswith('.svg')
            and not any(s.startswith(p) for p in ['#', 'Bearer', 'application/', 'Content-Type', 'en', 'hi', 'as', 'bn', 'lus', 'mni'])
            and any(c.isalpha() for c in s)
            and len(s.split()) >= 1
            and any(c.isupper() for c in s)
        ):
            strings.append(s)
            
    seen = set()
    for s in strings:
        if s not in seen and not any(k in s for k in ['AdaptiveDifficultyConfig', 'CulturalCategory', 'PictureTrialTelemetry', 'PictureGamePhase', 'PatternGamePhase', 'KingShanaba', 'BambooDance']):
            seen.add(s)
            out_lines.append(f"  - {s}")
            
with open('scratch/game_strings_report.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out_lines))
print('Wrote scratch/game_strings_report.txt successfully')
