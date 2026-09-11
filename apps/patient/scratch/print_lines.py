with open(r'd:\SIH2026\Smriti\apps\patient\lib\l10n\app_translations.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(618, 630):
    print(f"L{i+1}: {repr(lines[i])}")
