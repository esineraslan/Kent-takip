# Kent Takip shared demo API sözleşmesi

Base path: `/v1`. Tüm JSON yanıtları `cache-control: no-store` taşır. Demo bearer değerleri yalnız sentetik hesapları eşler ve production kimliği değildir.

| Yöntem | Rota | Yetki | Davranış |
|---|---|---|---|
| GET | `/health/live` | Açık | Process liveness |
| GET | `/health/ready` | Açık | Snapshot okunabilirliği, schema ve revision |
| GET | `/v1/snapshot` | Guest/citizen/staff | Server-side filtrelenmiş, checksum'lı snapshot |
| POST | `/v1/commands/report` | `submitReport` | Idempotent vatandaş bildirimi |
| POST | `/v1/commands/verify` | `reviewReport` + `routeReport` | Aktif lease + insan public-preview onayıyla doğrulama ve public incident |
| POST | `/v1/commands/review-lease` | `viewReviewQueue` + `reviewReport` | Acquire/release/supervisor takeover review lease |
| POST | `/v1/commands/staff-decision` | `reviewReport` (+ eyleme göre `mergeReport`/`routeReport`) | Reject, out-of-scope, ek bilgi, merge, reroute ve transfer-back |
| POST | `/v1/commands/citizen-action` | Owner/eyleme göre citizen permission | Ek bilgi yanıtı, corroboration, feedback, appeal ve notification read |
| POST | `/v1/commands/field-operation` | `manageFieldWork` (+ unit boundary) | Saha atama, müdahale başlatma, gecikme/re-estimate ve resolution evidence |
| POST | `/v1/commands/municipal-work` | `manageMunicipalWork` | Draft autosave, explainable impact, review/publish, DemoClock reconcile ve cancel |
| PUT | `/v1/media/:id` | `submitReport` | En fazla 8 MB, aktöre ait namespace içinde immutable demo upload |
| GET | `/v1/media/:id` | `viewOriginalMedia` | Yetkili original media okuma |
| GET/WS | `/v1/revisions` | Kimliği doğrulanmış | Yalnız revision event |

Komutlar `actorId`, `clientMutationId` ve `expectedRevision` taşır. Staff kararları ayrıca aktif actor review lease'i ister. `verify` komutu `publicPreviewApproved=true` olmadan public incident üretemez. `reject` ve `outOfScope`, önceden tanımlı `reasonCode` ile ayrı insan açıklamasını birlikte ister; routing/merge eylemleri kendi permission ve state geçiş matrisine tabidir. AI hiçbir staff command'ı kendiliğinden çağırmaz. Server aktörü bearer kimliğiyle eşleştirir. Aynı mutation replay'i aynı resource'u döndürür. Stale revision `409` ile `current`, `currentRevision` ve `retryable=true` döndürür; sessiz overwrite yapılmaz. Yetkisiz komut `403` döner ve ayrı bir denied audit kaydı üretir.

Desteklenen ret/kapsam-dışı `reasonCode` değerleri: `insufficient_evidence`, `not_municipal_scope`, `private_property`, `outside_service_boundary`, `invalid_or_abusive`. Application katmanı allow-list dışındaki değeri `validation` hatasıyla reddeder; yalnız UI dropdown'ına güvenilmez.

Medya ID biçimi `media_<accountId>_<benzersiz-parça>` olmalıdır. Sunucu farklı aktör namespace'ine yazmayı `403`, aynı ID'ye farklı byte yazmayı `409` ile reddeder; aynı byte retry'ı idempotent `204` döner. `GET /v1/media/<id>` yalnız `viewOriginalMedia` yetkisi ve 8–240 karakter erişim gerekçesiyle çalışır, her başarılı okuma audit edilir. `GET /v1/public-media/<id>` yalnız `privacyStatus=safe` kamusal kopyayı verir. Citizen snapshot hiçbir zaman `originalRef` taşımaz.

`POST /v1/commands/citizen-action`, owner-scoped corroboration, ek bilgi yanıtı, çözüm geri bildirimi, itiraz ve notification-read mutasyonlarını revision/clientMutationId ile idempotent işler. AI sonucu bu uç üzerinden domain state geçişi yaptıramaz.

`field-operation` çözüm açıklamasını zorunlu tutar, dış iş emri bağlantısı yoksa yalnız `DEMO_SIMULATED_WORK_ORDER` referansı üretir ve SLA bilgisini hedef aralığı olarak taşır. `municipal-work` taslağı public projection dışında tutar; impact kaynağını/geometri-zaman kuralını açıklar ve `publicPreviewApproved=true` olmadan publish etmez. DemoClock reconcile geçişleri state-machine adımlarını atlamaz.
