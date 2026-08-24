# WP-19–20 Kalite Kanıtı

Teslim tarihi: 17 Ağustos 2026

| Kapı | Sonuç | Kanıt / not |
|---|---|---|
| Kaynak yapı + JSON/XML + Dart delimiter/declaration | PASS | `python3 tool/validate_source_structure.py` |
| Kanonik belge tutarlılığı | PASS | `python3 tool/check_doc_consistency.py` — 8 belge / 8 ADR |
| Localization completeness / hard-coded copy | PASS | 671 ortak TR/EN key, 647 referanslı key, doğrudan UI copy 0 |
| Accessibility source invariants | PASS | Map/list, focus recovery, live region, reduced motion, high contrast, 48×48 ve camera resume recovery |
| Security hardening invariants | PASS | Origin/session/media/import/log/AI/abuse invariant gate |
| Seed + checksum | PASS | revision 1, `sha256:21dc27ab91e20cefda362d58d9ab18dc9bb1ab337aaf0f408b6da4d7d91a06ee` |
| Secret / PII kaynak taraması | PASS | Test fixture dahil temiz |
| Tasarım sistemi statik kapısı | PASS | Token ve marka asset manifesti doğrulandı |
| Demo AI evaluation | PASS | 7 fixture; category accuracy 0.833333, duplicate recall 1.0, privacy FN 0.0, valid response 0.857143 |
| 10.000 kayıt snapshot contract benchmark | PASS | Final son-kod koşusu: 31.2 ms |
| Python tool syntax | PASS | `python3 -m py_compile tool/*.py` |
| Resolved dependency license inspection | BLOCKED_LOCAL | `.dart_tool/package_config.json` yok; CI'da `--strict` |
| Dart formatter / Flutter analyzer | BLOCKED | SDK executable yok |
| WP-19 Dart/server security testleri | BLOCKED | Test kaynakları hazır; Dart SDK yok |
| WP-20 widget/keyboard/200% text testleri | BLOCKED | Flutter SDK yok |
| TR/EN/long-text golden diff | BLOCKED | Flutter golden run/baseline yok |
| TalkBack / VoiceOver / NVDA / Safari | BLOCKED | Gerekli cihaz/OS/AT ortamları yok |
| Native camera permission denial/recovery | BLOCKED | Kaynak recovery yolu var; gerçek platform kanıtı yok |
| Android / iOS / web build | BLOCKED | Flutter/platform build toolchain yok |

## Kalite sınırı

SDK-bağımsız kapılar gerçek Dart compiler/analyzer, Flutter widget/golden, cihaz/browser yardımcı teknoloji ve platform permission testlerinin yerine geçmez. Dependency license inspection yerelde dependency resolution olmadığı için `BLOCKED_LOCAL`; CI `flutter pub get` sonrasında aynı scripti `--strict` çalıştırır. BLOCKED satırları PASS olarak gösterilmez.
