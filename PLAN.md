# Booloop — Plan

**Mağaza adı:** Booloop: Ghost Sort Puzzle (26/30 karakter)
**Tür:** hybridcasual sıralama bulmacası, kısa bölümlü
**Platform:** yalnızca iOS, iPhone, dikey. Android ve iPad bu planın dışında.
**Motor:** Swift + SpriteKit. Kurallar ve çözücü, SpriteKit'e bağımlı olmayan
saf bir Swift paketinde (`BooloopCore`).
**Durum (18 Eyl 2026):** kurallar net, 200 bölüm üretildi ve doğrulandı
(`data/levels-200.json`), referans üreteç ve çözücü hazır (`tools/`).
Kod yazılmadı. 16 Eyl boşluk analizinin Booloop'a ait bütün maddeleri
18 Eyl'de araştırılıp bu belgeye işlendi; ayrı dosya kaldırıldı.

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

**Doğrulandı (18 Eyl 2026, oynanarak):** Snacky Dash'te kamyona
teslimde gövdedeki sıra **önemsiz**; eşleşen meyve konumundan bağımsız
boşalıyor. "İlk toplanan ilk bırakılır" kuralı yapısal fark olarak
geçerli. Snacky Dash Google Play'de ~4,3★, 500 bin+ indirme.

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
aldırıyor. Aşama 2'de ikisi de denenecek. Bu soru FTUE 4. seviyeyi
kapsamaz: orada gösterge her zaman anında gelir (§5).

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
| 4 (par 3) | Çıkmaz, geri al | İlk doğal hamle çıkmaza götürür, fenerler söner, el geri al'ı gösterir |
| 5 (par 3–4) | Sıra önemli: ilk toplanan ilk bırakılır | El yok. Gövdede iki ruh taşınır; ters sırayla toplanırsa çıkmaz |

4. ve 5. seviye özel seçilir: aday havuzundan elle seçilir, sonra
değişmez (`tools/level4_candidates.py`, `tools/level5_candidates.py`).

- **4. seviye:** ilk hamlelerden en az biri çıkmaz olmalı ve o hamle
  "en doğal" görünen olmalı. Çıkmaz göstergesi burada geliştirici
  ayarından bağımsız olarak her zaman anında gelir (§2.8); el geri al'ı
  ancak gösterge yandıktan sonra gösterebilir.
- **5. seviye:** çözümde bir hamle sonunda gövdede iki ruh bulunur ve
  kuyruk ucundaki ruh önce kendi fenerine gider. Gövdede en fazla bir
  ruh taşıyarak kazanmak mümkün değildir, yani ders atlanamaz. İki ruh
  ters sırayla taşınırsa durum çıkmazdır ve ters sıra par hamle içinde
  kurulabilir. Tahta 4×5, iki renk.

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
  730 gün) gün numarasına göre seçilir (§6.2.1).
- Haftanın gününe göre zorluk: Pazartesi kolay, Pazar zor. Havuz haftanın
  her günü için ayrı zorluk ayarıyla üretilir.
- **Dokunulmaz kurallar:** güçlendirici yok, reklam yok, hamle hakkı yok
  (sayılır ama sınır yok), geri al serbest.
- Sonuç kartı spoiler'sız: `Booloop #127 👻 11/9 ⭐⭐` — gün numarası,
  hamle/par, yıldız. Çözüm yolu paylaşılmaz.
- Seri (streak) sayacı. Kaçırılan gün seriyi bozar; seri dondurma yok
  (v1).
- Günlük mod Aşama 3'te gelir; 30. seviyeyi geçmeden açılmaz.

#### 6.2.1 Gün, saat dilimi ve saat oynatma

- **Gün yerel gece yarısında değişir** (Wordle modeli; alışkanlık ve
  paylaşım için en doğalı). Gün numarası = yerel tarih − başlangıç
  tarihi + 1. Başlangıç tarihi (#1) yumuşak lansmanın ilk günüdür, kodda
  sabittir ve sonra değişmez.
- Aynı #N farklı ülkelerde farklı saatlerde açılır. Kabul edildi: kartta
  tarih değil numara var, paylaşım bozulmaz.
- **Seri** yerel takvim günleriyle sayılır. Saat dilimi değişikliğinden
  doğan tek günlük boşluk seriyi bozmaz; aynı numara iki kez oynanmaz.
- **Saat oynatma:** cihaz tarihi görülmüş en büyük tarihten geriye
  giderse günlük bölüm o tarihe yetişene kadar kilitli kalır. İleri
  alınan saat sunucusuz güvenilir biçimde tespit edilemez; oyuncu
  yarının bölümünü önceden oynayabilir. Bedeli sınırlı: sonuç yalnızca
  kendi cihazında görünür, Game Center'a gönderilmeden önce §6.2.2'deki
  kontrolden geçer.

#### 6.2.2 Game Center

iOS 26'da Game Center oyunları Games uygulamasında görünür. Sunucu
gerektirmeyen iki yapı kullanılır:

- **Yinelenen lider tablosu "Haftanın gecesi".** Dönem 1 hafta,
  Pazartesi 00:00 UTC'de başlar. Skor: hafta içinde bitirilen her
  günlük bölüm için `max(10, 100 − 10 × (hamle − par))`, toplamı.
  Her gün oynamayı ve par'ı yakalamayı ödüllendirir. Taslak formül,
  Aşama 3'te ayarlanır.
  - *Neden günlük değil haftalık:* yinelenen tablolar sabit bir UTC
    anına bağlı döner, günlük bölüm ise yerel gece yarısında değişir.
    Günlük tabloda uzak saat dilimlerindeki oyuncular farklı bölümlerle
    aynı döneme düşerdi. Haftalıkta bu kayma yalnızca hafta sınırında
    birkaç saati etkiler.
- **Meydan okuma (Challenge):** bu tabloya bağlı, tekrarlanabilir.
  Süresi dönemin kalanı. Ayrı kod gerekmez; tabloya gönderilen skor
  meydan okumaya da sayılır. Oyun haftalık toplamı her günlük bölümden
  sonra yeniden gönderir; toplam hafta içinde yalnızca arttığı için
  Apple'ın meydan okumalar için önerdiği "Best Score" türüyle çalışır.
- **Gönderim kontrolü:** GameKit tablonun geçerli döneminin başlangıcını
  Apple'ın saatinden verir. Yerel gün numarası bu dönemin içine
  düşmüyorsa skor gönderilmez.
- **Hile uyarısı:** skorlar sunucuda doğrulanmaz. Tablo "arkadaşlarınla"
  çerçevesinde sunulur; "dünya sıralaması", "resmi" gibi dil kullanılmaz.
- Game Center isteğe bağlıdır; giriş yapmayan oyuncu için her şey
  çalışır. Giriş istemi FTUE'de değil, günlük mod ilk açıldığında çıkar.
- Sınırlar: uygulama başına en fazla 20 meydan okuma; her biri 3840×2160
  görsel, en az bir yerelleştirme ve App Review onayı ister.

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
- **Şans unsuru ve ganimet kutusu.** Rastgele içerikli ücretli ödül
  yok; yaş derecesini yükseltir (Brezilya'da otomatik 18+) ve §12.4'teki
  anket yanıtlarını değiştirir.

### 7.5 Coin ekonomisi simülasyonu (18 Eyl 2026)

`tools/coin_sim.py` 200 bölümü üç oyuncu tipiyle 2.000'er kez oynatır.
Varsayımlar kaba ve Aşama 2–5 verisiyle değişir: yıldız dağılımı,
bölüme göre artan başarısızlık olasılığı (1. bölümde hak sınırsız
olduğu için başarısızlık yok), bölüm sonu ×2 reklamını izleme oranı.

| Oyuncu | 3★ / 2★ | Deneme başına başarısızlık (2.→10. bölüm) | ×2 izleme | 200 bölümde kazanç | Başarısızlık | Hepsini coinle +5 ile kurtarma |
|---|---|---|---|---|---|---|
| Zayıf | %20 / %40 | %10 → %40 | %30 | ~3.900 | ~64 | ~7.650 |
| Orta | %35 / %40 | %6 → %28 | %50 | ~5.150 | ~37 | ~4.400 |
| İyi | %60 / %30 | %3 → %18 | %50 | ~6.150 | ~20 | ~2.400 |

**Sonuç:**
- Orta ve iyi oyuncu kazandığı coinle bütün başarısızlıklarını
  kurtarabiliyor; coin satın almaya ihtiyaç duymuyor. Ücretsiz tekrar
  da olduğu için coin hiçbir zaman zorunlu değil. Bu, §2.6 değişmezinin
  doğal sonucu ve bilerek korunur.
- Coin baskısı yalnızca zayıf oyuncuda: kazancının yaklaşık iki katı
  gerekir.
- Coin paketlerinden gelen gelire güvenilmez. Gelirin ağırlığı ödüllü
  reklamda (×2 coin, +5 hamle, ipucu) ve reklamsız pakette.
- **Paket büyüklükleri (taslak):** 1,99 $ = 500 coin (~4 × +5 hamle),
  4,99 $ = 1.400 coin, 9,99 $ = 3.200 coin; başlangıç paketi 2,99 $ =
  600 coin + 2 takas.
- **Ayar kolları (Aşama 5, gerekirse):** 2★ ödülünü düşürmek, ×2 yerine
  ×1,5, coin için kozmetik harcama yeri (Aşama 6). Kozmetik, kurala
  dokunmayan tek coin çukurudur.

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
- **Ses:** toplamada artan tonlar, bırakmada fener çınlaması.
  - Kaynak: lisanslı ya da CC0 efekt kütüphanesi, gerekirse düzenlenerek.
    Her dosyanın lisans belgesi `assets/licenses/` altında saklanır
    (§12.2, madde 6).
  - v1'de müzik yok, yalnızca efekt. Müzik Aşama 6'da, veriye göre.
  - Ses oturumu `ambient`: sessiz anahtarına uyar, oyuncunun çaldığı
    müziği kesmez.
  - Ayarlarda ses ve haptik ayrı ayrı kapatılabilir.

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

### 9.2 Erişilebilirlik

App Store ürün sayfasında OS 26'dan itibaren Erişilebilirlik Besin
Etiketleri görünüyor: VoiceOver, Voice Control, Larger Text, Dark
Interface, Differentiate Without Color Alone, Sufficient Contrast,
Reduced Motion, Captions, Audio Descriptions. Şimdilik isteğe bağlı;
Apple zorunlu olacağını duyurdu, tarih vermedi.

- **v1'de beyan edilecekler:** Differentiate Without Color Alone (renk +
  şekil kuralı, §2.1; gri tonlama filtresiyle test edilir), Sufficient
  Contrast, Reduced Motion, Dark Interface. Menülerde Dynamic Type
  ucuza gelirse Larger Text de.
- **Reduced Motion açıkken:** kare kare kayma yerine hayalet hedef kareye
  kısa bir solmayla geçer; geçtiği yol kısa süre soluk bir iz olarak
  kalır, böylece hangi ruhların toplandığı okunur. Parçacık, sarsıntı,
  parallax yok. Çıkmaz göstergesinde nabız yerine sabit vurgu.
  Apple'ın ölçütü: anlamlı hareket solma ile değiştirilir, süs hareketi
  kaldırılır, bütün görevler yapılabilir kalır.
- **VoiceOver:** v1'de beyan edilmez. Izgarayı sesli anlatmak ayrı bir
  tasarım işi; Aşama 6 adayı.
- **Motor:** tek girdi kaydırma. İsteğe bağlı ekran yön düğmeleri Aşama 6
  adayı.

### 9.3 AI ile görsel üretilirse

Görsel üretim yolu henüz seçilmedi (§14). AI kullanılırsa:

- ABD Telif Hakkı Ofisi (Part 2 raporu, 29 Oca 2025): yalnızca istemle
  üretilmiş görsel korunmaz; insanın seçimi, düzenlemesi ve değişikliği
  korunabilir.
- Bu yüzden hayalet karakteri ve logo insan eliyle çizilir ya da
  belirgin biçimde yeniden çizilir. Her varlık için istem, seçim ve
  düzenleme kaydı `art/LOG.md`'de tutulur.
- App Review'da AI görsele özel kural yok; 4.1 (taklit) ve 5.2 (haklar)
  geçerli.

---

## 10. Teknik yapı

### 10.1 Depo

```
booloop/
  PLAN.md
  CLAUDE.md
  project.yml              # XcodeGen; Booloop.xcodeproj üretilir, depoya girmez
  Booloop/                 # Xcode uygulaması (SpriteKit sahnesi, UI)
  BooloopTests/            # uygulama testleri (sahne üzerinden çözüm oynatma)
  Packages/BooloopCore/    # saf Swift: kurallar, çözücü, veri modeli
  data/levels-200.json
  tools/booloop_gen.py     # referans kurallar + çözücü + üreteç
  tools/build_levels.py    # bölüm üretimi ve doğrulama
  tools/make_slide_golden.py  # Swift için kayma altın verisi
  tools/level4_candidates.py  # FTUE 4. seviye aday üretimi ve seçimi (§5)
  tools/coin_sim.py        # coin ekonomisi simülasyonu (§7.5)
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
  Üreteç adayları 60 bin durum sınırıyla taranıyor; yayınlanan 200
  bölümde ulaşılabilir uzay en fazla 7.825 durum (#200). Swift'te bu
  uzayın tamamı Mac'te (M serisi, release) 5,4 ms'de taranıyor; 200
  bölümün toplamı 47 ms (18 Eyl 2026). Cihaz ölçümü Aşama 2'de. Hedef
  tutmazsa çıkmaz tespiti arka planda yapılır ve sonuç gelene kadar
  gösterge sessiz kalır.

### 10.3 Uygulama

- Kayıt yerel (ilerleme, yıldız, coin, seri). Hesap yok, sunucu yok,
  veritabanı yok.
- **iCloud senkronu (Aşama 3, zorunlu).** Coin tüketilebilir ürün;
  "geri yükle" onu geri getirmez. Senkron olmazsa telefonunu değiştiren
  ödeme yapmış oyuncu coinlerini kaybeder; bu, tek yıldızlı yorumların
  klasik sebebi. iCloud Key-Value Store yeter (sınır 1 MB ve 1.024
  anahtar; kayıt birkaç KB). KVS "son yazan kazanır" diye çalıştığı için
  birleştirme kuralları:
  - yıldızlar ve açılan seviye: bölüm bölüm en büyük değer
  - seri: oynanan günlerin birleşimi
  - **coin bakiye olarak saklanmaz**; her cihaz kendi iki sayacını
    tutar (toplam kazanılan, toplam harcanan). Bakiye = Σ kazanılan −
    Σ harcanan. İki cihaz aynı anda yazsa da coin kaybolmaz.
  - iCloud kapalıysa ayarlarda "İlerleme yalnızca bu cihazda" uyarısı
    görünür.
- Satın alma: StoreKit 2 ya da RevenueCat (Aşama 4'te karar). Reklamsız
  paket non-consumable olduğu için "Satın alımları geri yükle" düğmesi
  şart.
- Reklam: bir aracılık SDK'sı (AdMob ya da AppLovin MAX; Aşama 4'te
  karar). İzin akışı (GDPR mesajı, ATT, gizlilik seçenekleri) §12.4'te.
- **Gizlilik manifesti** (Aşama 2, ilk TestFlight build'inden önce):
  `PrivacyInfo.xcprivacy`. UserDefaults için gerekçe kodu `CA92.1`
  (yalnızca uygulamanın kendi okuduğu veri). Gerekçesi beyan edilmemiş
  API kullanan build App Store Connect'te reddedilir. SDK'lar kendi
  manifestleriyle gelir: Google Mobile Ads ≥ 11.2.0, AppLovin ≥ 12.4.1.
  Gizlilik etiketi SDK'ların beyanıyla birlikte doldurulur.
- Çökme takibi: başlangıçta Xcode Organizer + MetricKit; gerekirse
  harici araç.
- Lokalizasyon: tüm metinler en baştan string kataloğunda. İlk dil
  İngilizce; diğer diller Aşama 6'da.
- **Deployment target: iOS 26.** Apple'ın 7 Haz 2026 verisine göre
  bütün iPhone'ların %79'u, son dört yılın iPhone'larının %86'sı iOS
  26'da; 2027 lansmanında oran daha yüksek olur. Game Center meydan
  okumaları ve Games uygulaması iOS 26 ile geldi (§6.2.2). App Store
  28 Nis 2026'dan beri Xcode 26 / iOS 26 SDK ile derleme istiyor;
  Nisan 2027'de iOS 27 SDK şartı beklenir.
- **Ekran:** tahta yerleşimi güvenli alanı (Dynamic Island, ana ekran
  çubuğu) hesaba katar; en küçük ve en büyük iPhone'da test edilir.
  120 Hz için Info.plist'te `CADisableMinimumFrameDurationOnPhone = YES`
  ve `SKView.preferredFramesPerSecond = 120`; tahta hareketsizken 60'a
  iner (pil).

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

**Aşama 0 — İsim kilidi ve ön kontroller**
- ✅ Snacky Dash farkı doğrulandı (§1.1, 18 Eyl).
- Alan adı, TikTok/Instagram/X kullanıcı adları, TÜRKPATENT ve TMview
  araması: hesap gerektirmez, şimdi yapılabilir.
- ⏸ App Store Connect'te uygulama kaydı: **Apple Developer hesabı yok,
  bekliyor.** Risk: App Store'da uygulama adı tekildir; kayıt
  yapılana kadar "Booloop" adını başkası alabilir. Hesap en geç
  Aşama 3'ten (TestFlight) önce açılır; Aşama 2'de cihaz testi ücretsiz
  Apple hesabıyla yapılabilir.
- Mali müşavir görüşmesi Aşama 4'e taşındı (yayından önce, §12.5).

*Kapı:* fark doğrulandı ✅; isim kilidi hesap açılınca tamamlanır.
Aşama 1 bu kapıyı beklemez.

**Aşama 1 — Çekirdek**
BooloopCore: kurallar, çözücü, çıkmaz tespiti, JSON yükleyici, altın
testler.
*Kapı:* 200/200 çözüm Swift'te kazanıyor ve Swift çözücü 200/200 aynı
par'ı buluyor.

**Aşama 2 — Oynanabilir dilim**
SpriteKit sahnesi, kaydırma, kare kare kayma animasyonu, geri al, çıkmaz
göstergesi, hamle sayacı ve hakkı, FTUE, ilk 40 seviye, geçici hayalet
çizimleri, güvenli alan yerleşimi ve 120 Hz (§10.3),
`PrivacyInfo.xcprivacy`.
*Kapı:* 10 kişi, yüz yüze ilk oturum gözlemi. En az 8'i yardımsız 5.
seviyeyi bitiriyor ve en az 6'sı kendiliğinden 10. seviyeye kadar oynayıp
"bir daha" diyor. Hamle çarpanları ve çıkmaz göstergesi zamanlaması
burada ayarlanır.
*Kişiler:* oyunu hiç görmemiş, telefonda bulmaca oynayan yetişkinler
(arkadaş ve aile çevresi); en az 3'ü sıralama/bulmaca oyunlarını
düzenli oynuyor.

**Aşama 3 — İçerik ve döngü**
200 seviye, harita, yıldız, coin, güçlendiriciler, günlük gece,
paylaşım kartı, bildirim, haptik, ses, son görsel dil, iCloud senkronu
(§10.3), Game Center haftalık tablo ve meydan okuma (§6.2.2),
erişilebilirlik (§9.2).
*Kapı:* TestFlight'ta 10–20 kişi bir hafta oynuyor; en az yarısı üç ayrı
günde açıyor.
*Kişiler:* Aşama 2 grubu + TestFlight herkese açık bağlantısı (en fazla
10.000 dış testçi): r/playmygame ve r/iosgaming beta konuları, Aşama
0'dan beri ısınan TikTok hesabı. İlk dış build Beta App Review'dan
geçer; 1–2 gün pay bırakılır.

**Aşama 4 — Marka, gelir ve mağaza**
Marka (§9.1), reklam ve satın alma entegrasyonu, reklam izni akışı
(§12.4), analitik, gizlilik politikası ve destek sayfası (§12.4),
mağaza varlıkları, mağaza metinlerinin yerelleştirilmesi (§12.1),
inceleme notları (§12.2), yaş derecelendirme anketi, DSA tüccar beyanı
ve yaş güvencesi kontrolü (§12.4), Small Business Program başvurusu
(§12.5), mali müşavir görüşmesi ve 20/B istisna belgesi (§12.5; ilk
gelirden önce), lansman öne çıkarma başvurusu (§12.6), ASO becerilerinin
kurulumu (§12.3).
*Kapı:* Apple onayı.

**Aşama 5 — Yumuşak lansman**
Önce Kanada, Avustralya, Yeni Zelanda ve Birleşik Krallık: İngilizce
konuşan, küçük, AB dışı pazarlar. AB dışı olduğu için DSA tüccar
bilgilerinin AB ürün sayfasında yayımı AB'ye açılana kadar bekler;
Birleşik Krallık yine de reklam izni ister (§12.4). ABD ve AB kapı
geçilince açılır. Organik yayın + TikTok slayt ve kısa video
içerikleri. 2–4 hafta ölçüm.
*Kapı:* §8.2.

**Aşama 6 — Büyüme**
Yeni bölüm paketleri (üreteçle), sonsuz mod, kozmetikler, uygulama içi
etkinlikler (Cadılar Bayramı 2027, §12.6), oyun içi lokalizasyon,
widget, müzik (§9), VoiceOver ve ekran yön düğmeleri (§9.2).

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
  etiketleri, erişilebilirlik etiketleri (§9.2).
- **Mağaza metinleri Aşama 4'te yerelleştirilir**, oyun içi metinden
  önce (en ucuz büyüme kaldıracı). Diller `keyword-research` ile seçilir.
- **Çocuk kitlesi.** Oyun Kids kategorisinde yer almaz. Yönerge 2.3.8:
  Kids dışındaki bir uygulama ad, ikon, ekran görüntüsü ve açıklamada
  çocukların ana kitle olduğunu ima edemez; mağaza görselleri yetişkin
  bulmaca oyuncusuna konuşur. Reklam ayarları: `maxAdContentRating` G
  (en fazla PG); AdMob `ageRestrictedTreatment` belirtilmez, çünkü çocuk
  hedef kitle değil. Yaş işareti aracılık yoluyla diğer ağlara
  aktarılmadığı için aynı ayar her ağda ayrıca yapılır.

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
   (varsa) RevenueCat, Game Center, iCloud Key-Value Store. Hiçbiri
   kullanıcı hesabı oluşturmaz.
5. **Bölgesel fark:** "The app works identically in all regions."
6. **Lisanslar:** kullanılan font ve ses lisansları. Üçüncü taraf
   karakter ya da içerik yok.
7. **Satın almalar:** her ürünün ne verdiği ve mağaza ekranına nasıl
   gidildiği (yazılı + kayıttaki zaman damgası).
8. **İzin akışı:** GDPR mesajının (AB, Birleşik Krallık, İsviçre) ve
   ATT'nin ne zaman çıktığı; Ayarlar > Gizlilik seçenekleri.

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
| `app-store-featured` | Öne çıkarılma hazırlığı, pitch şablonu, uygulama içi etkinlik takvimi | §12.6 |
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

### 12.4 Yasal uyum

Kaynaklar 18 Eyl 2026'da tarandı. Kurallar hızlı değişiyor; her madde
Aşama 4'te Apple ve Google'ın kendi sayfasından yeniden okunur.

**Reklam izni**
- AB/AEA, Birleşik Krallık ve İsviçre'de kişiselleştirilmiş reklam için
  Google sertifikalı, IAB TCF v2.2'ye entegre bir izin yönetim
  platformu (CMP) gerekiyor (AEA ve BK 16 Oca 2024'ten, İsviçre 31 Tem
  2024'ten beri). Yoksa yalnızca sınırlı ya da kişiselleştirilmemiş
  reklam gelir; gelir düşer.
- Google'ın UMP SDK'sı sertifikalı ve kullanılır. AppLovin MAX seçilirse
  onun "Terms and Privacy Policy Flow" akışı da UMP'yi gösterir; GDPR
  mesajı yine AdMob panelinde oluşturulur ve **aracılıktaki bütün ağlar**
  mesajın ortak listesine eklenir, yoksa o ağ reklam vermeyebilir.
- **Sıra:** önce GDPR mesajı; oyuncu onay verdiyse ATT. UMP'nin IDFA
  açıklama ekranı ATT'den hemen önce çıkar. Info.plist'te
  `NSUserTrackingUsageDescription`. İzin karşılığında ödül verilmez.
- **Zaman:** FTUE (5. seviye) bittikten sonra, ilk reklam fırsatından
  önce. `requestConsentInfoUpdate` her açılışta çağrılır; `canRequestAds`
  false iken reklam istenmez ve önyüklenmez.
- **Ayarlar > Gizlilik seçenekleri:** `privacyOptionsRequirementStatus`
  "required" ise görünür ve izin formunu yeniden açar. GDPR'da izin her
  an geri alınabilmeli.
- **ABD eyaletleri:** UMP'nin "US state regulations" mesajı açılır
  (satış/paylaşımdan çıkma, IAB GPP). Küçük bir uygulama yasal eşiklerin
  altında kalabilir, ama açmanın maliyeti düşük.

**Yaş derecelendirmesi (her gönderimde)**
- Bantlar: 4+, 9+, 13+, 16+, 18+ (Tem 2025). Anket: uygulama içi
  kontroller, yetenekler (sınırsız web, kullanıcı içeriği, mesajlaşma,
  reklam), sağlık, şiddet, şans temelli etkinlikler.
- **Booloop'un yanıtları:** reklam **var**. Kullanıcı içeriği,
  mesajlaşma, sınırsız web **yok**. Sosyal medya (Eylül 2026'dan beri
  her gönderimde zorunlu soru; tanımı "sosyal akışta kullanıcı içeriğini
  dağıtma ya da onunla etkileşim") **yok**: paylaşım kartı sistemin
  paylaşım sayfasıyla dışarı gider, uygulamada akış yok. Şans oyunu ve
  ganimet kutusu **yok** (§7.4).
- **Belirsiz:** Apple "yarışma"yı "sıralama ya da ödül için yarışmak"
  diye tanımlıyor. Game Center lider tablosunun buna girip girmediğine
  dair Apple yönlendirmesi bulunamadı. Aşama 4'te anketin o anki
  metnine göre karar verilir. Beklenen derece 4+ ya da 9+.

**Yaş güvencesi (ABD)**
- Texas SB 2420 yürürlükte: Apple 4 Haz 2026'dan beri uyguluyor, ABD
  Yüksek Mahkemesi 6 Tem 2026'da durdurma talebini reddetti. Alabama
  1 Oca 2027, Utah 6 May 2027, Louisiana 1 Tem 2027.
- Apple geliştiriciden Declared Age Range API'yi, "önemli değişiklik"
  bildirimini, StoreKit'teki yaş derecesi alanını ve ebeveyn onayının
  geri çekildiği sunucu bildirimlerini kullanmasını istiyor; yasanın
  gerektirdiği yerde kullanıcının yaşını kontrol etmek zorunlu.
- Hesapsız ya da 4+/9+ uygulamalar için resmi bir muafiyet bulunamadı.
  Hukukçu özetlerine göre satın alma akışında Apple'ın yaş ve onay
  sinyaline dayanmak yeterli görünüyor. **Doğrulanmadı;** Aşama 4'te
  Apple'ın "age assurance" sayfası yeniden okunur, gerekirse hukuki
  görüş alınır.

**AB DSA tüccar statüsü**
- Reklam ya da satın alma olan uygulama ticari sayılır. Bireysel
  hesapta adres, telefon ve e-posta Apple tarafından doğrulanır ve 27 AB
  ülkesindeki ürün sayfasında yayımlanır.
- Posta kutusu, üzerine kayıtlı fatura ya da makbuzla kabul ediliyor.
  Sanal ofis Apple'ın sayfasında geçmiyor; doğrulanmadı.
- **Yapılacak:** AB'ye açılmadan önce iş telefonu ve posta kutusu.
  Yumuşak lansman AB dışında (§11 Aşama 5).

**Gizlilik politikası ve destek sayfası**
- GitHub Pages'te barındırılır, Aşama 0'da alınan alan adına bağlanır.
- İçerik: toplanan veri (§8.3 olay listesi, reklam SDK'ları), izni geri
  alma yolu, iletişim e-postası, iCloud'da ne tutulduğu.

### 12.5 Hesap türü ve vergi

*Bilgi amaçlı; karar mali müşavirle verilir.*

- **Ön karar: bireysel hesap + GVK mükerrer 20/B.** Booloop'ta şirket
  hesabını zorlayan bir sebep yok. Apple'ın yönergesi (5.1.1(ix))
  kumar gibi sıkı düzenlenen alanlarda tüzel kişi istiyor; Booloop'ta
  şans unsuru yok. DSA iletişim bilgisi posta kutusuyla karşılanabiliyor.
- **20/B:** bankadaki "özel hesap"a gelen ödemeden %15 stopaj kesilir,
  nihai vergidir, beyanname verilmez. 2026 sınırı 5.300.000 TL (GVK 103.
  madde 4. dilimin başı; Gelir Vergisi Genel Tebliği No. 332, RG
  31.12.2025). Rakam muhasebe kaynaklarından; tebliğ metninden
  doğrulanır.
- Sınır aşılırsa o yılın gelirinin **tamamı** beyan edilir (en fazla
  %40); kesilen %15 mahsup edilir.
- Yalnızca gerçek kişi; şirket üzerinden elde edilen gelir kapsam dışı.
- Sıra: önce vergi dairesinden istisna belgesi, sonra bankada özel
  hesap; IBAN bir ay içinde vergi dairesine bildirilir.
- **Açık:** reklam geliri kapsamda mı? Tebliğ 325 özetleri uygulama içi
  reklamı sayıyor; bazı 2026 yorumları, ödeme mağaza üzerinden değil
  doğrudan reklam ağından geldiği için dışarıda bırakıyor. Özelge ile
  netleştirilir.
- **Apple tarafı:** App Store Small Business Program'a başvuru (yıllık
  1 milyon dolara kadar %15 komisyon; kendiliğinden gelmez). App Store
  Connect'te W-8BEN; ABD–Türkiye anlaşmasında telif için kesinti %10,
  form yoksa %30. App Store gelirinin telif mi ticari kazanç mı
  sayıldığı doğrulanmadı.

### 12.6 Öne çıkarılma ve etkinlik takvimi

- **Featuring Nominations** (App Store Connect): Apple en az 2 hafta,
  geniş değerlendirme için 3 aya kadar önceden başvuru öneriyor; App
  Store Connect yardım sayfası en az 3 hafta diyor. Kural: en az 3
  hafta önce.
- **Uygulama içi etkinlik:** en fazla 31 gün sürer, başlamadan 14 gün
  öncesine kadar tanıtılır. Aynı anda 10 yayında, 15 onaylı etkinlik
  olabilir. Ürün sayfasında ve arama sonuçlarında görünür; uygulamayı
  yüklemiş olanlar etkinlik kartını görür. Sürümden ayrı incelenir;
  birkaç gün pay bırakılır.

| Ne | Ne zaman |
|---|---|
| Lansman öne çıkarma başvurusu | Aşama 5'ten en az 3 hafta önce |
| Her büyük güncelleme (yeni bölüm paketi) | Yayından en az 3 hafta önce başvuru |
| Cadılar Bayramı 2027 etkinliği (en fazla 31 gün, 31 Eki'de biter) | Öne çıkarma başvurusu Temmuz 2027 sonu; etkinlik ekim başından önce incelemeye |

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

1. Çıkmaz göstergesi: anında mı, bir hamle gecikmeli mi? (Aşama 2; FTUE 4. seviye her zaman anında, §5)
2. Hamle hakkı çarpanları (Aşama 2 verisi)
3. StoreKit 2 mi RevenueCat mi? AdMob mu AppLovin MAX mı? (Aşama 4)
4. Analitik aracı (Aşama 4)
5. Hayaletin adı, karakter tasarımı ve görsel üretim yolu (§9, §9.3)
6. Oyun içi lokalizasyon dilleri (Aşama 6; mağaza metinleri Aşama 4'te)
7. Swift çözücünün cihazdaki gerçek süresi (Aşama 1)
8. 9. ve 10. bölümde eğrinin alt seviyeleri için daha uzun üretim
9. Geçiş reklamı kalsın mı? Dropward bunu reddetti; Booloop'ta sınırlı
   tutuldu. Aşama 5'te D1/D7 ve yorumlara göre karar verilir.
10. Apple Developer hesabı ne zaman açılacak? (En geç Aşama 3; §11
    Aşama 0)
11. Hesap türünün mali müşavirle onayı; 20/B reklam gelirini kapsıyor
    mu? (Aşama 4, yayından önce; özelge; §12.5)
12. Yaş anketinde Game Center lider tablosu "yarışma" sayılır mı?
    (Aşama 4, §12.4)
13. Coin ekonomisi fazla cömert mi? (§7.5; Aşama 5 verisi)
14. "Haftanın gecesi" skor formülü (§6.2.2; Aşama 3)

**18 Eyl'de kapananlar:** deployment target → iOS 26 (§10.3); iCloud
senkronu → Aşama 3'te zorunlu (§10.3); günlük modun saat dilimi →
yerel gece yarısı (§6.2.1); Snacky Dash'te sıra önemsiz → fark geçerli
(§1.1).
