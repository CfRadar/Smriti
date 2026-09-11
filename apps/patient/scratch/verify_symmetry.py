import re

with open('lib/l10n/app_translations.dart', 'r', encoding='utf-8') as f:
    text = f.read()

langs = ['en', 'hi', 'as', 'bn', 'lus', 'mni']
key_sets = {}
for lang in langs:
    pos = text.find(f"'{lang}': {{")
    end_pos = text.find("    },", pos)
    block = text[pos:end_pos]
    keys = set(re.findall(r"'([^']+)'\s*:", block))
    key_sets[lang] = keys
    print(f"{lang}: {len(keys)} keys")

all_keys = key_sets['en']
for lang in langs[1:]:
    diff = all_keys.symmetric_difference(key_sets[lang])
    print(f"Diff between en and {lang}: {len(diff)}")
