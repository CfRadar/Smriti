import re

with open(r"d:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

current_lang = None
keys_by_lang = {}
for line in lines:
    line_strip = line.strip()
    if line_strip in ["'en': {", "'hi': {", "'as': {", "'bn': {", "'lus': {", "'mni': {"]:
        current_lang = line_strip[1:line_strip.index("':")]
        keys_by_lang[current_lang] = set()
    elif current_lang and line_strip.startswith("'"):
        # Match 'key': 'value' or 'key': "value"
        m = re.match(r"^'([a-zA-Z0-9_.-]+)':\s*['\"]", line_strip)
        if m:
            keys_by_lang[current_lang].add(m.group(1))
    elif line_strip in ["},", "};"] and current_lang and line.startswith("    }"):
        current_lang = None

for lang, ks in keys_by_lang.items():
    print(f"Language {lang}: {len(ks)} keys")

all_matched = True
for lang in ['hi', 'as', 'bn', 'lus', 'mni']:
    diff_en = keys_by_lang['en'] - keys_by_lang[lang]
    diff_lang = keys_by_lang[lang] - keys_by_lang['en']
    if diff_en:
        print(f"Missing in {lang}: {diff_en}")
        all_matched = False
    if diff_lang:
        print(f"Extra in {lang}: {diff_lang}")
        all_matched = False

if all_matched:
    print("PERFECT 100% SYMMETRY ACROSS ALL 6 LANGUAGES!")
