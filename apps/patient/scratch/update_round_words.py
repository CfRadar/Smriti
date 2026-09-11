with open(r"lib/l10n/app_translations.dart", 'r', encoding='utf-8') as f:
    content = f.read()

# Hindi
content = content.replace(
    "'gameplay.round': 'राउंड {round} / {total}',",
    "'gameplay.round': 'प्रयास {round} / {total}',"
)
content = content.replace(
    "'gameplay.step': 'कदम {step} / {total}',",
    "'gameplay.step': 'प्रयास {step} / {total}',"
)
content = content.replace(
    "'gameplay.aimAndStrike': 'दौर {round} / {total} • निशाना लगाएं और मारें',",
    "'gameplay.aimAndStrike': 'प्रयास {round} / {total} • निशाना लगाएं और मारें',"
)

# Assamese
content = content.replace(
    "'gameplay.round': 'ৰাউণ্ড {round} / {total}',",
    "'gameplay.round': 'চেষ্টা {round} / {total}',"
)
content = content.replace(
    "'gameplay.step': 'পদক্ষেপ {step} / {total}',",
    "'gameplay.step': 'চেষ্টা {step} / {total}',"
)
content = content.replace(
    "'gameplay.aimAndStrike': 'ৰাউণ্ড {round} / {total} • লক্ষ্য আৰু আঘাত',",
    "'gameplay.aimAndStrike': 'চেষ্টা {round} / {total} • লক্ষ্য আৰু আঘাত',"
)

# Bengali
content = content.replace(
    "'gameplay.round': 'রাউন্ড {round} / {total}',",
    "'gameplay.round': 'চেষ্টা {round} / {total}',"
)
content = content.replace(
    "'gameplay.step': 'ধাপ {step} / {total}',",
    "'gameplay.step': 'চেষ্টা {step} / {total}',"
)
content = content.replace(
    "'gameplay.aimAndStrike': 'রাউন্ড {round} / {total} • টিপ ও আঘাত',",
    "'gameplay.aimAndStrike': 'চেষ্টা {round} / {total} • টিপ ও আঘাত',"
)

# Mizo
content = content.replace(
    "'gameplay.step': 'Kalphung {step} / {total}',",
    "'gameplay.step': 'Trial {step} / {total}',"
)
content = content.replace(
    "'gameplay.round': 'Round {round} / {total}',",
    "'gameplay.round': 'Trial {round} / {total}',"
)
content = content.replace(
    "'gameplay.aimAndStrike': 'Round {round} / {total} • Tin la kap rawh',",
    "'gameplay.aimAndStrike': 'Trial {round} / {total} • Tin la kap rawh',"
)

# Manipuri
content = content.replace(
    "'gameplay.round': 'রাউন্দ {round} / {total}',",
    "'gameplay.round': 'হোৎনবা {round} / {total}',"
)
content = content.replace(
    "'gameplay.step': 'খোঙথাং {step} / {total}',",
    "'gameplay.step': 'হোৎনবা {step} / {total}',"
)
content = content.replace(
    "'gameplay.aimAndStrike': 'রাউন্দ {round} / {total} • পান্দম অমসুং থাদোকপা',",
    "'gameplay.aimAndStrike': 'হোৎনবা {round} / {total} • পান্দম অমসুং থাদোকপা',"
)

with open(r"lib/l10n/app_translations.dart", 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated round words across all languages successfully!")
