# İBB Kent Takip — WP-21 Raporu

## Kapsam

WP-21 performans, offline, recovery ve kaos senaryolarını WP-00–WP-20 kaynak tabanının üzerine ekler. Yeni özellik üretmek yerine mevcut veri/harita/personel/shared-client akışlarını yüksek hacim ve hata koşullarına dayanıklı hale getirir.

## Uygulanan kaynak değişiklikleri

- `PerformanceBudgets`, benchmark örnekleri, offline surface policy ve bounded exponential-backoff/jitter politikası ortak application katmanına eklendi.
- Staff dashboard/queue aynı revision içinde tek `StaffOperationsProjectionIndex` üzerinden çalışacak şekilde indekslendi.
- Harita projection lookup'ları O(N×M) taramalarından indeksli lookup'a geçirildi; UI tarafında revision/viewer/role/work-clock anahtarlı `MemoizedMapProjectionService` eklendi.
- Shared gateway 408/429/5xx/timeout/malformed JSON için bounded retry; kalıcı son-başarılı snapshot cache; WebSocket revision reconnect/backoff ve command idempotency ile güçlendirildi.
- Başarılı remote snapshot, opsiyonel cache okuma/yazma hatasından etkilenmez; cache best-effort resilience katmanıdır. Stable media ID üzerindeki `PUT` upload da timeout + bounded idempotent retry kullanır.
- `SnapshotController` ilk başarılı snapshot okunana kadar online varsaymaz; staff mutation başlangıçtan itibaren fail-closed/read-only kalır.
- Shared cache kullanıldığında controller kendini online saymıyor; citizen draft yazımı açık, staff mutation kapalı kalıyor.
- Web/IO media storage failure'ları güvenli `FailureCode.storage` olarak map ediliyor; vatandaş draft/media staging hatası veri kaybettirmeden UI'a taşınıyor.
- Active snapshot corruption, migration failure ve media quota recovery testleri eklendi.
- `tool/benchmark_wp21.dart` seed parse/validation, 10K queue/filter/sort, 10K map projection+cluster, snapshot boyutu ve deterministic AI latency bütçelerini bloklayıcı rapora dönüştürüyor.

## Kaos/recovery kapsaması

| Senaryo | Kanıt |
|---|---|
| 429/503/timeout sınıfı | `apps/kent_takip_app/test/wp21/remote_resilience_test.dart`, `wp21_reliability_test.dart` |
| Malformed JSON | Remote gateway testinde son geçerli cache fallback |
| Server restart | `apps/demo_server/test/server_contract_test.dart` runtime recovery |
| Stale source/circuit breaker | `wp17_wp18_test.dart` retry + stale cache |
| Snapshot corruption | `packages/kent_takip_persistence/test/wp21_recovery_test.dart` |
| Migration failure | Aynı recovery test paketi |
| Low storage/media quota | `wp21_recovery_test.dart` storage failure mapping |
| AI timeout | `wp08_wp12_test.dart`; manuel akış blocking değildir |
| Shared stale revision/conflict | `server_contract_test.dart` + walking skeleton stale-revision testleri |
| Offline draft | `offline_draft_test.dart` + controller offline policy |

## Son SDK-bağımsız proxy kanıtı

Final `python3 tool/benchmark_snapshot_contract.py` koşusu 10.000 kayıt için **30.4 ms** verdi ve seed checksum değişmedi. Bu Python proxy, Flutter frame/jank veya Dart `benchmark_wp21.dart` sonucunun yerine geçmez; yalnız contract/projection regresyon göstergesidir.

## Açık runtime kanıtları

Bu kaynak hazırlama ortamında Flutter/Dart SDK ve gerçek cihaz/browser profile oturumu bulunmadığı için aşağıdaki kanıtlar üretilmiş sayılmaz:

- cold/warm startup ve route transition profile trace;
- 60 Hz frame/jank ölçümü;
- DevTools memory/image-cache export;
- gerçek kamera background/resume ve OS permission recovery;
- Android/iOS/web profile smoke.

Bu nedenle WP-21 ROADMAP durumu `BLOCKED` kalır. Kaynak ve CI kapısı hazırdır; runtime budget kanıtı alınmadan `COMPLETED` değildir.
