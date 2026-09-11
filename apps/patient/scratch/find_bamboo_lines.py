import sys
sys.stdout.reconfigure(encoding='utf-8')

with open(r"d:\SIH2026\Smriti\apps\patient\lib\games\bamboo_dance_game.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

targets = [
    'Bamboo Dance',
    'Dance Stages',
    'Stage ',
    'Step ',
    'Done:',
    'pts',
    'Tap on the target',
    'Game Paused',
    'Resume Session',
    'showGameCompletionDialog',
]

for i, line in enumerate(lines):
    for t in targets:
        if t in line:
            print(f"L{i+1}: {line.strip()}")
