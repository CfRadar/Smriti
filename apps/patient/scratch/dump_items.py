import re, json

with open('lib/games/picture_recognition_game.dart', 'r', encoding='utf-8') as f:
    text = f.read()

items = re.findall(
    r"GameItem\(\s*id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*regionalName:\s*'([^']+)',\s*region:\s*'([^']+)',\s*category:\s*CulturalCategory\.([^\s,]+)",
    text
)

catalog = []
for item in items:
    catalog.append({
        'id': item[0],
        'name': item[1],
        'regionalName': item[2],
        'region': item[3],
        'category': item[4]
    })

with open('scratch/items_catalog.json', 'w', encoding='utf-8') as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)

print(f"Exported {len(catalog)} items.")
