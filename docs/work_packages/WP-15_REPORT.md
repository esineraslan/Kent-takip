# WP-15 — Birim operasyonu, saha ataması, SLA ve çözüm kanıtı

## Uygulanan kaynak

- `FieldTaskProjection` ile personelin yetkisine göre yoğun birim görev listesi ve `all/unassigned/mine/fieldAssigned/inProgress/overdue` filtreleri eklendi. Unit officer yalnız kendi birimini görür.
- `FieldOperationCommand` ve gateway/server uçları ile `assignedUnit → fieldAssigned → inProgress → resolved` saha hattı ortak revision, authorization, idempotency, invariant, audit/timeline/notification ve transaction queue üzerinden yürütülür.
- Saha atamasında kişi veya ekip zorunludur. Dış iş emri verilmemiş ve mevcut referans yoksa `DEMO_SIMULATED_WORK_ORDER` kaydı üretilir; bu simülasyon gerçek entegrasyon gibi sunulmaz.
- `FieldSlaPolicy` kategori/birim bazlı deterministik hedef aralığı üretir. İlk routing/atama SLA saatini başlatır; çözüm `slaPausedAt` ile saati durdurur. Aralık her UI yüzeyinde “garanti değildir” diliyle gösterilir.
- Gecikme kaydı neden + yeni minimum/maksimum müdahale aralığı ister ve citizen timeline'a yeniden tahmin bilgisini taşır.
- Çözüm açıklaması zorunludur. Opsiyonel sonuç medyası yalnız privacy-safe ve public referanslıysa vatandaş yüzeyine geçebilir.
- Çözüm report ve incident üzerinde atomik tutulur; vatandaş tracking detayında çözüm açıklaması, güvenli medya referansı ve SLA/re-estimate bilgisi görünür.
- Vatandaşın “sorun devam ediyor” geri bildirimi state'i otomatik reopen etmez; `reopenReviewRequested` sinyali review kuyruğuna girer ve insan lease'i ile incelenir.
- İlk insan incelemesi, routing ve resolution süreleri `operational_metric` audit olaylarıyla kaydedilir; dashboard medyanları snapshot'tan türetilir.

## Uzman incelemesinde düzeltilenler

- WP-14 routing sonrası SLA başlangıcının eksik kalması kapatıldı; transfer-back saha sahipliği ve SLA aktif bağlarını temizler.
- Çözüm anında SLA saatini durduran `slaPausedAt` eksikliği giderildi.
- Mevcut/gerçek work-order ref varken gereksiz ikinci demo ref üretilmesi engellendi.
- `FieldOperationCommand` içindeki yinelenen `reestimateMinMinutes` alanı kaldırıldı.
- Çözüm metni yazılırken buton state'inin anlık güncellenmesi için controller listener eklendi.
- WP-14 merge geçmişindeki terminal `merged` alias raporların saha geçişini bloke etmesi engellendi; operasyonel state geçişleri yalnız aktif bağlı raporlara uygulanırken alias kayıtlar incident tarihçesi ve bildirim alıcısı olarak korunur.

## Test kaynakları

- `packages/kent_takip_application/test/wp15_wp16_test.dart`: route→field assign→start→delay→resolve, mandatory explanation, SLA start/stop, simulated work order, citizen evidence, reopen-review ve merged-alias regresyon senaryoları.
- `apps/demo_server/test/server_contract_test.dart`: shared HTTP field-operation kontratı.
- Medya privacy kuralı application command katmanında fail-closed uygulanır.

## Durum

Kaynak uygulaması tamamlandı. Flutter/Dart executable bu çalışma ortamında bulunmadığı için gerçek formatter/analyzer/Dart unit-widget-integration/E2E ve platform build kapıları koşturulamıyor; kanonik durum `BLOCKED` tutulur.
