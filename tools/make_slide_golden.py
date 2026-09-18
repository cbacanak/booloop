"""
Swift çekirdeği için kayma altın verisi (PLAN.md §10.2).

Her bölümde sabit tohumla rastgele hamle dizileri oynatılır ve her hamleden
sonraki durum booloop_gen.slide ile kaydedilir. Swift aynı diziyi oynatıp
her adımda aynı durumu bulmalı (değişmez 1). Çözüm yeniden oynatması yalnızca
kazanan yolları sınar; bu dosya geçersiz hamleleri, çıkmazları ve ara
durumları da kapsar.

Kullanım:
    cd tools
    python3 make_slide_golden.py
"""
import json, random, os
from booloop_gen import slide, won
from build_levels import from_json

WALKS, STEPS, SEED = 3, 30, 2026
OUT = os.path.join(os.path.dirname(__file__), '..', 'Packages', 'BooloopCore', 'Tests',
                   'BooloopCoreTests', 'Fixtures', 'slide-golden.json')

def enc(st):
    """[gövde [[x,y]...], renkler, kalan ruhlar [[x,y,renk]...], doluluk]"""
    pos, cols, wisps, fill = st
    return [[list(p) for p in pos], list(cols), [[x, y, c] for (x, y), c in wisps], list(fill)]

def main():
    data = json.load(open(os.path.join(os.path.dirname(__file__), '..', 'data', 'levels-200.json')))
    rng = random.Random(SEED); out = []
    for l in data['levels']:
        L = from_json(l['level'])
        for _ in range(WALKS):
            s = L.start(); moves = []; states = []
            for _ in range(STEPS):
                if won(L, s): break
                d = rng.randrange(4); n = slide(L, s, d)
                moves.append(d); states.append(None if n is None else enc(n))
                if n is not None: s = n
            out.append(dict(id=l['id'], moves=moves, states=states))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(dict(rules_version=data['meta']['rules_version'], walks=out), open(OUT, 'w'),
              separators=(',', ':'))
    print(f"{len(out)} yürüyüş -> {os.path.relpath(OUT)}")

if __name__ == '__main__':
    main()
