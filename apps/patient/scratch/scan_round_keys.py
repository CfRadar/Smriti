import re

with open(r"lib/l10n/app_translations.dart", 'r', encoding='utf-8') as f:
    content = f.read()

# Match EN block
m_en = re.search(r"'en':\s*\{(.*?)\n    \},", content, re.DOTALL)
if m_en:
    en_block = m_en.group(1)
    for line in en_block.splitlines():
        m = re.search(r"'([^']+)':\s*'([^']+)'", line)
        if m:
            k, v = m.group(1), m.group(2)
            if any(w in k.lower() for w in ['round', 'trial', 'step']) or any(w in v.lower() for w in ['round', 'trial', 'step']):
                print(f"{k} => {v}")
