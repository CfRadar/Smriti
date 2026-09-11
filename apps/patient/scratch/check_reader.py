import re

files = [
    r"lib/screens/folklore_reader_screen.dart",
    r"lib/screens/folklore_list_screen.dart",
    r"lib/screens/karaoke_screen.dart",
    r"lib/screens/karaoke_player_screen.dart",
    r"lib/games/bamboo_dance_game.dart",
    r"lib/models/karaoke_song.dart",
    r"lib/models/folklore_story.dart",
    r"lib/services/folklore_service.dart"
]

for file_path in files:
    print(f"=== {file_path} ===")
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    for idx, line in enumerate(lines):
        line_str = line.strip()
        matches = re.findall(r"'([^'\\]*(?:\\.[^'\\]*)*)'|\"([^\"\\]*(?:\\.[^\"\\]*)*)\"", line_str)
        for m in matches:
            text = m[0] or m[1]
            if not text or len(text.strip()) <= 1:
                continue
            if re.match(r'^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_.-]+$', text):
                continue
            if text.startswith('assets/') or text.startswith('package:') or text.startswith('#') or text.startswith('http'):
                continue
            if text in ['serif', 'en', 'hi', 'as', 'bn', 'lus', 'mni', 'Roboto', 'Outfit', 'MaterialIcons', 'OpenSans']:
                continue
            # Look for English words
            if re.search(r'\b(Gentle|Start|Shifts|Directions|Rhythmic|Tempo|Memory|Rhythm|Harmonious|Flow|Oral|Tradition|Preview|Sample|Narration|Story|Listen|Bookmark|Stage|Lyrics|Singing|Score|Points|Level)\b', text, re.IGNORECASE):
                print(f"  Line {idx+1}: {line_str}")
                break
