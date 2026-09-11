import re

with open('lib/l10n/app_translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find all keys in en map
en_part = content.split("'en': {")[1].split("},\n    'hi': {")[0]
keys = re.findall(r"'([^']+)':", en_part)
print(f"Total keys in 'en': {len(keys)}")

for prefix in ['gameplay.bamboo', 'gameplay.step', 'gameplay.done', 'karaoke', 'folklore', 'common.pts']:
    matching = [k for k in keys if k.startswith(prefix)]
    print(f"Prefix '{prefix}': {matching}")
