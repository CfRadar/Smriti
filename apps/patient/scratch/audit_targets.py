import os
import re

def audit_file(path):
    print("==================================================")
    print("FILE:", path)
    if not os.path.exists(path):
        print("NOT FOUND!")
        return
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    tr_calls = []
    text_widgets = []
    hardcoded = []
    
    for i, line in enumerate(lines):
        if "context.tr" in line:
            tr_calls.append((i+1, line.strip()))
        # Check for Text('...' or Text("..."
        m = re.search(r'Text\(\s*([\'"][^\'\"]+[\'"])', line)
        if m and "context.tr" not in line:
            text_widgets.append((i+1, m.group(1), line.strip()))
            
    print(f"Total lines: {len(lines)}")
    print(f"context.tr occurrences: {len(tr_calls)}")
    print(f"Direct string Text widgets: {len(text_widgets)}")
    for line_num, txt, full in text_widgets[:20]:
        print(f"  L{line_num}: {txt}  --> {full[:60]}")

for p in [
    "lib/games/bamboo_dance_game.dart",
    "lib/screens/folklore_list_screen.dart",
    "lib/screens/folklore_reader_screen.dart",
    "lib/services/folklore_service.dart",
    "lib/screens/karaoke_screen.dart",
    "lib/screens/karaoke_player_screen.dart",
    "lib/data/karaoke_data.dart",
    "lib/screens/welcome_login_screen.dart",
    "assets/research.txt",
]:
    audit_file(p)
