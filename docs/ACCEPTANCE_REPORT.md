# İBB Kent Takip — Kabul Raporu

## Release kararı

**Durum: BLOCKED.** WP-21/WP-22 kaynak uygulaması ve SDK-bağımsız kapılar hazırlanmıştır; gerçek Flutter analyzer/test coverage, onaylı golden baseline, runtime performance/AT ve üç platform release build kanıtı olmadan release kabulü verilmez.

## E2E kabul seti

Kanonik set **E2E-01–E2E-30**'dur. Her senaryo `docs/acceptance_matrix.json` içinde bir veya daha fazla gerçek test dosyasına bağlıdır. E2E-23–30 yeni hardening senaryolarıdır.

| Alan | Kaynak durumu | Çalıştırılmış kanıt | Release sonucu |
|---|---|---|---|
| E2E-01–30 traceability | Hazır | SDK-bağımsız validator | Kaynak PASS |
| Dart domain/application/persistence/server testleri | Hazır | Bu ortamda Dart SDK yok | BLOCKED |
| Flutter widget/integration testleri | Hazır | Bu ortamda Flutter SDK yok | BLOCKED |
| State matrix | `docs/screen_state_matrix.json` ile W-00–W-10 izleniyor; test kaynağı hazır | Validator PASS, Flutter runtime bekliyor | BLOCKED |
| Golden 8 viewport × 2 locale | Test + strict gate hazır | Approved PNG/font yok | BLOCKED |
| Semantics/focus/a11y | Kaynak testleri hazır | Gerçek AT matrisi ayrıca bekliyor | BLOCKED |
| Genel coverage ≥80% | Strict LCOV gate hazır | LCOV yok | BLOCKED |
| Kritik branch/line coverage ≥90% | Strict critical-source gate hazır | LCOV yok | BLOCKED |
| Android release | CI komutu hazır | Runtime yok | BLOCKED |
| iOS release | macOS CI komutu hazır | Runtime yok | BLOCKED |
| Web release | CI komutu hazır | Runtime yok | BLOCKED |
| Runtime jank/memory | Runbook hazır | DevTools/profile kanıtı yok | BLOCKED |

## P0/P1 bug burn-down

Kaynak incelemesinde **bilinen açık P0/P1: 0**. Bu ifade release sertifikası değildir: analyzer, tüm testler, golden, coverage ve üç platform build çalışmadan “P0/P1 kesin 0” sonucu verilemez. Yeni P0/P1 bulunursa root cause ve regresyon testi eklenmeden kapatılamaz.

### Bu turda kapanan kabul engelleri

- shared modun yeniden açılış sonrası yalnız RAM snapshot'a güvenmesi: persistent last-success cache eklendi;
- başarılı remote read'in opsiyonel cache storage hatasıyla zehirlenmesi: cache best-effort yapıldı ve remote truth korunur;
- media PUT timeout/503 yolunun retry bütçesi dışında kalması: stable media ID ile idempotent bounded retry eklendi;
- controller'ın ilk snapshot öncesi online varsayması: staff için fail-closed/read-only başlangıç eklendi;
- 10K staff projection'da tekrarlı lookup kurulumları: revision-scoped index eklendi;
- map projection'da iç içe kaynak/incident taramaları: lookup index + memoized service eklendi;
- 429/5xx/timeout/malformed JSON sırasında tek denemelik shared read: bounded retry + stale cache fallback eklendi;
- Web/IO media quota hatalarının ham storage exception olarak sızması: domain storage failure mapping eklendi;
- E2E kabul senaryolarının yeni WP-17–20 kararlarını kapsamaması: E2E-23–30 eklendi;
- coverage ve golden'ın raporlanıp bloklamaması: strict CI gate eklendi; kanıt upload adımı `if: always()` ile fail-closed joblarda da raporu korur.
- ekran durumlarının yalnız ortak widget testine dayanması: W-00–W-10 için açık state matrix ve validator eklendi.

## Final SDK-bağımsız kanıt

17 Ağustos 2026 final kaynak koşusunda source/doc/localization/accessibility/security/WP21-22 traceability/design/AI/Secret-PII/seed kapılarının tamamı PASS verdi. Son Python 10K contract proxy ölçümü **30.4 ms**; seed checksum `sha256:21dc27ab91e20cefda362d58d9ab18dc9bb1ab337aaf0f408b6da4d7d91a06ee`. Bu proxy Flutter runtime benchmark'ı değildir. `dart/flutter/fvm` bulunmadığı ve approved golden baseline olmadığı için runtime release kararı değişmez: **BLOCKED**.

## Golden review

`docs/golden_review.json` halen `blocked_pending_approved_fonts_and_design_review` durumundadır. Baseline PNG üretimi ve tasarım sorumlusu onayı olmadan gate bilinçli olarak kırmızıdır.

## Sonuç

WP-21 ve WP-22 kaynak kapsamı uygulanmıştır ancak kanonik kabul kriterleri runtime kanıtı gerektirdiği için ROADMAP statüsü `BLOCKED` tutulur. `COMPLETED` için CI'nın tüm zorunlu kapıları yeşil olmalıdır.

## WP-23/WP-24 çıkış durumu

WP-23 kaynak kapsamı; privacy-safe KPI olayları, türetilmiş pilot dashboard, formül tabanlı ROI, baseline/target/go-no-go, 7 dakikalık demo senaryosu ve release evidence üretimiyle uygulanmıştır. WP-24 kaynak kapsamı; adversarial audit, release manifest, bilinen sınırlar, RC sürüm sabitlemesi ve insan onayı kapısıyla uygulanmıştır.

Release kararı yine **BLOCKED**: üç tam prova çalıştırılmış kanıtı yoktur; Android/iOS/web release artifact'leri ve checksum'ları bu ortamda üretilememiştir; `.git` metadata olmadığı için gerçek commit hash/tag dondurulamamıştır; teknik lider/ürün/tasarım/güvenlik-KVKK yazılı son onayları yoktur. Bu eksikler kapatılmadan “P0/P1=0 final sertifika”, “release-ready” veya “production-ready” iddiası verilemez.

### WP-23/24 son kaynak ölçümü

Son SDK-bağımsız 10.000 kayıt contract proxy koşusu **32.6 ms** verdi. Source/doc/localization/accessibility/security/WP21-24 traceability/design/AI/Secret-PII/seed kapıları PASS; bu sonuç Flutter runtime benchmark veya release build kanıtının yerine geçmez.
