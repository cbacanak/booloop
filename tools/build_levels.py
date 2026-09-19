"""
Booloop macera bölümlerini üretir ve doğrular.

Kullanım (her bölüm ayrı çalıştırılabilir; uzun bölümler için önerilir):
    python3 build_levels.py chapter 0 50        # 1. bölüm, 50 sn üretim süresi
    python3 build_levels.py chapter 8 150       # 9. bölüm
    python3 build_levels.py assemble            # part-*.json -> levels-200.json + doğrulama

Elle seçilen seviyeler LOCKED listesindedir: `chapter` onları üretmez, depodaki
data/levels-200.json'dan alır ve güncel kurallarla yeniden doğrular. O yuvanın üretimi yine
yapılıp atılır; böylece bir seviyeyi kilitlemek bölümün diğer seviyelerini değiştirmez.

Kurallar PLAN.md §2'de. Bu dosya ve booloop_gen.py Swift çekirdeğinin altın referansıdır.
"""
import sys, json, hashlib, random, collections, time
from booloop_gen import Level, analyze, accept, rand_level, difficulty, sig, slide, won

TUT = [  # 1. bölümün ilk 5 seviyesi (öğretici)
    dict(W=4,H=5,colors=1,walls=(0,1),par=(1,1),need_trap=False),
    dict(W=4,H=5,colors=1,walls=(1,2),par=(2,2),need_trap=False),
    dict(W=4,H=5,colors=2,walls=(1,2),par=(2,2),need_trap=False),
    dict(W=4,H=5,colors=2,walls=(1,3),par=(3,3),need_trap=False),
    dict(W=4,H=5,colors=2,walls=(1,3),par=(3,4),need_trap=False),
]
# Elle seçilen seviyeler (kimlik -> neden). Üretim bunların üzerine yazmaz (PLAN.md §5).
# Yeni bir seviye elle seçilince `apply` sonrası kimliği buraya eklenir.
LOCKED = {
    4: "FTUE çıkmaz + geri al (level4_candidates.py)",
    5: "FTUE sıra önemli (level5_candidates.py)",
}
DATA = '../data/levels-200.json'

CH = [
 dict(name="1 Uyanış",      W=5,H=6,colors=2,walls=(2,4),par=(3,6),need_trap=False,max_opt=20,mult=None),
 dict(name="2 Üç renk",     W=5,H=7,colors=3,walls=(2,5),par=(4,8),mult=2.0),
 dict(name="3 Örümcek ağı", W=6,H=7,colors=3,walls=(2,4),webs=2,par=(4,9),mult=2.0,feats=['webs']),
 dict(name="4 Geniş gece",  W=6,H=8,colors=3,walls=(3,6),webs=1,par=(5,10),mult=1.75),
 dict(name="5 Büyük fener", W=6,H=7,colors=2,walls=(2,5),webs=1,cap2=1,par=(5,10),mult=1.75),
 dict(name="6 Yön okları",  W=6,H=7,colors=3,walls=(2,4),arrows=2,par=(5,10),mult=1.75,feats=['arrows']),
 dict(name="7 Fener kapısı",W=6,H=8,colors=3,walls=(2,5),webs=1,gates=1,par=(6,11),mult=1.75,feats=['gates']),
 dict(name="8 Dört renk",   W=7,H=8,colors=4,walls=(3,6),webs=2,par=(6,11),mult=1.5),
 dict(name="9 Karışık",     W=7,H=8,colors=3,walls=(3,5),webs=1,arrows=1,gates=1,cap2=1,par=(7,12),mult=1.5,feats=['arrows','gates']),
 dict(name="10 Usta",       W=7,H=9,colors=4,walls=(3,6),webs=2,arrows=1,cap2=1,par=(8,13),max_opt=12,mult=1.5),
]

def from_json(j):
    return Level(j['w'],j['h'],map(tuple,j['walls']),map(tuple,j['webs']),
                 {(a,b):d for a,b,d in j['arrows']},{(a,b):g for a,b,g in j['gates']},
                 tuple(j['head']),[tuple(x) for x in j['lanterns']],[tuple(x) for x in j['wisps']])

def strip(L, feat):
    j = L.to_json()
    if feat in ('webs','arrows','gates'): j[feat] = []
    return from_json(j)

def needs(L, r, feats, limit):
    """Tanıtılan mekanik kaldırılınca bölüm aynı ya da daha kısa çözülüyorsa mekanik süstür -> ret."""
    for f in feats:
        r2 = analyze(strip(L,f), limit=limit+4, cap=60000)
        if r2 and r2['par'] <= r['par']: return False
    return True

def targets(lo, hi):
    """Testere dişi: 1-5 düşük, 6-15 artan, 16-19 tepe, 20 nefes."""
    t = [lo, lo, lo+1, lo, lo+1]
    t += [lo+1+round(i*(hi-1-(lo+1))/9) for i in range(10)]
    t += [hi, hi-1, hi, hi, (lo+hi)//2]
    return t

def move_budget(par, mult):
    return None if mult is None else par + max(3, round(par*(mult-1)))

def gen_pool(cfg, rng, seen, want, seconds, feats=()):
    pool = collections.defaultdict(list); t = time.time(); tries = 0
    while time.time()-t < seconds and sum(map(len, pool.values())) < want:
        tries += 1
        L = rand_level(cfg, rng); r = analyze(L, limit=cfg['par'][1], cap=60000)
        if not r or not accept(r, cfg, L): continue
        if feats and not needs(L, r, feats, cfg['par'][1]): continue
        s = sig(L)
        if s in seen: continue
        seen.add(s); r['diff'] = difficulty(r); pool[r['par']].append((L, r))
    return pool, tries

def take(pool, par):
    for dp in (0,-1,1,-2,2,-3,3):
        g = pool.get(par+dp)
        if g:
            g.sort(key=lambda x: x[1]['diff']); return g.pop(len(g)//2)
    return None

def locked_entry(n):
    """Kilitli seviye: depodaki veriden alınır, güncel kurallarla yeniden doğrulanır."""
    e = next(l for l in json.load(open(DATA))['levels'] if l['id'] == n)
    L = from_json(e['level']); s = L.start()
    for d in e['solution']:
        s = slide(L, s, d); assert s is not None, n
    assert won(L, s) and len(e['solution']) == e['par'], n
    r = analyze(L, limit=e['par'], cap=200000)
    assert r and r['par'] == e['par'], f"kilitli seviye {n}: güncel kurallarla par {r and r['par']} != {e['par']}"
    return {k: v for k, v in e.items() if k != 'id'}

def build_chapter(ci, seconds):
    cfg = CH[ci]; rng = random.Random(2026+ci); seen = set(); out = []
    locked = {n: locked_entry(n) for n in LOCKED if ci*20 < n <= ci*20+20}
    for e in locked.values(): seen.add(sig(from_json(e['level'])))
    pool, tries = gen_pool(cfg, rng, seen, 160, seconds, cfg.get('feats', ()))
    for i, p in enumerate(targets(*cfg['par'])):
        if ci == 0 and i < 5:
            tp, _ = gen_pool(TUT[i], rng, seen, 1, 10); x = take(tp, TUT[i]['par'][0])
        else:
            x = take(pool, p) or take(pool, cfg['par'][1]) or take(pool, cfg['par'][0])
        if x is None: raise SystemExit(f"{cfg['name']}: aday bitti, süreyi artır")
        L, r = x
        if ci*20+i+1 in locked:                # yuva kilitli: üretilen atılır
            out.append(locked[ci*20+i+1]); continue
        out.append(dict(chapter=cfg['name'], level=L.to_json(), par=r['par'],
                        moves=move_budget(r['par'], cfg.get('mult')), opt=r['opt'], dead=r['dead'],
                        diff=r['diff'], solution=r['solution'], intro=(i == 0 and 'feats' in cfg)))
    rep = dict(chapter=cfg['name'], tries=tries, pars=[l['par'] for l in out],
               dead=round(sum(l['dead'] for l in out)/len(out), 2), locked=sorted(locked))
    json.dump(out, open(f'part-{ci}.json','w'), ensure_ascii=False)
    json.dump([rep], open(f'rep-{ci}.json','w'), ensure_ascii=False)
    print(rep)

def assemble(path='levels-200.json'):
    levels = []
    for i in range(len(CH)): levels += json.load(open(f'part-{i}.json'))
    hashes = set()
    for n, l in enumerate(levels, 1):
        l['id'] = n
        L = from_json(l['level']); s = L.start()
        for d in l['solution']:
            s = slide(L, s, d); assert s is not None, n
        assert won(L, s) and len(l['solution']) == l['par'], n
        assert l['moves'] is None or l['moves'] >= l['par'], n
        h = hashlib.md5(json.dumps(l['level'], sort_keys=True).encode()).hexdigest()
        assert h not in hashes, n
        hashes.add(h)
    meta = dict(schema=1, rules_version=1, count=len(levels),
                directions="0=up 1=right 2=down 3=left",
                lantern="[x,y,color,capacity]", wisp="[x,y,color]",
                gate="[x,y,lanternIndex]", arrow="[x,y,direction]")
    json.dump(dict(meta=meta, levels=levels), open(path,'w'), ensure_ascii=False, separators=(',',':'))
    print(f"{len(levels)} bölüm doğrulandı -> {path}")

if __name__ == '__main__':
    if sys.argv[1] == 'chapter': build_chapter(int(sys.argv[2]), float(sys.argv[3]))
    elif sys.argv[1] == 'assemble': assemble()
