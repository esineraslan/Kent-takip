# İBB Kent Takip — Kaynak Teslim Manifesti

- Teslim tarihi: 19 Ağustos 2026
- Kapsam: WP-00–WP-24 kaynak uygulaması + 19 Ağustos harita/auth/sidebar P1 hotfix
- Flutter hedefi: 3.47.0 stable
- Kanonik snapshot schema: v1
- Seed: 2026.08.17.2, revision 1
- Seed checksum: `sha256:21dc27ab91e20cefda362d58d9ab18dc9bb1ab337aaf0f408b6da4d7d91a06ee`
- Tasarım referansı: 5 PNG
- Paket durumu: WP-00 `COMPLETED`; WP-01–24 SDK test/build, üç prova, final insan onayı ve cihaz/AT/performance/golden kanıtı beklediği için `BLOCKED`

Arşiv; WP-00–14 kapsamına ek olarak WP-15 birim görev projection'ı, saha atama/başlatma/gecikme/çözüm komutları, kategori-birim SLA hedef aralığı ve saat durdurma, privacy-safe çözüm kanıtı, simüle external work-order fallback'i, vatandaş “devam ediyor” reopen-review sinyali ve operasyon metriklerini; WP-16 için autosave planlı çalışma taslağı, açıklanabilir geometri+zaman etki analizi, kural tabanlı alternatifler, insan onaylı public preview/yayın, sarı→kırmızı→tamamlandı DemoClock projection/transition hattı ve ilgili local/shared HTTP test kaynaklarını içerir. WP-17 için ortak adaptör contract'ı, GTFS gerçek-şema fixture kanıtı, deterministik fixture katalogu, otorite önceliği, quarantine, retry/backoff/jitter/circuit-breaker/stale cache, W-09 DataSourceHealth, yetkili manuel olay/iş, doğrulamalı JSON/CSV import-export ve gerçek entegrasyon olmadığını açıkça etiketleyen 153/İstanbul Senin mock sınırını; WP-18 için ayrık RBAC matrisi, demo supervisor aktif rol bağlamı, user/role/unit yönetimi, immutable audit explorer/export, gerekçeli original-media erişimi, KVKK ve hesap silme, kademeli geçici restriction/appeal ve security/source/automation yönetim uyarılarını içerir.

WP-19 için threat model, Origin/CORS/session/brute-force/server error hardening, recursive import escalation guard, original-media denial audit, human-review-only abuse/replay sinyalleri, AI untrusted-data sınırı, log redaction ve strict dependency/license CI kanıtını; WP-20 için 757-key TR/EN katalog, locale formatter, direct-copy CI gate, focus/target-size/semantics/reduced-motion/high-contrast, map/list eşdeğeri, kamera lifecycle recovery ve VPAT-Lite/WCAG/platform-AT matrisini ekler.


WP-21 için ortak performance budget/offline policy, 10K staff queue index'i, map lookup+memoization, shared persistent last-success snapshot cache, 408/429/5xx bounded retry, revision reconnect, corruption/migration/media-quota recovery ve bloklayıcı benchmark kaynağını; WP-22 için E2E-01–30 kabul matrisi, yeni acceptance/state-matrix regresyon kaynakları, strict genel/kritik coverage kapısı, approved golden gate, bug burn-down ve `docs/ACCEPTANCE_REPORT.md` içerir.

Build çıktısı, üretim credential'ı ve gerçek kişisel veri içermez. Flutter/Dart toolchain bu çalışma ortamında bulunmadığı için analyzer, formatter, Dart unit/widget/integration/E2E ve platform build kanıtları üretilmiş sayılmaz; `BLOCKED` statüsü bu kalite kapısının bilinçli olarak açık tutulduğunu gösterir.

WP-23 için privacy-safe operasyon metriği olayları, snapshot/audit türevli KPI projection'ı, baseline/target/go-no-go politikası, değişken/formül tabanlı ROI hesaplayıcısı, EKSRA 7 dakikalık jüri rotası, DemoClock/source-outage/AI-failure/reset kontrol merkezi, demo runbook'u ve deterministik release-evidence üreticisini; WP-24 için adversarial final audit, release manifest, bilinen sınırlar, traceability/acceptance doğrulayıcısı, RC sürüm sabitlemesi ve insan onayı olmadan tag/publish yapılmayan çıkış kapısını içerir.


## 19 Ağustos P1 hotfix

- Citizen ve staff harita yüzeyi statik 2x2 tile grid yerine gerçek interaktif `flutter_map` kamera/marker katmanına geçirildi; drag/pan, pinch/wheel ve 48×48 zoom kontrolleri aynı ortak bileşende çalışır.
- İlçe/mahalle/adres araması exact-match, Enter veya sonuç seçimiyle `MapController` üzerinden koordinata odaklanır; viewport hareketinden sonra “Bu alanda ara”, odak sonrası “Tüm İstanbul’u göster” durumu birlikte yönetilir.
- Citizen OTP ve staff MFA doğrulama ekranlarında sabit demo kodunun görünür UI bildirimi kaldırıldı; deterministic fixture credential yalnız test/demo auth servisinde kalır.
- Desktop staff sidebar sabit yüksek `Column` taşması yerine `Expanded + Scrollbar + ListView` yapısına geçirildi; KVKK ve Ayarlar kısa viewportlarda da erişilebilir.
- App candidate sürümü `0.2.0-rc.2+1` olarak yükseltildi; demo server sürümü değişmedi. Runtime analyzer/widget/integration/build kanıtı Flutter/Dart toolchain olmadığı için hâlâ `BLOCKED`.
