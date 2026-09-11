import re

def inspect_texts(filename):
    print("="*60)
    print("FILE:", filename)
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Let's find all Text(...) occurrences across multiple lines
    matches = re.finditer(r'Text\s*\(\s*(.*?)(?:,\s*style|\s*,\s*textAlign|\s*,\s*overflow|\s*,\s*maxLines|\s*\))', content, re.DOTALL)
    for m in matches:
        first_arg = m.group(1).strip()
        # Clean up newlines
        first_arg_clean = " ".join(first_arg.split())
        if not first_arg_clean.startswith("context.tr"):
            print("  Text arg:", first_arg_clean[:80])

for path in [
    "lib/games/bamboo_dance_game.dart",
    "lib/screens/folklore_list_screen.dart",
    "lib/screens/folklore_reader_screen.dart",
    "lib/screens/karaoke_screen.dart",
    "lib/screens/karaoke_player_screen.dart",
]:
    inspect_texts(path)
