# WP-19 — Bağımlılık ve Lisans Denetimi

Tarih: 17 Ağustos 2026

## Politika

- Pubspec bağımlılıkları exact sürümle pinlidir.
- `flutter pub get` sonrasında `.dart_tool/package_config.json` üzerinden bütün **üçüncü taraf resolved package** köklerinde LICENSE/COPYING kanıtı aranır.
- Workspace içindeki first-party Kent Takip paketleri external license gate'e yanlış pozitif olarak dahil edilmez.
- Flutter SDK paketleri kendi paket kökünde lisans yoksa sınırlı SDK parent zincirindeki Flutter LICENSE kanıtını kullanabilir.
- CI `python3 tool/dependency_license_report.py --strict` başarısızsa build zinciri durur.
- CI ayrıca `flutter pub deps --json > dependency-sbom.json` üretir.

## Doğrudan bağımlılıklar

Detaylı gerekçe ve lisans beklentisi `docs/DEPENDENCIES.md` içindedir. Ana üçüncü taraf yüzey: `crypto`, `go_router`, `provider`, `path_provider`, `web`, `http`, `image_picker`, `web_socket_channel`, `shelf`, `shelf_router`, `shelf_web_socket`, `test`, `flutter_lints`.

## Bu teslimdeki sonuç

Hazırlama ortamında Flutter/Dart toolchain olmadığı ve `flutter pub get` çalıştırılamadığı için resolved package license inspection **BLOCKED**. `tool/dependency_license_report.py` bu durumu PASS olarak gizlemez; yerelde rapor `build/dependency-license-report.txt` içine BLOCKED yazar. Aynı script CI'da `--strict` modunda, dependency resolution sonrasında license kanıtı eksikse job'u fail eder.

Harici vulnerability/advisory servisi bu ortamda sorgulanmadı. Bu eksik kanıt `SECURITY_REVIEW.md` içindeki `P2-SEC-02` olarak sahip ve tarihle takip edilir.
