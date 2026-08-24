# WP-19 — Güvenlik Değerlendirmesi

Tarih: 17 Ağustos 2026

## Sonuç özeti

Kaynak incelemesinde açık bırakılan P0/P1 ürün güvenliği bulgusu yoktur. Buna rağmen gerçek Flutter/Dart testleri, cihaz/browser authenticated-role turu ve harici vulnerability registry taraması bu ortamda koşturulamadığı için WP-19 `BLOCKED` kalır; bu doküman runtime kanıtı yerine geçmez.

## MASVS-benzeri istemci matrisi

| Alan | Durum | Kanıt |
|---|---|---|
| Storage / snapshot bütünlüğü | SOURCE_PASS | Atomik store, checksum, actor projection; önceki WP test kaynakları |
| Authentication/session | PARTIAL | Demo auth + re-auth hesap silme; gerçek IdP yok; server session epoch 8 saat |
| Network | SOURCE_PASS | Shared HTTP bearer, fail-closed browser origin, security headers; production TLS ayrı deployment sorumluluğu |
| Platform interaction | SOURCE_PASS | `image_picker`, `requestFullMetadata:false`, lost-data recovery; gerçek cihaz permission testi WP-20'de BLOCKED |
| Privacy | SOURCE_PASS | Original/public media ayrımı, EXIF strip, citizen projection minimizasyonu, structured log redaction |
| Code quality | BLOCKED_RUNTIME | Kaynak kapıları PASS; gerçek `dart format` / `flutter analyze` çalıştırılamadı |
| Resilience | SOURCE_PASS | Size limitleri, safe failure, revision/idempotency, rate/abuse human-review sinyalleri |

## ASVS-benzeri demo server matrisi

| Kontrol | Durum | Kanıt |
|---|---|---|
| Server-side authorization | SOURCE_PASS | Route + application permission; denied audit |
| Session lifetime | SOURCE_PASS_DEMO | Server epoch maksimum 8 saat; sabit demo bearer üretim auth değildir |
| Brute-force response | SOURCE_PASS_DEMO | Başarısız bearer denemelerine kademeli gecikme |
| CORS / Origin / CSRF yüzeyi | SOURCE_PASS | Wildcard yok; browser mutation foreign Origin reddedilir; cookie auth kullanılmaz |
| Request limits / safe errors | SOURCE_PASS | JSON 128 KB, media 8 MB; raw DomainFailure echo yok |
| Media authorization | SOURCE_PASS | Enumeration/path traversal validator; original access permission+reason+audit |
| Import escalation | SOURCE_PASS | Nested JSON dahil reserved role/audit/token alanları fail-closed |
| Sensitive data exposure | SOURCE_PASS | Citizen snapshot audit/internal decision/originalRef içermez; logger redaction + scan |
| AI injection boundary | SOURCE_PASS | `untrusted_citizen_data` wrapper ve typed output; AI state transition yapmaz |
| Dependency security | PARTIAL | Exact pins + SBOM CI + resolved license gate; harici vulnerability registry taraması yerelde BLOCKED |

## Negatif/adversarial test kaynakları

- `packages/kent_takip_application/test/wp19_security_test.dart`: same-media, rate, impossible-location, replay, prompt isolation, nested import escalation, JPEG EXIF/comment strip.
- `apps/demo_server/test/server_contract_test.dart`: foreign Origin, güvenli error payload, session expiry, import denial audit, media enumeration/path traversal/unauthorized original access ve citizen projection leakage.
- `apps/kent_takip_app/test/structured_logger_test.dart`: keyed ve unkeyed secret/PII redaction.
- `tool/validate_security_hardening.py`: origin/session/media/import/log/AI/abuse source invariant gate.
- `tool/scan_sensitive_data.py`: fixture/source secret ve PII gate.

## Bulgular

### Kapatılan P1'ler

- Wildcard CORS → localhost/127.0.0.1 allow-list + mutating Origin fail-closed.
- Import içinden role/audit/token escalation → nested recursive reserved-key rejection.
- Original media denial'ın audit dışı kalması → denied immutable audit.
- Ham DomainFailure/kamera mesajının UI/HTTP üzerinden sızması → error-code-to-localized-safe-message ve generic HTTP failure.
- Prompt-benzeri kullanıcı metninin AI talimatı gibi yorumlanması → untrusted data boundary.

### P2 takip maddeleri

| ID | Risk | Sahip | Hedef tarih | Kapanış ölçütü |
|---|---|---|---|---|
| P2-SEC-01 | Sabit demo bearer/OTP üretim kimlik doğrulama değildir | Platform/Auth | 31 Ağustos 2026 | Kurumsal IdP/OAuth, kişi/cihaz session yönetimi ve revoke kanıtı |
| P2-SEC-02 | Harici vulnerability registry/advisory taraması bu ortamda çalışmadı | Platform/Security | 24 Ağustos 2026 | Resolved SBOM üzerinde advisory scan + rapor; kritik/yüksek bulgu 0 veya onaylı remediation |
| P2-SEC-03 | Gerçek cihaz/browser authenticated-role adversarial turu çalışmadı | QA/Security | 31 Ağustos 2026 | Citizen/reviewer/unit/planner/admin hesaplarıyla manuel route/media/import review kaydı |

## Release kararı

P0/P1 kaynak bulgusu 0 olsa da runtime/toolchain ve manuel security kanıtları tamamlanmadan `COMPLETED`, production-ready veya OWASP-certified iddiası yoktur.
