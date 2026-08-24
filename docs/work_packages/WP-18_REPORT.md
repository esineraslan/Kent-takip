# WP-18 — Admin, RBAC, immutable audit ve KVKK

## Uygulanan kaynak

- `RolePermissionMatrix` reviewer, unit officer, planner, system admin ve demo supervisor izinlerini ayrı domain-policy setlerinde tutar. Demo supervisor üretim rolü değildir ve permission bypass etmez.
- Staff topbar aktif rol bağlamını gösterir; yeni core/staff/field/work/source/admin audit olayları `activeRoleContext` taşır. W-10 audit explorer bu bağlamı gösterir; legacy olayları açıkça `legacy/unknown` olarak ayırır.
- `/staff/users` user/role/unit yönetimi kritik permission değişikliklerinde ikinci onay ister ve rol dışı permission setini reddeder. Yeni demo-supervisor atanamaz.
- `/staff/audit` immutable filtre/search/original-media filtresi ve CSV/JSON export sağlar; UI'dan audit silme/düzenleme yolu yoktur.
- Original media yalnız `viewOriginalMedia` + 8–240 karakter insan gerekçesiyle açılır; başarılı erişim ayrı `original_media_accessed` audit olayı üretir.
- Vatandaş ayarlarında KVKK erişim/düzeltme/silme/otomatik değerlendirmeye itiraz talepleri tracking number üretir. Staff privacy ekranı insan kararıyla sonuçlandırır.
- Hesap silme talebi demo re-auth + ikinci onay ister; account `deletionRequested` olduğunda yeni report application katmanında engellenir.
- Abuse/restriction süreci kademelidir; kalıcı otomatik ceza yoktur. Geçici restriction insan onayı ister; vatandaş itirazı `human_review_required` durumuna geçer.
- Demo reset yalnız `resetDemo` izniyle ve kullanıcı onayıyla; source import yalnız `manageSources` izniyle çalışır.
- Security denied audit, source-health, privacy/restriction appeal ve WP-16 `admin_alert` otomasyon başarısızlığı yönetim banner/uyarı projection'ına bağlandı.
- Server staff snapshot'ı izin bazında accounts/audit/privacy/restriction/source-health/originalRef alanlarını daraltır; citizen snapshot yalnız kendi privacy/restriction kayıtlarını görür.
- Local gateway, remote gateway ve demo server `/v1/commands/administration` aynı processor/DTO sözleşmesini paylaşır.

## Uzman incelemesinde düzeltilenler

- `FailureCode` içinde olmayan authentication kodu kullanımı derleme riskiydi; mevcut `unauthorized` kontratına çekildi.
- Restriction appeal'da yinelenen local değişken kaldırıldı.
- Aktif rol bağlamının yalnız user-access audit'inde bulunması yetersizdi; tüm kritik mutasyon audit helper'larına yayıldı ve W-10'da görünür yapıldı.
- WP-16 otomasyon başarısızlığı yalnız `admin_alert` log'unda kalıyordu; WP-18 governance alert projection'ına ve dashboard banner'ına bağlandı.
- Audit listesinde tekrarlanan iterable `.last` kullanımı kaldırıldı; boş/filtreli liste davranışı sadeleştirildi.
- Original-media unit testi asset seed ref'ini `media://` API ID'si sanıyordu; test gerçek auditable media referansı oluşturarak kontrata uygun hale getirildi.

## Test kaynakları

- `packages/kent_takip_application/test/wp17_wp18_test.dart`: authorization matrix, ikinci onay, KVKK tracking, deletion/re-auth/report block, progressive restriction+appeal, original-media reason/audit/active-role ve automation alert projection.
- `apps/kent_takip_app/test/route_policy_test.dart`: admin route exact permissions ve reset permission.
- `apps/demo_server/test/server_contract_test.dart`: shared administration KVKK/active-role audit ve original-media erişim audit'i.

## Durum

Kaynak uygulaması tamamlandı. Flutter/Dart executable bulunmadığı için formatter/analyzer/unit-widget-integration/E2E ve platform build kapıları çalıştırılamadı; kanonik ROADMAP durumu `BLOCKED` tutulur.
