with open(r"d:\SIH2026\Smriti\apps\patient\lib\games\pattern_memory_game.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

targets = [
    'Pattern Memory',
    'Level ',
    'Trial ',
    'pts',
    'Game Paused',
    'Resume Session',
    'End Game Session',
    'Get Ready',
    'Memorize the',
    'Difficulty Preset',
    'Say ',
    'showGameCompletionDialog',
]

for i, line in enumerate(lines):
    for t in targets:
        if t in line:
            print(f"L{i+1}: {line.strip()}")
