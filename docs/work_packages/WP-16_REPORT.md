# WP-16 — Planlı çalışma, yayınlama ve açıklanabilir etki analizi

## Uygulanan kaynak

- DESIGN W-05'e uygun iki panelli planlama ekranında çalışma türü, konum/etki alanı, başlangıç-bitiş, sorumlu birim ve açıklama alanları bulunur; geçerli form 700 ms debounce ile taslak autosave yapar.
- Taslak `draft` durumunda public projection'a girmez. Taslak düzenleme impact sonucunu sıfırlayıp yeniden analiz gerektirir.
- `MunicipalImpactAnalyzer`; demo yol segmenti bufferları, toplu taşıma hat bufferları ve diğer belediye çalışmalarının uzamsal + zamansal çakışmalarını deterministik olarak hesaplar.
- Her çakışma kaynak ID/etiket, mesafe, kural, açıklama ve varsa zaman örtüşmesini taşır. Metin açıkça “AI trafik tahmini kullanılmadı” der.
- Alternatif zaman/güzergâh önerileri yalnız kural tabanlıdır ve gerekçesi görünürdür; insan kabulü dışında yayınlanmaz.
- DESIGN W-06 tek rapor yüzeyinde gerçek `MapExperience` taslak etki merkezi, zaman çizgisi, etkilenen yollar/hatlar, çakışma gerekçeleri, alternatifler ve vatandaş bilgilendirme taslağı gösterilir. Taslak pin yalnız staff önizlemesidir ve public projection'a yazılmaz.
- DESIGN W-07 yayın kontrolünde ortak `KtMapPin` ile sarı planlı pin önizlemesi, tarih, birim ve düzenlenebilir citizen text sunulur. `publicPreviewApproved=true` olmadan publish command oluşturulamaz.
- Publish sonrası etkin görünüm DemoClock/projection ile `publishedPlanned → active → completed` olur: başlangıç öncesi sarı, çalışma sırasında kırmızı, tamamlanınca live map'ten kalkar; municipal work history snapshot'ta korunur. `MapExperience` en yakın başlangıç/bitiş sınırında ve uygulama resume olduğunda saat projection'ını yeniler; staff planlama modülü ayrıca persisted clock reconciliation çalıştırır.
- Uygulama bitişten sonra açılırsa persisted reconcile işlemi yasak state sıçraması yapmaz; audit/timeline'a önce `active`, sonra `completed` yazar.
- Otomatik transition hatası fail-closed `admin_alert` audit olayı üretir.
- Local gateway, remote gateway ve demo server `/v1/commands/municipal-work` kontratını paylaşır.

## Uzman incelemesinde düzeltilenler

- `publishedPlanned → completed` doğrudan sıçrama denemesi state-machine kuralını ihlal ettiği için ara `active` transition'ı zorunlu hale getirildi.
- Yayın ekranına gerçek design-system sarı pin önizlemesi eklendi.
- Citizen text değişikliğinde publish butonunun validation state'i anlık güncellenir.
- Planlama alan etiketleri W-05 sırasına göre netleştirildi.
- Autosave `Future<bool>` dönüşünün `unawaited(Future<void>)` ile uyumsuz kalabileceği derleme riski giderildi; debounce callback sonucu doğrudan await eder.

## Test kaynakları

- `packages/kent_takip_application/test/wp15_wp16_test.dart`: draft private projection, açıklanabilir uzamsal+zamansal overlap (`timeOverlapMinutes` ve kural gerekçesi), preview approval guard, publish, fake clock sarı→kırmızı→tamamlandı ve history retention.
- `apps/demo_server/test/server_contract_test.dart`: HTTP draft + impact analysis kontratı.
- `DemoProjections.visiblePins(..., nowUtc:)` acceptance'ı persisted transition'dan bağımsız olarak saat bazlı doğrular.

## Durum

Kaynak uygulaması tamamlandı. Flutter/Dart executable bu çalışma ortamında bulunmadığı için formatter/analyzer/unit-widget-integration/golden/E2E ve platform build kapıları çalıştırılamıyor; kanonik durum `BLOCKED` tutulur.
