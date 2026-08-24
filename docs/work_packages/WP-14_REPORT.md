# WP-14 — Belediye kararları, merge, yönlendirme ve public projection

## Uygulanan kaynak

- `ReviewLeaseCommand` ve `StaffDecisionCommand` ile authorize/validate/stale-check/mutate/invariant/audit-event/persist hattı typed command katmanına taşındı; tüm staff mutasyonları aynı `SnapshotTransactionQueue` üzerinden seri hale gelir.
- Verify artık aktif actor lease'i, `reviewReport` + `routeReport`, güncel revision, zorunlu insan gerekçesi ve `publicPreviewApproved=true` ister.
- Verify yeni `UrbanIncident` oluşturur veya merge'in oluşturduğu `pendingVerification` incident'i doğrular; sonuç `verifiedActive` olduğu için public kırmızı pin projection'ına girer.
- Reject ve out-of-scope hem seçilmiş yapılandırılmış `reasonCode` hem de insan açıklaması ister; terminal state üretir ve public incident oluşturmaz. Kritik sinyalde supervisor/system-admin ikinci onayı zorunludur.
- Additional-info request staff timeline/notification/audit üretir; mevcut citizen `additionalInfoResponse` akışı aynı tracking ile kaydı `ibbReview` durumuna döndürür.
- Merge kendine merge'i, terminal hedefi ve tekrar merge'i reddeder. Model report-to-report zinciri tutmak yerine iki report'u tek kanonik incident altında bağlar; ters yönde yeniden merge denemesi de reddedilir, cycle oluşmaz ve tracking numaraları korunur.
- Karar-state matrisi fail-closed uygulanır: reject/out-of-scope/additional-info/merge yalnız doğrulama öncesi review durumlarında; İBB birimi/ilçe yönlendirmesi ve transfer-back yalnız doğrulanmış aktif incident'e bağlı `assignedUnit` kayıtta çalışır. Böylece doğrulanmış public incident'i arkada bırakıp report'u terminale taşıyan yetim-state yolu kapatılır.
- AI reason code içinde önerilen unit değiştiriliyorsa `aiOverrideReason` zorunludur; verify category/unit override kontrolü de korunur.
- Yanlış yönlendirme `transferBack` ile `assignedUnit -> ibbReview` yapar; önceki sorumlu birim audit'te tutulur, incident üzerindeki aktif sorumluluk temizlenir ve tracking sıfırlanmaz.
- Her staff kararında actor, UTC time, reason, before/after, timeline ve citizen notification atomik snapshot yazımının parçasıdır.
- Demo server ve remote gateway'e `/v1/commands/review-lease` ve `/v1/commands/staff-decision` uçları eklendi.
- Stale revision yalnız yetkili personel doğrulamasından sonra conflict üretir; yetkisiz kullanıcı güncel staff state'i komut sırası üzerinden okuyamaz.

## Öz-denetim düzeltmeleri

- İlk routing taslağında doğrulama öncesi `ibbReview -> assignedUnit` yapılabilmesi incident/unit bilgisini eksik bırakıyor ve sonradan verify yolunu kapatıyordu. Routing yalnız doğrulanmış incident üzerinde yeniden yönlendirme olacak şekilde daraltıldı.
- Transfer-back'in eski responsible unit değerini incident üzerinde bırakması düzeltildi; sorumluluk geçmişi audit'e alınırken aktif değer temizlenir.
- Server contract verify senaryoları yeni lease + public-preview onayı şartına göre güncellendi.
- Eski walking-skeleton verify testi yeni güvenli karar sırasına geçirildi.
- Uzman turunda doğrulanmış `assignedUnit` report üzerinde reject/out-of-scope yapılabilmesinin public incident'i yetim bırakabileceği görüldü; action/state matrisi ile kapatıldı.
- Reject/out-of-scope için yalnız serbest metin yerine seçilmiş reason code + insan açıklaması birlikte zorunlu hale getirildi.

## Test ve kanıt

- `packages/kent_takip_application/test/wp13_wp14_test.dart`: structured reject/no-public-incident, additional-info round trip, merge + pending-to-verified public projection + reverse-cycle guard, AI unit override gerekçesi, routing/transfer history, post-verify invalid transition, stale decision, work-order DTO roundtrip, 10k projection ve lease concurrency senaryoları.
- `packages/kent_takip_application/test/walking_skeleton_test.dart`: verify artık önce lease alır ve public preview insan onayı gönderir.
- `apps/demo_server/test/server_contract_test.dart`: HTTP verify kontratı lease/revision/public approval sırasıyla güncellendi; unauthorized/stale ve citizen projection privacy testleri korunur.

## Durum

Kaynak uygulaması tamamlandı. Bu ortamda Dart/Flutter SDK bulunmadığından zorunlu analyzer/unit/widget/integration/E2E komutları çalıştırılamıyor; kanonik durum toolchain engeli nedeniyle `BLOCKED` tutulur. SDK-bağımsız source/seed/security/document doğrulamaları teslimde ayrıca raporlanır.
