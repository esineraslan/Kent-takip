# WP-08–12 kalite kanıt matrisi

| Kapı | Kaynak | Bu ortam sonucu |
|---|---|---|
| Harita/place/projection | `place_search.dart`, `projections.dart`, `map_experience.dart`, `places.json` | Source structure + JSON doğrulandı |
| Medya metadata/privacy | `media_pipeline.dart`, server media projection/audit, `wp08_wp12_test.dart` | Kaynak hazır; Dart testi bekliyor |
| AI evaluation | `ai_evaluation_fixture.json`, `AI_EVALUATION_REPORT.json`, `evaluate_demo_ai.py` | PASS |
| 5 adımlı akış | `report_wizard.dart`, güncel WP-06 integration | Kaynak hazır; Flutter E2E bekliyor |
| Takip/notification/action | `citizen_tracking_screens.dart`, `CitizenActionCommand` | Kaynak hazır; Dart/Flutter test bekliyor |
| Seed/checksum | `validate_seed.py` | PASS |
| Secret/PII | `scan_sensitive_data.py` | PASS |
| Tasarım token/brand manifest | `validate_design_system.py` | PASS |
| 10.000 olay contract benchmark | `benchmark_snapshot_contract.py` | PASS |
| Analyzer/unit/widget/platform build | CI `quality` | BLOCKED — Flutter/Dart SDK yok |

`BLOCKED`, kaynak eksiği değil zorunlu runtime/ci kanıtının bu teslim ortamında üretilememesi anlamındadır.
