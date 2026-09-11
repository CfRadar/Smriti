with open(r'd:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, l in enumerate(lines):
    if "'common.pts'" in l:
        print(f"L{i+1}: {l.strip()}")
