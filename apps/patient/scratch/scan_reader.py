import re

with open(r"lib/screens/folklore_reader_screen.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

print("Scanning folklore_reader_screen.dart...")
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
        if any(w in line_str for w in ['Text(', 'tooltip:', 'Semantics(', 'label:', 'hint:', 'message:', 'title:', 'subtitle:', 'SnackBar(']):
            print(f"Line {idx+1}: {text}  -->  {line_str}")
            break
