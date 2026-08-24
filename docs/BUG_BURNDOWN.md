# İBB Kent Takip — WP-22 Bug Burn-down

## Politika

P0: veri kaybı, yetki/gizlilik ihlali, uygulamanın temel akışta açılamaması veya geri alınamayan yanlış public state. P1: zorunlu kabul akışını bloke eden, güvenilir workaround'u olmayan hata.

Bir P0/P1 yalnız şu üç kayıtla kapanır: root cause, düzeltme ve regresyon testi/kanıtı.

## 17 Ağustos 2026 kaynak incelemesi

| ID | Öncelik | Root cause | Düzeltme | Regresyon |
|---|---|---|---|---|
| BB-21-01 | P1 | Shared snapshot fallback yalnız process-memory davranışına bağlıydı | Persistent `SnapshotStore` cache + offline flag | `remote_resilience_test.dart` |
| BB-21-02 | P1 | Malformed/429/5xx read tek hata ile shared yüzeyi koparabiliyordu | Bounded retry + stale-cache fallback | `remote_resilience_test.dart`, `wp21_reliability_test.dart` |
| BB-21-03 | P1 | 10K projection path tekrar lookup kuruyordu | Staff index + map lookup/memoization | `benchmark_wp21.dart` |
| BB-21-04 | P1 | Media quota raw storage failure olarak sızabiliyordu | `FailureCode.storage` mapping | `wp21_recovery_test.dart` |
| BB-21-05 | P1 | Başarılı remote snapshot, opsiyonel cache'in ham storage hatasıyla başarısız sayılabiliyordu | Cache persist best-effort yapıldı; remote truth korunur | `remote_resilience_test.dart` |
| BB-21-06 | P1 | Shared media PUT timeout/503 hattında bounded retry yoktu | Sabit media ID + aynı bytes ile idempotent timeout/retry eklendi | `remote_resilience_test.dart` |
| BB-21-07 | P1 | Snapshot yüklenmeden önce controller online varsayımı staff mutation'ı fail-open başlatabiliyordu | Controller ilk başarılı read'e kadar offline/read-only başlar | source invariant + state matrix |
| BB-22-01 | P1 | E2E kabul seti WP-17–20 kararlarını kapsamıyordu | E2E-23–30 + acceptance matrix | `wp22_acceptance_test.dart`, matrix validator |
| BB-22-02 | P1 | Coverage/golden yalnız belge niteliğindeydi, release'i bloklamıyordu | Strict coverage/golden CI gate | `check_coverage.py`, `check_golden_baselines.py` |
| BB-23-01 | P1 | `MutationResult.toJson()` içinde yinelenen `revision` map anahtarı statik kaynak kontrolünden kaçmıştı | Yinelenen anahtar kaldırıldı; final source validator'a dahil edildi | WP-23/24 source validation |
| BB-24-01 | P1 | RC kaynağında `.git` metadata olmadığı halde commit/tag freeze varsayımı yapılabilirdi | Commit/tag alanı fail-closed `BLOCKED`; kaynak-ağacı SHA-256 release manifestine alınır | WP-23/24 validator + final audit |

| HF-25-01 | P1 | Vatandaş/personel haritası dört sabit tile + `NeverScrollableScrollPhysics` kullanıyordu; gerçek kamera/pan/zoom yoktu | `flutter_map` tabanlı ortak harita yüzeyi, mouse/touch pan, pinch/wheel/keyboard zoom, ± kontroller ve cluster zoom eklendi | `map_auth_sidebar_regression_test.dart` |
| HF-25-02 | P1 | Arama sonucu yalnız `_center` state'ini değiştiriyor, harita kamerasını taşımıyordu | Exact district auto-focus + Enter/sonuç seçimi ile `MapController.move`, alan filtresi ve “Tüm İstanbul” reset eklendi | `map_auth_sidebar_regression_test.dart` |
| HF-25-03 | P1 | Citizen OTP ve staff MFA sabit demo kodu doğrulama ekranında açıkça gösteriliyordu | Demo-code notice UI'dan kaldırıldı; doğrulama servisi/akış sınırı korunuyor | `wp04_auth_shell_test.dart`, `map_auth_sidebar_regression_test.dart` |
| HF-25-04 | P1 | Desktop staff sidebar tüm destinasyonları sabit `Column` içine koyduğu için kısa viewport'ta bottom overflow üretiyordu | Menü `Expanded + Scrollbar + ListView` yapısına alındı, hedef yüksekliği 48 px'e çekildi; footer sabit ve KVKK/Ayarlar erişilebilir | `map_auth_sidebar_regression_test.dart` |

**Bilinen açık P0/P1 (kaynak incelemesi): 0.** Runtime/analyzer/full regression çalışmadan bu sayı release sertifikası değildir.
