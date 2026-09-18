# Booloop — Plan

**Mağaza adı:** Booloop: Ghost Sort Puzzle (26/30 karakter)
**Tür:** hybridcasual sıralama bulmacası, kısa bölümlü
**Platform:** yalnızca iOS, iPhone, dikey. Android ve iPad bu planın dışında.
**Motor:** Swift + SpriteKit. Kurallar ve çözücü, SpriteKit'e bağımlı olmayan
saf bir Swift paketinde (`BooloopCore`).
**Durum (16 Eyl 2026):** kurallar net, 200 bölüm üretildi ve doğrulandı
(`data/levels-200.json`), referans üreteç ve çözücü hazır (`tools/`).
Kod yazılmadı.

Bu belge tek kaynak. Bir kural burada yazmıyorsa oyunda yoktur. Bir kural
değişirse önce burası değişir, sonra kod.

---

## 1. Oyun tek cümlede

Sevimli bir hayaleti kaydırarak kayıp ruhları topla; ruhlar hayaletin
arkasında sıraya girer ve **en önce toplanan, en önce bırakılır**. Kuyruk
kendi rengindeki fenerin üstünden geçince ruh fenere girer. Bütün fenerler
yanınca gece biter.

### 1.1 Fark

En yakın rakip Voodoo'nun **Snacky Dash** oyunu (yılan + meyve + kamyona
teslim, 300+ elle tasarlanmış bölüm, 4,7★ / 1,7 bin puan). Farkımız
yapısal olmak zorunda, çünkü arayüz iyileştirmelerini büyük bir ekip iki
haftada kopyalar:

| | Snacky Dash | Booloop |
|---|---|---|
| Teslim | Önce topla, sonra kamyon | Yol boyunca, kuyruktan, sırayla |
| Bölüm | Elle | Üreteç + çözücü; her bölüm çözülebilir ve par'ı bilinir |
| Çıkmaz | Oyuncu fark etmez | Çözücü anında gösterir (§2.8) |
| İpucu | Pahalı güçlendirici | Çözücünün bir sonraki doğru hamlesi (§7) |
| Günlük mod | Yok | Par'lı günlük bölüm + spoiler'sız paylaşım (§6.2) |
| Tema | Yılan, meyve, kamyon | Hayalet, ruh, fener |
| Renk körlüğü | Beyan yok | Her renk bir şekille eşleşir |

Snacky Dash yorumlarındaki iki şikâyet tasarımı doğrudan etkiledi:
güçlendirici olmadan geçilemeyen bölümler ve mekaniklerin çok erken, üst
üste gelmesi. İkisi de §4 ve §7'de kurala bağlandı.

---

## 2. Kurallar (sürüm 1)

### 2.1 Tahta ve nesneler

Tahta W×H ızgara (5×6'dan 7×9'a). Her karede en fazla bir nesne bulunur.

| Nesne | Kural |
|---|---|
| **Hayalet (baş)** | Oyuncunun kontrol ettiği tek nesne. Renksiz. |
| **Ruh** | Renkli. Hayalet üstünden geçince toplanır. |
| **Fener** | Renkli, kapasitesi 1 ya da 2. Geçilebilir kare. |
| **Mezar taşı** | Duvar. Geçilmez. |
| **Örümcek ağı** | Geçilebilir; hayalet bu kareye girince durur. |
| **Yön oku** | Geçilebilir; hayalet bu kareye girince kaymaya okun yönünde devam eder. |
| **Fener kapısı** | Bağlı olduğu fener dolana kadar duvar, dolunca geçilebilir kare. |

Renkler: 4'e kadar. Her renk sabit bir şekille eşleşir (daire, kare,
elmas, üçgen); renk tek başına hiçbir zaman bilgi taşımaz.

### 2.2 Hareket

Oyuncu dört yönden birine kaydırır. Hayalet o yönde **birer kare
ilerleyerek** kayar ve şunlardan biri olana kadar durmaz:

1. Sonraki kare tahta dışı, mezar taşı ya da kapalı kapı.
2. Sonraki kare kendi gövdesinin bir parçası. Kuyruğun son karesi bu
   adımda boşalacaksa engel sayılmaz; bu adımda ruh toplanıyorsa sayılır.
3. Hayalet bir örümcek ağına girdi (o karede durur).
4. Bütün fenerler doldu.

Yön okuna giren hayalet kaymaya okun yönünde devam eder. Oklar sonsuz
döngü kurarsa kayma W×H×4 adımda kesilir (üreteç böyle bölümleri zaten
elemeye çalışır; bu, güvenlik sınırıdır).

Hayalet en az bir kare ilerleyemiyorsa kaydırma **geçersizdir**: hamle
sayılmaz, hayalet hafifçe sallanır.

### 2.3 Toplama

Hayalet ruhlu bir kareye girince ruh **başın hemen arkasına** eklenir ve
gövde bir kare uzar (o adımda kuyruk ilerlemez). Kayma devam eder.

Sonuç: gövde bir kuyruktur. En önce toplanan ruh kuyruğun ucundadır.

### 2.4 Bırakma

Her adımın sonunda kontrol edilir: kuyruk ucundaki ruh kendi rengindeki
bir fenerin üstündeyse ve fenerde yer varsa ruh fenere girer, gövde bir
kare kısalır. Kontrol, bırakma olmayana kadar tekrarlanır (zincir).

Yanlış renkteki fenerin üstünden geçmek hiçbir şey yapmaz.

### 2.5 Kazanma

Bütün fenerler kapasitesine ulaşınca bölüm biter. Kalan ruh olamaz;
üreteç her fener için tam kapasitesi kadar ruh koyar.

### 2.6 Hamle hakkı ve başarısızlık

Geçerli her kaydırma 1 hamle. Hamle hakkı:

| Bölüm | Hak |
|---|---|
| 1 | Sınırsız |
| 2–3 | par + max(3, par × 1,0) |
| 4–7 | par + max(3, par × 0,75) |
| 8–10 | par + max(3, par × 0,5) |

Hak biterken fenerler dolmamışsa bölüm başarısız. Seçenekler: ücretsiz
tekrar, ödüllü reklamla +5 hamle ya da coin ile +5 hamle.

**Değişmez:** hamle hakkı her zaman ≥ par. Her bölüm güçlendirici
kullanmadan geçilebilir.

*Kaynak:* basit bir oyuncu modelinde (çözüme giden hamleyi %60 olasılıkla
seçen, çıkmazı 2 hamlede fark eden) 2×par ile ilk denemede bitirme oranı
~%81, 1,5×par ile ~%57. Model kaba; çarpanlar Aşama 2 testinde ayarlanır.

### 2.7 Geri al

Ücretsiz ve sınırsız. Hayaleti, gövdeyi, ruhları ve fenerleri bir önceki
duruma döndürür, ama **harcanan hamleyi iade etmez**. İade etseydi hamle
hakkı anlamsız olurdu.

### 2.8 Çıkmaz göstergesi

Çözücü her hamleden sonra durumun hâlâ çözülebilir olup olmadığını
kontrol eder. Çözülemiyorsa fenerlerin ışığı söner ve geri al düğmesi
nabız atar. Metin yok.

*Neden:* ölçümde ulaşılabilir durumların %53–84'ü çıkmaz. Göstergesiz bir
oyunda oyuncu çoktan kaybettiği bir bölümü dakikalarca oynar; bu,
"haksız" hissinin en bilinen kaynağıdır.

*Açık soru:* gösterge anında mı gelsin, yoksa bir hamle gecikmeli mi?
Anında olursa deneme-yanılma ucuzlar ama hamle hakkı bunun bedelini zaten
aldırıyor. Aşama 2'de ikisi de denenecek.

Çözücü belirlenen sınır içinde sonuca varamazsa gösterge hiçbir şey
göstermez. Emin olmadığı zaman konuşmaz.

### 2.9 Yıldız

- 3 yıldız: par hamlede bitirmek
- 2 yıldız: par + 2'ye kadar
- 1 yıldız: bitirmek

Güçlendirici kullanılan bölümde en fazla 2 yıldız alınır.

### 2.10 Değişmezler (kod bunları test eder)

1. Aynı bölüm + aynı hamle dizisi → her cihazda aynı sonuç.
2. Yayınlanmış bir bölümün verisi değişmez. Düzeltme gerekiyorsa bölüm
   yeni bir kimlikle yeniden yayınlanır.
3. Her bölümün kayıtlı çözümü yeniden oynatılınca kazanır ve uzunluğu
   par'a eşittir.
4. Hamle hakkı ≥ par.
5. Kozmetikler hiçbir kuralı etkilemez.

---

## 3. Mekanik kataloğu

| Mekanik | Bölüm | Gereklilik testi |
|---|---|---|
| Mezar taşı | 1 | — |
| Üçüncü renk | 2 | — |
| Örümcek ağı | 3 | Ağlar kaldırılınca bölüm aynı ya da daha kısa hamlede çözülemiyor |
| Büyük tahta | 4 | — |
| Büyük fener (2 ruh) | 5 | Tahta başına en fazla 1 büyük fener |
| Yön oku | 6 | Oklar kaldırılınca aynı ya da daha kısa hamlede çözülemiyor |
| Fener kapısı | 7 | Kapılar kaldırılınca aynı ya da daha kısa hamlede çözülemiyor |
| Dördüncü renk | 8 | — |
| Karışık | 9 | Ok ve kapı gereklilik testi |
| Usta | 10 | — |

**Kural:** yeni mekanik ancak üreteç onu destekledikten ve gereklilik
testi yazıldıktan sonra oyuna girer. Her bölüm tek bir yeni kavram
tanıtır, ilk seviyesi o kavramın en kolay örneğidir.

**Bilinçli sınır:** bütün fenerlerin 2 ruhluk olduğu bölümler par'ı
15–24 hamleye çıkarıyor. Bu, kısa bölüm vaadini bozuyor; bu yüzden büyük
fener tahta başına bir tane.

**İleride, yalnızca üreteç desteğiyle:** sis (yakına gelince görünen
ruh), gökkuşağı ruh (her fenere girer), portal çifti.

---

## 4. Bölüm üretimi

### 4.1 Üret ve doğrula

Bölümler elle çizilmez. Bir bölüm şu yoldan geçer:

1. Bölüm ayarına göre rastgele yerleşim (tahta boyu, renk sayısı, duvar
   aralığı, mekanik sayısı).
2. Çözücü BFS ile en kısa çözümü, en kısa çözüm sayısını, ulaşılabilir
   durum sayısını ve çıkmaz oranını hesaplar.
3. Kabul filtreleri:
   - par bölümün aralığında
   - par ≥ 5 ise ilk hamlelerden en az biri çıkmaza götürmeli (ilk hamle
     hiç tuzak değilse bölüm sıkıcıdır)
   - en kısa çözüm sayısı üst sınırın altında (çok çözüm = kolay)
   - tanıtılan mekanik için gereklilik testi (§3)
   - daha önce üretilmiş bir bölümün aynısı değil
4. Zorluk puanı: par, en kısa çözüm sayısı, çıkmaz oranı ve durum
   uzayının ağırlıklı toplamı (`booloop_gen.difficulty`).

Bölümler **yapım sırasında** üretilir ve JSON olarak uygulamaya gömülür.
Cihazda bölüm üretilmez; cihazda yalnızca çözücü ipucu ve çıkmaz tespiti
için çalışır.

### 4.2 Zorluk eğrisi

Her bölüm 20 seviye, testere dişi yapısında:

- 1–5: bölümün alt ucu (yeni kavram rahatça öğrenilir)
- 6–15: yavaş yükseliş
- 16–19: tepe
- 20: nefes (orta)

Hedef par dizisi `build_levels.targets()` içinde. 1. bölümün ilk 5
seviyesi öğretici ayardan gelir (4×5 tahta, par 1–3).

### 4.3 Ölçülen sonuç (16 Eyl 2026)

200 bölüm üretildi, her birinin çözümü bağımsız olarak yeniden oynatıldı:
**200/200 kazanıyor, 200/200 benzersiz, hamle hakkı her yerde ≥ par.**
Veri 62 KB.

| Bölüm | Par | Ortalama çıkmaz | Deneme | Süre (Python) |
|---|---|---|---|---|
| 1 Uyanış | 1–6 | %53 | 972 | 0,4 sn |
| 2 Üç renk | 4–8 | %71 | 5.163 | 4 sn |
| 3 Örümcek ağı | 4–9 | %69 | 11.335 | 16 sn |
| 4 Geniş gece | 5–10 | %67 | 4.848 | 6 sn |
| 5 Büyük fener | 5–10 | %67 | 3.402 | 4 sn |
| 6 Yön okları | 5–10 | %66 | 9.386 | 11 sn |
| 7 Fener kapısı | 6–11 | %70 | 11.107 | 18 sn |
| 8 Dört renk | 6–11 | %80 | 16.901 | 42 sn |
| 9 Karışık | 8–12 | %78 | 64.307 | 150 sn* |
| 10 Usta | 9–13 | %84 | 37.387 | 170 sn* |

\* Süre sınırına kadar çalıştı. Son iki bölümde hedef eğrinin alt
seviyeleri için aday azaldı; eğri beklenenden biraz daha düz. Swift
portundan sonra daha uzun üretimle iyileştirilecek.

Ortalama par 7,7, en uzun çözüm 13 hamle.

### 4.4 200'den sonrası

- **Yeni bölüm paketleri:** aynı üreteç, yeni tohumlar. Uygulama
  güncellemesiyle gelir, sunucu gerekmez.
- **Sonsuz mod** (Aşama 6): 10. bölüm ayarından sürekli üretim, önceden
  hazırlanmış büyük bir havuzdan.

### 4.5 Bölüm veri şeması

```json
{
  "id": 1,
  "chapter": "1 Uyanış",
  "level": {
    "w": 4, "h": 5,
    "walls": [[x, y]], "webs": [[x, y]],
    "arrows": [[x, y, yön]], "gates": [[x, y, fenerIndeksi]],
    "head": [x, y],
    "lanterns": [[x, y, renk, kapasite]],
    "wisps": [[x, y, renk]]
  },
  "par": 1, "moves": null,
  "opt": 1, "dead": 0.0, "diff": 1.4,
  "solution": [2],
  "intro": false
}
```

Yön: 0 yukarı, 1 sağ, 2 aşağı, 3 sol. `moves: null` = sınırsız.

---

## 5. İlk oturum (FTUE)

Metin yok. Yalnızca el işareti animasyonu ve tahta.

| Seviye | Öğrettiği | Gösterim |
|---|---|---|
| 1 (par 1) | Kaydırma, toplama, bırakma | El kaydırmayı gösterir; tek kaydırmada ruh toplanır ve fenere girer |
| 2 (par 2) | Kayma engelde durur | El yok |
| 3 (par 2) | İki renk | El yok |
| 4 (par 3) | Sıra önemli, çıkmaz, geri al | İlk doğal hamle çıkmaza götürür, fenerler söner, el geri al'ı gösterir |
| 5 (par 3–4) | Kendi başına | El yok |

4. seviye özel seçilir: ilk hamlelerden en az biri çıkmaz olmalı ve o
hamle "en doğal" görünen olmalı. Aday havuzundan elle seçilir, sonra
değişmez.

Hamle sayacı ve yıldızlar 6. seviyeden itibaren görünür. Hamle hakkı 2.
bölümde başlar.

**FTUE başarısı:** 1. seviyeyi başlatanların ≥ %85'i 5. seviyeyi bitiriyor.

---

## 6. Modlar

### 6.1 Macera
200 bölüm, sırayla açılır. Harita ekranı bölüm başlıklarını ve yıldızları
gösterir.

### 6.2 Günlük gece
- Her gün herkes için aynı bölüm. Önceden üretilmiş bir havuzdan (en az
  730 gün) tarihe göre seçilir.
- Haftanın gününe göre zorluk: Pazartesi kolay, Pazar zor.
- **Dokunulmaz kurallar:** güçlendirici yok, reklam yok, hamle hakkı yok
  (sayılır ama sınır yok), geri al serbest.
- Sonuç kartı spoiler'sız: `Booloop #127 👻 11/9 ⭐⭐` — gün numarası,
  hamle/par, yıldız. Çözüm yolu paylaşılmaz.
- Seri (streak) sayacı. Kaçırılan gün seriyi bozar; seri dondurma yok
  (v1).
- Günlük mod Aşama 3'te gelir; 30. seviyeyi geçmeden açılmaz.

### 6.3 Sonsuz (Aşama 6)
200. bölümden sonra açılır. Skor: art arda par'da biten bölüm sayısı.

---

## 7. Gelir

Hybridcasual karışık model: reklam + uygulama içi satın alma.

*Dropward ile karşılaştırma (Dropward PLAN.md §13):* Dropward reklamı
tamamen reddetmedi. Kabul ettiği: tek seferlik "pro" (reklamsız dahil),
**yalnızca kozmetik açan ödüllü reklam**, bahşiş. Reddettiği: **geçiş
reklamı** ("türün bir numaralı şikayeti") ve **"kaybettin, reklam izle
devam et"** (Dropward'da o an yok, kontrol noktası var). Günlük mod her
iki oyunda da reklamsız.

Booloop bu iki reddedilen kalemden ayrılıyor, bilerek:
- **Devam için ödüllü reklam (+5 hamle):** Booloop'ta başarısızlık anı
  tasarımın parçası (hamle hakkı, §2.6); Dropward'da böyle bir an yok.
- **Geçiş reklamı:** sıkı sınırlarla kabul edildi (§7.1). Dropward'ın
  gerekçesi burada da geçerli; bu kalem Aşama 5 verisine göre
  kaldırılabilir ilk kalemdir. Açık soru §14.

### 7.1 Kaynaklar

- **Coin:** bölüm bitirince (1★ 10, 2★ 15, 3★ 25; ilk bitirmede), bölüm
  sonu ödüllü reklamla ×2.
- **Ödüllü reklam:** +5 hamle (başarısızlıkta), ipucu, bölüm sonu coin ×2.
- **Geçiş reklamı:** 15. seviyeden sonra, bölüm bitişinde, en fazla 3
  bölümde bir ve en az 3 dakika arayla. Başarısızlık ekranında, günlük
  modda ve ilk oturumda asla.
- **Satın almalar (fiyatlar taslak):**
  - Reklamsız paket (non-consumable): geçiş reklamlarını kaldırır; ödüllü
    reklamlar isteğe bağlı olarak kalır. 4,99 $.
  - Coin paketleri (consumable): 1,99 $ / 4,99 $ / 9,99 $.
  - Başlangıç paketi (tek sefer): coin + güçlendirici. 2,99 $.

### 7.2 Güçlendiriciler

| Güçlendirici | Etki | Bedel |
|---|---|---|
| İpucu | Çözücü bir sonraki doğru kaydırmanın okunu gösterir | 1 reklam ya da 60 coin |
| Takas | Kuyruktaki son iki ruhun yerini değiştirir | 90 coin |
| +5 Hamle | Başarısızlık ekranında | 1 reklam ya da 120 coin |

Coin bedelleri taslak; Aşama 5 verisiyle ayarlanır.

Takas bir kuralı esnetir. Kullanıldığı bölümde yıldız en fazla 2 olur ve
çözücü takastan sonraki durumu yeniden değerlendirir.

### 7.3 Kozmetik ve güç

- **Güç** = güçlendiriciler. Bölümü kolaylaştırır, yıldızı sınırlar.
- **Kozmetik** (Aşama 6): hayalet görünümleri, fener temaları, gece
  paletleri. Kurallara dokunmaz (§2.10-5).

### 7.4 Reddedilen gelir kalemleri

- **Can/hayat sistemi (v1).** Tekrar oynamayı cezalandırır; ilk sürümü
  sade tutmak için dışarıda.
- **Zaman sınırı.** Türün en bilinen şikâyetlerinden biri.
- **Güçlendirici gerektiren bölüm.** §2.6 değişmezi.
- **Gizli zorluk ayarı** (reklam izleyene ya da takılan oyuncuya
  bölümü sessizce kolaylaştırmak). Aldatıcı ve fark edilir.
- **Abonelik / paywall.** Bu oyunda aylık yeni değer vaadi yok.
- **Günlük modda reklam ya da güçlendirici.** Paylaşılan skorun
  anlamını bozar.

---

## 8. Metrikler

### 8.1 Sözlük

| Terim | Anlamı | Booloop'ta nasıl ölçülür |
|---|---|---|
| FTUE | İlk oturum deneyimi | 1–5. seviye tamamlama hunisi |
| D1 / D7 / D30 | Kurulumdan 1/7/30 gün sonra dönenlerin oranı | Kurulum kohortuna göre |
| Churn | Oyunu bırakma | 7 gün açılmama |
| Kohort | Aynı dönemde kurulan oyuncu grubu | Kurulum haftası |
| Winback | Bırakanı geri kazanma | Bildirim ve yeni bölüm paketi dönüşü |
| İlerleme | Oyuncunun bölümlerde ne kadar ilerlediği | 5/10/20/40/100/200. seviyeye ulaşma |
| Kozmetik ve güç | Harcamanın görünüşe mi avantaja mı gittiği | Coin harcaması dağılımı |
| ARPDAU | Günlük aktif kullanıcı başına gelir | Reklam + satın alma / DAU |
| ARPPU | Ödeme yapan kullanıcı başına gelir | Satın alma / ödeyen |
| CPI / CAC | Kurulum / kullanıcı edinme maliyeti | Yalnızca ücretli kampanya açılırsa |
| ROAS | Reklam harcamasının geri dönüşü | Yalnızca ücretli kampanya açılırsa |
| LTV | Kullanıcı ömür boyu geliri | D30 ve gelirden tahmin |

### 8.2 Hedefler ve kapılar

Kaynak notu: GameAnalytics 2025 verisinde (11.600 oyun) medyan D1 %22;
üst çeyrek Android'de %25–27, iOS'ta %31–33. Tür bazlı 2025–2026 D1/D7/D30
tablosu açıkta yok; dolaşımdaki tür tabloları 2022 verisine dayanıyor.
Ücretli edinmenin Tier 1 pazarda dönmesi için D7 ~%18 gerekiyor, ölçülen
üst çeyrek ise %7–8. Booloop organik büyümeye göre planlanır.

| Metrik | Hedef | Kapı |
|---|---|---|
| FTUE (5. seviyeyi bitirme) | ≥ %85 | < %70 → FTUE yeniden |
| D1 | ≥ %30 | **< %25 → dur**; %25–30 → FTUE ve ilk 20 seviye iterasyonu |
| D7 | ≥ %10 | < %6 → günlük mod ve ilerleme sorgulanır |
| D30 | ≥ %4 | Bilgi amaçlı |
| Ücretli edinme | Açılmaz | D7 ≥ %18 görülmeden bütçe konmaz |

**D1 %25 satırı şimdi yazıldı ve lansmandan sonra değiştirilmez.**

### 8.3 Olay listesi

- `app_open`, `ftue_step(n)`
- `level_start(id)`
- `level_complete(id, moves, par, stars, undo_count, deadend_count, hint_used, swap_used, seconds)`
- `level_fail(id, moves)`
- `deadend_shown(id, move_index)`
- `booster_use(type, id)`
- `ad_offer(placement)`, `ad_watch(placement, completed)`
- `iap_view(product)`, `iap_purchase(product)`, `restore`
- `daily_start(day)`, `daily_complete(day, moves, par)`, `daily_share(day)`
- `streak(length)`

Kişisel veri yok. Analitik aracı Aşama 4'te seçilir (gizlilik dostu bir
araç ya da Mixpanel).

---

## 9. Tema, görsel dil, ses

- **Ton:** sevimli ürperti. Korkutmaz. Gece, sıcak fener ışığı, yumuşak
  renkler.
- **Hayalet tasarımı** iki bilinen karakterden **açıkça ayrışmalı**:
  Pac-Man hayaletleri (dalgalı alt kenar + iki büyük göz) ve Mario'daki
  Boo (yuvarlak gövde + dil). Mockup'taki dalgalı alt kenar bu yüzden
  son tasarımda kalmaz.
- **Ruhlar:** renkli alevler; her rengin iç şekli farklı (§2.1).
- **Fenerler:** sönükken koyu, dolunca parlar. Çıkmazda hepsi söner
  (§2.8).
- **Hareket:** kayma kare kare okunur olmalı; yaklaşık 80 ms/kare
  başlangıç değeri. Uzun kaymalarda hızlanır.
- **Haptik:** toplama (hafif), bırakma (orta), bölüm sonu (başarı),
  geçersiz kaydırma (hata).
- **Ses:** toplamada artan tonlar, bırakmada fener çınlaması. Lisanslı
  ses kullanılırsa lisans belgesi saklanır (§12, madde 6).

### 9.1 Marka çalışması (Aşama 4)

Sıra: temel önce, logo sonra. Kullanılacak istemler **5 (Logo Brief'i)**
ve **7 (Varlık Kiti Planı)**. 5 numara bir konumlandırmaya ihtiyaç
duyduğu için girdileri buradan verilir:

- **Ne satıyoruz:** ücretsiz, kısa bölümlü, sıralama mantığına dayanan
  bir bulmaca; günlük bölümü paylaşılabilir.
- **Kime:** mobilde kısa mola oyunu oynayan, bulmaca seven yetişkinler
  (varsayım; lansman verisiyle doğrulanır). Türkiye dışı, önce İngilizce.
- **Güvendiği üç marka:** *doldurulacak.* Öneri olarak bakılabilecekler:
  Monument Valley, Two Dots, Alto's Odyssey.
- **Duygu:** "sevimli ürperti + çözmenin rahatlığı".
- **Konum cümlesi taslağı:** "Kuyruğun sırasını düşündüren, her bölümü
  çözülebilir ve adil bir hayalet bulmacası."

5 numara için ek girdiler: işaretin en sık görüneceği yerler (uygulama
ikonu, TikTok profil resmi, bildirim), hayatta kalması gereken en küçük
boyut (ana ekrandaki ikon), kategorideki sahipli şekiller (§9'daki iki
hayalet).

7 numaranın çıktısı §12'deki mağaza varlıklarıyla birleştirilir. TikTok
slayt şablonu en az dört tür için tek sefer hazırlanır: "bu bölümü
çözebilir misin", "tek hamlede kaybettim", "par'ı yakaladım", "günlük
gece #N".

---

## 10. Teknik yapı

### 10.1 Depo

```
booloop/
  PLAN.md
  CLAUDE.md
  Booloop/                 # Xcode uygulaması (SpriteKit sahnesi, UI)
  Packages/BooloopCore/    # saf Swift: kurallar, çözücü, veri modeli
  data/levels-200.json
  tools/booloop_gen.py     # referans kurallar + çözücü + üreteç
  tools/build_levels.py    # bölüm üretimi ve doğrulama
```

### 10.2 BooloopCore

- `Level`, `State`, `slide(state, dir)`, `isWon`
- `Solver`: BFS, durum sınırıyla. İki kullanım: ipucu (ilk hamle) ve
  çıkmaz tespiti (çözülebilir mi / bilinmiyor).
- SpriteKit, UIKit, Foundation dışı bağımlılık yok. `swift test`
  simülatörsüz koşar.
- **Altın testler:**
  1. `levels-200.json` içindeki 200 çözüm Swift'te yeniden oynatılır;
     hepsi kazanır ve uzunluğu par'a eşittir.
  2. Swift çözücü 200 bölümün hepsinde Python ile aynı par'ı bulur.
  3. Elle yazılmış kural vakaları: gövdeye çarpma, kuyruğun boşalan
     karesi, zincirleme bırakma, ağda durma, ok döngüsü sınırı, kapının
     açılması.
- **Performans hedefi:** ipucu ve çıkmaz tespiti cihazda < 100 ms.
  Ölçümde durum uzayı bölüm başına ~60 bine kadar çıkıyor. Hedef
  tutmazsa çıkmaz tespiti arka planda yapılır ve sonuç gelene kadar
  gösterge sessiz kalır.

### 10.3 Uygulama

- Kayıt yerel (ilerleme, yıldız, coin, seri). Hesap yok, sunucu yok,
  veritabanı yok. iCloud senkronu açık soru.
- Satın alma: StoreKit 2 ya da RevenueCat (Aşama 4'te karar). Reklamsız
  paket non-consumable olduğu için "Satın alımları geri yükle" düğmesi
  şart.
- Reklam: bir aracılık SDK'sı (Aşama 4'te karar). Reklam SDK'sı takip
  yapıyorsa ATT izni gerekir; izin ilk oturumda değil, FTUE bittikten
  sonra istenir. Gizlilik manifesti ve gizlilik etiketi buna göre
  doldurulur.
- Çökme takibi: başlangıçta Xcode Organizer + MetricKit; gerekirse
  harici araç.
- Lokalizasyon: tüm metinler en baştan string kataloğunda. İlk dil
  İngilizce; diğer diller Aşama 6'da.
- Deployment target: **açık soru.** iOS 26 en yeni arayüz öğelerini
  verir ama kitleyi daraltır. Oyun iOS 26'ya özel bir API'ye ihtiyaç
  duymuyorsa daha eski bir sürüm seçilir.

### 10.4 Paylaşılan kontrol listesinin uyarlaması

| Madde | Karar |
|---|---|
| Expo, OTA güncelleme | Yok (native Swift) |
| Supabase / veritabanı, RLS, edge function | Yok (sosyal özellik yok) |
| Giriş / kayıt, Apple/Google Sign In | Yok |
| Hesap silme | Gerekmez (hesap yok) |
| Paywall, abonelik, iptal akışı | Yok (§7.4) |
| Sentry + Mixpanel | Çökme + analitik var; araç Aşama 4'te |
| AppsFlyer | Yalnızca ücretli edinme açılırsa |
| TikTok Ads SDK + ATT | Yalnızca TikTok reklamı açılırsa; ATT kuralı geçerli |
| RevenueCat | Seçenek; StoreKit 2 ile karşılaştırılacak |
| Restore Purchases | Şart |
| İlk satın alma incelemesi | Satın alma ürünleri ilk kez bir build ile birlikte incelemeye gönderilir |
| Lokalizasyon, ikon, mağaza sayfası, destek URL'si, gizlilik politikası | Var |
| Bildirimler | Aşama 3: günlük gece hatırlatması, izin istek anı FTUE sonrası |
| Widget | Aşama 6: günlük gece widget'ı |
| iPad testi | Yok (yalnızca iPhone); farklı iPhone boyutlarında test var |

---

## 11. Aşamalar ve kapılar

**Aşama 0 — İsim kilidi (bugün)**
App Store Connect'te uygulama kaydı, alan adı, TikTok/Instagram/X
kullanıcı adları, TÜRKPATENT ve TMview araması.
*Kapı:* isim ayrıldı.

**Aşama 1 — Çekirdek**
BooloopCore: kurallar, çözücü, çıkmaz tespiti, JSON yükleyici, altın
testler.
*Kapı:* 200/200 çözüm Swift'te kazanıyor ve Swift çözücü 200/200 aynı
par'ı buluyor.

**Aşama 2 — Oynanabilir dilim**
SpriteKit sahnesi, kaydırma, kare kare kayma animasyonu, geri al, çıkmaz
göstergesi, hamle sayacı ve hakkı, FTUE, ilk 40 seviye, geçici hayalet
çizimleri.
*Kapı:* 10 kişi, yüz yüze ilk oturum gözlemi. En az 8'i yardımsız 5.
seviyeyi bitiriyor ve en az 6'sı kendiliğinden 10. seviyeye kadar oynayıp
"bir daha" diyor. Hamle çarpanları ve çıkmaz göstergesi zamanlaması
burada ayarlanır.

**Aşama 3 — İçerik ve döngü**
200 seviye, harita, yıldız, coin, güçlendiriciler, günlük gece,
paylaşım kartı, bildirim, haptik, ses, son görsel dil.
*Kapı:* TestFlight'ta 10–20 kişi bir hafta oynuyor; en az yarısı üç ayrı
günde açıyor.

**Aşama 4 — Marka, gelir ve mağaza**
Marka (§9.1), reklam ve satın alma entegrasyonu, analitik, gizlilik
politikası, destek sayfası, mağaza varlıkları, inceleme notları (§12),
ASO becerilerinin kurulumu (§12.3).
*Kapı:* Apple onayı.

**Aşama 5 — Yumuşak lansman**
Organik yayın + TikTok slayt ve kısa video içerikleri. 2–4 hafta ölçüm.
*Kapı:* §8.2.

**Aşama 6 — Büyüme**
Yeni bölüm paketleri (üreteçle), sonsuz mod, kozmetikler, etkinlikler
(Cadılar Bayramı), lokalizasyon, widget.

*Zamanlama notu:* Cadılar Bayramı 2026 altı hafta uzakta. Aşama 1–4'ü
buna sıkıştırmak kapıları atlamak demek. Bu yıl yalnızca içerik ve
kullanıcı adı ısınması için kullanılır; ilk Cadılar Bayramı etkinliği
2027.

---

## 12. App Store

### 12.1 Mağaza sayfası

- **Ad:** Booloop: Ghost Sort Puzzle
- **Alt başlık (≤30):** Lead lost spirits home
- **Anahtar kelimeler (≤100, addaki kelimeler tekrar edilmez):**
  `snake,queue,color,logic,brain,lantern,halloween,cute,slide,maze,daily,spooky,spirit,match`
- **Ekran görüntüleri:** App Store Connect'in istediği güncel iPhone
  boyutu (yükleme sırasında doğrulanır). İlk görüntü kuralı tek cümlede
  anlatır: "First in, first out."
- **Önizleme videosu:** 15–30 sn; bir bölümün tamamı ve bir çıkmaz + geri
  al anı.
- Gizlilik politikası URL'si, destek URL'si, yaş derecesi, gizlilik
  etiketleri.
- Oyun çocuklar kategorisinde yer almaz. Sevimli görsel dil bunu
  değiştirmez; reklam ağı ayarları buna göre yapılır.

### 12.2 İnceleme notları (her gönderimde)

Paylaşılan listeden uyarlandı. İngilizce yazılır.

1. **Ekran kaydı:** fiziksel cihazda, güncel iOS'ta. İçerik: ilk açılış,
   FTUE, bir bölüm, başarısızlık ve +5 hamle, günlük gece, mağaza
   ekranı, bir satın alma, satın alımları geri yükleme.
2. **Amaç ve değer:** "Booloop is a short-level logic puzzle. Players
   slide a ghost to collect spirits; spirits follow in a queue and must
   be delivered to matching lanterns in first-in, first-out order."
3. **Özelliklere erişim:** "No account or login is required. All
   features are available from the home screen."
4. **Dış servisler:** reklam aracılık SDK'sı, analitik, çökme raporu,
   (varsa) RevenueCat. Hiçbiri kullanıcı hesabı oluşturmaz.
5. **Bölgesel fark:** "The app works identically in all regions."
6. **Lisanslar:** kullanılan font ve ses lisansları. Üçüncü taraf
   karakter ya da içerik yok.
7. **Satın almalar:** her ürünün ne verdiği ve mağaza ekranına nasıl
   gidildiği (yazılı + kayıttaki zaman damgası).

### 12.3 ASO araçları (aso-skills)

`github.com/appeeky/aso-skills` — Cursor ve Claude Code için ASO
becerileri, MIT lisanslı. Beceriler tek başına genel çerçeve veriyor;
canlı App Store verisi için Appeeky'nin MCP sunucusu ve API anahtarı,
kendi App Store Connect verini senkronlamak için de aylık ücretli plan
gerekiyor.

**Aşama 4'te kurulacak beş beceri ve karşıladıkları boşluk:**

| Beceri | Ne için | Boşluk |
|---|---|---|
| `metadata-optimization` | Başlık, alt başlık, anahtar kelime alanı, açıklama — karakter sayılı varyantlar | §12.1'deki metinler elle yazıldı, test edilmedi |
| `keyword-research` | Hacim × zorluk × alaka ile anahtar kelime seçimi | Aynı |
| `app-store-featured` | Öne çıkarılma hazırlığı, pitch şablonu, uygulama içi etkinlik takvimi | BOSLUK-ANALIZI D2 |
| `screenshot-optimization` | 10 kareli ekran görüntüsü stratejisi ve tasarım brifi | §9 görsel üretim yolu |
| `app-rejection-recovery` | Reddedilmede Resolution Center yanıtı | §12.2'yi tamamlar |

**Aşama 5–6'da bakılacaklar:** `seasonal-aso` ve `in-app-events`
(Cadılar Bayramı etkinliği), `localization` (mağaza metinleri),
`competitor-tracking` (Snacky Dash izleme), `creator-ugc-marketing`
(TikTok), `onboarding-optimization` ve `rating-prompt-strategy`
(izin ve puanlama isteğinin zamanlaması), `app-analytics` (§8.3 olay
listesiyle karşılaştırma), `app-icon-optimization`,
`app-preview-video`, `category-positioning`, `crash-analytics`.

**Bu oyunda kullanılmayacaklar:** abonelik ve paywall becerileri,
`android-aso`, ücretli edinme becerileri (`ua-campaign`,
`apple-search-ads`, `attribution-setup`), `referral-program`,
`web-to-app-funnel`.

**Uyarılar:**
- Beceri içerikleri doğrulanmadı; kontrol listesi olarak kullanılır,
  kaynak olarak değil. Yaş derecelendirme, DSA, gizlilik gibi konularda
  Apple'ın kendi sayfası esas alınır.
- Appeeky Connect, App Store Connect verini üçüncü tarafa aktarır.
  Ölçülecek veri çıkana kadar (Aşama 5) bağlanmaz.
- README'de kurulum komutu `eronred/aso-skills`, repo ise
  `appeeky/aso-skills`. Komut çalıştırılmadan doğrulanır.

---

## 13. Reddedilenler

- **Kaymasız, adım adım hareket.** Kaymalı hareket daha tatmin edici ve
  türün beklentisi.
- **Tüm fenerlerin 2 ruhluk olması.** Par 15–24; kısa bölüm vaadi bozulur.
- **Elle bölüm tasarımı (ana yol olarak).** Tek kişilik ekip içerik
  yetiştiremez. İstisna: FTUE 4. seviyenin seçimi.
- **Cihazda anlık bölüm üretimi.** Kalite filtresi pahalı ve sonucu
  önceden görülemez.
- **Gizli zorluk ayarı (DDA).** Bkz. §7.4.
- **Hesap, sunucu, veritabanı.** Sosyal özellik yok.
- **Penguen ve köpek temaları.** Penguen + renkli iglo zaten kullanılmış
  (Hole Penguin vb.); köpek teması sort türünde çok kaplanmış.
- **Android (şimdilik).**
- **Günlük modda reklam, güçlendirici, tekrar hakkı.**

---

## 14. Açık sorular

1. Çıkmaz göstergesi: anında mı, bir hamle gecikmeli mi? (Aşama 2)
2. Hamle hakkı çarpanları (Aşama 2 verisi)
3. Deployment target (§10.3)
4. StoreKit 2 mi RevenueCat mi? Hangi reklam aracılığı? (Aşama 4)
5. Analitik aracı (Aşama 4)
6. iCloud ile ilerleme senkronu
7. Hayaletin adı ve karakter tasarımı (§9)
8. İlk lokalizasyon dilleri (Aşama 6)
9. Swift çözücünün cihazdaki gerçek süresi (Aşama 1)
10. 9. ve 10. bölümde eğrinin alt seviyeleri için daha uzun üretim
11. Geçiş reklamı kalsın mı? Dropward bunu reddetti; Booloop'ta sınırlı
    tutuldu. Aşama 5'te D1/D7 ve yorumlara göre karar verilir.
