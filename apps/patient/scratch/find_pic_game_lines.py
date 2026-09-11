with open(r"d:\SIH2026\Smriti\apps\patient\lib\games\picture_recognition_game.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

targets = [
    'Picture Recognition',
    'Level ',
    'Round ',
    'pts',
    'Game Paused',
    'Resume Session',
    'End Game Session',
    'Select Difficulty Level',
    'Difficulty Settings',
    'Choose starting challenge',
    'Remember and recognize',
    'Find this Item',
    'Find Both Items',
    'Find All 3 Items',
    'Memorize item',
    "I'm Ready!",
    'Say ',
    'showGameCompletionDialog',
]

for i, line in enumerate(lines):
    for t in targets:
        if t in line:
            print(f"L{i+1}: {line.strip()}")
