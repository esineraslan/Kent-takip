# İBB Kent Takip - Proje Çalışma Kuralları

Belge durumu: Onaylı ve bağlayıcı proje kuralı  
Belge sürümü: 1.0  
Tarih: 16 Ağustos 2026  
Kapsam: Flutter uygulaması, demo sunucusu, veri fixture'ları, testler, dokümantasyon ve görsel varlıklar  
Hedef kitle: İnsan geliştiriciler, tasarımcılar, test ekibi ve AI/kodlama ajanları  

Kanonik düzeltme: 17 Ağustos 2026 tarihli ADR-0001–ADR-0008 bu belgedeki çelişen eski kararların yerine geçer. Özellikle karar önceliği, AI görünürlüğü, kişi güven skoru ve JSON yazımı aşağıdaki güncel metinlerle yönetilir.

---

## 1. Amaç

Bu belge, İBB Kent Takip projesinde değişiklik yapan herkesin uyması gereken bağlayıcı kuralları tanımlar. Amaç:

- vatandaş ve belediye yüzeylerinin eksiksiz ve güvenilir çalışmasını sağlamak;
- ürün, tasarım ve mimari kararların uygulama sırasında bozulmasını önlemek;
- kişisel veri, yetki, AI ve kamusal bilgi risklerini sınırlandırmak;
- Android, iOS ve modern web hedeflerinde aynı kalite seviyesini korumak;
- her değişikliği test edilebilir, incelenebilir ve geri izlenebilir hâle getirmek;
- demo özelliği ile gerçek üretim yeteneği arasındaki farkı dürüstçe göstermektir.

Bu belgedeki **zorunludur**, **yasaktır**, **yapılmalıdır** ve **yapılamaz** ifadeleri normatiftir. Yazılı ve süreli istisna olmadan esnetilemez.

---

## 2. Kapsam

Kurallar aşağıdaki varlıkların tamamına uygulanır:

- Flutter vatandaş uygulaması;
- Flutter belediye web paneli;
- ortak domain, repository, servis ve ViewModel katmanları;
- yerel JSON deposu ve paylaşımlı Dart demo servisi;
- seed, fixture, örnek medya ve senaryo katalogları;
- AI servis arayüzleri, gerçek veya simüle AI adaptörleri;
- harita, kamera, konum ve bildirim adaptörleri;
- test, golden, şema doğrulama ve CI yapılandırmaları;
- ürün, tasarım, mimari, AI ve veri kaynağı belgeleri;
- logo, ikon, font, görsel ve diğer marka varlıkları.

Kurallar yalnız kaynak kodunu değil; veri, ekran metni, demo davranışı, test ve teslim paketini de kapsar.

---

## 3. Karar kaynakları ve çelişki çözümü

### 3.1 Temel karar sırası

Normal durumda aşağıdaki sıra kullanılır:

1. Güvenlik, KVKK, lisans ve diğer hukuk zorunlulukları
2. Yazılı ürün sahibi/proje yöneticisi kararı
3. Onaylı ve kapsamı açık ADR kayıtları
4. `PRODUCT.md`
5. `USER_FLOWS.md`
6. `DESIGN.md`
7. `ARCHITECTURE.md`
8. `AI_SYSTEM.md`
9. `DATA_SOURCES.md`
10. Onaylı iş paketi kabul ölçütleri

`RULES.md`, bu kaynakların uygulanma biçimini bağlar.

### 3.2 Yeni belge kuralı

Yeni bir belge eski kararı yalnız tarih nedeniyle geçersiz kılamaz. Maddi değişiklik; karar sahibi, onaylayan, gerekçe, etkilenen karar ve supersedes kaydı bulunan ADR ile yapılır. Güvenlik, KVKK ve hukuk kararı gerekli ortak onay olmadan geçersiz kılınamaz. ADR yoksa çelişki kodlamayı durdurur.

### 3.3 Bu belgenin açıkça değiştirdiği eski kararlar

Bu sürüm, daha eski belgelerde farklı yazılmış olsa dahi aşağıdaki kararları kesinleştirir:

- Vatandaş AI'ın sade ve eyleme dönük sonucunu; personel ayrık skor, gerekçe ve sürümünü görür. Kişiye yönelik vatandaş güven skoru üretilmez.
- Jüri ana rotası deterministik demo AI ile çevrimdışı çalışır. Gerçek servis opsiyoneldir; yokluğunda manuel rota devam eder ve sahte başarı gösterilmez.
- JSON kalıcılığı IO'da temp + doğrulama + yedek + atomik rename; webde iki slot veya eşdeğer güvenli commit kullanır. Doğrudan aktif dosya overwrite yasaktır.
- Tasarımda piksel düzeyinde birebirlik ve her değerin token'dan gelmesi teslim engeli değildir. Bununla birlikte marka, bilgi hiyerarşisi, pin semantiği, erişilebilirlik, temel bileşen ailesi ve `DESIGN.md` deneyim kararları korunmalıdır.

### 3.4 Çelişki kaydı

Bir çelişki tespit edildiğinde geliştirici:

1. iki karar kaynağını kaydeder;
2. tarih ve sürümlerini karşılaştırır;
3. yeni belge kuralını uygular;
4. güvenlik veya ürün etkisi varsa ilgili onay sahibine bildirir;
5. seçilen sonucu PR açıklamasına yazar.

---

## 4. Roller ve son onay yetkisi

| Karar alanı | Son onay |
|---|---|
| Ürün kapsamı ve yayın | Ürün sahibi/proje yöneticisi |
| Tasarım ve kullanıcı deneyimi | Tasarım sorumlusu |
| Mimari ve teknik yaklaşım | Teknik lider |
| AI eşikleri ve AI davranışı | Teknik lider + ürün sahibi |
| Veri kaynağı | Teknik lider + ilgili kurumsal veri sorumlusu |
| Güvenlik, KVKK ve gerçek veri | Kurumun yetkili güvenlik/KVKK sorumlusu + ilgili teknik sorumlu |
| Üretim yayını | Ürün sahibi/proje yöneticisi + teknik lider + gerekli kurumsal sorumlular |

Güvenlik, KVKK, gerçek veri kullanımı veya kritik AI davranışı tek kişinin onayıyla uygulanamaz. Ortak yazılı onay gerekir.

---

## 5. Değişiklik disiplini

### 5.1 İş paketi

Her çalışma:

- tek ve açık bir amacı olan küçük bir feature/fix paketi olmalıdır;
- kabul ölçütü, etkilenen akış ve test planı taşımalıdır;
- kod, test ve gerekiyorsa belge değişikliğini aynı pakette tamamlamalıdır;
- ilgisiz refactor veya biçimlendirme içermemelidir.

### 5.2 Mevcut çalışmayı koruma

- Başka kişilere ait ilgisiz değişiklikler geri alınamaz, yeniden yazılamaz veya topluca formatlanamaz.
- Hata çözmek için çalışan özellik, erişilebilirlik davranışı veya test kaldırılamaz.
- Kullanıcı tarafından onaylanmış tasarım omurgası sessizce değiştirilemez.
- Kök neden düzeltilmeli; yalnız görünen semptom kapatılmamalıdır.

### 5.3 Kısmi ve gerekli değişiklik

Herhangi bir değişiklik gerektiğinde ekip proje yapısına uygun karar alır. Yapının tamamı yeniden kurulmaz. Yalnız sorunu veya yeni gereksinimi karşılayan gerekli bölüm değiştirilir.

Büyük refactor için:

- gerekçe;
- etkilenen alanlar;
- alternatifler;
- test ve migration etkisi;
- geri dönüş planı

yazılmalıdır. Onaysız geniş kapsamlı yeniden yazım yapılamaz.

### 5.4 Teslimde yasak eksikler

Teslim edilen akışlarda şunlar bulunamaz:

- `TODO`, `FIXME` veya işlevsiz placeholder;
- boş veya tıklanınca hiçbir şey yapmayan buton;
- sahte başarı bildirimi;
- yalnız ekran görüntüsü gibi davranan statik mock;
- yakalanmamış exception;
- bilinen P0/P1 hata;
- eksik loading, empty, offline veya error durumu.

Demo simülasyonu yalnız belgelenmiş adaptörlerde, deterministik ve açıkça demo olarak etiketlenmiş biçimde kullanılabilir.

### 5.5 Yeni bağımlılık

Yeni paket eklenmeden önce:

- mevcut SDK veya paketlerle çözülememe gerekçesi;
- bakım ve yayın sıklığı;
- lisans;
- Android, iOS ve web desteği;
- uygulama boyutu ve performans etkisi;
- güvenlik ve veri aktarımı

incelenir. Sonuç PR'a yazılır ve `pubspec.lock` commit edilir.

---

## 6. Mimari ve kod kuralları

### 6.1 Bağlayıcı mimari

`ARCHITECTURE.md` temel teknik kaynaktır. Özellikler aşağıdaki akışı korur:

```text
View/Widget -> ViewModel/Command -> Use-case/Policy -> Repository -> Service/Store
```

- Widget içinde iş kuralı, yetki kararı veya doğrudan veri erişimi yapılamaz.
- UI, verinin yerel JSON, paylaşımlı sunucu veya gerçek API'den geldiğini bilmez.
- Repository sözleşmeleri veri kaynağını gizler.
- Domain modeli platform ve UI paketlerinden bağımsız kalır.

### 6.2 Durum ve yönlendirme

Boş bırakılan RL-16 için önerilen standart kabul edilmiştir:

- durum yönetimi ve dependency injection: `provider`;
- feature kapsamlı `ChangeNotifier` ViewModel'ler;
- yönlendirme: `go_router` ve mümkün olan yerde typed route;
- rol kontrolü: router guard + use-case policy + repository/service kontrolü.

Yazılı mimari kararı olmadan ikinci bir state management veya router kütüphanesi eklenemez.

### 6.3 Modeller ve JSON

- Domain ve DTO modelleri immutable ve açık tipli olmalıdır.
- Kontrolsüz `Map<String, dynamic>` UI katmanına taşınamaz.
- Her JSON girişi parse, tip, enum, referans ve invariant doğrulamasından geçmelidir.
- Bilinmeyen enum değeri sessizce varsayılana çevrilemez; kontrollü hata veya karantina üretir.
- Eşik, rol, kategori, süre ve diğer iş sabitleri merkezi ve sürümlü olmalıdır.
- Magic literal iş kurallarında kullanılamaz.

### 6.4 Platform kodu

- `dart:io`, browser API'leri, kamera ve konum plugin'leri adaptör arkasında tutulur.
- Koşullu import kullanılır.
- Ortak domain ve ViewModel dosyaları platforma özgü API çağırmaz.
- Android, iOS ve web eşit hedef platformlardır.

### 6.5 Hata modeli

Hatalar en az şu alanları ayırır:

- kullanıcıya gösterilecek sade mesaj;
- teknik hata kodu;
- retry edilebilirlik;
- kaynak/servis;
- correlation veya işlem kimliği;
- güvenli log ayrıntısı.

Genel `catch` ile hata yutulamaz. Kullanıcı müdahalesi isteyen hata yalnız geçici toast olarak gösterilemez.

### 6.6 Test edilebilir zaman ve kimlik

Zaman, UUID, takip numarası ve rastgelelik sağlayıcı üzerinden enjekte edilir. Testler `FakeClock` ve deterministik ID üreticisi kullanır.

---

## 7. Tasarım, içerik ve dil

### 7.1 Tasarım kaynağı

`DESIGN.md` aşağıdaki konularda bağlayıcıdır:

- marka ve İBB görsel ailesi;
- ekran bilgi mimarisi;
- vatandaş ve belediye kabukları;
- ortak bileşen dili;
- pin anlamları;
- responsive davranış;
- hata, boş, yükleniyor ve çevrimdışı durumları;
- erişilebilirlik ve motion ilkeleri.

Piksel düzeyinde birebir eşleme zorunlu değildir. Yaklaşık görsel uyum kabul edilir; ancak tasarım sorumlusu onayı olmadan temel yerleşim, hiyerarşi veya marka algısı değiştirilemez.

### 7.2 Marka varlıkları

- Yalnız resmî olarak sağlanan İBB logo ve varlıkları kullanılır.
- Logo yeniden çizilemez, esnetilemez veya benzeri üretilemez.
- Logo oranı, güvenli alanı ve minimum boyutu korunur.
- Onaysız font veya marka rengi eklenemez.

### 7.3 Pin semantiği

| Pin | Anlam | Görünürlük |
|---|---|---|
| Kırmızı `!` | Doğrulanmış aktif olay | Vatandaş + belediye |
| Sarı saat | Yayınlanmış planlı olay | Vatandaş + belediye |
| Gri `?` | Kullanıcının doğrulama bekleyen kendi bildirimi | Yalnız sahibi; belediyede inceleme bağlamında |
| Turuncu uyarı | Kritik personel incelemesi | Yalnız yetkili belediye personeli |

Renk tek başına anlam taşıyamaz; ikon, metin ve semantics etiketi zorunludur.

### 7.4 Anti-AI-slop kuralları

Aşağıdakilerin tamamı yasaktır:

- amaçsız gradient ve neon parıltı;
- aşırı cam/blur kartlar;
- her içeriği bağımsız yüzen karta bölmek;
- rastgele büyük radius ve aşırı gölge;
- dekoratif ama işlevsiz grafik, emoji ve ikon;
- benzer eylemlerde farklı buton biçimi;
- sahte metrik veya dashboard dolgu öğesi.

### 7.5 Dil

Uygulama şimdilik iki kullanıcı dili sunar:

- Türkçe (`tr-TR`)
- İngilizce (`en`)

Kullanıcıya görünen metinler localization dosyalarından gelmelidir. Widget içinde kalıcı kullanıcı metni yazılamaz. Eksik çeviri sessiz boş metin üretmez; geliştirmede hata, kontrollü fallback'te Türkçe gösterir.

Ürün ve operasyon belgeleri Türkçe; kod sembolleri, JSON alanları ve teknik API sözleşmeleri İngilizcedir.

### 7.6 Motion

- Hareket yalnız durum ve mekânsal ilişkiyi açıklamak için kullanılır.
- Sürekli dekoratif animasyon kullanılmaz.
- Sistem `reduced motion` tercihi okunur.
- Hareket kapatıldığında bilgi veya eylem kaybolmaz.

---

## 8. Erişilebilirlik

Hedef WCAG 2.2 AA'dır. P0/P1 erişilebilirlik hatası kabul edilmez ve erişilebilirlik kontrolleri geçmeden iş tamamlanmış sayılmaz.

Zorunlu kontrollerin tamamı:

- klavye ile tam kullanım;
- mantıklı ve görünür focus sırası;
- ekran okuyucu adı, rolü, durumu ve hata ilişkisi;
- yüzde 200 metin büyütmede kayıpsız mobil kullanım;
- webde uygun zoom/reflow;
- minimum dokunma hedefi ve öğeler arası güvenli mesafe;
- renk dışında ikon, metin veya desenle anlam;
- reduced-motion desteği;
- otomatik ve manuel erişilebilirlik testi;
- haritanın eşdeğer liste görünümü;
- modal focus trap ve kapanışta focus dönüşü;
- dinamik sonuçlarda uygun live region.

Test kapsamı en az TalkBack, VoiceOver, NVDA/Chrome ve VoiceOver/Safari ana rotalarını içerir.

---

## 9. Kimlik, yetki, gizlilik ve güvenlik

### 9.1 Yetki

Yetki üç katmanda uygulanır:

1. Route/navigation
2. Use-case/policy
3. Repository/service veya shared demo server

Menüyü gizlemek tek başına yetki kontrolü sayılmaz. Yetkisiz erişim kontrollü `403/forbidden` davranışı ve audit kaydı üretir.

### 9.2 Demo hesapları

- Yalnız kurgu test hesapları kullanılır.
- Demo parolaları açıkça demo fixture/config alanında tutulabilir.
- Gerçek ekip e-postası, telefon, parola veya token kullanılamaz.
- `demo.invalid` gibi üretimde kullanılamayan alan adları tercih edilir.

### 9.3 Sır ve kişisel veri

Gerçek kişisel veri; kaynak kod, fixture, test, log, ekran görüntüsü veya teslim paketine eklenemez. Parola, OTP, API anahtarı, token ve sertifika repoya yazılamaz.

Loglarda şu veriler bulunamaz:

- açık telefon/e-posta;
- parola, OTP veya token;
- tam hassas konum;
- orijinal gizli medya;
- kişiyi tanımlayabilecek serbest metin.

### 9.4 Medya

- Orijinal ve kamusal/maskeli medya ayrılır.
- Gizlilik tespiti veya maskeleme başarısızsa orijinal medya halka açılamaz.
- Orijinal medyayı açan yetkili personel için audit zorunludur.
- Vatandaş ve genel harita yalnız izinli kamusal projection alır.

### 9.5 Audit

En az şu işlemler audit edilir:

- giriş ve rol seçimi;
- personel kararı ve gerekçesi;
- atama, yönlendirme ve durum değişimi;
- birleştirme;
- AI önerisini geçersiz kılma;
- gizli medyaya erişim;
- demo reset;
- veri içe aktarma;
- yetkisiz erişim denemesi;
- hesap kısıtlaması ve itiraz kararı.

Audit olayında actor, zaman, işlem, kaynak, önce/sonra özeti ve gerekçe tutulur. Audit ekranı üzerinden geçmiş sessizce değiştirilemez.

### 9.6 Acil olay

Uygulama kurumca onaylı sabit güvenli yönlendirme gösterebilir. Otomatik acil servis çağrısı, otomatik ihbar, ceza veya yaptırım başlatamaz.

---

## 10. AI kuralları

### 10.1 Yetki sınırı

- AI öneri ve yardımcı sinyal üretir.
- AI tek başına bildirim silemez, reddedemez, yaptırım uygulayamaz veya halka yayımlayamaz.
- Kritik sinyal insan incelemesini atlayamaz.
- Vatandaş güven sinyali tek başına ret veya kısıtlama nedeni olamaz.

### 10.2 Rol bazlı görünürlük

Vatandaşa ham confidence, abuse sinyali veya model iç ayrıntısı gösterilmez; sade sonuç, belirsizlik ve itiraz yolu gösterilir. Personel ayrık skor, gerekçe kodu, veri kalitesi ve model/config sürümünü görür. Kişiye yönelik vatandaş güven skoru hiçbir rolde üretilmez.

### 10.3 Harici servis

Harici AI veya ağ servisi ilgili özellik için zorunlu olabilir. Böyle bir bağımlılık:

- açıkça konfigüre edilir;
- gerekli anahtarları güvenli secret yönetiminden alır;
- veri aktarım ve KVKK onayı olmadan gerçek veri göndermez;
- timeout, retry ve servis yok durumu gösterir;
- sahte başarı üretmez;
- otomatik nihai karar yetkisi kazanmaz.

Testlerde sözleşmeye uygun fake kullanılabilir. Vatandaşın AI dışı temel kayıt ve takip fonksiyonları `DATA_SOURCES.md` çevrimdışı kabul ölçütlerine uymalıdır.

---

## 11. Veri ve kalıcılık kuralları

### 11.1 JSON yazımı

1. Yeni snapshot bellek içinde hazırlanır, schema/referans/invariant doğrulanır ve checksum/revision güncellenir.
2. IO ortamında aynı dizindeki geçici dosya yazılır, flush edilir ve tekrar doğrulanır.
3. Mevcut aktif dosya son geçerli yedeğe alınır; geçici dosya atomik rename ile aktifleştirilir.
4. Webde aktif olmayan slota yazılır ve doğrulandıktan sonra pointer değiştirilir.
5. Bütün yazımlar tek writer kuyruğunda seri yürür.
6. Aktif kopya bozuksa yedek/diğer slot, ardından açık kullanıcı onayıyla deterministik seed kullanılır.

Yarım veya doğrulanmamış veri başarı sayılmaz.

### 11.2 Veri kökeni

Her dış kayıt en az şu bilgileri korur:

- kaynak adı ve türü;
- `sourceId/externalId`;
- kaynak güncelleme zamanı;
- sisteme alınma zamanı;
- lisans/atıf;
- tazelik ve sağlık durumu.

### 11.3 Demo verisi

- Gerçek kişisel veri yasaktır.
- Seed deterministik ve tekrar kurulabilir olmalıdır.
- Reset açık onay ister ve audit üretir.
- Harici kaynaktan gelen demo veri, canlıysa “canlı”; seed ise “demo verisi” olarak etiketlenir.
- Harita sağlayıcı atfı görünür olmalıdır.

---

## 12. Test ve kalite kapıları

### 12.1 Zorunlu otomatik kontroller

Aşağıdakilerin tamamı zorunludur:

- `dart format` kontrolü;
- `flutter analyze --fatal-infos --fatal-warnings`;
- unit testleri;
- widget testleri;
- golden/görsel regresyon testleri;
- integration/E2E testleri;
- JSON şema ve fixture testleri;
- otomatik erişilebilirlik kontrolleri;
- web, Android ve iOS build/smoke kontrolleri.

### 12.2 Kapsam hedefi

- Kritik domain, yetki, AI eşik, persistence ve migration dalları: en az yüzde 90.
- Genel satır kapsamı: en az yüzde 80.
- Yüzde hedefi, davranış ve E2E kanıtının yerine geçmez.

### 12.3 E2E

`ARCHITECTURE.md` içindeki E2E-01 ile E2E-22 arasındaki senaryolar teslim kapısıdır. Android, iOS ve web hedefleri eşit önceliklidir.

### 12.4 Hata düzeltme

Her hata düzeltmesi:

- kök neden analizi;
- en küçük güvenli kod değişikliği;
- regresyon testi;
- benzer kod yollarının taranması

içermelidir.

### 12.5 Golden

Golden dosyaları yalnız beklenen tasarım değişikliği doğrulandıktan ve diff görsel olarak incelendikten sonra güncellenir. Testi yeşile çevirmek için toplu golden yenilemek yasaktır.

### 12.6 Performans

`ARCHITECTURE.md` performans bütçeleri bağlayıcıdır. Ölçüm cihazı, build modu ve veri hacmi raporlanır. Belirgin regresyon teslimi engeller.

---

## 13. Git, PR ve CI

### 13.1 Dal kuralı

- Her çalışma ayrı `feature/*` veya `fix/*` dalında yapılır.
- Ana dala doğrudan değişiklik gönderilmez.
- Değişiklik pull request üzerinden incelenir.
- Force push, geçmişi yeniden yazma ve başka kişilerin commit'lerini amend etme yasaktır.

### 13.2 Commit

Commit mesajı kısa, anlamlı ve yapılan değişikliği açıkça belirtmelidir. Varsa issue/görev numarası branch, commit veya PR açıklamasına eklenir.

Örnekler:

```text
feat(report): add offline citizen draft flow
fix(auth): enforce staff route permission
test(data): cover corrupt snapshot recovery
docs(rules): record AI score visibility decision
```

### 13.3 İnceleme

Yetki, güvenlik, AI, veri kaybı ve migration değişiklikleri en az iki yetkili kişi tarafından incelenir.

PR birleştirilmeden önce format, analiz, unit, widget, golden, erişilebilirlik, şema, E2E ve gerekli platform build kontrolleri CI üzerinde başarılı olmalıdır.

---

## 14. Teslim standardı

Her teslim şunları içerir:

- değişiklik özeti ve etkilenen kullanıcı akışları;
- çalıştırılan testler ve sonuçları;
- bilinen sınırlamalar ve riskler;
- Android APK;
- iOS build/test kanıtı;
- web release build;
- demo hesapları ve reset talimatı;
- görsel değişiklikte ekran görüntüsü veya golden diff;
- şema değişikliklerinde migration notu;
- gerekli belge güncellemeleri.

### 14.1 Definition of Done

Bir iş yalnız şu koşullarda tamamlanmıştır:

- kabul ölçütlerinin tamamı karşılanmıştır;
- bütün zorunlu kontroller yeşildir;
- erişilebilirlik kontrolleri geçmiştir;
- loading, empty, offline ve error durumları tamamdır;
- belge ve çeviriler günceldir;
- secret veya gerçek kişisel veri yoktur;
- ölü eylem, placeholder veya sahte başarı yoktur;
- P0/P1 açık hata yoktur;
- P2 hata yalnız yazılı kabul ve çalışan workaround ile bırakılmıştır;
- P3 hata açıkça listelenmiştir.

Demo, üretime hazır güvenlik, ölçek veya mevzuat çözümü gibi tanıtılamaz.

---

## 15. Kesinlikle yasak işlemler

Aşağıdakiler hiçbir koşulda onaysız yapılamaz:

- gerçek kişisel veri, vatandaş bilgisi veya gerçek erişim bilgisi eklemek;
- parola, API anahtarı, token veya sertifikayı kaynak koda yazmak;
- veri silmek veya geçmişi yeniden yazmak;
- force push yapmak;
- güvenlik veya yetki kontrolünü devre dışı bırakmak;
- testi kaldırarak build'i yeşile çevirmek;
- AI'a otomatik ret, yaptırım veya yayımlama yetkisi vermek;
- gizli/orijinal medyayı kamuya açmak;
- temel proje belgeleriyle çelişen davranışı sessizce geliştirmek;
- hatayı gizlemek için sahte başarı, çalışmayan buton, placeholder veya yanıltıcı demo verisi kullanmak;
- onaysız üretim sistemi veya gerçek İBB servisine veri yazmak.

---

## 16. İstisna süreci

Geliştirici tek başına istisna veremez. Her istisna kaydı şunları içerir:

- istisna kimliği;
- etkilenen kural;
- teknik gerekçe;
- kapsam;
- kullanıcı, erişilebilirlik, veri ve güvenlik etkisi;
- değerlendirilen alternatifler;
- geçici önlem;
- sorumlu kişi;
- onaylayanlar;
- başlangıç ve sona erme tarihi;
- kaldırma planı.

Onay matrisi:

- Teknik istisna: teknik lider
- Ürün istisnası: ürün sahibi/proje yöneticisi
- Tasarım istisnası: tasarım sorumlusu
- Güvenlik, KVKK, gerçek veri veya AI yetkisi istisnası: ilgili teknik sorumlu + kurumun güvenlik/KVKK sorumlusu

İstisna yalnız gerekli bölüm ve belirli süreyle sınırlıdır. Süresi dolduğunda kaldırılır veya yeniden yazılı onaya sunulur.

---

## 17. Demo doğrulama ortamı

Demo aşağıdaki hedeflerin tamamında doğrulanır:

- güncel Android telefon ve tablet;
- güncel iOS telefon ve tablet;
- Chrome, Safari ve Edge'in desteklenen güncel sürümleri;
- telefon, tablet ve masaüstü breakpoint'leri;
- yüzde 200 metin büyütme;
- klavye ve ekran okuyucu kullanımı;
- reduced-motion tercihi;
- yavaş ve kesintili ağ;
- çevrimdışı durum;
- AI, harita ve veri kaynağı servis hataları.

Kesin cihaz modelleri, işletim sistemi sürümleri ve ekran çözünürlükleri teslimden önce kurumla yazılı olarak sabitlenir.

---

## 18. Uygulama kontrol listesi

Bir PR açılmadan önce geliştirici veya AI ajanı şu soruları yanıtlamalıdır:

- [ ] Değişiklik onaylı kapsam içinde mi?
- [ ] En yeni belge ve sürüm kontrol edildi mi?
- [ ] Yalnız gerekli bölüm mü değişti?
- [ ] Vatandaş ve belediye görünürlük sınırları korundu mu?
- [ ] Yetki üç katmanda uygulandı mı?
- [ ] Gerçek kişisel veri veya secret taraması temiz mi?
- [ ] Türkçe ve İngilizce metinler tamam mı?
- [ ] Android, iOS ve web davranışı test edildi mi?
- [ ] Loading, empty, offline ve error durumları var mı?
- [ ] Klavye, ekran okuyucu ve yüzde 200 metin testi geçti mi?
- [ ] Unit, widget, golden, E2E ve build kontrolleri geçti mi?
- [ ] Belge, fixture ve migration notları güncel mi?
- [ ] Demo ile gerçek entegrasyon arasındaki fark doğru etiketlendi mi?

Bu maddelerden biri karşılanmıyorsa iş tamamlandı olarak işaretlenemez.

---

## 19. Karar izlenebilirliği

| Karar kodu | Uygulandığı bölüm |
|---|---|
| RL-01 - RL-02 | Bölüm 1-2: hedef kitle ve tam proje kapsamı |
| RL-03 - RL-06 | Bölüm 3: karar sırası, yeni belge kuralı, belge değişikliği ve belirsizlik yönetimi |
| RL-07 - RL-14 | Bölüm 5 ve 14: küçük iş paketi, mevcut işi koruma, kısmi değişiklik, bağımlılık ve demo dürüstlüğü |
| RL-15 - RL-22 | Bölüm 6: MVVM/repository, `provider`, `go_router`, tipli model, adaptör, hata, clock ve config |
| RL-23 - RL-30 | Bölüm 7: tasarım kaynağı, yaklaşık uyum, marka, bütün anti-AI-slop yasakları, pin, iki dil ve motion |
| RL-31 - RL-33 | Bölüm 8: WCAG 2.2 AA ve P0/P1 erişilebilirlik teslim engeli |
| RL-34 - RL-40 | Bölüm 9: üç katmanlı yetki, demo hesap, log, medya, destrüktif işlem, audit ve acil olay |
| RL-41 - RL-46 | Bölüm 10-11: AI sınırı, eşit puan görünürlüğü, zorunlu olabilen harici servis, JSON overwrite, provenance ve gerçek veri yasağı |
| RL-47 - RL-53 | Bölüm 12 ve 17: bütün test türleri, kapsam, E2E-01-22, regresyon, golden, performans ve üç eşit platform |
| RL-54 - RL-60 | Bölüm 13-14: dal/PR/CI, iki inceleme, teslim kanıtı, DoD, hata sınırı, belge dili ve ihlal davranışı |
| RL-61 | Bölüm 4: son onay matrisi ve ortak güvenlik/KVKK onayı |
| RL-62 | Bölüm 13: feature/fix dalı, PR, commit, CI ve iki yetkili incelemesi |
| RL-63 | Bölüm 15: kesinlikle yasak işlemler |
| RL-64 | Bölüm 17: Android, iOS, web, cihaz, erişilebilirlik, ağ ve hata doğrulaması |
| RL-65 | Bölüm 16: yazılı, süreli ve rol bazlı istisna süreci |
