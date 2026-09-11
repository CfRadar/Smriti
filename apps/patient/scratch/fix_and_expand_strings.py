# -*- coding: utf-8 -*-
import json, re

# Load items_data
import sys
sys.path.append('scratch')
from generate_item_translations import items_data
from expand_translations_all_games import extra_game_keys

print(f"Total extra game keys: {len(extra_game_keys)}")

with open('lib/l10n/app_translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Clean languages map
clean_languages_block = """  static const Map<String, Map<String, String>> languages = {
    'en': {
      'name': 'English',
      'nativeName': 'English',
    },
    'hi': {
      'name': 'Hindi',
      'nativeName': 'हिंदी',
    },
    'as': {
      'name': 'Assamese',
      'nativeName': 'অসমীয়া',
    },
    'bn': {
      'name': 'Bengali',
      'nativeName': 'বাংলা',
    },
    'lus': {
      'name': 'Mizo',
      'nativeName': 'Mizo',
    },
    'mni': {
      'name': 'Manipuri',
      'nativeName': 'মৈতৈলোন্',
    },
  };"""

# Replace from "static const Map<String, Map<String, String>> languages = {" up to "static const Map<String, Map<String, String>> strings = {"
strings_start_idx = content.find("static const Map<String, Map<String, String>> strings = {")
if strings_start_idx == -1:
    print("Error finding strings map!")
    sys.exit(1)

content_before = content[:content.find("  static const Map<String, Map<String, String>> languages = {")]
content_strings = content[strings_start_idx:]

new_content = content_before + clean_languages_block + "\n\n  " + content_strings

# Now inject extra_game_keys into content_strings for each language in `strings`
languages = ["en", "hi", "as", "bn", "lus", "mni"]

for lang in languages:
    # Build lines to add
    lines_to_add = []
    for key, trans in extra_game_keys.items():
        val = trans[lang].replace("'", "\\'")
        lines_to_add.append(f"      '{key}': '{val}',")
    
    inject_str = "\n".join(lines_to_add) + "\n"
    
    # Locate "'<lang>': {" INSIDE strings map
    # Search after "static const Map<String, Map<String, String>> strings = {"
    strings_pos = new_content.find("static const Map<String, Map<String, String>> strings = {")
    lang_header = f"    '{lang}': {{"
    start_pos = new_content.find(lang_header, strings_pos)
    if start_pos == -1:
        print(f"Error finding strings map header for {lang}")
        continue
    
    # find next "    }," after start_pos
    end_pos = new_content.find("    },", start_pos)
    if end_pos == -1:
        print(f"Error finding end of strings map for {lang}")
        continue
        
    new_content = new_content[:end_pos] + inject_str + new_content[end_pos:]

with open('lib/l10n/app_translations.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("lib/l10n/app_translations.dart fixed and expanded successfully!")
