# -*- coding: utf-8 -*-
import json, re

from generate_item_translations import items_data

# Additional game keys for all 6 languages:
extra_game_keys = {
    "gameplay.categoryFauna": {
        "en": "Fauna",
        "hi": "जीव-जंतु",
        "as": "প্ৰাণী আৰু বন্যপ্ৰাণ",
        "bn": "প্রাণীকুল ও বন্যপ্রাণী",
        "lus": "Ramsate",
        "mni": "শা-ঙা অমসুং উচেক"
    },
    "gameplay.categoryAttire": {
        "en": "Traditional Attire",
        "hi": "पारंपरिक पोशाक",
        "as": "পাৰম্পৰিক সাজ-পোছাক",
        "bn": "ঐতিহ্যবাহী পোশাক",
        "lus": "Hnam Thuam",
        "mni": "হৈন-চৎনবী ফিজোল"
    },
    "gameplay.categoryFood": {
        "en": "Delicacy",
        "hi": "पारंपरिक व्यंजन",
        "as": "স্থানীয় সুস্বাদু খাদ্য",
        "bn": "ঐতিহ্যবাহী খাবার",
        "lus": "Ei tur tui",
        "mni": "লোকেল চানবা মহাও"
    },
    "gameplay.categoryCraft": {
        "en": "Craft & Heritage",
        "hi": "शिल्प व विरासत",
        "as": "শিল্প আৰু ঐতিহ্য",
        "bn": "শিল্প ও ঐতিহ্য",
        "lus": "Kutchhuak leh Hnam Ro",
        "mni": "খুৎশাবা অমসুং লৈবাক্কী পুৱারী"
    },
    "gameplay.diffSingleTargetDesc": {
        "en": "Single Target • {time}s",
        "hi": "एकल लक्ष्य • {time} से",
        "as": "এটা লক্ষ্য • {time} ছে",
        "bn": "একক লক্ষ্য • {time} সে",
        "lus": "Target Pakhat • {time}s",
        "mni": "তার্গেট অমা • {time} সে"
    },
    "gameplay.diffDualTargetDesc": {
        "en": "Dual Targets • {time}s/item",
        "hi": "दोहरे लक्ष्य • {time} से/वस्तु",
        "as": "দুটা লক্ষ্য • {time} ছে/বস্তু",
        "bn": "দ্বৈত লক্ষ্য • {time} সে/আইটেম",
        "lus": "Target Pahnih • {time}s/thil",
        "mni": "তার্গেট অনি • {time} সে/পোৎলম"
    },
    "gameplay.diffTripleTargetDesc": {
        "en": "Triple Targets • {time}s/item",
        "hi": "तीन लक्ष्य • {time} से/वस्तु",
        "as": "তিনিটা লক্ষ্য • {time} ছে/বস্তু",
        "bn": "তিনটি লক্ষ্য • {time} সে/আইটেম",
        "lus": "Target Pathum • {time}s/thil",
        "mni": "তার্গেট অহুম • {time} সে/পোৎলম"
    },
    "gameplay.patternDifficultySubtitle": {
        "en": "{count} tiles • {time}s",
        "hi": "{count} टाइलें • {time} से",
        "as": "{count} টা টাইল • {time} ছে",
        "bn": "{count}টি টাইল • {time} সে",
        "lus": "{count} tiles • {time}s",
        "mni": "{count} তাইল • {time} সে"
    },
    "gameplay.memorizePattern": {
        "en": "Memorize the highlighted pattern",
        "hi": "हाइलाइट किए गए पैटर्न को याद रखें",
        "as": "চিহ্নিত আৰ্হিটো মনত ৰাখক",
        "bn": "চিহ্নিত প্যাটার্নটি মনে রাখুন",
        "lus": "Pattern lan chiang kha vawng rawh",
        "mni": "উৎলিবা পেতর্ন অসি নীংশিংবীরু"
    },
    "gameplay.tapPatternRemaining": {
        "en": "Tap the pattern tiles ({count} left)",
        "hi": "पैटर्न टाइलों पर टैप करें ({count} शेष)",
        "as": "আৰ্হিৰ টাইলত টিপক ({count} বাকী)",
        "bn": "প্যাটার্নের টাইলগুলোতে ট্যাপ করুন ({count} বাকি)",
        "lus": "Pattern tiles hmet rawh ({count} la awm)",
        "mni": "পেতর্ন তাইলশিংদা নম্বীরু ({count} ৱাৎলি)"
    },
    "gameplay.patternCompleted": {
        "en": "Pattern completed!",
        "hi": "पैटर्न पूरा हुआ!",
        "as": "আৰ্হি সম্পূৰ্ণ হ'ল!",
        "bn": "প্যাটার্ন সম্পন্ন হয়েছে!",
        "lus": "Pattern zawh a ni!",
        "mni": "পেতর্ন লোইশিনখ্রে!"
    },
    "gameplay.completingSession": {
        "en": "Completing session...",
        "hi": "सत्र पूरा हो रहा है...",
        "as": "অধিৱেশন সম্পূৰ্ণ হৈছে...",
        "bn": "সেশন সম্পন্ন হচ্ছে...",
        "lus": "Hun zawh mek a ni...",
        "mni": "সেসন লোইশিল্লক্লি..."
    },
    "gameplay.reviewingPattern": {
        "en": "Reviewing pattern...",
        "hi": "पैटर्न की समीक्षा...",
        "as": "আৰ্হি পৰ্যালোচনা...",
        "bn": "প্যাটার্ন পর্যালোচনা...",
        "lus": "Pattern enfiah mek a ni...",
        "mni": "পেতর্ন য়েংশিল্লি..."
    },
    "gameplay.nextPattern": {
        "en": "Next pattern...",
        "hi": "अगला पैटर्न...",
        "as": "পৰৱৰ্তী আৰ্হি...",
        "bn": "পরবর্তী প্যাটার্ন...",
        "lus": "Pattern dawt leh...",
        "mni": "মথংগী পেতর্ন..."
    },
    "gameplay.patternGameCompleted": {
        "en": "Game completed! Well done.",
        "hi": "खेल पूरा हुआ! बहुत बढ़िया।",
        "as": "খেল সম্পূৰ্ণ হ'ল! বহুত ভাল।",
        "bn": "খেলা সমাপ্ত! খুব ভালো।",
        "lus": "Game a zo ta! I ti tha lutuk e.",
        "mni": "শান্নবা লোইরে! য়াম্না ফরে।"
    },
    "gameplay.tileAria": {
        "en": "Tile {num}",
        "hi": "टाइल {num}",
        "as": "টাইল {num}",
        "bn": "টাইল {num}",
        "lus": "Tile {num}",
        "mni": "তাইল {num}"
    },
    "gameplay.targetStruck": {
        "en": "Target Struck! +{pts}",
        "hi": "लक्ष्य पर प्रहार! +{pts}",
        "as": "লক্ষ্যত আঘাত! +{pts}",
        "bn": "লক্ষ্যে আঘাত! +{pts}",
        "lus": "Target a fuh e! +{pts}",
        "mni": "তার্গেট থুংলে! +{pts}"
    },
    "gameplay.bambooStage1Name": {
        "en": "Familiarisation",
        "hi": "परिचय",
        "as": "পৰিচিয়",
        "bn": "পরিচিতিকরণ",
        "lus": "Inhriat chianna",
        "mni": "উপায় হৌদোকপা"
    },
    "gameplay.bambooStage1Sub": {
        "en": "Gentle Start",
        "hi": "सहज शुरुआत",
        "as": "সহজ আৰম্ভণি",
        "bn": "সহজ শুরু",
        "lus": "Tan zawi",
        "mni": "তপ্না হৌদোকপা"
    },
    "gameplay.bambooStage2Name": {
        "en": "Gentle Alternation",
        "hi": "हल्का परिवर्तन",
        "as": "ধীৰে সালসলনি",
        "bn": "মৃদু পরিবর্তন",
        "lus": "Inthlak kual",
        "mni": "অনিদা ওন্থোক-ওনশিন"
    },
    "gameplay.bambooStage2Sub": {
        "en": "Left-Right Shifts",
        "hi": "बाएं-दाएं गति",
        "as": "বাওঁ-সোঁ সালসলনি",
        "bn": "বাম-ডান পরিবর্তন",
        "lus": "Vei leh Ding",
        "mni": "য়েৎ-ওই ওনবা"
    },
    "gameplay.bambooStage3Name": {
        "en": "Four Directions",
        "hi": "चारों दिशाएं",
        "as": "চাৰি দিশ",
        "bn": "চার দিক",
        "lus": "Kilmali",
        "mni": "মাইকৈ মরি"
    },
    "gameplay.bambooStage3Sub": {
        "en": "All Directions",
        "hi": "सभी दिशाएं",
        "as": "সকলো দিশ",
        "bn": "সব দিক",
        "lus": "Kil tin",
        "mni": "মাইকৈ পুম্নমক"
    },
    "gameplay.bambooStage4Name": {
        "en": "Rhythm Pattern",
        "hi": "ताल का क्रम",
        "as": "ছন্দৰ আৰ্হি",
        "bn": "ছন্দের প্যাটার্ন",
        "lus": "Rim zawn",
        "mni": "ঈশৈগী তানফম"
    },
    "gameplay.bambooStage4Sub": {
        "en": "Rhythmic Tempo",
        "hi": "लयबद्ध गति",
        "as": "ছন্দোময় গতি",
        "bn": "ছন্দময় গতি",
        "lus": "Rim rang",
        "mni": "তানফমগী খোঙজেল"
    },
    "gameplay.bambooStage5Name": {
        "en": "Pattern Memory",
        "hi": "पैटर्न स्मृति",
        "as": "আৰ্হি স্মৃতি",
        "bn": "প্যাটার্ন স্মৃতি",
        "lus": "Hriatrengna",
        "mni": "পেতর্ন নীংশিংবা"
    },
    "gameplay.bambooStage5Sub": {
        "en": "Memory & Rhythm",
        "hi": "स्मृति और लय",
        "as": "স্মৃতি আৰু ছন্দ",
        "bn": "স্মৃতি ও ছন্দ",
        "lus": "Hriat & Rim",
        "mni": "নীংশিংবা অমসুং তান"
    },
    "gameplay.bambooStage6Name": {
        "en": "Cheraw Harmony",
        "hi": "चेराव सामंजस्य",
        "as": "চেৰাও সমন্বয়",
        "bn": "চেরাও সামঞ্জস্য",
        "lus": "Cheraw Inmil",
        "mni": "চেরাও পুল্লপ তান"
    },
    "gameplay.bambooStage6Sub": {
        "en": "Harmonious Flow",
        "hi": "सुलभ प्रवाह",
        "as": "সুন্দৰ প্ৰবাহ",
        "bn": "সুরল প্রবাহ",
        "lus": "Rualrem taka kal",
        "mni": "নুংঙাইবা চৎখিবী"
    },
    "gameplay.stepTargetHint": {
        "en": "Hint: Tap on the target circle",
        "hi": "संकेत: लक्ष्य वृत्त पर टैप करें",
        "as": "ইংগিত: লক্ষ্য বৃত্তত স্পৰ্শ কৰক",
        "bn": "ইঙ্গিত: লক্ষ্যের বৃত্তে ট্যাপ করুন",
        "lus": "Hriattirna: Target bial kha hmet rawh",
        "mni": "হিন্ট: তার্গেট কোয়দা নম্বীরু"
    },
    "gameplay.exitToHomeTooltip": {
        "en": "Exit to Home",
        "hi": "होम पर जाएं",
        "as": "মুখ্য পৃষ্ঠালৈ যাওক",
        "bn": "হোমে ফিরে যান",
        "lus": "In lamah haw",
        "mni": "য়ুমদা হল্লু"
    },
    "gameplay.readyStartTooltip": {
        "en": "I'm Ready / Start",
        "hi": "मैं तैयार हूँ / शुरू करें",
        "as": "মই সাজু / আৰম্ভ কৰক",
        "bn": "আমি প্রস্তুত / শুরু করুন",
        "lus": "Ka inpeih e / Tan rawh",
        "mni": "ঐ শেম-শারে / হৌরো"
    }
}

# Add all 35 items into extra_game_keys
for item_id, lang_dict in items_data.items():
    name_key = f"items.{item_id}.name"
    region_key = f"items.{item_id}.region"
    
    extra_game_keys[name_key] = {}
    extra_game_keys[region_key] = {}
    
    for lang in ["en", "hi", "as", "bn", "lus", "mni"]:
        extra_game_keys[name_key][lang] = lang_dict[lang]["name"]
        extra_game_keys[region_key][lang] = lang_dict[lang]["region"]

print(f"Total new keys to inject: {len(extra_game_keys)}")

# Now load existing app_translations.dart and parse each language block
with open("lib/l10n/app_translations.dart", "r", encoding="utf-8") as f:
    content = f.read()

languages = ["en", "hi", "as", "bn", "lus", "mni"]

for lang in languages:
    # Generate Dart map entries
    lines_to_add = []
    for key, trans in extra_game_keys.items():
        val = trans[lang].replace("'", "\\'")
        lines_to_add.append(f"      '{key}': '{val}',")
    
    inject_str = "\n".join(lines_to_add) + "\n"
    
    # Locate the closing brace of the language map
    # e.g. for 'en': find "'en': {" up to "    },"
    lang_header = f"    '{lang}': {{"
    start_pos = content.find(lang_header)
    if start_pos == -1:
        print(f"Error: could not find {lang_header}")
        continue
    
    # find next "    }," after start_pos
    end_pos = content.find("    },", start_pos)
    if end_pos == -1:
        print(f"Error: could not find end of map for {lang}")
        continue
    
    # insert inject_str right before end_pos
    content = content[:end_pos] + inject_str + content[end_pos:]

with open("lib/l10n/app_translations.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Updated lib/l10n/app_translations.dart successfully!")
