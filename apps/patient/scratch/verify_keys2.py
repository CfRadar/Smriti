with open(r"d:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

current_lang = None
keys_by_lang = {}
for line in lines:
    line_strip = line.strip()
    if line_strip in ["'en': {", "'hi': {", "'as': {", "'bn': {", "'lus': {", "'mni': {"]:
        current_lang = line_strip[1:line_strip.index("':")]
        keys_by_lang[current_lang] = set()
    elif current_lang and line_strip.startswith("'") and "': '" in line_strip:
        k = line_strip[1:line_strip.index("': '")]
        keys_by_lang[current_lang].add(k)
    elif line_strip in ["},", "};"] and current_lang and line.startswith("    }"):
        current_lang = None

for lang, ks in keys_by_lang.items():
    print(f"Language {lang}: {len(ks)} keys")

en_k = keys_by_lang['en']
for lang in ['hi', 'as', 'bn', 'lus', 'mni']:
    diff = en_k - keys_by_lang[lang]
    if diff:
        print(f"Missing in {lang}: {diff}")
    else:
        print(f"{lang} matches en 100%!")
