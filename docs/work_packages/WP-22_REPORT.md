# İBB Kent Takip — WP-22 Raporu

## Kapsam

WP-22 özellik dondurma aşamasıdır. Amaç yeni ürün fonksiyonu eklemek değil, kanonik kabul senaryolarını teste bağlamak, regresyon/golden/coverage/build kapılarını bloklayıcı hale getirmek ve P0/P1 kapanış kanıtını üretmektir.

## Uygulananlar

- `ARCHITECTURE.md` zorunlu kabul seti E2E-01–E2E-30 olarak güncellendi.
- E2E-23–30: çoklu report/source incident, 153 mock sync, structured corroboration, fotoğrafsız erişilebilir rota, çözüm sonrası reopen review, resmî salt-okunur uyarı, role-specific AI ve real-schema GTFS senaryoları eklendi.
- `docs/acceptance_matrix.json` her E2E kimliğini gerçek test kaynaklarına bağlar; `tool/validate_wp21_wp22.py` eksik/boş mapping'i CI'da reddeder.
- `docs/screen_state_matrix.json` W-00–W-10 ekranlarının loading/content/empty/offline-cache/recoverable/blocking davranışlarını izler; `apps/kent_takip_app/test/wp22/state_matrix_test.dart` ortak state yüzeylerini test eder.
- `packages/kent_takip_application/test/wp22_acceptance_test.dart` yeni cross-layer kabul sözleşmelerini test eder.
- CI tüm integration-test klasörünü, coverage gate'i, approved golden baseline gate'ini, golden diff testini ve Android/web/iOS release buildlerini zorunlu tutar; evidence upload `if: always()` ile başarısız gate sonrasında da mevcut raporları saklar.
- `tool/check_coverage.py` genel ≥%80 ve kritik kaynak ≥%90 line coverage ister.
- `tool/check_golden_baselines.py` 16 viewport×locale baseline'ı ve `docs/golden_review.json` içindeki açık tasarım onayını doğrular; baseline üretmez veya onay uydurmaz.
- P0/P1 bug burn-down ve release kararı `docs/ACCEPTANCE_REPORT.md` altında tek yerde tutulur.

## Kapanış politikası

Bir hata yalnız root cause tanımı ve regresyon testi eklendikten sonra kapatılabilir. Test retry ile flaky durum gizlenmez. Golden değişiklikleri otomatik olarak kabul edilmez. Coverage veya üç platform build eşiği karşılanmıyorsa WP-22 `COMPLETED` sayılamaz.

## Durum

Kaynak düzeyi kabul altyapısı tamamlandı. Flutter/Dart runtime, golden baseline/design review, coverage sonucu ve Android/iOS/web release build kanıtı bu çalışma ortamında üretilemediği için ROADMAP durumu `BLOCKED` kalır.
