# -*- coding: utf-8 -*-
with open('assets/research.txt', 'r', encoding='utf-8') as f:
    text = f.read()

stories = text.split('\n# ')
for idx, s in enumerate(stories):
    if not s.strip(): continue
    lines = s.strip().split('\n')
    title = lines[0].replace('# ', '').strip()
    print(f"Story {idx}: {title}")
    sub_headers = [l for l in lines if l.startswith('## ') or l.startswith('### ')]
    for sh in sub_headers:
        print(f"  {sh}")
