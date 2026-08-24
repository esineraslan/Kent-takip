# WP-17 — Kaynak adaptörleri, sağlık ve 153 sözleşme sınırı

## Uygulanan kaynak

- `SourceAdapter<T>` ile fetch/decode/validate/normalize/freshness/provenance sözleşmesi tek application katmanında toplandı.
- `IettGtfsStopsSchemaAdapter`, GTFS `stops.txt` gerçek şema alanlarını doğrulayan deterministik fixture mapping kanıtı sağlar; iki geçerli kayıt normalize edilir, hatalı koordinatlı kayıt quarantine edilir. Bu **canlı İETT entegrasyonu değildir** ve UI/doküman bunu açıkça etiketler.
- Kaynak otorite sırası `owningAuthority > ibbApproved > licensedOpenData > thirdPartyUnverified > citizen > ai` olarak policy ile fail-closed tanımlandı. Daha kolay/yeni erişim, daha yüksek resmî otoriteyi otomatik ezmez.
- Su, trafik, ulaşım, planlı çalışma ve resmî afet uyarısı deterministic fixture katalogunda; elektrik kaynağı somut yetkili kaynak gelene kadar disabled.
- Decode/validate başarısız kayıtlar quarantine; bilinmeyen kayıtlar sessiz “Diğer” yapılmaz.
- Retry/backoff/jitter, circuit-breaker ve son geçerli stale cache uygulanır. Source health `lastAttemptAt`, `lastSuccessAt`, source timestamp, ingested-at, accepted/quarantine count, last error, retry/circuit state alanlarını taşır.
- DESIGN W-09 `/staff/data-sources` ekranı Güncel/Gecikmiş/Karantina/Unavailable/Manual durumlarını, API/CSV türünü, source timestamp ile ingestion zamanını ayrı gösterir.
- Yetkili manuel olay/planlı çalışma provenance + audit ile snapshot'a girer.
- JSON/CSV fixture import doğrulanır ve `manageSources` ister; export provenance alanlarını korur.
- 153/İstanbul Senin mock contract external application ID, simulated status sync, source timestamp, citizen report/incident link ve hata alanlarını taşır; gerçek entegrasyon gibi sunulmaz.
- Local gateway, remote gateway ve demo server `/v1/commands/source-operation` aynı processor/DTO sözleşmesini paylaşır.

## Uzman incelemesinde düzeltilenler

- Kaynak CSV helper'ındaki string interpolation, repo delimiter scanner'ının gerçek parser olmaması nedeniyle false-positive üretiyordu; aynı davranış scanner-uyumlu güvenli concatenation'a çevrildi.
- `SourceOperationAction` enumunda statik delimiter kapısının yakalamadığı yinelenen `refreshGtfsSchema` üyesi uzman kaynak turunda bulundu ve kaldırıldı; teslim öncesi ayrıca tüm enum üyeleri için tekrar taraması çalıştırıldı.
- Retry/circuit acceptance kanıtı için yalnız deterministik fixture adaptöründe kontrollü transient failure hook'u eklendi; 2 hata sonrası recovery ve 3/3 hata sonrası stale-cache + open-circuit test kaynağı hazırlandı.
- Circuit açıkken başarısız kaynağın geçerli cache'i silinmiyor; freshness açıkça stale/unavailable olarak taşınıyor.
- Manual entry ve 153 mock, canlı/İBB doğrulanmış kaynak etiketi kullanmayacak şekilde ayrı source/provenance kimlikleriyle tutuldu.
- Import işlemi UI yetkisine güvenmek yerine application katmanında da `manageSources` ile korunuyor.

## Test kaynakları

- `packages/kent_takip_application/test/wp17_wp18_test.dart`: GTFS mapping/quarantine, authority priority, import authorization/export, manual provenance ve 153 simulation.
- `apps/demo_server/test/server_contract_test.dart`: shared source-operation RBAC ve 153 simulation provenance.
- SDK-bağımsız seed/source/design/secret/AI/benchmark kapıları `docs/QUALITY_EVIDENCE_WP17_WP18.md` içindedir.

## Durum

Kaynak uygulaması tamamlandı. Bu çalışma ortamında Flutter/Dart executable bulunmadığı için formatter/analyzer/Dart testleri ve cihaz/browser E2E kanıtı üretilemedi; kanonik ROADMAP durumu `BLOCKED` tutulur.
