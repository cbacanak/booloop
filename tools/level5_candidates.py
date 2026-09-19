"""
FTUE 5. seviye adayları (PLAN.md §5).

5. seviye "sıra önemli" öğretir: ruhlar gövdede sırayla durur ve yalnızca kuyruk ucundaki
bırakılır, yani ilk toplanan ilk bırakılır. Aday şu koşulları sağlar:

  - çözümde bir hamle sonunda gövdede iki ruh vardır (oyuncu bunu görür);
  - gövdede en fazla bir ruh taşıyarak kazanmak mümkün değildir (ders atlanamaz);
  - iki ruh ters sırayla taşınırsa (kuyrukta çözümdekinin öbür rengi) durum çıkmazdır,
    ve ters sıra par hamle içinde kurulabilir (tuzak gerçekten önünde durur).

    python3 level5_candidates.py                  # 3 aday (4×5, par 3–4), ASCII tahta + gerekçe
    python3 level5_candidates.py 80000 5 5 3 4    # deneme, genişlik, yükseklik, par aralığı
    python3 level5_candidates.py apply N          # level5-candidates.json'daki N. adayı 5. seviye yap

Üretim tohumlu ve deneme sayısına bağlıdır; aynı parametrelerle her makinede aynı adaylar çıkar.
Aday seçimi elle yapılır (§5); `apply` seçimden sonra çalıştırılır ve ardından
`python3 make_slide_golden.py` ile kayma altın verisi yenilenir.
"""
import collections, json, random, sys
from booloop_gen import slide, won, sig, rand_level, difficulty
from build_levels import from_json
from level4_candidates import ARROW, graph, shortest_count, natural_move

SEED = 2026_05
DATA = "../data/levels-200.json"
OUT = "level5-candidates.json"


def render(L, st):
    """Tahta: G hayalet, a/b ruh (gövdede de), A/B fener, dolu fener *, # duvar."""
    g = [["." for _ in range(L.W)] for _ in range(L.H)]
    for x, y in L.walls: g[y][x] = "#"
    for i, (x, y, c, k) in enumerate(L.lanterns): g[y][x] = "AB"[c] if st[3][i] < k else "*"
    for (x, y), c in st[2]: g[y][x] = "ab"[c]
    for i, (x, y) in enumerate(st[0]): g[y][x] = "G" if i == 0 else "ab"[st[1][i - 1]]
    return "\n".join(" ".join(r) for r in g)


def carried_two(r):
    """Gövdede iki ruh taşınan durumlar: {durum: kuyruktaki renk}."""
    return {s: s[1][-1] for s in r["dist"] if len(s[1]) >= 2}


def wins_carrying_one(L, r):
    """Gövdede hiçbir hamle sonunda ikiden az ruh taşıyarak kazanılabiliyor mu."""
    s0 = L.start(); seen = {s0}; q = collections.deque([s0])
    while q:
        s = q.popleft()
        if won(L, s): return True
        for _, n in r["edges"].get(s, ()):
            if len(n[1]) < 2 and n not in seen: seen.add(n); q.append(n)
    return False


def path_to(L, r, target):
    """Başlangıçtan `target` durumuna en kısa hamle dizisi."""
    s0 = L.start(); prev = {s0: None}; q = collections.deque([s0])
    while q:
        s = q.popleft()
        if s == target: break
        for d, n in r["edges"].get(s, ()):
            if n not in prev: prev[n] = (s, d); q.append(n)
    out = []; cur = target
    while prev[cur]: cur, d = prev[cur]; out.append(d)
    return out[::-1]


def lesson(L, r):
    """Ders koşulları sağlanıyorsa (doğru kuyruk rengi, tuzak durumu), yoksa None."""
    two = carried_two(r)
    st = L.start(); right = None
    for d in r["solution"]:
        st = slide(L, st, d)
        if len(st[1]) >= 2: right = st[1][-1]; break
    if right is None or wins_carrying_one(L, r): return None
    wrong = [s for s, tail in two.items() if tail != right]
    if not wrong or any(s in r["good"] for s in wrong): return None
    trap = min(wrong, key=lambda s: r["dist"][s])
    if r["dist"][trap] > r["par"]: return None
    return right, trap


def strip(L, moves, title):
    """Başlangıç ve her hamleden sonraki tahta yan yana."""
    st = L.start(); boards = [("başlangıç", render(L, st))]
    for i, d in enumerate(moves, 1):
        st = slide(L, st, d); boards.append((f"{i}. {ARROW[d]}", render(L, st)))
    w = 2 * L.W - 1
    print(f"  {title}")
    print("  " + "   ".join(t.ljust(w) for t, _ in boards))
    for row in zip(*(b.split("\n") for _, b in boards)):
        print("  " + "   ".join(x.ljust(w) for x in row))


def describe(L, r, tag):
    right, trap = lesson(L, r)
    names = "ab"; moves = path_to(L, r, trap)
    nat, why = natural_move(L, r["first"])
    print(f"--- {tag}: {L.W}×{L.H}, par {r['par']}, çıkmaz oranı %{round(r['dead']*100)}, "
          f"durum {r['states']}, en kısa çözüm sayısı {shortest_count(L, r)}; "
          f"doğal ilk hamle {ARROW[nat]} ({why}) → {'tuzak' if nat == moves[0] else 'doğru yol' if nat == r['solution'][0] else 'başka'}")
    strip(L, r["solution"], f"doğru çözüm {' '.join(ARROW[d] for d in r['solution'])}: "
                            f"kuyrukta {names[right]}, önce {names[right].upper()} dolar")
    strip(L, moves, f"tuzak {' '.join(ARROW[d] for d in moves)}: kuyrukta {names[1 - right]}, çıkmaz")
    print()


def candidates(cfg, tries):
    rng = random.Random(SEED); seen = set(); out = []
    lo, hi = cfg["par"]
    for _ in range(tries):
        L = rand_level(cfg, rng); r = graph(L)
        if not r or not lo <= r["par"] <= hi: continue
        s = sig(L)
        if s in seen: continue
        seen.add(s)
        x = lesson(L, r)
        if x is None: continue
        right, trap = x
        opt = shortest_count(L, r)
        nat, _ = natural_move(L, r["first"])
        # doğal ilk hamle tuzağa girsin, tuzak erken kurulabilsin, tek çözüm yolu olsun,
        # tahta öğretici kalsın (az çıkmaz)
        score = (nat != path_to(L, r, trap)[0], r["dist"][trap], opt, r["par"], r["dead"])
        out.append((score, L, r))
    out.sort(key=lambda x: x[0])
    # yalnızca bir ruhun ya da başın yeri farklı olan neredeyse aynı tahtaları ele
    picked, layouts = [], set()
    for _, L, r in out:
        key = (L.walls, tuple(l[:3] for l in L.lanterns))
        if key in layouts: continue
        layouts.add(key); picked.append((L, r))
    return picked


def main():
    args = sys.argv[1:]
    if args and args[0] == "apply":
        idx = int(args[1]); c = json.load(open(OUT))[idx - 1]
        L = from_json(c["level"]); r = graph(L)
        assert r["par"] == c["par"] and r["solution"] == c["solution"] and lesson(L, r)
        pack = json.load(open(DATA)); e = pack["levels"][4]; assert e["id"] == 5
        opt = shortest_count(L, r)
        e.update(level=L.to_json(), par=r["par"], moves=None, opt=opt, dead=r["dead"],
                 diff=difficulty(dict(r, opt=opt)), solution=r["solution"], intro=False)
        st = L.start()
        for d in e["solution"]: st = slide(L, st, d)
        assert won(L, st) and len(e["solution"]) == e["par"]
        json.dump(pack, open(DATA, "w"), ensure_ascii=False, separators=(",", ":"))
        print(f"5. seviye {idx}. adayla değiştirildi; şimdi: python3 make_slide_golden.py ve swift test")
        return
    tries = int(args[0]) if args else 40000
    W, H = (int(args[1]), int(args[2])) if len(args) >= 3 else (4, 5)
    par = (int(args[3]), int(args[4])) if len(args) >= 5 else (3, 4)
    cfg = dict(W=W, H=H, colors=2, walls=(1, 3), par=par)
    cands = candidates(cfg, tries)
    print(f"{len(cands)} uygun aday bulundu ({W}×{H}, par {par[0]}–{par[1]}); en iyi 3:\n")
    for i, (L, r) in enumerate(cands[:3], 1):
        describe(L, r, f"Aday {i}")
    json.dump([dict(level=L.to_json(), par=r["par"], solution=r["solution"], dead=r["dead"],
                    opt=shortest_count(L, r))
               for L, r in cands[:3]], open(OUT, "w"), ensure_ascii=False, indent=1)
    print(f"Adaylar {OUT} dosyasına yazıldı. Seçim: python3 level5_candidates.py apply N")


if __name__ == "__main__":
    main()
