# İBB Kent Takip — Demo Prova Raporu

## Durum

**BLOCKED — bu çalışma ortamında Flutter SDK/cihaz/browser olmadığı için üç tam 7 dakikalık prova gerçek runtime üzerinde koşturulamadı.**

Kaynakta tekrar üretilebilir `JuryDemoScenario`, reset, DemoClock, source outage/recovery ve AI failure/recovery kontrolleri hazırdır.

## Zorunlu prova kayıt tablosu

| Prova | Reset checksum | Başlangıç | Bitiş | Süre | Hata | Offline ana hikâye | Sonuç |
|---|---|---|---|---:|---|---|---|
| 1 | BEKLENİYOR | — | — | — | — | — | BLOCKED |
| 2 | BEKLENİYOR | — | — | — | — | — | BLOCKED |
| 3 | BEKLENİYOR | — | — | — | — | — | BLOCKED |

## Prova kabulü

Her üç koşuda reset sonrası aynı başlangıç seed'i, aynı adım sırası ve aynı beklenen domain sonuçları görülmelidir. Süre sapması ve her hata ayrı kaydedilmelidir; prova başarısızlığı retry ile gizlenmez.
