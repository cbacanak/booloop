"""
FTUE 4. seviye adayları (PLAN.md §5).

4. seviye "sıra önemli, çıkmaz, geri al" öğretir: ilk hamlelerden en az biri
çıkmaza götürmeli ve o hamle "en doğal" görünen olmalı. Bu betik öğretici
ayarla (4×5, iki renk, par 3) aday üretir, her adayın ilk hamlelerini
sınıflandırır ve doğal hamlesi çıkmaza götüren en iyi 3 adayı basar.

    python3 level4_candidates.py            # 3 aday, ASCII tahta + gerekçe
    python3 level4_candidates.py 80000      # daha çok deneme (varsayılan 40000)
    python3 level4_candidates.py apply N    # level4-candidates.json'daki N. adayı 4. seviye yap

Üretim tohumlu ve deneme sayısına bağlıdır; aynı sayıyla her makinede aynı adaylar çıkar.

"Doğal hamle" sezgisi: ruh toplayan ilk hamle (en az adımda toplayan önce);
hiçbiri toplamıyorsa hayaleti en yakın ruha en çok yaklaştıran hamle.
Aday seçimi elle yapılır (§5); `apply` seçimden sonra çalıştırılır ve ardından
`python3 make_slide_golden.py` ile kayma altın verisi yenilenir.
"""
import collections, json, random, sys
from booloop_gen import Level, slide, won, sig, rand_level, difficulty
from build_levels import TUT, from_json

ARROW = "↑→↓←"
SEED = 2026_04
DATA = "../data/levels-200.json"
OUT = "level4-candidates.json"


def graph(L, cap=20000):
    """Tam durum grafiği: mesafe, kenarlar, kazanabilen durumlar."""
    s0 = L.start(); dist = {s0: 0}; q = collections.deque([s0]); edges = {}
    while q:
        s = q.popleft(); edges[s] = []
        if won(L, s): continue
        for d in range(4):
            n = slide(L, s, d)
            if n is None: continue
            edges[s].append((d, n))
            if n not in dist:
                dist[n] = dist[s] + 1; q.append(n)
                if len(dist) > cap: return None
    goal = min((dist[s] for s in dist if won(L, s)), default=None)
    if goal is None: return None
    rev = collections.defaultdict(list)
    for s, es in edges.items():
        for d, n in es: rev[n].append(s)
    good = {s for s in dist if won(L, s)}; st = list(good)
    while st:
        x = st.pop()
        for p in rev[x]:
            if p not in good: good.add(p); st.append(p)
    nonwin = [s for s in dist if not won(L, s)]
    dead = sum(1 for s in nonwin if s not in good) / max(1, len(nonwin))
    # en kısa çözüm
    path = []; cur = next(s for s in dist if won(L, s) and dist[s] == goal)
    while cur != s0:
        p = next(p for p in rev[cur] if dist[p] == dist[cur] - 1)
        path.append(next(d for d, n in edges[p] if n == cur)); cur = p
    return dict(par=goal, states=len(dist), dead=round(dead, 3), solution=path[::-1],
                first=[(d, n in good, n) for d, n in edges[s0]], edges=edges, good=good, dist=dist)


def shortest_count(L, r):
    """En kısa çözüm sayısı (booloop_gen.analyze ile aynı tanım)."""
    s0 = L.start(); ways = {s0: 1}; layers = collections.defaultdict(list)
    for s, dd in r["dist"].items(): layers[dd].append(s)
    for dd in range(r["par"]):
        for s in layers[dd]:
            w = ways.get(s, 0)
            if not w or won(L, s): continue
            for d, n in r["edges"][s]:
                if r["dist"].get(n) == dd + 1: ways[n] = ways.get(n, 0) + w
    return sum(ways.get(s, 0) for s in layers[r["par"]] if won(L, s))


def natural_move(L, first):
    """(yön, gerekçe). Ruh toplayan hamle; yoksa en yakın ruha en çok yaklaşan."""
    s0 = L.start(); wisps = [w for w, _ in s0[2]]
    best = None
    for d, ok, n in first:
        collected = len(s0[2]) - len(n[2])
        if collected:
            # kaç adımda toplandı: baş ile başlangıç arası mesafe kadar kaydı; toplanan ruhun
            # başlangıç konumu gövdenin sonundadır
            steps = abs(n[0][0][0] - L.head[0]) + abs(n[0][0][1] - L.head[1]) + len(n[0]) - 1
            key = (0, steps)
        else:
            hx, hy = n[0][0]
            key = (1, min(abs(hx - x) + abs(hy - y) for x, y in wisps))
        if best is None or key < best[0]: best = (key, d, collected)
    key, d, collected = best
    why = "ruh toplar" if collected else "en yakın ruha yaklaşır"
    return d, why


def render(L):
    g = [["." for _ in range(L.W)] for _ in range(L.H)]
    for x, y in L.walls: g[y][x] = "#"
    for x, y, c, k in L.lanterns: g[y][x] = "AB"[c]
    for x, y, c in L.wisps: g[y][x] = "ab"[c]
    x, y = L.head; g[y][x] = "G"
    return "\n".join(" ".join(r) for r in g)


def describe(L, r, tag):
    nat, why = natural_move(L, r["first"])
    dead_moves = [ARROW[d] for d, ok, _ in r["first"] if not ok]
    print(f"--- {tag}: {L.W}×{L.H}, par {r['par']}, çözüm {' '.join(ARROW[d] for d in r['solution'])}, "
          f"çıkmaz oranı %{round(r['dead']*100)}, durum {r['states']}")
    print(render(L))
    print(f"    ilk hamleler: " + ", ".join(f"{ARROW[d]}{'✓' if ok else '✗'}" for d, ok, _ in r["first"]))
    print(f"    doğal hamle {ARROW[nat]} ({why}) → {'ÇIKMAZ' if nat in [d for d, ok, _ in r['first'] if not ok] else 'güvenli'}; "
          f"çıkmaza götüren hamleler: {' '.join(dead_moves) or 'yok'}")
    print()


def candidates(tries):
    cfg = TUT[3]; rng = random.Random(SEED); seen = set(); out = []
    for _ in range(tries):
        L = rand_level(cfg, rng); r = graph(L)
        if not r or r["par"] != 3: continue
        s = sig(L)
        if s in seen: continue
        seen.add(s)
        nat, _ = natural_move(L, r["first"])
        dead = {d for d, ok, _ in r["first"] if not ok}
        if nat not in dead: continue
        # doğal hamle ruh toplamalı (ders: "yanlış sırayla toplamak"), çözüm hamlesi ise
        # güvenli kalmalı; çok fazla hamle çıkmaza götürüyorsa ders bulanıklaşır
        s0 = L.start(); n_nat = next(n for d, ok, n in r["first"] if d == nat)
        if len(n_nat[2]) == len(s0[2]): continue
        score = (len(dead), -len(r["first"]), r["dead"])
        out.append((score, L, r))
    out.sort(key=lambda x: x[0])
    return [(L, r) for _, L, r in out]


def main():
    args = sys.argv[1:]
    if args and args[0] == "apply":
        idx = int(args[1]); c = json.load(open(OUT))[idx - 1]
        L = from_json(c["level"]); r = graph(L)
        assert r["par"] == c["par"] == 3 and r["solution"] == c["solution"]
        pack = json.load(open(DATA)); e = pack["levels"][3]; assert e["id"] == 4
        e.update(level=L.to_json(), par=r["par"], moves=None, opt=c["opt"], dead=r["dead"],
                 diff=difficulty(dict(r, opt=c["opt"])), solution=r["solution"], intro=False)
        st = L.start()
        for d in e["solution"]: st = slide(L, st, d)
        assert won(L, st) and len(e["solution"]) == e["par"]
        json.dump(pack, open(DATA, "w"), ensure_ascii=False, separators=(",", ":"))
        print(f"4. seviye {idx}. adayla değiştirildi; şimdi: python3 make_slide_golden.py ve swift test")
        return
    tries = int(args[0]) if args else 40000
    pack = json.load(open(DATA)); cur = from_json(pack["levels"][3]["level"])
    describe(cur, graph(cur), "Mevcut 4. seviye (id 4)")
    cands = candidates(tries)
    print(f"{len(cands)} uygun aday bulundu; en iyi 3:\n")
    for i, (L, r) in enumerate(cands[:3], 1):
        describe(L, r, f"Aday {i}")
    json.dump([dict(level=L.to_json(), par=r["par"], solution=r["solution"], dead=r["dead"],
                    opt=shortest_count(L, r))
               for L, r in cands[:3]], open(OUT, "w"), ensure_ascii=False, indent=1)
    print(f"Adaylar {OUT} dosyasına yazıldı. Seçim: python3 level4_candidates.py apply N")


if __name__ == "__main__":
    main()
