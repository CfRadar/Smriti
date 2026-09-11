with open(r"d:\SIH2026\Smriti\apps\patient\lib\games\king_shanaba_game.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

targets = [
    'King Shanaba',
    'Traditional Manipuri Kangshang',
    'Level ',
    'Round ',
    'pts',
    'Game Paused',
    'Resume Session',
    'Pull back to aim',
    'Aim & Strike',
    'Close call',
    'A gentle push',
    'Good force',
    'showGameCompletionDialog',
]

for i, line in enumerate(lines):
    for t in targets:
        if t in line:
            print(f"L{i+1}: {line.strip()}")
