# WP-07 Raporu

## Sonuç

`apps/demo_server` altında aynı command processor'ı kullanan Shelf demo server eklendi. Snapshot, command, media, health/readiness ve revision WebSocket rotaları; tek writer queue, optimistic revision, mutation replay, server authorization, rol bazlı snapshot projection, denied audit ve atomik runtime recovery uygulandı.

## Senkron ve conflict kararı

- WebSocket yalnız `type` + `revision` taşır; istemci her değişimde REST refetch yapar.
- Komut cevabında stale state `409 revision_conflict`, güncel yetkili snapshot ve retry bilgisi döner.
- Server request içindeki `actorId` değerine güvenmez; demo bearer hesabıyla birebir eşleştirir.
- Citizen snapshot yalnız kendi report'unu, kendi notification/timeline/media/analysis kayıtlarını ve public olayları görür. Hidden citizen report referansları public incident içinde sentetik, doğrulanmış projection source ile değiştirilir; corroboration ve audit iç projection'da bırakılmaz.
- Citizen offline taslağı cihazda korunur; staff bağlantı yokken salt okunurdur.
- Runtime active bozulduğunda checksum'lı backup, o da yoksa seed okunur.
- Sunucu varsayılan olarak loopback'e bind olur; LAN açılımı runbook'ta açık bir operatör kararıdır. Android cleartext istisnası yalnız debug manifestindedir.

## Kanıt kaynakları

- `apps/demo_server/test/server_contract_test.dart`: health, idempotency, eşzamanlı writer conflict, iki citizen visibility, filtrelenmiş snapshot codec doğrulaması, iki istemci convergence, stale conflict, denied audit, restart/corrupt recovery.
- `docs/SHARED_API_CONTRACT.md`
- `docs/LOCAL_NETWORK_RUNBOOK.md`

## Çıkış kapısı

Kaynak uygulaması tamamlandı. Server contract ve gerçek iki cihaz/istemci senaryosu Dart/Flutter SDK bulunmadığı için bu ortamda çalıştırılamadı; durum `BLOCKED`.
