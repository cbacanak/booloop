# Boşluk analizi — Booloop ve Dropward (16 Eyl 2026)

**Kapsam.** Booloop: PLAN.md, CLAUDE.md, DROPWARD-EK.md (tam).
Dropward: PLAN.md'nin geçmiş sohbetteki sürümünden bölümler (§0 kimlik,
§1 çekirdek, §2 kaldıraçlar, §3 merdiven, §5 ilk oturum, §6 tasarım dili,
§8 dağıtım, §9 teknoloji, §13 gelir, Game Center ve erişilebilirlik
notları) ve 13 Eyl'e kadarki ilerleme notları. **Dropward reposundaki son
sürümü görmedim;** repoda kapatılmış bir madde burada açık görünebilir.

Öncelik: **K** = yayını engelleyebilir, **Y** = yüksek etki,
**O** = orta. Her maddede hangi oyunu etkilediği yazılı.

---

## A. Yayını engelleyebilecekler

### A1. [K · Dropward] "Simüle şans oyunu" algısı
Apple bir geliştiriciye, bireysel hesaplardan gelen şans oyunu
uygulamalarını artık kabul etmediğini, bunun **şans oyununu simüle eden
uygulamaları da kapsadığını** ve bu uygulamaları yalnızca şirket
hesaplarının gönderebileceğini yazmış (Apple Developer Forums).

Dropward'ın kimliği "kendi nişanına bahis koymak", ekranın en görünür
öğesi ×9 gibi bir çarpan ve plan zaten Plinko/pachinko komşuluğu
uyarısı içeriyor. İnceleme bunu simüle şans oyunu olarak okursa bireysel
hesapla yayın kapanır.

**Yapılacak:**
- Oyun içi ve mağaza metninde bet, wager, odds, payout, jackpot, stake
  gibi kelimeler kullanılmaz. Yerine confidence, precision, aim, call.
- Jeton, kumarhane ışığı, slot sesi gibi görsel ve işitsel işaretler yok.
- Yaş anketinde Simulated Gambling = None; inceleme notunda: "Skill-based
  aiming. No chance element, no currency is wagered, the multiplier only
  scales score."
- PLAN.md'deki "bahis" kelimesi iç tasarım dili olarak kalabilir; arayüze
  ve mağazaya çıkmaz.
- En kötü durum planı: şirket hesabı (bkz. A6).

### A2. [K · ikisi] AB DSA "tüccar" statüsü
Apple, AB'de dağıtılan tüccarların adresini, telefonunu ve e-postasını
doğrulayıp AB ürün sayfasında yayınlıyor; AB'de dağıtmasan da statüyü
beyan etmen gerekiyor. Satın alma ya da reklam içeren bir uygulama
ticari faaliyet sayılır; bireysel hesapta bu bilgiler kişisel adres ve
telefonun olur.

**Yapılacak:** Aşama 4'ten önce iş telefonu ve yazışma adresi (sanal
ofis, posta kutusu) hazırla. Bu karar A6'ya bağlı.

### A3. [K · ikisi] Yeni yaş derecelendirmesi ve yaş güvencesi
Apple 13+, 16+, 18+ bantlarını ekledi ve ankete kontroller, yetenekler,
sağlık ve şiddet sorularını koydu. Eylül 2026'dan itibaren sosyal medya
yeteneği sorusunun yanıtı her yeni gönderimde zorunlu. ABD'de Texas,
Utah ve Louisiana için yaş aralığı bilgisi Declared Age Range API ile
paylaşılıyor.

**Yapılacak:** Aşama 4'te iki oyun için de anket yanıtları yazılı hale
getirilir. Game Center meydan okumaları ve paylaşım kartı "sosyal
yetenek" sayılıyor mu, belirsiz; netleştirilmeli. Yaş güvencesi
yasalarının hesapsız, sosyal özelliksiz bir oyuna ne yükümlülük
getirdiği araştırılmadı — açık.

### A4. [K · Booloop] Reklam izni (AB, Birleşik Krallık, İsviçre)
Google, bu bölgelerde kişiselleştirilmiş reklam için TCF'ye entegre,
Google sertifikalı bir izin yönetim platformu (CMP) istiyor; yoksa
yalnızca Limited Ads sunuluyor. Önerilen sıra: önce GDPR izin mesajı,
kullanıcı onay verirse ardından iOS ATT. İzni geri alma seçeneği de
zorunlu.

Booloop PLAN.md §10.3 yalnızca ATT'den bahsediyor. **Eklenmeli.**
Ayarlara "Gizlilik seçenekleri" satırı gerekiyor.

### A5. [K · ikisi] Gizlilik manifesti
UserDefaults, Apple'ın "gerekçe gerektiren API" listesinde. İlerlemeyi
yerelde tutan her iki oyun da `PrivacyInfo.xcprivacy` dosyasında
gerekçe beyan etmek zorunda; reklam ve analitik SDK'larının kendi
manifestleri de kontrol edilmeli. İki planda da yok.

### A6. [Y · ikisi] Hesap türü, vergi ve ödeme — tek karar
Üç konu birbirine bağlı ve birlikte karar verilmeli:

1. **Şirket mi bireysel mi:** A1 (simüle şans oyunu kuralı) ve A2
   (kamuya açık iletişim bilgisi) şirket hesabını öne çıkarıyor.
2. **Vergi (Türkiye):** GVK mükerrer 20/B'de özel hesaptan kesilen %15
   stopaj nihai vergi oluyor ve beyanname gerekmiyor. Bu rejim yalnızca
   gerçek kişiler için; şirketler kullanamıyor. 2026 sınırı bir
   kaynakta 5.300.000 TL, başka kaynaklarda farklı tahminler var;
   güncel rakam vergi dairesinden doğrulanmalı. Mobil uygulamadaki
   reklam geliri de bu istisna kapsamında sayılıyor.
3. **Apple tarafı:** App Store Connect'teki vergi formu (W-8BEN) ve App
   Store Small Business Program başvurusu (yıllık 1 milyon dolara kadar
   gelirde %15 komisyon; kendiliğinden gelmez, başvuru gerekir).

Burada **1 ile 2 çelişiyor:** 20/B'nin kolaylığı bireysel hesapla
uyumlu, A1 ve A2 ise şirket hesabını öne çıkarıyor. Bu, bir mali
müşavirle birlikte verilecek bir karar. Ben vergi danışmanı değilim.

---

## B. Dropward'da olup Booloop'ta eksik olanlar

### B1. [Y] Game Center: yinelenen lider tabloları ve meydan okumalar
Dropward araştırmasında bulundu: iOS 26'da Games uygulaması, arkadaşa
1 gün, 3 gün ya da 1 haftalık meydan okuma ve periyodik sıfırlanan lider
tabloları var. Booloop'un günlük gecesi buna birebir oturuyor; sunucu
gerektirmiyor. Booloop §6.2'ye girmeli.

### B2. [Y] Küçük pazarlarda yumuşak lansman
Dropward: önce Kanada, Avustralya, Yeni Zelanda, Birleşik Krallık; ABD,
Japonya, Kore, Çin ilk aşamada yok. Booloop Aşama 5 "organik yayın"
diyor, pazar seçimi yok.

### B3. [Y] Mağaza metinlerinin yerelleştirilmesi
Dropward bunu en ucuz büyüme kaldıracı olarak öne almıştı. Booloop
lokalizasyonu Aşama 6'ya koydu; oyun içi metin değil ama **mağaza
metinleri** Aşama 4'e alınmalı.

### B4. [O] Hile uyarısı
Dropward: günlük skorlar sunucuda doğrulanmıyor, sıralama "resmi" gibi
sunulmaz. Booloop'a eklenmeli; saat değiştirerek günlük bölümü önceden
görme de buna dahil (bkz. D1).

### B5. [O] Dropward'ın pratik dersleri → Booloop CLAUDE.md
- Git yazma işlemleri Mac terminalinden; Xcode MCP köprüsü `.git/*.lock`
  dosyalarını bırakabiliyor.
- Xcode → Settings → Intelligence'ta MCP açılmadan köprü bağlanmıyor.
- Tahta yerleşiminde güvenli alan (Dynamic Island) hesaba katılmalı;
  Dropward'da bu hata geç bulundu.
- 120 Hz için plist anahtarı ve kare hızı ayarı.

---

## C. Booloop'ta olup Dropward'da eksik olanlar

### C1. [Y] Yayınlanmış içeriğin sürümlenmesi
Dropward'da üreteç değişince tohum→tahta eşlemesi değişiyor (altın tablo
bu yüzden yeniden yazıldı). Yayından sonra bu olursa **eski günlük
tohumlar farklı tahta üretir**: paylaşılmış sonuçlar ve seriler
anlamsızlaşır. Booloop'taki `rules_version` + "yayınlanmış veri
değişmez" kuralının Dropward karşılığı: üreteç sürümü tohumla birlikte
saklanır ve eski sürümler kodda kalır.

### C2. [O] Commit yazarlığı kuralı
Booloop CLAUDE.md'ye eklendi; Dropward CLAUDE.md'de yok.

### C3. [O] Haftanın gününe göre günlük zorluk
Booloop'ta var (Pazartesi kolay → Pazar zor); Dropward'ın günlük
tohumu tek zorlukta.

### C4. [O] Metrik sözlüğü, olay listesi, inceleme notu şablonu
DROPWARD-EK.md'de hazır.

---

## D. İki planda da hiç ele alınmamış olanlar

### D1. [Y] Günlük modun saat dilimi
Tanımsız: gün yerel gece yarısında mı, UTC'de mi değişiyor? Yerel saat
seçilirse farklı ülkeler aynı "#127"yi farklı saatlerde görür ve saati
ileri alan kullanıcı yarının bölümünü önceden oynar. UTC seçilirse
bazı ülkelerde gün öğleden sonra değişir. Seyahatte seri nasıl
hesaplanır? Gün numarası hangi tarihten başlar?

**Öneri:** yerel gece yarısı (paylaşım ve alışkanlık için daha doğal),
gün numarası sabit bir başlangıç tarihinden, cihaz saati ileri alınırsa
seri korunur ama günlük sonuç "resmi" sayılmaz. Karar yazılmalı.

### D2. [Y] Öne çıkarılma ve uygulama içi etkinlikler
App Store Connect'teki Featuring Nominations formu için Apple en az iki
hafta önceden, geniş değerlendirme için üç aya kadar önceden başvuru
öneriyor. Uygulama içi etkinlikler arama sonuçlarında ve ürün
sayfasında, uygulamayı zaten yüklemiş kullanıcılara da görünüyor.

**Yapılacak:** her iki planda Aşama 4–6'ya bir takvim: lansman
başvurusu, sezon etkinlikleri (Booloop için Cadılar Bayramı 2027; Eylül
2027'de başvuru), her büyük güncellemede bir başvuru.

### D3. [Y] Kayıt kaybı ve cihaz değişimi
İki oyunda da kayıt yalnızca yerel. Booloop'ta coin satın alınıyor;
coin tüketilebilir ürün olduğu için "geri yükle" onu geri getirmez.
Telefonunu değiştiren ödeme yapmış kullanıcı coinlerini kaybeder. Bu,
tek yıldızlı yorumların klasik sebebi.

**Öneri:** Booloop'ta iCloud senkronu (Key-Value Store ya da CloudKit)
açık sorudan **Aşama 3 zorunluluğuna** taşınmalı. Dropward'da seri ve
kozmetik kilidi için aynı soru geçerli.

### D4. [Y] Erişilebilirlik Besin Etiketleri
App Store ürün sayfalarında VoiceOver, Voice Control, Larger Text,
Sufficient Contrast, Reduced Motion ve Differentiate Without Color
Alone gibi özellikler etiket olarak gösteriliyor. Şimdilik isteğe bağlı;
Apple'ın ileride zorunlu yapacağı yorumlanıyor.

- **Booloop:** Renk + şekil kuralı ile "Differentiate Without Color
  Alone" ve "Sufficient Contrast" doğal adaylar. Reduced Motion açıkken
  kayma nasıl gösterilir, tanımsız. VoiceOver ile ızgara bulmacası
  oynanabilir mi (tahtayı sesli anlatmak), karar verilmedi.
- **Dropward:** Dropward §11 var, ama etiket ölçütlerine göre kontrol
  edilmedi. Nişan jesti motor güçlüğü olan oyuncu için alternatif
  istiyor mu, açık.

### D5. [O] Ses
Dropward "sonra" dedi, Booloop yalnızca fikir listesi içeriyor. Açık:
kaynak (kendi üretim, lisanslı kütüphane, prosedürel), lisans belgesi,
sessiz modda davranış, müzik olacak mı.

### D6. [O] Gizlilik politikası ve destek sayfasının barındırılması
İki planda da URL gerekli yazıyor ama nerede barındırılacağı yok. Dropgap
GitHub Pages kullanmıştı; aynı yol en ucuzu. Alan adı (Booloop Aşama 0)
buna bağlanabilir.

### D7. [O] Coin ekonomisi
Booloop'ta coin kaynakları ve harcamaları taslak rakamlar. Oyuncunun
200 bölüm boyunca kazanacağı ve harcayacağı toplamı gösteren basit bir
simülasyon yok; güçlendiricilerin çok ucuz ya da ulaşılmaz olup
olmadığı bilinmiyor.

### D8. [O] Test oyuncusu bulma
"10 kişi" iki planda da kapı, ama bu kişilerin nereden bulunacağı yok.
TestFlight dış testi ayrıca Apple'ın beta incelemesinden geçiyor.

### D9. [Y · Booloop] Farkın doğrulanması
Booloop'un Snacky Dash'ten yapısal farkı "ilk toplanan ilk bırakılır"
kuralı. Snacky Dash'te gövde sırasının önemli olup olmadığı hâlâ
oynanarak doğrulanmadı. Sıra önemliyse fark zayıflar. **Aşama 1'den
önce yapılmalı;** 20–30 bölüm oynamak yeterli.

### D10. [O] Çocuk kitlesi
Booloop'un sevimli görsel dili çocuk çekebilir. Oyun Kids kategorisinde
olmasa da reklam ağlarının çocuk işaretleri ve yaş derecesi seçimi buna
göre yapılmalı. Dropward için daha az geçerli.

### D11. [O] Deployment target
Dropward iOS 26 seçti; Booloop'ta açık soru. iOS 26'ya özel bir API
kullanılmıyorsa hedefin düşürülmesi kitleyi genişletir. Dropward'da bu
kararın gerekçesi yeniden kontrol edilmeli.

### D12. [O] AI görsel kullanılırsa kayıt tutma
Görsel yolu seçilmedi (Booloop §9). AI kullanılırsa: ABD Telif Hakkı
Ofisi tamamen AI ile üretilmiş materyali korumuyor; insan katkısının
kaydı tutulmalı.

---

## E. Zaten bilinen açıklar (yeniden hatırlatma)

- **Dropward:** güç ekseni ayrı bir kontrol olarak hissedilmiyor
  (yapısal; "zorunlu sekme" kaldıracı henüz tasarlanmadı). Kadranın
  dokunulabilir olduğu ilk oturumda öğretilmiyor. İsim müsaitliği ve
  marka araması yapılmadı.
- **Booloop:** çıkmaz göstergesi zamanlaması, hamle çarpanları, Swift
  çözücünün cihaz süresi, 9–10. bölüm eğrisi, görsel üretim yolu.

---

## F. Önerilen sıra

1. **Bu hafta:** D9 (Snacky Dash'i oyna), A6 (mali müşavir görüşmesi,
   hesap türü kararı).
2. **Aşama 1 öncesi:** D1 (saat dilimi kararı), C1 (Dropward üreteç
   sürümlemesi — Dropward günlük modu yazılmadan önce).
3. **Aşama 3:** D3 (iCloud), B1 (Game Center), D4 (erişilebilirlik).
4. **Aşama 4:** A1–A5, B3, D2, D6.
