import re
import sys
sys.path.append('scratch')
from inject_keys import NEW_KEYS

with open(r'd:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Remove all injected blocks first
text = re.sub(r"\n\s*// Extended Activities, Folklore & Karaoke Keys.*?(?=\n    \},|\n    \}\n  \};)", "", text, flags=re.DOTALL)

# Split by language headers
langs = ['en', 'hi', 'as', 'bn', 'lus', 'mni']
pattern = r"(    '(?:en|hi|as|bn|lus|mni)': \{)"
parts = re.split(pattern, text)

# parts[0] is preamble before 'en'
# parts[1] is "    'en': {"
# parts[2] is en content
# parts[3] is "    'hi': {"
# parts[4] is hi content
# etc.

new_parts = [parts[0]]
for i in range(1, len(parts), 2):
    header = parts[i]
    content = parts[i+1]
    m = re.search(r"'([a-z]+)':", header)
    lang = m.group(1)
    
    # Inject keys right before the last closing brace
    last_brace = content.rfind("    }")
    if last_brace == -1:
        last_brace = content.rfind("}")
    
    lines_to_add = ["\n      // Extended Activities, Folklore & Karaoke Keys"]
    for k, v in sorted(NEW_KEYS[lang].items()):
        val_escaped = v.replace("'", "\\'")
        lines_to_add.append(f"      '{k}': '{val_escaped}',")
    
    addition = "\n".join(lines_to_add) + "\n"
    new_content = content[:last_brace] + addition + content[last_brace:]
    
    new_parts.append(header)
    new_parts.append(new_content)

final_text = "".join(new_parts)

with open(r'd:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart', 'w', encoding='utf-8') as f:
    f.write(final_text)

print("Accurately reassembled app_translations.dart!")
