import re

with open('lib/games/bamboo_dance_game.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    # look for Text(, tooltip:, title:, etc
    if any(k in line for k in ['Text(', 'tooltip:', 'title:', 'label:', 'showDialog', 'AlertDialog', 'SnackBar']):
        print(f"L{i+1}: {line.strip()[:100]}")
