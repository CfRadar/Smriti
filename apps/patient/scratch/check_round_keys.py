import re

with open(r"lib/l10n/app_translations.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

current_lang = None
data = {}

for line in lines:
    line_strip = line.strip()
    if line_strip in ["'en': {", "'hi': {", "'as': {", "'bn': {", "'lus': {", "'mni': {"]:
        current_lang = line_strip[1:line_strip.index("':")]
        data[current_lang] = {}
    elif current_lang and line_strip.startswith("'"):
        m = re.match(r"^'([a-zA-Z0-9_.-]+)':\s*['\"](.*)['\"],?$", line_strip)
        if m:
            data[current_lang][m.group(1)] = m.group(2)
    elif line_strip in ["},", "};"] and current_lang and line.startswith("    }"):
        current_lang = None

keys_to_check = ['gameplay.round', 'gameplay.trial', 'gameplay.step', 'gameplay.aimAndStrike']
for k in keys_to_check:
    print(f"=== {k} ===")
    for lang in ['en', 'hi', 'as', 'bn', 'lus', 'mni']:
        val = data.get(lang, {}).get(k, 'MISSING')
        print(f"  {lang}: {val.encode('ascii', 'backslashreplace').decode()}")
