import re, os

games = [
    'lib/games/picture_recognition_game.dart',
    'lib/games/pattern_memory_game.dart',
    'lib/games/king_shanaba_game.dart',
    'lib/games/bamboo_dance_game.dart',
    'lib/widgets/game_completion_dialog.dart'
]

for path in games:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    print(f"=== {path} ===")
    for i, line in enumerate(lines):
        # find Text(
        if 'Text(' in line or 'TextSpan(' in line:
            if 'context.tr' not in line and not line.strip().startswith('//'):
                # print lines that have string literals or variable texts
                print(f"  Line {i+1}: {line.strip()[:100]}")
