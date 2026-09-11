import re

with open(r"d:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

en_keys = {}
current_lang = None
for line in lines:
    line_strip = line.strip()
    if line_strip == "'en': {":
        current_lang = 'en'
    elif current_lang == 'en' and line_strip.startswith("'"):
        m = re.match(r"^'([a-zA-Z0-9_.-]+)':\s*(['\"].*)$", line_strip)
        if m:
            en_keys[m.group(1)] = m.group(2)
    elif line_strip in ["},", "};"] and current_lang and line.startswith("    }"):
        current_lang = None

print(f"Total en keys: {len(en_keys)}")
for prefix in ['gameplay', 'games', 'folklore', 'karaoke', 'common']:
    sub = {k: v for k, v in en_keys.items() if k.startswith(prefix)}
    print(f"\n--- {prefix} ({len(sub)}) ---")
    for k, v in sorted(sub.items()):
        print(f"  {k}: {v}")
