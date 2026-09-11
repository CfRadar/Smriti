import re
import os
import sys

# Set utf-8 stdout
sys.stdout.reconfigure(encoding='utf-8')

game_files = [
    r"d:\SIH2026\Smriti\apps\patient\lib\widgets\game_completion_dialog.dart",
    r"d:\SIH2026\Smriti\apps\patient\lib\games\picture_recognition_game.dart",
    r"d:\SIH2026\Smriti\apps\patient\lib\games\pattern_memory_game.dart",
    r"d:\SIH2026\Smriti\apps\patient\lib\games\king_shanaba_game.dart",
    r"d:\SIH2026\Smriti\apps\patient\lib\games\bamboo_dance_game.dart",
]

for file_path in game_files:
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        continue
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    print(f"\n=== {os.path.basename(file_path)} ===")
    
    # find Text( ... )
    matches = re.findall(r"Text\s*\(\s*['\"]([^'\"]+)['\"]", content)
    for m in sorted(set(matches)):
        if len(m.strip()) > 1 and not m.startswith("assets/"):
            print(f"  Text: '{m}'")
    
    # find GameCompletionMetric or showGameCompletionDialog
    dialog_matches = re.findall(r"GameCompletionMetric\s*\(\s*[^)]*label:\s*['\"]([^'\"]+)['\"]", content)
    for dm in sorted(set(dialog_matches)):
        print(f"  Metric label: '{dm}'")

    # find title/subtitle
    titles = re.findall(r"(?:title|subtitle|label|message|header):\s*['\"]([^'\"]+)['\"]", content)
    for t in sorted(set(titles)):
        if len(t.strip()) > 1 and not t.startswith("assets/"):
            print(f"  Field: '{t}'")
