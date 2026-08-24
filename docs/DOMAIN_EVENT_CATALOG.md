# İBB Kent Takip — Domain Event Kataloğu

Bu katalog WP-02 için kanonik olay adlarını ve asgari tüketicileri sabitler. Her event `id`, `aggregateId`, UTC `occurredAt` ve kişisel veri içermeyen `data` taşır.

| Event | Aggregate | Ana tüketici |
|---|---|---|
| `reportReceived` | CitizenReport | Timeline, kullanıcı bildirimi |
| `reportStatusChanged` | CitizenReport | Timeline, bildirim |
| `reportMerged` | CitizenReport | Incident projection, takip |
| `incidentVerified` | UrbanIncident | Public map projection |
| `incidentResolved` | UrbanIncident | Public map, çözüm bildirimi |
| `workPublished` | MunicipalWork | Planned map projection |
| `workCompleted` | MunicipalWork | Map projection |
| `additionalInfoRequested` | CitizenReport | Kullanıcı bildirimi |
| `privacyRequestReceived` | PrivacyRequest | Privacy queue, audit |
| `accountRestricted` | AccountRestriction | Auth guard, audit |
| `demoReset` | AppSnapshot | Audit, demo telemetry |

AI çıktıları event değildir ve tek başına durum değişikliği üretemez. Event gövdesine ham telefon, adres, plaka, yüz verisi veya orijinal medya yolu yazılmaz.
