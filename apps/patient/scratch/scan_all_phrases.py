import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

game_files = [
    r"d:\SIH2026\Smriti\apps\patient\lib\widgets\game_completion_dialog.dart",
    r"d:\SIH2026\Smriti\apps\patient\lib\games\picture_recognition_game.dart",
    r"d:\SIH2026\Smriti\apps\patient\lib\games\pattern_memory_game.dart",
    r"d:\SIH2026\Smriti\apps\patient\lib\games\king_shanaba_game.dart",
    r"d:\SIH2026\Smriti\apps\patient\lib\games\bamboo_dance_game.dart",
]

for file_path in game_files:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    print(f"\n=== {file_path.split('\\')[-1]} ===")
    
    # Check for quotes inside child: Text(...) or child: ...
    # Find all strings enclosed in quotes that have letters
    raw_strings = re.findall(r"['\"]([A-Z][a-zA-Z0-9\s.,!?:–—•'’()]{2,})['\"]", content)
    unique_strings = set()
    for s in raw_strings:
        # filter out package:, assets/, dart:, etc.
        if any(s.startswith(x) for x in ['assets/', 'package:', 'dart:', 'http', 'UTF-8', 'BPM']):
            continue
        unique_strings.add(s)
    for s in sorted(unique_strings):
        print(f"  {s}")
