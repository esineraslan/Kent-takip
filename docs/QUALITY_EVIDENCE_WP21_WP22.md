# İBB Kent Takip — WP-21 / WP-22 Kalite Kanıtı

## SDK-bağımsız final kapıları — 17 Ağustos 2026

Final kaynak üzerinde aşağıdaki kapılar çalıştırıldı ve **PASS** verdi:

- `python3 tool/validate_source_structure.py` — JSON/XML, Dart delimiter/declaration/duplicate-enum ve belge kodlama kontrolleri PASS.
- `python3 tool/check_doc_consistency.py` — 8 kanonik belge, 8 ADR PASS.
- `python3 tool/check_localization.py` — 671 ortak TR/EN anahtarı, 647 referanslanan anahtar, doğrudan UI copy 0.
- `python3 tool/check_accessibility_source.py` — map/list eşdeğeri, focus recovery, live region, reduced motion, high contrast, 48×48 hedef ve camera-resume kaynak kapısı PASS.
- `python3 tool/validate_security_hardening.py` — origin/session/media/import/log/AI/abuse invariants PASS.
- `python3 tool/validate_wp21_wp22.py` — E2E-01–30, W-00–W-10 state matrix ve CI gate izlenebilirliği PASS.
- `python3 tool/validate_design_system.py` — token/brand manifest PASS.
- `python3 tool/evaluate_demo_ai.py` — deterministic fixture gate PASS (`caseCount=7`, category accuracy `0.833333`, duplicate recall `1.0`, privacy false-negative `0.0`).
- `python3 tool/scan_sensitive_data.py` — Secret/PII kaynak taraması temiz.
- `python3 tool/validate_seed.py` — revision `1`, checksum `sha256:21dc27ab91e20cefda362d58d9ab18dc9bb1ab337aaf0f408b6da4d7d91a06ee`.
- `python3 -m py_compile tool/*.py` — Python kalite araçları syntax PASS.

SDK-bağımsız **10.000 kayıt contract proxy** son koşusu `30.4 ms` verdi. Bu değer yalnız Python contract/projection proxy ölçümüdür; Flutter/Dart runtime performans kanıtının yerine geçmez. Asıl `tool/benchmark_wp21.dart` bütçe kapısı CI'da Flutter/Dart SDK ile çalışacaktır.

## Beklenen biçimde BLOCKED kalan kapılar

Bu çalışma ortamında `dart`, `flutter` ve `fvm` executable bulunmadığı doğrulandı. Bu nedenle aşağıdakiler çalıştırılmış veya PASS sayılmış değildir:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
dart test packages/kent_takip_domain packages/kent_takip_contracts packages/kent_takip_persistence packages/kent_takip_application apps/demo_server
flutter test apps/kent_takip_app --coverage
flutter test apps/kent_takip_app/integration_test
dart run tool/benchmark_wp21.dart --out build/wp21/performance_report.json
```

Ayrıca approved golden PNG/font/design-review kanıtı yoktur. `tool/check_golden_baselines.py` final yerel koşuda bilinçli olarak `BLOCKED` raporlamıştır: 16/16 baseline eksik ve `docs/golden_review.json` onayı `approved` değildir.

Dependency/license aracı `.dart_tool/package_config.json` oluşmadığı için yerel non-strict koşuda `BLOCKED` raporu üretir; CI'da `flutter pub get` sonrasında `--strict` çalışır ve eksik lisans kanıtını bloklar.

## CI kanıt koruması

Quality workflow şu sonuçları bloklayıcı kapı yapar: runtime benchmark, analyzer, Dart/Flutter testleri, integration testleri, Android/web release buildleri, coverage ≥%80 / kritik ≥%90, approved golden baseline ve golden regression. iOS release `--no-codesign` ayrı macOS job'ındadır.

SBOM, coverage ve performance raporları mümkün olduğunda bloklayıcı gate'lerden önce üretilir; `actions/upload-artifact` adımı `if: always()` ile çalıştığı için coverage/golden gibi bir gate başarısız olsa dahi mevcut kanıtların kaybolması engellenir.

## Release yorumu

WP-21 ve WP-22 kaynak kapsamı uygulanmış ve SDK-bağımsız kapılar yeşildir. Kanonik kabul runtime/profile/coverage/golden/üç-platform build kanıtı istediği için her iki WP de ROADMAP'te **BLOCKED** kalır; bu durum kaynak eksikliğini gizlemek için değil, kanıt üretilmeden `COMPLETED` dememek içindir.
