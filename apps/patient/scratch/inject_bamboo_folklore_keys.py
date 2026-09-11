import re

new_keys = {
    'en': {
        'gameplay.bambooStage1Name': 'Familiarisation',
        'gameplay.bambooStage1Sub': 'Gentle Start',
        'gameplay.bambooStage2Name': 'Gentle Alternation',
        'gameplay.bambooStage2Sub': 'Left-Right Shifts',
        'gameplay.bambooStage3Name': 'Four Directions',
        'gameplay.bambooStage3Sub': 'All Directions',
        'gameplay.bambooStage4Name': 'Rhythm Pattern',
        'gameplay.bambooStage4Sub': 'Rhythmic Tempo',
        'gameplay.bambooStage5Name': 'Pattern Memory',
        'gameplay.bambooStage5Sub': 'Memory & Rhythm',
        'gameplay.bambooStage6Name': 'Cheraw Harmony',
        'gameplay.bambooStage6Sub': 'Harmonious Flow',
        'folklore.samplePreview': 'Preview: Sample Storybook Text ({size} pt)',
        'folklore.bookmarked': 'Bookmarked',
        'folklore.bookmarkStory': 'Bookmark Story',
    },
    'hi': {
        'gameplay.bambooStage1Name': 'प्रारंभिक अभ्यास',
        'gameplay.bambooStage1Sub': 'सहज शुरुआत',
        'gameplay.bambooStage2Name': 'सहज प्रत्यावर्तन',
        'gameplay.bambooStage2Sub': 'बाएँ-दाएँ बदलाव',
        'gameplay.bambooStage3Name': 'चारों दिशाएँ',
        'gameplay.bambooStage3Sub': 'सभी दिशाएँ',
        'gameplay.bambooStage4Name': 'ताल क्रम',
        'gameplay.bambooStage4Sub': 'लयबद्ध गति',
        'gameplay.bambooStage5Name': 'क्रम स्मृति',
        'gameplay.bambooStage5Sub': 'स्मृति और लय',
        'gameplay.bambooStage6Name': 'चेरॉव तालमेल',
        'gameplay.bambooStage6Sub': 'सुरीला प्रवाह',
        'folklore.samplePreview': 'पूर्वावलोकन: नमूना कहानी पाठ ({size} pt)',
        'folklore.bookmarked': 'बुकमार्क किया गया',
        'folklore.bookmarkStory': 'कहानी बुकमार्क करें',
    },
    'as': {
        'gameplay.bambooStage1Name': 'প্ৰাৰম্ভিক অভ্যাস',
        'gameplay.bambooStage1Sub': 'সহজ আৰম্ভণি',
        'gameplay.bambooStage2Name': 'মৃদু পৰিৱৰ্তন',
        'gameplay.bambooStage2Sub': 'বাওঁ-সোঁ পৰিৱৰ্তন',
        'gameplay.bambooStage3Name': 'চাৰি দিশ',
        'gameplay.bambooStage3Sub': 'সকলো দিশ',
        'gameplay.bambooStage4Name': 'ছন্দৰ আৰ্হি',
        'gameplay.bambooStage4Sub': 'ছন্দোময় গতি',
        'gameplay.bambooStage5Name': 'আৰ্হি স্মৃতি',
        'gameplay.bambooStage5Sub': 'স্মৃতি আৰু ছন্দ',
        'gameplay.bambooStage6Name': 'চেৰাও সমন্বয়',
        'gameplay.bambooStage6Sub': 'সুৰীয়া প্ৰবাহ',
        'folklore.samplePreview': 'পূৰ্বদৰ্শন: নমুনা সাধুকথাৰ পাঠ ({size} pt)',
        'folklore.bookmarked': 'বুকমাৰ্ক কৰা হ’ল',
        'folklore.bookmarkStory': 'সাধুকথা বুকমাৰ্ক কৰক',
    },
    'bn': {
        'gameplay.bambooStage1Name': 'প্রাথমিক অভ্যাস',
        'gameplay.bambooStage1Sub': 'সহজ শুরু',
        'gameplay.bambooStage2Name': 'মৃদু পরিবর্তন',
        'gameplay.bambooStage2Sub': 'বাম-ডান সরণ',
        'gameplay.bambooStage3Name': 'চারটি দিক',
        'gameplay.bambooStage3Sub': 'সকল দিক',
        'gameplay.bambooStage4Name': 'ছন্দের বিন্যাস',
        'gameplay.bambooStage4Sub': 'ছন্দময় গতি',
        'gameplay.bambooStage5Name': 'বিন্যাস স্মৃতি',
        'gameplay.bambooStage5Sub': 'স্মৃতি ও ছন্দ',
        'gameplay.bambooStage6Name': 'চেরাও মেলবন্ধন',
        'gameplay.bambooStage6Sub': 'সুললিত প্রবাহ',
        'folklore.samplePreview': 'প্রাকদর্শন: নমুনা গল্পের পাঠ ({size} pt)',
        'folklore.bookmarked': 'বুকমার্ক করা হয়েছে',
        'folklore.bookmarkStory': 'গল্প বুকমার্ক করুন',
    },
    'lus': {
        'gameplay.bambooStage1Name': 'Inzir ṭanna',
        'gameplay.bambooStage1Sub': 'Zawi zawiin',
        'gameplay.bambooStage2Name': 'Inthlak kual',
        'gameplay.bambooStage2Sub': 'Vei leh ding',
        'gameplay.bambooStage3Name': 'Kiltin sawm',
        'gameplay.bambooStage3Sub': 'Hawi zawng zawng',
        'gameplay.bambooStage4Name': 'Rik dan kalhmang',
        'gameplay.bambooStage4Sub': 'Hla rithim',
        'gameplay.bambooStage5Name': 'Hriat kawng',
        'gameplay.bambooStage5Sub': 'Hriatreng leh rithim',
        'gameplay.bambooStage6Name': 'Cheraw inmil',
        'gameplay.bambooStage6Sub': 'Nungchang mawi',
        'folklore.samplePreview': 'En lawkna: Thawnthu ziak zikzawng ({size} pt)',
        'folklore.bookmarked': 'Chhinchhiah tawh',
        'folklore.bookmarkStory': 'Thawnthu chhinchhiah rawh',
    },
    'mni': {
        'gameplay.bambooStage1Name': 'অহানবা তাঙ্কাক',
        'gameplay.bambooStage1Sub': 'তপ্না হৌবা',
        'gameplay.bambooStage2Name': 'অহোংবা তান্থা',
        'gameplay.bambooStage2Sub': 'ওই-য়েত লেপ্নবা',
        'gameplay.bambooStage3Name': 'মাইকৈ মরি',
        'gameplay.bambooStage3Sub': 'মাইকৈ পুম্নমক',
        'gameplay.bambooStage4Name': 'তান্থাগী শক্তম',
        'gameplay.bambooStage4Sub': 'তান্থাগী খোঙজেল',
        'gameplay.bambooStage5Name': 'শক্তম নীংশিংবা',
        'gameplay.bambooStage5Sub': 'নীংশিংবা অমসুং তান্থা',
        'gameplay.bambooStage6Name': 'চেরাওগী পুল্লপ খোঙজেল',
        'gameplay.bambooStage6Sub': 'নুংশিবা ঈচেল',
        'folklore.samplePreview': 'য়েংখৎপা: ৱারীগী নমুনা ময়েক ({size} pt)',
        'folklore.bookmarked': 'খুৎয়েক থমখ্রে',
        'folklore.bookmarkStory': 'ৱারীদা খুৎয়েক থম্মু',
    },
}

with open(r"lib/l10n/app_translations.dart", 'r', encoding='utf-8') as f:
    content = f.read()

for lang, kvs in new_keys.items():
    # Insert before "'activities.moodBoost':" in each language section
    insert_block = ""
    for k, v in sorted(kvs.items()):
        v_escaped = v.replace("'", "\\'")
        insert_block += f"      '{k}': '{v_escaped}',\n"

    # Find the language block
    pattern = rf"('{lang}':\s*\{{\s*'name':\s*'[^']+',\s*'nativeName':\s*'[^']+',\s*)"
    m = re.search(pattern, content)
    if not m:
        print(f"Could not find header for {lang}!")
        continue
    content = content[:m.end()] + f"\n      // Bamboo & Folklore Extras\n{insert_block}" + content[m.end():]

with open(r"lib/l10n/app_translations.dart", 'w', encoding='utf-8') as f:
    f.write(content)

print("Successfully injected all new keys into app_translations.dart!")
