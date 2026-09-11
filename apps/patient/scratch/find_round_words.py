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
        if "राउंड" in line or "कदम" in line or "दौर" in line or "फेरी" in line or "प्रयास" in line:
            m = re.search(r"'([^']+)':\s*'([^']+)'", line)
            if m:
                print(f"Line {idx+1}: {m.group(1)} => {m.group(2).encode('ascii', 'backslashreplace').decode()}")
