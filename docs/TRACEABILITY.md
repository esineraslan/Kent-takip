# İBB Kent Takip — Karar İzlenebilirliği

| Karar | Akış | Tasarım | Mimari/kod | Test kapısı |
|---|---|---|---|---|
| İstanbul Senin/153 tamamlayıcısı | USER_FLOWS 5 | Mini-app bağlamı | `ExternalApplicationRef` | Contract/ref testleri |
| Ortak olay kimliği | USER_FLOWS 6-8 | Olay çalışma alanı | `UrbanIncident` | Merge ve referans testleri |
| Vatandaş güven skoru yok | USER_FLOWS 1 | Ham kişi puanı yok | Modelde alan yok | Kaynak taraması |
| Rol bazlı AI görünürlüğü | USER_FLOWS 4/6 | Sade vatandaş, ayrıntılı staff | Projection policy | Rol projection testi |
| Fotoğrafsız rota | USER_FLOWS 4 | Alternatif eylem | `manualReviewRequired` | Unit/E2E sözleşmesi |
| Atomik persistence | Tüm mutasyonlar | Recovery durumu | temp+validate+backup+rename / web dual-slot | Power-loss/corruption |
| Resmî uyarı ayrımı | USER_FLOWS 12 | Ayrı salt okunur katman | `SourceAuthority.officialAlert` | Citizen mutation yasağı |
| Kaynak otoritesi | USER_FLOWS 5/12 | Rozet+tazelik | `SourceAuthorityRank` | Sıralama/provenance |
| Local CI, shared jüri | USER_FLOWS tümü | Demo bandı | Store sözleşmeleri | Local+shared E2E |
| TR/EN altyapısı | USER_FLOWS tümü | Localization | `AppStrings` + Flutter delegates | Locale widget testi; ARB kapısı WP-05 |
| Yetkisiz URL kapısı | USER_FLOWS rol girişleri | Ayrı citizen/staff shell | `AppRoutePolicy` + permission guard | Route/returnTo testleri |
| Deterministik demo auth | USER_FLOWS 2–3 | Telefon/OTP ve password/MFA | `DemoAuthService`, lockout/cooldown | Auth servis testleri |
| Rol değişiminde veri korunması | USER_FLOWS 1 | Demo bandı | Session sıfırlanır, `SnapshotStore` korunur | Widget regresyon testi |
| Ayrı responsive shell | USER_FLOWS 1–3/6 | 3 sekmeli mobil + 232 px personel menüsü | `CitizenShell` / `StaffShell` | Shell izolasyon testleri |
| Tasarım drift kapısı | USER_FLOWS tümü | Token, ortak component, dört pin, 5 durum | `ui/design/*` + brand manifest | Contrast/literal scanner, semantics, 8 viewport golden matrisi |
| Local dikey kesit | USER_FLOWS 4/6/8 | Gri kişisel pin → kırmızı public olay → timeline | `SnapshotCommandProcessor` + `SnapshotController` | WP-06 unit + Android/web integration kaynağı |
| Ortak revision ve conflict | USER_FLOWS 4/6 | Salt-okunur/offline/conflict bannerları | Shelf server + REST gateway + revision-only WebSocket | İki citizen projection, concurrent 409, idempotency, recovery |
| Public veri minimizasyonu | USER_FLOWS 1/4/8 | Citizen sade görünüm | Server-side role projection | Filtrelenmiş snapshot strict codec doğrulaması |
| Harita kaynak/tazelik görünürlüğü | USER_FLOWS 1/5/12 | Pin detay sheet + erişilebilir liste | `DemoProjections`, `MapSurface`, `places.json` | Place/projection/widget + offline fallback testleri |
| Medya fail-closed | USER_FLOWS 4 | Fotoğraf analizi ve kamusal önizleme uyarısı | `MediaPipeline`, actor-scoped `MediaStore`, original access audit | EXIF/PNG strip, privacy fail, server leakage testleri |
| AI yalnız öneri | USER_FLOWS 4/6 | Citizen sade öneri, staff gerekçeli override | `KentAiAnalysisService`, `AiAuthorityPolicy` | Deterministik senaryolar + evaluation gate |
| Beş adımlı vatandaş akışı | USER_FLOWS 4 | Tür/fotoğraf/konum/detay/kontrol | `CitizenReportWizardScreen`, atomik `CreateReportCommand` | Güncellenmiş walking skeleton E2E kaynağı |
| Vatandaş takip ve geri bildirim | USER_FLOWS 8 | Filtre, detay, timeline, SLA, notification center | `CitizenActionCommand`, `CitizenReportDetail` | Owner/action/idempotency projection testleri |
| Birim/saha çözüm operasyonu | USER_FLOWS staff saha | DESIGN W-08 yoğun görev listesi + çözüm detayı | `FieldTaskProjection`, `FieldOperationCommand`, `FieldSlaPolicy` | WP-15 saha/SLA/transfer/reopen/privacy test kaynakları |
| Planlı çalışma ve etki analizi | USER_FLOWS planlı çalışma | DESIGN W-05/06/07 planlama + etki + vatandaş önizleme | `MunicipalWorkCommand`, `MunicipalImpactAnalyzer`, `MunicipalWorkProjection` | WP-16 geometri/zaman/DemoClock/publish test kaynakları |
| Security trust boundary hardening | Tüm citizen/staff/source/AI akışları | Güvenli hata/uyarı yüzeyleri | `SecuritySignalCode`, server security middleware, recursive import guard, log redaction | WP-19 security/server/logger/static gate kaynakları |
| TR/EN ve WCAG 2.2 AA | USER_FLOWS tümü | Localization + focus + semantics + map/list | `appTextTr/appTextEn`, `LocaleFormatter`, `KtFocusRegion`, highContrast/reducedMotion | WP-20 localization/a11y/static/widget/AT matrisi |
| Performans/offline/recovery | USER_FLOWS tüm citizen/staff/shared akışları | Cache ile okunabilir offline + staff read-only | `PerformanceBudgets`, `OfflineStatePolicy`, `StaffOperationsProjectionIndex`, `MemoizedMapProjectionService`, remote cache/retry | WP-21 10K benchmark + chaos/recovery testleri |
| Release kabul seti | E2E-01–30 | Golden/state/error parity | `docs/acceptance_matrix.json`, strict coverage/golden/build CI | WP-22 acceptance/state-matrix + full CI kapıları |

| Pilot KPI olayları | EKSTRA 9 / WP-23 | Staff rapor dashboard'u | `PilotAnalyticsProjection`, privacy-safe `operational_metric` audit olayları | `wp23_wp24_test.dart`, WP-23 validator |
| ROI ve go/no-go | EKSTRA 9 / WP-23 | Girdi zorunlu KPI/ROI formu | `RoiCalculator`, `PilotGoNoGoPolicy` | ROI/KPI unit testleri |
| 7 dakikalık jüri senaryosu | EKSTRA demo rotası | Demo senaryoları kontrol merkezi | `JuryDemoScenario`, DemoClock/source/AI controls | Demo runbook + rehearsal report |
| RC release evidence | WP-23/24 | Release ekranından bağımsız kanıt paketi | `build_release_evidence.py`, RC version | WP-23/24 validator + manifest checksum |
| Bağımsız final audit ve insan kapısı | WP-24 | Publish/tag UI yok | `FINAL_AUDIT.md`, `KNOWN_LIMITATIONS.md`, approval record | Runtime/build/rehearsal/approval olmadan BLOCKED |

## EKSTRA P0 karşılıkları

| EKSTRA maddesi | Kapatıldığı kaynak |
|---|---|
| 4.1–4.2 ürün çakışması/değer | PRODUCT 1–2, ADR-0001 |
| 4.3 AI kapsamı | AI_SYSTEM 2–3, ADR-0002 |
| 4.4 vatandaş güven skoru | PRODUCT 5, ADR-0003 |
| 4.5 AI görünürlüğü | AI_SYSTEM 5, ADR-0004 |
| 4.6 kaynak önceliği | PRODUCT 6, ADR-0007 |
| 4.7 gerçek entegrasyon kanıtı | PRODUCT 7; uygulama WP-17 kapısı |
| 4.8 sahiplik | PRODUCT 10; yazılı insan onayı bekler |
| 4.9 pilot | PRODUCT 9 |
| Belediye dashboard ve yedi review kuyruğu | USER_FLOWS staff operasyonu | Dashboard + queue URL state | `StaffOperationsProjection`, `StaffOperationsQueueScreen` | Projection/filter/sort/10k test kaynağı |
| Staff review workspace + harita | USER_FLOWS staff operasyonu | DESIGN W-02: filtre + kuyruk + detay; W-03: detay içinde 240 px gerçek operasyonel harita | `StaffOperationsQueueScreen`, `MapSurface` | Responsive/golden/a11y kapısı toolchain bekliyor |
| Incident work/source/corroboration refs | USER_FLOWS staff olay inceleme | Olay çalışma alanı | `UrbanIncidentDto.workOrderRefs`, source/corroboration projections | Contract + workspace test kaynağı |
| Review lease ve stale-write koruması | USER_FLOWS staff karar | Read-only lock/takeover banner | `ReviewLeaseCommand`, revision ordered audit lease projection | Lease conflict/concurrency test kaynağı |
| Gerekçeli insan karar hattı | USER_FLOWS verify/reject/merge/routing | Public preview + karar paneli | `StaffDecisionCommand`, `verifyReport`, transaction queue | Reject/merge/routing/stale test kaynağı |
| Public kırmızı incident + privacy | USER_FLOWS public harita | Verify sonrası red pin, original media permission guard | `DemoProjections.visiblePins`, server role projection | Public projection/privacy contract tests |
