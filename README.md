# İBB Kent Takip

İstanbul Senin/153 üzerine bağlanan doğrulanmış kent olayı ve operasyon koordinasyon katmanının Flutter 3.47.0 demo kaynak kodudur.

## Durum

- WP-00 kanonik karar ve dokümantasyon: uygulandı.
- WP-01 workspace/CI kaynakları: uygulandı; SDK bulunan ortamda doğrulanmalıdır.
- WP-02 domain/state/contract kaynakları: uygulandı.
- WP-03 atomik JSON/seed/migration/media kaynakları: uygulandı.
- WP-04 bootstrap/router/demo auth/rol shell kaynakları: uygulandı; beş görsel referansa göre responsive mobil ve masaüstü kabukları kuruldu.
- WP-05 tasarım tokenları, erişilebilir ortak bileşenler, pinler, durum yüzeyleri, component gallery ve golden matrisi: uygulandı; onaylı kurumsal font/logo baseline'ı bekleniyor.
- WP-06 local walking skeleton: gerçek command/repository, kalıcı JSON, kişisel pending pin, staff insan doğrulaması, public incident ve vatandaş timeline akışı uygulandı.
- WP-07 shared Shelf server: REST query/command/media/health, revision WebSocket, server authorization, idempotency, conflict yanıtı, offline draft ve atomik runtime recovery uygulandı.
- WP-08 harita: OSM attribution, ayarlanabilir HTTPS tile, timeout/retry/offline fallback, cluster, rol projection'ı, trafik/resmî uyarı katmanı, 39 ilçe araması ve erişilebilir liste uygulandı.
- WP-09 medya: gerçek `image_picker` kamera adaptörü, Android lost-data recovery, JPEG/PNG metadata temizliği, boyut/çözünürlük kotaları, actor-scoped rastgele ID ve fail-closed original/public yaşam döngüsü uygulandı.
- WP-10 AI: dar typed sözleşme, deterministik success/partial/unavailable/timeout/invalid senaryoları, opsiyonel fail-closed remote adapter, rol projeksiyonu ve evaluation gate uygulandı.
- WP-11 vatandaş bildirimi: tür → fotoğraf → konum → detay → kontrol sihirbazı, AI düzeltmesi, duplicate corroboration, çevrimdışı medya taslağı ve atomik snapshot mutasyonu uygulandı.
- WP-12 takip: filtreli bildirimlerim, detay/timeline, tahmini SLA, kaynak tazeliği, bildirim merkezi, ek bilgi, çözüm geri bildirimi ve itiraz akışları uygulandı.
- WP-13 belediye operasyonu: dashboard, yedi staff kuyruğu, responsive review workspace, gerçek harita, lease/concurrency ve projection katmanı uygulandı.
- WP-14 personel kararları: verify/reject/out-of-scope/additional-info/merge/reroute/transfer-back, structured reason ve public preview güvenlik hattı uygulandı.
- WP-15 birim/saha operasyonu: görev filtreleri, saha atama/başlatma/gecikme/çözüm, SLA hedef aralığı, simüle dış iş emri, privacy-safe çözüm kanıtı ve reopen-review sinyali uygulandı.
- WP-16 planlı çalışma: autosave taslak, açıklanabilir geometri-zaman etki analizi, kural tabanlı alternatif, insan onaylı yayın ve DemoClock sarı→kırmızı→tamamlandı yaşam döngüsü uygulandı.
- WP-17 veri kaynakları: ortak source-adapter contract, İETT GTFS gerçek-şema fixture mapping'i, quarantine, otorite önceliği, retry/backoff/jitter/circuit-breaker, stale-cache, W-09 kaynak sağlığı, yetkili manuel giriş, doğrulamalı JSON/CSV fixture ve açıkça simüle 153/İstanbul Senin sözleşmesi uygulandı.
- WP-18 yönetişim: rol-permission matrisi, demo supervisor aktif rol bağlamı, kullanıcı/rol/birim yönetimi, immutable audit explorer/export, gerekçeli original-media erişimi, KVKK talepleri, re-auth hesap silme, kademeli geçici restriction/itiraz ve yönetim uyarıları uygulandı.
- WP-19 güvenlik/gizlilik: threat model, fail-closed Origin/CORS, demo session expiry ve brute-force delay, safe error payload, media/import escalation kontrolleri, ölçülü abuse sinyalleri, AI untrusted-data sınırı, log redaction ve dependency/license CI kanıtı uygulandı.
- WP-20 TR/EN ve erişilebilirlik: 753 ortak localization key, locale biçimleyicileri, hard-coded copy CI kapısı, focus-not-obscured, 48×48 hedefler, reduced-motion/high-contrast, map/list eşdeğeri, kamera resume recovery ve WCAG/AT kanıt matrisi uygulandı.
- WP-21 performans/offline/recovery: 10K staff/map indeksleme ve memoization, ortak performance budget, persistent shared snapshot cache, bounded retry/reconnect, offline read-only policy, corruption/migration/media-quota recovery ve benchmark kapısı uygulandı.
- WP-22 kabul/regresyon: E2E-01–30 kabul matrisi, yeni cross-layer acceptance/state-matrix testleri, strict coverage/golden gate, bug burn-down ve `docs/ACCEPTANCE_REPORT.md` uygulandı.
- WP-23 pilot/release: privacy-safe KPI olayları, gerçek snapshot/audit türevli pilot dashboard, değişken/formül ROI, baseline-target-go/no-go şablonu, 7 dakikalık jüri senaryosu, tek demo kontrol merkezi, release evidence/checksum ve runbook kaynakları uygulandı.
- WP-24 final audit/RC: code-to-requirement izlenebilirlik, adversarial final audit, bilinen sınırlar, RC sürüm sabitleme, release manifest/evidence ve yazılı insan onayı kapısı uygulandı; `.git` metadata ve runtime/build kanıtı olmadığı için tag/publish yapılmadı.

Flutter/Dart SDK bu hazırlama ortamında bulunmadığı için WP-01–24 roadmap durumları `BLOCKED` olarak tutulur. Kaynaklar ve CI kapıları hazırdır; analyzer, test, kamera cihaz smoke'u ve üç platform build'i yeşil olmadan `COMPLETED` veya release iddiası verilmez.

## Gereksinimler

- Flutter `3.47.0` stable ve bu sürümle gelen Dart SDK
- Android toolchain ve Chrome
- iOS için macOS + Xcode

## İlk kurulum

```bash
./tool/bootstrap_platforms.sh
flutter pub get
dart run tool/check_doc_consistency.dart
dart run tool/validate_demo_data.dart
python3 tool/validate_source_structure.py
python3 tool/check_localization.py
python3 tool/check_accessibility_source.py
python3 tool/validate_security_hardening.py
python3 tool/dependency_license_report.py --strict
python3 tool/validate_wp21_wp22.py
python3 tool/validate_wp23_wp24.py
python3 tool/evaluate_demo_ai.py
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
dart test packages/kent_takip_domain packages/kent_takip_contracts packages/kent_takip_persistence packages/kent_takip_application apps/demo_server
flutter test apps/kent_takip_app
flutter test apps/kent_takip_app/integration_test
python3 tool/check_coverage.py --strict
python3 tool/check_golden_baselines.py --strict
dart run tool/benchmark_wp21.dart --out build/wp21/performance_report.json
python3 tool/build_release_evidence.py --out build/wp23/release_evidence.json
```

`bootstrap_platforms.sh`, Flutter tarafından üretilen Android/iOS/web kabuklarını güvenli biçimde oluşturur. Uygulama ve paket kaynaklarını silmez.

## Çalıştırma

```bash
cd apps/kent_takip_app
flutter run --dart-define=APP_ENV=demo --dart-define=DEMO_DATA_MODE=local
```

Shared mod için önce `docs/LOCAL_NETWORK_RUNBOOK.md` adımlarını izleyin; ardından `DEMO_DATA_MODE=shared` ve `DEMO_API_URL` ile iki istemci açın.

## Mimari

```text
View -> ViewModel/Command -> Use-case/Policy -> Repository -> Service/Store
```

- `packages/kent_takip_domain`: saf Dart entity, policy, state machine ve portlar.
- `packages/kent_takip_contracts`: strict JSON DTO ve snapshot sözleşmeleri.
- `packages/kent_takip_persistence`: checksum, migration, atomik IO, web dual-slot ve media store.
- `packages/kent_takip_application`: ortak komut motoru, idempotency, projection, offline draft ve gateway sözleşmesi.
- `apps/demo_server`: Shelf REST/WebSocket demo server, server-side authorization ve atomik JSON runtime.
- `apps/kent_takip_app`: local/shared adaptörler, erişilebilir tasarım sistemi, gerçek walking-skeleton ekranları ve ayrı citizen/staff shell'leri.

## Demo güvenliği

Gerçek kişisel veri, credential, gerçek SMS/SSO, gerçek 153 yazımı veya üretim backend'i yoktur. Demo hesap/olayları sentetiktir. Gerçek servis ve veri geçişleri ilgili kurum/KVKK onayından sonra ayrı adaptör olarak eklenir.

## Ekran görüntüleri

Ekran görüntüleri sonradan aşağıdaki başlıkların altına eklenebilir:

### Vatandaş uygulaması

<!-- Ekran görüntüsünü ekleyin: docs/screenshots/citizen-home.png -->

### Personel paneli

<!-- Ekran görüntüsünü ekleyin: docs/screenshots/staff-dashboard.png -->

### Harita ve bildirim akışı

<!-- Ekran görüntüsünü ekleyin: docs/screenshots/map-report-flow.png -->

Uzman incelemesi ve paket bazlı kanıtlar `docs/EXPERT_REVIEW.md` ile `docs/work_packages/` altındadır.
WP-05–07 için son çalıştırılabilir kanıt matrisi `docs/QUALITY_EVIDENCE_WP05_WP07.md` dosyasındadır.
