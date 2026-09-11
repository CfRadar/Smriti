import re

# Read current translations
with open(r'd:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# First, remove the "Extended Activities, Folklore & Karaoke Keys" if already partially added to 'en'
text = re.sub(r"\n\s*// Extended Activities, Folklore & Karaoke Keys.*?(?=\n    \},|\n    \}\n  \};)", "", text, flags=re.DOTALL)

import sys
sys.path.append('scratch')
from inject_keys import NEW_KEYS

order = ['en', 'hi', 'as', 'bn', 'lus', 'mni']

for i, lang in enumerate(order):
    header = f"'{lang}': {{"
    start = text.find(header)
    assert start != -1, f"Could not find {header}"
    
    if i < len(order) - 1:
        next_header = f"'{order[i+1]}': {{"
        end = text.find(next_header, start)
    else:
        end = text.find("  };\n}\n", start)
        if end == -1:
            end = text.rfind("  };")
    
    # Within text[start:end], find the last '    },' or '    }'
    block = text[start:end]
    last_brace = block.rfind("    },")
    if last_brace == -1:
        last_brace = block.rfind("    }")
    
    lines_to_add = ["\n      // Extended Activities, Folklore & Karaoke Keys"]
    for k, v in sorted(NEW_KEYS[lang].items()):
        val_escaped = v.replace("'", "\\'")
        lines_to_add.append(f"      '{k}': '{val_escaped}',")
    
    addition = "\n".join(lines_to_add) + "\n"
    new_block = block[:last_brace] + addition + block[last_brace:]
    text = text[:start] + new_block + text[end:]

with open(r'd:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Properly injected keys into all 6 languages!")
