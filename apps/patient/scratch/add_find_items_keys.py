import re

translations_file = r"d:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart"

new_keys = {
    'en': {
        'gameplay.findBothItems': 'Find Both Items',
        'gameplay.findAll3Items': 'Find All 3 Items',
    },
    'hi': {
        'gameplay.findBothItems': 'दोनों वस्तुएं खोजें',
        'gameplay.findAll3Items': 'तीनों वस्तुएं खोजें',
    },
    'as': {
        'gameplay.findBothItems': 'দুয়োটা বস্তু বিচাৰক',
        'gameplay.findAll3Items': 'তিনিওটা বস্তু বিচাৰক',
    },
    'bn': {
        'gameplay.findBothItems': 'উভয় আইটেম খুঁজুন',
        'gameplay.findAll3Items': 'তিনটি আইটেম খুঁজুন',
    },
    'lus': {
        'gameplay.findBothItems': 'A pahnihin zawng rawh',
        'gameplay.findAll3Items': 'A pathumin zawng rawh',
    },
    'mni': {
        'gameplay.findBothItems': 'পোৎলম অনিমক থীবীয়ু',
        'gameplay.findAll3Items': 'পোৎলম অহুমমক থীবীয়ু',
    }
}

with open(translations_file, 'r', encoding='utf-8') as f:
    code = f.read()

strings_start = code.find("static const Map<String, Map<String, String>> strings = {")
strings_part = code[strings_start:]

for lang, kdict in new_keys.items():
    m = re.search(rf"('{lang}':\s*\{{)(.*?)(\n    \}},|\n  \}};\n)", strings_part, re.DOTALL)
    if not m:
        print(f"Failed to find lang {lang} in strings")
        continue
    prefix = m.group(1)
    body = m.group(2)
    suffix = m.group(3)

    added = []
    for k, v in kdict.items():
        if f"'{k}':" not in body:
            esc_v = v.replace("'", "\\'")
            added.append(f"      '{k}': '{esc_v}',")
    
    if added:
        new_body = body + "\n" + "\n".join(added)
        strings_part = strings_part[:m.start()] + prefix + new_body + suffix + strings_part[m.end():]
        print(f"Added {len(added)} strings to {lang}")

code = code[:strings_start] + strings_part

with open(translations_file, 'w', encoding='utf-8') as f:
    f.write(code)

print("Done updating translations")
