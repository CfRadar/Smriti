import re

with open(r"lib/l10n/app_translations.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

in_hi = False
for idx, line in enumerate(lines):
    if "'hi': {" in line:
        in_hi = True
    elif in_hi and line.strip() in ["},", "};"] and line.startswith("    }"):
        in_hi = False
    
    if in_hi:
        for word in ['राउंड', 'दौर', 'फेरी']:
            if word in line:
                print(f"Line {idx+1}: {line.strip().encode('ascii', 'backslashreplace').decode()}")
