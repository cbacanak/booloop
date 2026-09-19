# Booloop

**Booloop: Ghost Sort Puzzle** — iOS, iPhone, dikey. Swift + SpriteKit.

Sevimli bir hayaleti kaydırarak kayıp ruhları topla. Ruhlar hayaletin
arkasında sıraya girer: **ilk toplanan, ilk bırakılır.** Kuyruk kendi
rengindeki fenerin üstünden geçince ruh fenere girer. Bütün fenerler
yanınca gece biter.

## Belgeler

| Dosya | İçerik |
|---|---|
| `PLAN.md` | Tek kaynak: kurallar, mekanikler, 200 bölüm, gelir, metrikler, teknik yapı, aşamalar, mağaza |
| `CLAUDE.md` | Kodlama ajanı için çalışma kuralları ve değişmezler |
| `project.yml` | Xcode projesinin tek kaynağı (XcodeGen) |

Kural `PLAN.md` §2'de yazmıyorsa oyunda yoktur.

## Bölümler

`data/levels-200.json` — 200 bölüm, 10 bölüm × 20 seviye. Her bölüm
üretildi, çözüldü ve çözümü yeniden oynatılarak doğrulandı. Par 1–13,
ortalama 7,7.

```
cd tools
python3 build_levels.py chapter <0-9> <saniye>   # tek bölüm üret
python3 build_levels.py assemble                 # birleştir + doğrula -> data/levels-200.json
```

`tools/booloop_gen.py` kuralların **altın referansı.** Swift çekirdeği
bundan farklı davranıyorsa hata Swift'tedir (bkz. `CLAUDE.md`).

## Derleme

```
brew install xcodegen
xcodegen generate          # Booloop.xcodeproj üretir (depoya girmez)
open Booloop.xcodeproj     # Booloop şeması, iPhone simülatörü, ⌘R
```

`Packages/BooloopCore` için `swift test` simülatörsüz koşar. Uygulama
testleri (`BooloopTests`) ilk 40 seviyenin çözümünü sahne üzerinden
oynatır; Xcode'da ⌘U.

## Durum

Aşama 1 (BooloopCore: kurallar, çözücü, altın testler) tamam. Aşama 2
(oynanabilir dilim: SpriteKit sahnesi, kaydırma, geri al, çıkmaz
göstergesi, FTUE, ilk 40 seviye) bu depoda; görseller geçici. Görsel
üretim yolu henüz seçilmedi (PLAN.md §14).
