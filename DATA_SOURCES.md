# İBB Kent Takip - Veri Kaynakları ve Demo Veri Sözleşmesi

Belge durumu: Onaylı uygulama kaynağı  
Belge sürümü: 1.0  
Tarih: 16 Ağustos 2026  
Kapsam: Vatandaş uygulaması, belediye paneli, harita, olaylar, çalışmalar, kesintiler, ulaşım ve doğal afet verileri  
Hedef ortam: Android, iOS ve modern web  
Demo veri ilkesi: Veritabanı yok; paylaşımlı yerel Dart servisi ve JSON snapshot  

Kanonik düzeltme (17 Ağustos 2026): ADR-0005–ADR-0008 geçerlidir. Shared mod jüri ana modu, local mod CI/fallback'tir. Kaynak otoritesi teknik erişilebilirlikten önce gelir. Afet uyarıları yalnız yetkili kaynaktan salt okunurdur. Elektrik kesintisi yetkili kaynak bulunana kadar MVP filtresinde yoktur. Runtime yazımı atomik/yedekli veya web dual-slot'tur.

---

## 1. Amaç

Bu belge, İBB Kent Takip demosunda kullanılan her verinin:

- nereden geldiğini;
- hangi sözleşmeyle uygulamaya girdiğini;
- nasıl normalize edildiğini;
- nasıl güncellendiğini;
- hangi kullanıcıya gösterildiğini;
- kaynak kesintisinde nasıl davrandığını;
- nasıl test ve audit edildiğini

tanımlar.

Bu belge gerçek İBB üretim entegrasyonlarının tamamlandığını iddia etmez. Gerçek endpoint ve kurum içi servis sözleşmesi sağlanmayan kaynaklar deterministik seed veya açık veri adaptörüyle temsil edilir.

---

## 2. Kesin veri kararları

| Konu | Karar |
|---|---|
| Demo topolojisi | Telefon vatandaş uygulaması ve bilgisayar belediye paneli aynı anda aynı veriyi görür. |
| Ana çalışma modu | Paylaşımlı yerel Dart demo sunucusu + tek aktif JSON snapshot. |
| Veritabanı | Kullanılmaz. |
| Çevrimdışı hedef | Temel vatandaş akışları, seed harita ve yerel demo verisi internet olmadan çalışır. |
| Ana veri | Deterministik seed veri; canlı/açık veri adaptörleri ayrı ve opsiyonel katmandır. |
| Demo zamanı | Reset anına göre göreli zaman üreten `DemoClock`. |
| Reset | Yetkili ve onaylı eylemle başlangıç seed'ine dönüş; audit zorunlu. |
| Harita | İnternette OSM uyumlu tile; çevrimdışında örnek İstanbul haritası. |
| Adres arama | Yerel seed koordinat-adres sözlüğü. |
| İç koordinat | WGS84 `latitude/longitude`; dış kaynak sözleşmesi henüz kesin değildir. |
| Kişisel veri | Gerçek kişisel veri yok; bütün hesap ve kayıtlar kurgu/sentetik. |
| Belediye demo yetkisi | Belediye tarafını eksiksiz test etmek için tek yetkili demo hesabı yeterlidir. |
| Vatandaş kapsamı | Vatandaş panelindeki bütün tanımlı fonksiyonlar eksiksiz çalışmalıdır. |

---

## 3. Demo çalışma modeli

### 3.1 Paylaşımlı mod - ana sunum modu

```text
Vatandaş Flutter uygulaması
          |
          | REST + revision event
          v
Yerel Dart demo sunucusu
          |
          v
Tek JSON runtime snapshot
          ^
          |
Belediye Flutter web paneli
```

Kurallar:

- Sunucu tek process ve tek writer olarak çalışır.
- İki istemci aynı `revision` değerini izler.
- Mutasyon sonrası diğer istemciye yalnız değişiklik bildirimi gönderilir; güncel veri tekrar okunur.
- Aynı `clientMutationId` ikinci kez kayıt oluşturamaz.
- Sunucuya erişilemezse citizen taslağı yerelde korunur.
- Sunucu onayı olmadan “Gönderildi” sonucu gösterilmez.
- Belediye mutasyonları bağlantı yokken salt okunur olur; karar otomatik kuyruğa alınıp sonradan sessizce uygulanmaz.

### 3.2 Yerel mod - test ve fallback

Tek cihazda vatandaş ve belediye rolleri sırayla test edilebilir. Aynı yerel snapshot rol değişiminde korunur. Bu mod:

- CI testlerinde;
- internet olmayan sunumda;
- paylaşımlı sunucu başlatılamadığında;
- veri kaynağı hata senaryolarında

fallback olarak kullanılabilir.

### 3.3 İnternet kullanımı

İnternet aşağıdaki özellikler için opsiyonel veya kaynağa bağlıdır:

- canlı harita tile'ları;
- seçilmiş açık veri adaptörleri;
- kurumca daha sonra sağlanacak gerçek kaynaklar;
- harici AI servisi.

İnternet olmadığında vatandaşın kayıt oluşturma, kendi kaydını izleme, bildirimlerini görme, seed haritada olayları inceleme ve çevrimdışı taslak oluşturma işlevleri kaybolamaz.

---

## 4. Veri kaynağı envanteri

### 4.1 Zorunlu kaynaklar

| Kaynak ID | Veri | Demo kaynağı | Gelecek gerçek adaptör | Öncelik | Görünür etiket |
|---|---|---|---|---|---|
| `citizen_reports` | Vatandaş bildirimleri | Runtime JSON | Üretim backend | Zorunlu | Kullanıcı bildirimi |
| `municipal_entries` | Yetkili belediye olayları | Runtime JSON/manuel giriş | Kurum içi operasyon sistemi | Zorunlu | Belediye girişi |
| `planned_works` | Planlı yol/bakım çalışmaları | Seed + manuel giriş | İBB çalışma servisi/açık veri | Zorunlu | Planlı çalışma |
| `water_events` | Su kesintisi ve arıza | Seed | İSKİ açık/kurumsal veri adaptörü | Zorunlu | Kaynak adı + güncellik |
| `traffic_events` | Trafik olayı/yoğunluk etkisi | Seed | Erişilebilir trafik veri adaptörü | Zorunlu | Kaynak adı + güncellik |
| `transit_events` | Toplu ulaşım aksama/duyuru | Seed | Erişilebilir ulaşım veri adaptörü | Zorunlu | Kaynak adı + güncellik |
| `disaster_alerts` | Yüksek etkili doğal afet/tehlike olayı | Seed | Kurumca seçilecek yetkili uyarı kaynağı | Zorunlu | Doğal afet uyarısı + kaynak |
| `map_tiles` | Harita altlığı | OSM uyumlu tile | Kurum harita servisi opsiyonu | Destekleyici | Sağlayıcı atfı |
| `places_catalog` | İlçe, mahalle, örnek adres | `places.json` | Geocoding/adres servisi | Zorunlu | Demo adres verisi |

`disaster_alerts` hava durumu kartı değildir. Yalnız kent yaşamını ciddi biçimde etkileyen deprem, sel, heyelan, büyük yangın veya kurumca tanımlanan benzer doğal afet/tehlike olaylarını temsil eder. Kaynak ve mesaj kurumsal onay almadan gerçek resmî uyarı gibi gösterilemez.

### 4.2 Gerçek entegrasyon durumu

Şu anda kesin API sözleşmesi veya teknik kaynak sahibi rolü sağlanmamıştır. Bu nedenle:

- her dış kaynak için adaptör arayüzü hazırlanır;
- örnek JSON fixture sözleşmenin yürütülebilir örneği olur;
- uygun veri seti bulunursa açık veri portalı kullanılabilir;
- endpoint, anahtar ve kurum içi erişim zorunlu demo bağımlılığı yapılmaz;
- gerçek veri eklenene kadar seed kaynağı ana ve deterministik kalır.

### 4.3 Kaynak seçme önceliği

DS-11 kararı gereği demoda “her zaman resmî kaynak” önceliği yoktur. Kaynak seçiminde sıra:

1. olay sahibi yetkili kurum/birim;
2. İBB veya iştirakinin onaylı kaynağı;
3. kullanım, önbellekleme ve gösterim lisansı uygun açık veri;
4. açıkça teyitsiz etiketlenen üçüncü taraf veri;
5. vatandaş bildirimi;
6. AI önerisi.

Resmî olmayan kaynak kullanılırsa kullanıcıya kaynak adı açıkça gösterilir; veri İBB'nin doğruladığı olay gibi işaretlenmez. Yetkili personel doğrulaması sonrası ayrı bir `PublicIncident` üretilebilir.

---

## 5. Harita ve mekânsal veri

### 5.1 Demo haritası

Demo iki yüzey taşır:

1. `LiveTileMapSurface`: OSM uyumlu canlı tile katmanı
2. `OfflineDemoMapSurface`: örnek/sentetik İstanbul haritası

Örnek harita:

- resmî canlı İBB haritası olarak sunulmaz;
- pin, seçim, filtre, pan/zoom ve erişilebilir liste akışını destekler;
- internet olmadan çalışır;
- demo senaryosundaki konumlarla görsel olarak tutarlıdır.

OSM kullanıldığında görünür `© OpenStreetMap contributors` atfı zorunludur. Tile URL'si config'ten gelir; toplu indirme veya izinsiz prefetch yapılmaz.

### 5.2 Adres ve yer kataloğu

`places.json` en az şunları içerir:

- İstanbul'un 39 ilçesi;
- demo için seçilen mahalleler;
- örnek adres/POI kayıtları;
- gösterim adı;
- normalize arama alanı;
- latitude/longitude;
- ilçe ve varsa mahalle kodu.

Arama:

- Türkçe büyük/küçük harf normalizasyonu yapar;
- Türkçe ve İngilizce görünen adları destekleyebilir;
- 250 ms debounce kullanır;
- ağ servisine bağımlı değildir.

### 5.3 Koordinat standardı

Dış kaynakların resmî geospatial sözleşmesi henüz belirlenmemiştir. Uygulama içi kanonik standart teknik zorunluluk olarak:

```json
{
  "latitude": 41.0082,
  "longitude": 28.9784,
  "coordinateSystem": "EPSG:4326"
}
```

şeklindedir. Farklı EPSG kullanan gelecekteki kaynaklar adaptör içinde WGS84'e dönüştürülür. Ham değer ve dönüşüm bilgisi provenance kaydında tutulur.

### 5.4 İstanbul dışı kayıt

İstanbul sınırı dışında seçilen konum otomatik reddedilmez. Kayıt:

- kullanıcıya açık sınır uyarısı gösterilerek kabul edilir;
- genel haritaya otomatik yayımlanmaz;
- manuel belediye inceleme kuyruğuna gider;
- `outside_service_area=true` işareti alır;
- insan kararıyla kapsam dışı bırakılabilir veya yönlendirilebilir.

### 5.5 Konum hassasiyeti

- Yetkili operasyon rolü gerekli olduğunda tam koordinatı görebilir.
- Kamu projection'ı hassas kategori veya konutta yaklaşık/yuvarlanmış konum kullanabilir.
- Ham tam konum loglara ve analytics olayına yazılamaz.
- Konum hassasiyeti kategori bazlı config ile belirlenir.

---

## 6. Kanonik veri modeli

### 6.1 Kaynak zarfı

Her dış kayıt önce aşağıdaki zarfla alınır:

```json
{
  "sourceId": "water_events",
  "externalId": "demo-water-0001",
  "sourceType": "open_data",
  "sourceUpdatedAt": "2026-08-16T18:00:00Z",
  "ingestedAt": "2026-08-16T18:00:12Z",
  "schemaVersion": 1,
  "licenseId": "source-specific",
  "attribution": "Demo source attribution",
  "payloadHash": "sha256:...",
  "payload": {}
}
```

### 6.2 Kanonik olay alanları

| Alan | Tip | Zorunlu | Açıklama |
|---|---|:---:|---|
| `id` | string | Evet | İç UUID/prefix kimliği |
| `sourceId` | string | Evet | Kaynak envanteri kimliği |
| `externalId` | string | Evet | Kaynaktaki değişmez kimlik |
| `entityType` | enum | Evet | `citizen_report`, `public_incident`, `municipal_work`, `source_event` |
| `category` | enum | Evet | Kanonik kategori |
| `status` | enum | Evet | Kanonik yaşam döngüsü |
| `riskLevel` | enum | Evet | `low`, `medium`, `high`, `critical`, `unknown` |
| `visibility` | enum | Evet | `owner`, `staff`, `public` |
| `location` | object | Evet | WGS84 koordinat + bölge bilgisi |
| `startsAt` | datetime | Duruma göre | UTC ISO-8601 |
| `expectedEndsAt` | datetime | Hayır | UTC ISO-8601 |
| `sourceUpdatedAt` | datetime | Evet | Kaynak güncelleme zamanı |
| `ingestedAt` | datetime | Evet | Sisteme alınma zamanı |
| `responsibleUnitId` | string | Hayır | Sorumlu birim |
| `mediaRefs` | array | Hayır | Binary değil güvenli referans |
| `freshness` | enum | Evet | `fresh`, `stale`, `unavailable` |
| `attribution` | string | Duruma göre | Gösterim/lisans metni |
| `auditRef` | string | Mutasyonda | İşlem kaydı bağlantısı |

### 6.3 Kimlik

- İç kayıt kimliği uygulama tarafından üretilir.
- Dış kayıt doğal anahtarı `sourceId + externalId` birleşimidir.
- Aynı birleşim tekrar geldiğinde yeni olay oluşturulmaz; mevcut kaydın daha yeni sürümü uygulanır.
- `sourceUpdatedAt` eskiyse değişiklik uygulanmaz ve gözlem audit/ingestion loguna yazılır.
- Vatandaş takip numarası birleştirme veya kaynak bağlantısından etkilenmez.

### 6.4 Zaman

- Saklama: UTC ISO-8601
- Gösterim: `Europe/Istanbul`
- Seed zamanı: reset anına göre göreli
- Kaynak saat dilimi: source config içinde açıkça belirtilir
- Saat dilimi olmayan tarih sessizce İstanbul saati sayılamaz; adaptör doğrulaması gerekir

---

## 7. Kategori ve durum normalizasyonu

### 7.1 Eşleme tabloları

Her kaynak aşağıdaki sürümlü eşlemeleri taşır:

```text
source_category -> canonical_category
source_status   -> canonical_status
source_unit     -> canonical_unit
source_severity -> canonical_risk
```

Eşlemeler kod içine dağınık `switch` blokları olarak yazılmaz. Kaynak adaptörü veya sürümlü config içinde tutulur.

### 7.2 Bilinmeyen değer

Bilinmeyen kategori, durum veya bozuk zorunlu alan:

- otomatik “Diğer” değerine çevrilmez;
- sessizce atılmaz;
- `quarantined` ingestion sonucu üretir;
- kamu haritasına çıkmaz;
- veri kaynağı sağlık ekranında görünür;
- fixture testi eklenmeden kalıcı mapping yapılamaz.

### 7.3 Durum otoritesi

Çelişen bilgilerde sıra:

1. Yetkili personelin gerekçeli kararı
2. Olay sahibi resmî/operasyonel birim
3. Diğer resmî kaynak
4. Erişilebilir üçüncü taraf/açık veri kaynağı
5. Vatandaş bildirimi
6. AI önerisi

AI veri kaynağı otoritesi değildir; yardımcı sinyaldir.

### 7.4 Geri çekme ve silme

Kaynakta silinen veya geri çekilen kayıt fiziksel olarak sessizce silinmez:

- `withdrawn` veya `archived` olur;
- kamu görünürlüğü kaldırılır;
- son bilinen provenance korunur;
- bağlı vatandaş raporları kendi takip numarasıyla yaşamaya devam eder;
- değişiklik audit edilir.

---

## 8. Ingestion pipeline

Her gerçek veya fixture kaynağı aynı aşamalardan geçer:

```text
Fetch/Read
  -> Decode
  -> Source schema validation
  -> Normalize
  -> Canonical validation
  -> Freshness check
  -> Duplicate candidate detection
  -> Conflict policy
  -> Single-writer commit
  -> Projection/event
  -> Health metric
```

### 8.1 Doğrudan istemci çağrısı yasağı

Canlı veri kaynağı Flutter istemcisinden doğrudan çağrılmaz. Paylaşımlı demo sunucusu adaptör/proxy görevi görür. Böylece:

- API anahtarı istemciye girmez;
- CORS ve rate limit merkezi yönetilir;
- şema normalizasyonu tek yerde yapılır;
- kaynak kesintisi iki istemcide aynı görünür;
- provenance kaybolmaz.

Harita tile isteği bu kuralın tek istisnasıdır; sağlayıcı şartlarına uygun olarak istemciden gelebilir.

### 8.2 Retry ve devre kesici

- Üstel geri çekilme ve jitter kullanılır.
- Sonsuz retry yapılamaz.
- Ardışık hata üst sınırında devre kesici açılır.
- Manuel “Yeniden dene” bulunur.
- Retry eski kaydı yeni kayıt olarak çoğaltamaz.
- Kaynak kesintisi vatandaş bildirim sistemini durduramaz.

---

## 9. Yenileme ve tazelik

### 9.1 Varsayılan yenileme tablosu

| Kaynak | Yenileme | `stale` eşiği | `unavailable` eşiği |
|---|---:|---:|---:|
| Doğal afet/tehlike | 1 dk | 5 dk | 15 dk veya devre kesici |
| Trafik olayları | 2 dk | 10 dk | 30 dk |
| Toplu ulaşım | 5 dk | 15 dk | 60 dk |
| Su kesintisi/arıza | 10 dk | 30 dk | 2 saat |
| Planlı çalışma | 30 dk | 2 saat | 6 saat |
| Seed/demo | Olay tabanlı | `DemoClock` ile | Uygulanmaz |

Gerçek kaynak rate limit veya kurum politikası farklıysa kaynak config'i tabloyu geçersiz kılabilir. Değişiklik belgelenir.

### 9.2 Tazelik gösterimi

Her dış veri projection'ı:

- kaynak adını;
- kaynak zamanını;
- sisteme alınma zamanını;
- `fresh/stale/unavailable` durumunu

taşır. Bayat veri gizlenmez; zaman etiketi ve uyarıyla gösterilir. Güvenli olmayan eski kritik bilgi otomatik resmî uyarı gibi yükseltilemez.

### 9.3 Kesinti

Kaynak kullanılamazsa:

- son doğrulanmış snapshot okunabilir kalır;
- bayat etiketi görünür;
- retry/backoff çalışır;
- personel kaynak sağlık ekranından ayrıntıyı görür;
- citizen report oluşturma ve takip devam eder;
- yalnız ilgili canlı katman etkilenir;
- uygulama genel blocking error'a düşmez.

---

## 10. Mükerrerlik ve çakışma

### 10.1 Kaynaklar arası adaylık

Aynı kategori, yakın zaman ve yakın konumdaki kayıtlar mükerrer adayı olabilir. Varsayılan demo ön filtresi:

- aynı veya eşlenmiş kategori;
- 250 metre yarıçap;
- son 72 saat veya olayın aktif zaman aralığı;
- açıklama/başlık benzerliği.

Bu değerler `AI_SYSTEM.md` onaylandığında kategori bazında güncellenebilir.

### 10.2 Karar

- Otomatik fiziksel silme yoktur.
- AI veya kural motoru yalnız aday bağlantı üretir.
- Personel ana kaydı seçer.
- Birleştirilen vatandaş raporu kendi takip numarasını korur.
- Döngüsel merge yasaktır.
- Kaynak provenance kayıtları korunur.

### 10.3 Planlı olay çakışması

Vatandaş konumunda planlı çalışma varsa:

- planlı olay kullanıcıya gösterilir;
- kullanıcı “Bunu da yaşıyorum” ile olaya katılabilir;
- farklı sorun olduğunu düşünüyorsa yeni bildirimle devam edebilir;
- yeni bildirim sessizce engellenmez veya otomatik birleşmez.

---

## 11. JSON dosya yapısı ve kalıcılık

### 11.1 Seed paketi

```text
assets/demo_data/v1/
├─ manifest.json
├─ accounts.json
├─ places.json
├─ reports.json
├─ incidents.json
├─ municipal_works.json
├─ source_events.json
├─ notifications.json
├─ audit_events.json
├─ data_sources.json
├─ privacy_requests.json
├─ account_restrictions.json
├─ scenario_catalog.json
└─ app_settings.json
```

### 11.2 Runtime snapshot

```json
{
  "schemaVersion": 1,
  "seedVersion": "2026.08.16.1",
  "revision": 1,
  "updatedAt": "2026-08-16T19:00:00Z",
  "checksum": "sha256:...",
  "payload": {
    "accounts": [],
    "reports": [],
    "incidents": [],
    "municipalWorks": [],
    "sourceEvents": [],
    "notifications": [],
    "auditEvents": [],
    "dataSources": [],
    "privacyRequests": [],
    "accountRestrictions": [],
    "demoState": {}
  }
}
```

### 11.3 Yazım kuralı

`RULES.md` ve ADR-0005 gereği mutasyon tek writer kuyruğuna girer. Yeni snapshot bellek içinde hazırlanır; schema, referans, invariant, revision ve checksum doğrulanır. IO'da temp dosya flush/read doğrulamasından sonra aktif kopya yedeğe çevrilir ve temp atomik rename edilir. Webde aktif olmayan slot doğrulandıktan sonra pointer değiştirilir. Bozuk active kopyada yedek/diğer slot denenir; seed reset açık kullanıcı onayı ister.

### 11.4 Medya

- Fotoğraf binary'si JSON içine konmaz.
- JSON yalnız `MediaRef` tutar.
- Seed medya `asset://demo_media/...` referansı kullanır.
- Orijinal ve kamusal/maskeli medya ayrıdır.
- Reset kullanıcı üretimli demo medyasını temizler.
- Gerçek kişi veya gerçek plaka içeren onaysız medya seed'e giremez.

### 11.5 İçe/dışa aktarma

Yetkili demo hesabı:

- doğrulanmış snapshot'ı JSON olarak dışa aktarabilir;
- yalnız şema, checksum, referans ve sentetik veri doğrulamasını geçen fixture'ı içe aktarabilir;
- içe aktarma öncesinde açık onay verir;
- işlem audit kaydı üretir.

---

## 12. Seed veri standardı

### 12.1 Asgari içerik

Seed en az şunları içerir:

- vatandaş giriş ve tüm vatandaş akışlarını çalıştıracak kurgu hesaplar;
- belediye panelini tamamıyla test edecek en az bir yetkili demo hesabı;
- 39 ilçe referansı;
- en az 12 doğrulanmış aktif olay;
- en az 6 planlı çalışma;
- her tanımlı inceleme kuyruğunda en az 3 kayıt;
- pending, ek bilgi gerekli, merged, rejected ve resolved vatandaş örnekleri;
- en az 3 mükerrer aday grubu;
- su, trafik, toplu ulaşım ve doğal afet kaynak örnekleri;
- taze, bayat ve kullanılamayan kaynak durumları;
- gizlilik güvenli/orijinal medya çiftleri;
- okunmuş ve okunmamış bildirimler;
- audit, kısıtlama, itiraz ve KVKK senaryoları.

Birden fazla staff rolü veya hesabı demo kabulü için zorunlu değildir. Tek yetkili hesap, gerekli belediye eylemlerinin tamamına erişebilir. Mimari permission kontrolleri yine korunur.

### 12.2 Coğrafi dağılım

Belirli bir ilçe zorunlu değildir. Seed:

- Avrupa ve Anadolu yakasını;
- merkez ve çeper bölgeleri;
- farklı yoğunlukları;
- farklı olay türlerini

dengeli temsil eder. Her 39 ilçede olay bulunması zorunlu değildir; ancak ilçe referans kataloğu tamdır.

### 12.3 Kategori ve pin kapsamı

Seed aşağıdaki görsel ve işlevsel durumların tamamını üretmelidir:

- kırmızı doğrulanmış aktif olay;
- sarı planlı olay;
- vatandaşın gri bekleyen bildirimi;
- personelin turuncu kritik incelemesi;
- küme/cluster;
- mükerrer aday;
- gizlilik incelemesi;
- kaynak kesintisi;
- itiraz ve çözüm timeline'ı.

### 12.4 Görsel kaynağı

Seed görseller:

- sentetik, ekipçe üretilmiş veya açıkça lisanslı olmalıdır;
- gerçek kişisel veri taşımamalıdır;
- gerekli senaryolarda önceden hazırlanmış orijinal/maskeli çift bulundurmalıdır;
- lisans ve üretim kaynağı manifestte belirtilmelidir.

İnternetten rastgele alınmış görsel kullanılamaz.

### 12.5 Stres fixture'ı

Normal seed'den ayrı 10.000 olaylık deterministik stres fixture'ı bulunur. Bu fixture:

- harita projection;
- filtre;
- sıralama;
- kuyruk pagination/virtualization;
- kaynak tazelik hesapları

için kullanılır ve normal sunum seed'ine yük bindirmez.

---

## 13. Kaynak sağlık modeli

Her kaynak için `DataSourceHealth` tutulur:

```json
{
  "sourceId": "traffic_events",
  "health": "stale",
  "lastAttemptAt": "2026-08-16T18:05:00Z",
  "lastSuccessAt": "2026-08-16T17:50:00Z",
  "sourceTimestamp": "2026-08-16T17:48:00Z",
  "durationMs": 620,
  "receivedCount": 125,
  "acceptedCount": 120,
  "quarantinedCount": 5,
  "lastErrorCode": "source_timeout"
}
```

Belediye veri kaynakları ekranı şunları gösterir:

- kaynak adı ve türü;
- taze/bayat/kullanılamıyor durumu;
- son başarılı güncelleme;
- kaynak zaman damgası;
- gecikme;
- alınan/kabul/karantina kayıt sayısı;
- güvenli hata özeti;
- manuel yeniden dene.

Vatandaş yüzeyinde teknik hata ayrıntısı gösterilmez; yalnız ilgili verinin son güncelleme zamanı ve gerekirse bayatlık uyarısı gösterilir.

---

## 14. Rol, görünürlük ve düzenleme

### 14.1 Vatandaş

Vatandaş panelindeki bütün tanımlı fonksiyonlar eksiksiz çalışmalıdır:

- misafir/genel harita;
- Türkçe ve İngilizce arayüz;
- telefon/OTP demo girişi;
- bildirim oluşturma;
- kamera/demo kamera;
- AI analiz sonucu;
- konum ve açıklama;
- mükerrer önerisi;
- gönderim ve takip numarası;
- kendi gri pinini görme;
- bildirim listesi ve timeline;
- ek bilgi gönderme;
- bildirim merkezi;
- çevrimdışı taslak ve retry;
- KVKK/itiraz/hesap işlemleri.

Başka vatandaşın pending bildirimi, kişisel bilgisi veya ham medyası citizen projection'a giremez.

### 14.2 Belediye

Demo için tek yetkili hesap yeterlidir. Bu hesap gerekli testlerde:

- kuyrukları görür;
- raporu inceler;
- doğrular, reddeder, birleştirir ve ek bilgi ister;
- birim/ilçe yönlendirmesi yapar;
- saha ve çözüm durumunu günceller;
- planlı çalışma oluşturur ve yayımlar;
- veri kaynağı sağlık ekranını görür;
- audit ve reset işlemlerini test eder.

Tek hesap seçimi, yetki kontrolünü kaldırmaz. Her eylem permission policy'den geçer ve audit üretir.

### 14.3 Manuel düzenleme

- Yalnız yetkili hesap düzenleme yapar.
- Önce/sonra değerleri ve gerekçe audit edilir.
- Kaynaktan gelen dış kimlik değiştirilemez.
- Personel düzeltmesi kaynak verisini sessizce silmez; override/projection üretir.
- Dış kaynağın daha sonraki güncellemesi personel kararını otomatik geçersiz kılamaz.

---

## 15. Gizlilik, lisans ve saklama

### 15.1 Kişisel veri

Demo ortamında:

- gerçek telefon, e-posta, kişi adı ve adres kullanılmaz;
- kurgu hesaplar ve `demo.invalid` alanları kullanılır;
- gerçek vatandaş açıklaması veya fotoğrafı fixture'a alınmaz;
- anonimleştirilmiş gerçek veri bile yazılı kurum onayı olmadan kullanılamaz.

### 15.2 Lisans envanteri

Her kaynak kaydı şu alanları taşır:

- kaynak sahibi/sağlayıcı;
- kullanım koşulu bağlantısı veya belge referansı;
- atıf metni;
- yeniden dağıtım izni;
- önbellekleme izni;
- türetilmiş gösterim izni;
- son lisans kontrol tarihi;
- kontrol eden rol.

Bu bilgiler bilinmiyorsa kaynak yalnız internal fixture olarak kullanılır; canlı kullanıcıya üçüncü taraf gerçek veri gibi sunulmaz.

### 15.3 Saklama

- Demo runtime verisi yetkili reset ile silinebilir.
- Reset öncesinde kullanıcıya kapsam gösterilir.
- Reset audit edilir.
- Üretim saklama süreleri bu demo belgesiyle kesinleştirilmez; kaynak ve veri türü bazında kurum/KVKK kararı gerekir.
- Ham dış kaynak cevapları süresiz biriktirilmez.
- Hata ayıklama için kişisel verisiz sınırlı snapshot veya hash tutulabilir.

---

## 16. Reset, tarih ve deterministiklik

### 16.1 Reset

“Demoyu sıfırla” eylemi:

1. Yetki kontrolü yapar.
2. Silinecek demo değişikliklerini açıklar.
3. Kullanıcı onayı alır.
4. Runtime snapshot ve kullanıcı üretimli demo medyasını temizler.
5. Seed paketini yeniden yükler.
6. `DemoClock` başlangıcını reset anına ayarlar.
7. Şema/invariant doğrular.
8. Yeni revision üretir.
9. Audit olayı yazar.
10. Bağlı istemcilere revision değişikliği bildirir.

### 16.2 Göreli zaman

Seed'de kullanıcıya görünen zamanlar sabit geçmiş tarihe bağlı kalmaz. Örnek:

```text
reset - 12 dakika -> aktif olay güncellemesi
reset + 5 dakika  -> planlı çalışmanın aktife geçişi
reset + 1 gün     -> planlı bakım başlangıcı
```

Testler gerçek saat yerine `FakeClock` kullanır.

---

## 17. Test ve kabul ölçütleri

### 17.1 Zorunlu testler

| Test | Beklenen sonuç |
|---|---|
| İki istemci ortak durum | Vatandaş mutasyonu belediye paneline revision sonrası gelir. |
| Çevrimdışı vatandaş | Harita fallback, taslak, liste ve takip çalışır. |
| Tekrarlanan gönderim | Aynı `clientMutationId` tek kayıt üretir. |
| Bozuk kaynak kaydı | Karantinaya alınır; genel haritaya çıkmaz. |
| Eski kaynak güncellemesi | Yeni kaydın üzerine yazılmaz. |
| Kaynak kesintisi | Son snapshot bayat etiketiyle kalır; genel uygulama çalışır. |
| Reset | Seed birebir ve deterministik kurulur. |
| İstanbul dışı bildirim | Kabul edilir, uyarı ve manuel kuyruk üretir. |
| Mükerrer aday | Otomatik silinmez/birleşmez; personel kararı bekler. |
| Planlı olay çakışması | Kullanıcı katılabilir veya yeni bildirimle devam edebilir. |
| Gizlilik hatası | Orijinal medya kamu projection'ına girmez. |
| Kaynak provenance | Kaynak, zaman, lisans ve dış ID korunur. |
| JSON overwrite hatası | Bozuk durum başarı sayılmaz; son geçerli veri veya seed ile kurtarılır. |
| 10.000 kayıt fixture | ARCHITECTURE performans bütçeleri sağlanır. |
| Yetkisiz düzenleme | Reddedilir ve audit edilir. |

### 17.2 Kaynak adaptörü kabulü

Gerçek bir adaptör tamamlanmış sayılmadan önce:

- örnek veri ve field mapping tablosu;
- kaynak şema doğrulama testi;
- canonical schema testi;
- tazelik ve kesinti testi;
- rate limit/retry testi;
- mükerrer ve çakışma testi;
- lisans ve atıf kaydı;
- veri sahibi veya yetkili onayı;
- performans testi

tamamlanmalıdır.

### 17.3 Genel demo kabulü

Veri katmanı yalnız şu koşullarda kabul edilir:

- temel vatandaş akışları internetsiz tamamlanır;
- telefon ve bilgisayar aynı paylaşımlı durumu görür;
- vatandaş panelindeki bütün tanımlı işlevler çalışır;
- tek yetkili belediye hesabı bütün gerekli personel senaryolarını tamamlar;
- reset deterministik seed'i geri kurar;
- kaynak bayatlık ve fallback davranışı görünürdür;
- gerçek kişisel veri yoktur;
- kaynak ve lisans bilgisi kaybolmaz;
- bozuk JSON/kaynak kaydı kontrollü kurtarılır;
- audit ve görünürlük değişmezleri geçer.

---

## 18. Ertelenen ve açık kararlar

Vatandaş panelindeki hiçbir tanımlı fonksiyon ertelenmez. Belediye tarafında çoklu personel hesabı ve ayrıntılı organizasyon rol çeşitliliği demo sonrası genişletilebilir; demo için tek yetkili hesap yeterlidir.

Aşağıdaki konular demo geliştirmesini durdurmadan açık kalabilir:

| Açık konu | Demo kararı | Kapanış sorumlusu |
|---|---|---|
| Gerçek İSKİ endpoint/sözleşmesi | Seed + adaptör fixture | Kurumsal veri sahibi + teknik lider |
| Gerçek trafik kaynağı | Erişilebilir veri veya seed | Teknik lider |
| Gerçek toplu ulaşım kaynağı | Erişilebilir veri veya seed | Teknik lider + ilgili birim |
| Doğal afet yetkili kaynağı | Sentetik kritik senaryo | Kurumsal güvenlik/afet sorumlusu |
| Kaynak teknik sahipleri | Şimdilik tanımlı değil | Proje yöneticisi |
| Kesin harita sağlayıcısı | OSM uyumlu + örnek fallback | Teknik lider + lisans sorumlusu |
| Dış kaynak koordinat sözleşmesi | İçeride WGS84 | Kaynak sahibi + teknik lider |
| Üretim saklama süreleri | Demo reset politikası | KVKK/hukuk sorumlusu |

Gerçek entegrasyon bilgisi geldiğinde bu tablo ve kaynak envanteri yeni onaylı sürümle güncellenir.

---


## 18A. WP-17 uygulanmış demo kaynak sınırı

17 Ağustos 2026 WP-17 kaynak uygulamasında aşağıdaki sınırlar kanoniktir:

- `SourceAdapter<T>` ortak sözleşmesi fetch → decode → validate → normalize → freshness/provenance hattını zorunlu kılar.
- `transit_gtfs_schema`, İETT/GTFS `stops.txt` alanlarını (`stop_id`, `stop_name`, `stop_lat`, `stop_lon`) gerçek şemaya göre doğrulayan **fixture mapping kanıtıdır**; canlı İETT endpoint entegrasyonu değildir. UI bunu açıkça böyle etiketler.
- Su, trafik, toplu ulaşım, planlı çalışma ve afet için deterministik fixture katalogu bulunur. Elektrik kaynağı somut ve yetkili veri kaynağı olmadığı için disabled kalır.
- Doğrulamayı geçmeyen veya tanımsız kayıtlar sessiz “Diğer”e dönüştürülmez; quarantine olarak sağlık/provenance kaydında tutulur.
- Kaynak yenilemesi retry/backoff/jitter, circuit-breaker ve son geçerli stale cache davranışı taşır; kesinti uygulama snapshot'ını kullanılmaz hale getirmez.
- Belediye yetkili manuel olay/çalışma girişleri `municipal_authorized_entry` provenance ve audit'i taşır.
- JSON/CSV fixture import `manageSources` yetkisi ister; export kaynak/provenance alanlarını korur.
- `external_153_mock` yalnız contract simulation'dır: external application ID, status sync, source timestamp, report/incident bağlantısı ve sync-error alanları vardır. Gerçek 153/İstanbul Senin yazımı veya canlı senkron iddiası yoktur.
- Afet uyarısı fixture'ı salt-okunur/authorized-source modelini temsil eder; gerçek resmî uyarı ancak kurumca onaylı kaynak bağlandığında etkinleştirilir.

Bu bölüm, Bölüm 18'deki “gerçek endpoint açık kararlarını” kapatmaz; yalnız demo entegrasyon dikişinin yürütülebilir sınırını belgeler.

---

## 19. Kaynak ekleme kontrol listesi

- [ ] Kaynak ID benzersiz mi?
- [ ] Kaynak sahibi veya sağlayıcı kaydedildi mi?
- [ ] API/dosya şeması örnek fixture ile doğrulandı mı?
- [ ] Field mapping ve enum eşlemeleri sürümlü mü?
- [ ] Dış ID ve güncelleme zamanı var mı?
- [ ] Saat dilimi ve koordinat sistemi açık mı?
- [ ] Lisans, atıf ve önbellekleme izni kayıtlı mı?
- [ ] Kişisel veri taraması yapıldı mı?
- [ ] Tazelik ve unavailable eşikleri tanımlı mı?
- [ ] Retry, rate limit ve devre kesici testi var mı?
- [ ] Eksik alan karantina akışı çalışıyor mu?
- [ ] Mükerrer/çakışma testi eklendi mi?
- [ ] Vatandaş ve personel projection'ları test edildi mi?
- [ ] Çevrimdışı ve son snapshot davranışı test edildi mi?
- [ ] Kaynak sağlık ekranında görünüyor mu?
- [ ] Audit ve provenance korunuyor mu?

Bu maddeler tamamlanmadan kaynak “hazır” olarak işaretlenemez.

---

## 20. Karar izlenebilirliği

| Karar kodu | Uygulandığı bölüm |
|---|---|
| DS-01 - DS-06 | Bölüm 2-3 ve 16: iki cihaz, shared JSON, çevrimdışı temel akış, seed önceliği, göreli saat ve reset |
| DS-07 - DS-11 | Bölüm 4: vatandaş, belediye, planlı iş, su, trafik, ulaşım ve doğal afet kaynakları; açık veri seçeneği; demo etiketi; kaynak sahibi TBD; erişilebilir kaynak önceliği |
| DS-12 - DS-18 | Bölüm 5: OSM/örnek harita, yerel adres, 39 ilçe, hassasiyet, iç WGS84 standardı ve İstanbul dışı manuel inceleme |
| DS-19 - DS-26 | Bölüm 6-7: kanonik model, kimlik, provenance, kategori/durum eşleme, karantina, arşiv ve UTC |
| DS-27 - DS-30 | Bölüm 7 ve 10: mükerrer aday, otorite sırası, planlı olay çakışması ve eski güncelleme koruması |
| DS-31 - DS-36 | Bölüm 8-9 ve 13: yenileme, tazelik, fallback, retry, sunucu adaptörü ve kaynak sağlık ekranı |
| DS-37 - DS-40 | Bölüm 12: seed hacmi, dengeli coğrafya, kategori kapsamı ve lisanslı/sentetik görseller |
| DS-41 - DS-42 | Bölüm 11-12: 10.000 kayıt fixture ve doğrulamalı içe/dışa aktarma |
| DS-43 - DS-47 | Bölüm 14-15: gerçek veri yasağı, lisans, saklama, sınırlı ham kayıt ve rol bazlı düzenleme |
| DS-48 - DS-50 | Bölüm 4, 13 ve 17: veri kabul ölçütleri, adaptör kanıtları ve somut kaynak envanteri |
| DS-51 | Bölüm 12.2: zorunlu pilot ilçe yok |
| DS-52 | Bölüm 14 ve 18: vatandaş işlevlerinde erteleme yok; belediyede tek yetkili demo hesabı yeterli |
