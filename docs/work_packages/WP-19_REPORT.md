# WP-19 — Güvenlik ve gizlilik hardening

## Uygulananlar

- Route/JSON/media/server/AI/source/log trust boundary'lerini kapsayan STRIDE threat model oluşturuldu.
- Demo server wildcard CORS'tan fail-closed localhost origin allow-list'e geçirildi; mutating foreign origin reddedilir.
- Sekiz saatlik demo server session epoch'i ve başarısız bearer denemelerinde kademeli gecikme eklendi.
- Raw domain hata ayrıntıları HTTP response'a taşınmaz; body/media boyutları sınırlı tutulur.
- Original media enumeration/path traversal/unauthorized access fail-closed; başarısız erişim de immutable denied audit üretir.
- Citizen projection'da internal human decision, audit ve `originalRef` kaldırılır; ham trust/abuse profili yayınlanmaz.
- Fixture import role/permission/audit/token/originalRef gibi ayrılmış alanları nested JSON içinde de reddeder; authority/provenance hattı korunur.
- Abuse sinyalleri rate, same-media, mutation replay ve fiziksel olarak imkânsız konum sıçramasını ölçer; otomatik yaptırım yok, yalnız insan incelemesi.
- Citizen serbest metni AI'ya `untrusted_citizen_data` olarak taşınır; prompt-benzeri içerik veri kabul edilir.
- Structured logger keyed/unkeyed secret ve PII redaction yapar; secret/PII scan CI'da zorunludur.
- Dependency SBOM + strict resolved-license evidence CI kapısı eklendi.
- Security review, OWASP-benzeri kontrol matrisi ve P2 sahip/tarih listesi üretildi.

## Uzman incelemesinde düzeltilenler

- CORS `*` kullanımı kaldırıldı.
- Fixture import yalnız top-level alanları kontrol ediyordu; recursive nested ve case-insensitive reserved-key guard'a çevrildi.
- Unauthorized original media erişiminin audit dışına düşebildiği yol kapatıldı.
- Abuse enumunda bulunup hiç üretilmeyen replay sinyali gerçek kural ve testle bağlandı.
- Kamera/domain raw hata metinleri localized safe error-code mesajına dönüştürüldü.
- Dependency license CI scriptinin workspace first-party paketlerini üçüncü taraf lisans hatası gibi sayma riski düzeltildi.

## Test kaynakları

- `packages/kent_takip_application/test/wp19_security_test.dart`
- `apps/demo_server/test/server_contract_test.dart`
- `apps/kent_takip_app/test/structured_logger_test.dart`
- `tool/validate_security_hardening.py`
- `tool/scan_sensitive_data.py`
- `tool/dependency_license_report.py`

## Durum

Kaynak uygulaması tamamlandı. Gerçek Dart/Flutter testleri, authenticated-role manuel security turu ve harici dependency advisory taraması bu ortamda üretilemediği için kanonik durum `BLOCKED`.
