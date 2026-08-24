# WP-23 — Pilot analitiği, KPI/ROI, jüri senaryosu ve release paketi

## Uygulanan

- `PilotAnalyticsProjection`: first human review, first-pass routing, duplicate yoğunluğu, staff AI override, hedefte çözüm, repeat status request, resolution feedback ve **tekil incident tabanlı north-star**.
- Privacy-safe `operational_metric` olayları: staff override, duplicate cluster, repeat status request, citizen resolution feedback; mevcut first review/routing/resolution olayları yeniden kullanılır.
- Vatandaş detayında state değiştirmeyen, önceliği otomatik yükseltmeyen tekrar durum isteği.
- `RoiCalculator`: EKSTRA.md formülündeki operasyon kazancı ve maliyet bileşenleri; girdi olmadan sonuç yok.
- Baseline/hedef/go-no-go şablonu.
- `/staff/reports` pilot KPI/ROI dashboard'u.
- `JuryDemoScenario`: EKSTRA.md 7 dakikalık rota.
- `/demo/scenarios`: reset + DemoClock + source outage/recovery + AI failure/recovery kontrol merkezi.
- Release evidence üretim aracı ve CI artifact adımı.

## Kabul durumu

**BLOCKED.** WP-22 runtime/build/golden kabulü bloklu olduğu için bağımlılık kanıtı geçmedi. Ayrıca üç tam prova, clean install ve Android/iOS/web release artifact'ları bu ortamda üretilemedi. Kaynak uygulaması tamamlandı; kanıt uydurulmadı.
