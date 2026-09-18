# Booloop — Çalışma kuralları

Tek kaynak `PLAN.md`. Kural orada yazmıyorsa oyunda yoktur.

## Değişmezler (PLAN.md §2.10)

1. Aynı bölüm + aynı hamle dizisi → her cihazda aynı sonuç.
2. Yayınlanmış bölüm verisi değişmez; düzeltme yeni kimlikle gelir.
3. Her bölümün kayıtlı çözümü kazanır ve uzunluğu par'a eşittir.
4. Hamle hakkı ≥ par; her bölüm güçlendiricisiz geçilebilir.
5. Kozmetik hiçbir kuralı etkilemez.

## Yapı

- `Packages/BooloopCore`: saf Swift. SpriteKit/UIKit içe aktarılmaz.
  Kurallar (`slide`), çözücü, çıkmaz tespiti, JSON modeli.
- `Booloop/`: SpriteKit sahnesi ve arayüz. Kural mantığı burada yazılmaz;
  sahne yalnızca `BooloopCore`'un döndürdüğü adımları çizer.
- `tools/booloop_gen.py`: **altın referans.** Swift kuralı Python'dan
  farklı davranıyorsa hata Swift'tedir, ta ki PLAN.md değişene kadar.

## Kural değişikliği sırası

1. PLAN.md §2 güncellenir (`rules_version` artar).
2. `tools/booloop_gen.py` güncellenir.
3. Bölümler yeniden üretilir ve doğrulanır (`build_levels.py assemble`).
4. Swift çekirdeği ve altın testler güncellenir.

Yayınlanmış bölümler varsa kural değişikliği yalnızca yeni
`rules_version` ile ve eski bölümlerin doğrulanmasıyla yapılır.

## Testler

- `swift test` (Packages/BooloopCore) simülatörsüz koşar ve her PR'da
  yeşil olmalı.
- Altın test: `data/levels-200.json` içindeki 200 çözüm yeniden oynatılır
  ve Swift çözücü aynı par'ı bulur.

## Bölüm üretimi

```
cd tools
python3 build_levels.py chapter <0-9> <saniye>
python3 build_levels.py assemble
```

Uzun bölümleri (8, 9) ayrı ayrı çalıştır. Üretim aynı tohumla
tekrarlanabilir.

## Git

Her iş ayrı dalda, ayrı PR. `main` her zaman derlenir ve testleri geçer.

**Commit yazarlığı:** Commit'lerde Claude yazar ya da ortak yazar olarak
yer almaz. `Co-Authored-By: Claude ...` satırı eklenmez; commit
mesajına ve PR açıklamasına "Generated with Claude Code" veya benzeri
bir imza yazılmaz. Commit'ler yalnızca depo sahibinin git kimliğiyle
atılır; `git config user.name` / `user.email` değiştirilmez.
