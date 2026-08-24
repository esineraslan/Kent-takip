# WP-17–18 Kalite Kanıtı

Teslim tarihi: 17 Ağustos 2026

| Kapı | Sonuç | Kanıt / not |
|---|---|---|
| Kaynak yapı + JSON/XML + Dart delimiter/declaration | PASS | `python3 tool/validate_source_structure.py` |
| Kanonik belge tutarlılığı | PASS | `python3 tool/check_doc_consistency.py` — 8 belge / 8 ADR |
| Seed + checksum | PASS | revision 1, `sha256:21dc27ab91e20cefda362d58d9ab18dc9bb1ab337aaf0f408b6da4d7d91a06ee` |
| Secret / PII kaynak taraması | PASS | `python3 tool/scan_sensitive_data.py` |
| Tasarım sistemi statik kapısı | PASS | `python3 tool/validate_design_system.py` |
| Demo AI evaluation | PASS | 7 fixture; category accuracy 0.833333, duplicate recall 1.0, privacy FN 0.0, valid response rate 0.857143 |
| 10.000 kayıt snapshot contract benchmark | PASS | Final son-kod koşusu: 33.2 ms |
| Python tool syntax | PASS | `python3 -m py_compile tool/*.py` |
| Dart formatter | BLOCKED | `dart`/`flutter` executable yok |
| Flutter analyzer (`--fatal-infos --fatal-warnings`) | BLOCKED | Flutter SDK executable yok |
| WP-17 adapter/schema/quarantine/retry/provenance testleri | BLOCKED | Test kaynağı hazır; Dart SDK yok |
| WP-17 shared source-operation HTTP contract | BLOCKED | Test kaynağı hazır; Dart SDK yok |
| WP-18 authorization/KVKK/restriction/original-media testleri | BLOCKED | Test kaynağı hazır; Dart SDK yok |
| WP-18 route/widget/E2E-17/21/22 | BLOCKED | Flutter test/device/browser toolchain yok |
| Android / iOS / web build | BLOCKED | Flutter/platform build toolchain yok |

## Kalite sınırı

Statik Python kapıları Dart compiler/analyzer yerine geçmez. `benchmark_snapshot_contract.py` snapshot/contract yolunu ölçer; Flutter UI frame performans testi değildir. Bu nedenle gerçek SDK gerektiren kapılar kaynakları hazırlanmış olsa bile PASS sayılmaz. Repo `.fvmrc` Flutter 3.47.0 hedefini sabitler; bu teslim ortamında `dart`, `flutter` ve `fvm` executable bulunmadığından toolchain sonucu uydurulmamıştır.
