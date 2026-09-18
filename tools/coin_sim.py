"""Booloop coin ekonomisi simülasyonu (PLAN.md §7.5).

200 bölümü üç oyuncu tipiyle oynatır; 200 bölüm boyunca kazanılan coin'i,
başarısızlık sayısını ve bütün başarısızlıkları coin ile +5 hamle alarak
kurtarmanın bedelini hesaplar. Varsayımlar kaba; Aşama 2–5 verisiyle
güncellenir.

    python3 coin_sim.py [tekrar]
"""
import random, statistics as st, sys

COIN = {3: 25, 2: 15, 1: 10}          # ilk bitirme ödülü (§7.1)
COST = {'hint': 60, 'swap': 90, 'moves5': 120}  # §7.2

# s3/s2: 3 ve 2 yıldız oranı; fail: bölüm (chapter) başına bir denemenin
# başarısız olma olasılığı; dbl: bölüm sonu x2 reklamını izleme oranı.
TYPES = {
    'zayıf': dict(s3=.20, s2=.40, dbl=.3,
                  fail=[.05, .10, .15, .20, .22, .25, .28, .30, .35, .40]),
    'orta':  dict(s3=.35, s2=.40, dbl=.5,
                  fail=[.03, .06, .09, .12, .14, .16, .18, .20, .24, .28]),
    'iyi':   dict(s3=.60, s2=.30, dbl=.5,
                  fail=[.01, .03, .05, .07, .08, .09, .10, .12, .15, .18]),
}

def play(t, rng):
    earned = fails = 0
    for i in range(200):
        ch = i // 20
        if i >= 20:                      # 1. bölümde hamle hakkı sınırsız
            while rng.random() < t['fail'][ch]:
                fails += 1
        r = rng.random()
        stars = 3 if r < t['s3'] else 2 if r < t['s3'] + t['s2'] else 1
        c = COIN[stars]
        if rng.random() < t['dbl']:
            c *= 2
        earned += c
    return earned, fails

def main(n=2000):
    rng = random.Random(1)
    print(f"{'oyuncu':8} {'kazanç':>8} {'başarısız':>10} {'+5 bedeli':>10}")
    for name, t in TYPES.items():
        runs = [play(t, rng) for _ in range(n)]
        e = st.mean(r[0] for r in runs)
        f = st.mean(r[1] for r in runs)
        print(f"{name:8} {e:8.0f} {f:10.0f} {f * COST['moves5']:10.0f}")

if __name__ == '__main__':
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 2000)
