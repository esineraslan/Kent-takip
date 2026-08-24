# WP-13 — Belediye dashboard, kuyruklar ve olay çalışma alanı

## Uygulanan kaynak

- Belediye dashboard metrikleri ayrı sayaç/state tutmadan `AppSnapshotDto` üzerinden `StaffOperationsProjection` ile türetilir.
- Kritik, yüksek öncelik, normal, düşük güven, gizlilik, abuse ve manuel/AI hata kuyrukları domain sinyallerinden ayrıştırılır; kritik kayıt normal kuyruğa düşerek kaybolmaz.
- Arama; kategori, birim, risk, durum ve minimum mükerrerlik filtresi; öncelik/en eski/en yeni/mükerrer olasılığı sıralaması; 50 kayıtlık bounded sayfalama ve URL query state eklendi.
- `RULES.md` karar önceliği uygulanarak geniş ekran kompozisyonu `DESIGN.md` W-02'deki kanonik yapıya sabitlendi: 260 px filtre + 440 px sanallaştırılmış kuyruk + kalan genişlikte detay paneli. Tablet ve mobilde iki/tek panel responsive davranış korunur.
- `DESIGN.md` W-03'e uygun olarak detay panelinde gerçek 240 px operasyonel `MapSurface` kullanılır; sahte/statik harita placeholder'ı yoktur. Detay çalışma alanı report, konum, AI neden/güven/model/config, kaynak authority/freshness/conflict, incident bağlantıları, corroboration sayısı, bağlı external work-order ref/sync durumu, public/original medya, benzer kayıtlar, işlem geçmişi ve public projection preview gösterir.
- `viewOriginalMedia` izni yoksa original media referansları UI'a render edilmez.
- Review lease projection'ı audit olaylarından türetilir; başka personelin aktif lease'i kaydı read-only yapar, supervisor gerekçeyle devralabilir.
- Aynı timestamp'e sahip lease olaylarında son durum revision ile belirlenir; release/takeover sırası belirsiz kalmaz.
- J/K veya ok tuşlarıyla kayıt gezinme, Enter ile karar alanına geçme ve Esc ile geri dönüş kısayolları eklendi.
- Loading, empty, offline/read-only, revision-stream error, stale conflict ve command failure durumları görünür hale getirildi.
- 10.000 kayıt için projection bounded pagination, UI list virtualization ve analiz/incident/media/source/lease lookup indeksleri birlikte kullanılır; report başına global koleksiyon taraması yapan O(N×liste) yol kaldırıldı.
- `/staff/dashboard`, `/staff/queues/:queueType` ve `/staff/reports/:reportId` kanonik personel rotaları güncel çalışma alanına bağlandı.

## Öz-denetim düzeltmeleri

- İlk projection sürümündeki `clamp()` sonucunun `num` kalması ve switch fall-through riski giderildi.
- Privacy kuyruğuna `pending` medya da dahil edildi; privacy pipeline tamamlanmadan kaydın normal kuyruğa düşmesi engellendi.
- Lease sıralaması yalnız timestamp'e bağlı olmaktan çıkarıldı; revision monotonic tie-breaker yapıldı.
- Personel UI'ında yetkisiz original media gösterimi yalnız görsel gizleme değil, render etmeme şeklinde uygulandı.
- ROADMAP iş-paketi metnindeki `queue/detail/map` ifadesi ile `DESIGN.md` W-02/W-03 arasında yorum farkı görüldü. `RULES.md` §3.1 öncelik sırasına göre `DESIGN.md` daha bağlayıcı olduğundan nihai çözüm filtre + kuyruk + detay üçlüsü olarak tutuldu; harita W-03'te tarif edildiği gibi detay içinde gerçek 240 px `MapSurface` olarak yerleştirildi.
- Domain’de var olan fakat snapshot DTO’dan düşen external work-order referansı geriye uyumlu kontrat alanına eklendi; boş listede seed checksum biçimi değişmez.

## Test ve kanıt

- `packages/kent_takip_application/test/wp13_wp14_test.dart`: dashboard/queue projection, kritik/privacy ayrımı, 10k bounded projection ve lease conflict/release testleri.
- Mevcut server contract testi citizen projection'da `originalRef` sızıntısını ve original media access audit'ini doğrulamaya devam eder.
- `tool/validate_source_structure.py`, `tool/validate_design_system.py` ve diğer SDK-bağımsız doğrulamalar teslim öncesi koşturulur.

## Durum

Kaynak uygulaması tamamlandı. Bu ortamda Flutter/Dart SDK bulunmadığından `flutter analyze`, widget/golden, NVDA/VoiceOver ve üç platform build/E2E kapıları çalıştırılamıyor; bu nedenle kanonik durum `BLOCKED` olarak tutulur. Engelin nedeni kaynak hatası değil, zorunlu toolchain erişiminin olmamasıdır.
