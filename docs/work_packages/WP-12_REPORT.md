# WP-12 — Vatandaş takip ve bildirim raporu

## Uygulanan kaynak

- Aktif/tamamlanan/tümü filtreli owner-only bildirim listesi ve offline son-eşitlenen durum uyarısı.
- Detay: tracking, status, konum, provenance, sorumlu birim, kaynak health, kronolojik timeline ve kategori bazlı tahmini SLA.
- “Tahmindir, garanti değildir” etiketi; merge/reject insan gerekçesi ve original media minimizasyon notu.
- Tek alıcılı notification center, unread filtresi, read mutation ve güvenli report deep-link.
- `additionalInfoRequired` yanıtı, resolved `stillPresent/noLongerVisible` sinyali ve rejected/out-of-scope itirazı.
- `stillPresent` otomatik reopen etmez; insan inceleme isteği audit/corroboration kaydına dönüşür.
- Bütün citizen action'lar owner/permission/revision/clientMutationId doğrulamalıdır.

## Öz-denetim düzeltmeleri

- Notification read'in yalnız UI state olması yerine paylaşımlı snapshot komutuna taşınmasıyla iki istemci tutarlılığı sağlandı.
- Citizen aksiyonlarının rapor sahibini kontrol etmeden çalışması engellendi.
- Terminal olmayan kayıtlar haritada/report listesinde tutarlı filtrelendi.

## Durum

Kaynak ve projection testleri hazırdır. Flutter widget/deep-link/E2E kanıtı SDK yokluğu nedeniyle koşturulamadı; `BLOCKED`.
