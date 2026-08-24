# WP-13–14 Kalite Kanıtı

Teslim tarihi: 17 Ağustos 2026

| Kapı | Sonuç | Kanıt / not |
|---|---|---|
| Kaynak yapı + JSON/XML + Dart delimiter/declaration | PASS | `python3 tool/validate_source_structure.py` |
| Kanonik belge tutarlılığı | PASS | `python3 tool/check_doc_consistency.py` — 8 belge / 8 ADR |
| Seed + checksum | PASS | `python3 tool/validate_seed.py` — revision 1, `sha256:21dc27ab91e20cefda362d58d9ab18dc9bb1ab337aaf0f408b6da4d7d91a06ee` |
| Secret / PII kaynak taraması | PASS | `python3 tool/scan_sensitive_data.py` |
| Tasarım sistemi statik kapısı | PASS | `python3 tool/validate_design_system.py` |
| Demo AI evaluation | PASS | 7 fixture; category accuracy 0.833333, duplicate recall 1.0, privacy FN 0.0, valid response rate 0.857143 |
| 10.000 kayıt snapshot contract benchmark | PASS | `python3 tool/benchmark_snapshot_contract.py` — 61.9 ms |
| Python tool syntax | PASS | `python3 -m py_compile tool/*.py` |
| Dart formatter | BLOCKED | Repo CI `dart format --output=none --set-exit-if-changed .` ister; ortamda Dart/Flutter executable yok |
| WP-13 projection/filter/sort/10k Dart testleri | BLOCKED | Test kaynağı `packages/kent_takip_application/test/wp13_wp14_test.dart`; Dart SDK yok |
| WP-13 responsive/golden + keyboard/a11y | BLOCKED | Flutter SDK / cihaz-browser a11y aracı yok |
| WP-14 command/repository + lease/concurrency/merge tests | BLOCKED | Test kaynağı mevcut; Dart SDK yok |
| Demo server HTTP contract | BLOCKED | Güncellenmiş test kaynağı mevcut; Dart SDK yok |
| Android / iOS / web build + E2E | BLOCKED | Flutter 3.47.x toolchain yok |

## Sınır

Python 10k benchmark'ı JSON/snapshot contract yolunu ölçer; yeni Dart `StaffOperationsProjection` performans testinin yerine geçmez. Dart testinde ayrıca 10.000 kayıt bounded page senaryosu vardır fakat bu ortamda koşturulamadığı için PASS iddiası yapılmaz.
