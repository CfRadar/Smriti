import re

translations_file = r"d:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart"

with open(translations_file, 'r', encoding='utf-8') as f:
    content = f.read()

languages = ['en', 'hi', 'as', 'bn', 'lus', 'mni']
keys_per_lang = {}

for lang in languages:
    pattern = rf"'{lang}':\s*\{{(.*?)\n    \}},"
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        # maybe the last one has different indent
        pattern = rf"'{lang}':\s*\{{(.*?)\n  \}};"
        match = re.search(pattern, content, re.DOTALL)
    if match:
        body = match.group(1)
        found_keys = set(re.findall(r"'([a-zA-Z0-9_.-]+)'\s*:\s*'", body))
        keys_per_lang[lang] = found_keys
        print(f"Language {lang}: {len(found_keys)} keys")
    else:
        print(f"Warning: could not extract keys for {lang}")

en_keys = keys_per_lang['en']
all_ok = True
for lang in languages[1:]:
    diff = en_keys - keys_per_lang[lang]
    extra = keys_per_lang[lang] - en_keys
    if diff:
        print(f"Missing in {lang}: {diff}")
        all_ok = False
    if extra:
        print(f"Extra in {lang}: {extra}")
        all_ok = False

if all_ok:
    print("SUCCESS! All 6 languages have exactly 100% identical keys!")
