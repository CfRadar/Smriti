import re

with open(r'd:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart', 'r', encoding='utf-8') as f:
    text = f.read()

en_block = text[text.find("'en': {"):text.find("'hi': {")]
keys = re.findall(r"'([a-zA-Z0-9_.-]+)':", en_block)
seen = set()
duplicates = set()
for k in keys:
    if k in seen:
        duplicates.add(k)
    seen.add(k)

print("Duplicates in en:", duplicates)
