# İBB Kent Takip — 7 Dakikalık Jüri Demo Runbook

## Amaç ve dürüst sınır

Bu runbook demo/pilot sürümünü gösterir. Üretim-ready iddiası yapılmaz. 153/İstanbul Senin gerçek entegrasyonu yerine açıkça `simulated_contract` kullanılır; İETT GTFS kanıtı gerçek şemaya dayalı fixture'dır.

## Ön kontrol

1. Flutter 3.47.0 / Dart 3.13.x doğrula.
2. Local ana hikâye için `DEMO_DATA_MODE=local`; iki cihaz paylaşımı için demo server + `shared` mod kullan.
3. Demo Supervisor hesabını doğrula.
4. `/demo/scenarios` kontrol merkezinde AI `success`, DemoClock `0 dk`, kaynaklar fresh olmalı.
5. Demo reset çalıştır; vatandaş taslaklarının temiz olduğunu kontrol et.
6. Cihaz şarjı, ekran parlaklığı ve ekran kaydı/HDMI yedeğini kontrol et.
7. İnternet kesilirse ana hikâye local deterministic seed ile devam edecek şekilde hazır ol.

## 7 dakikalık rota

| Süre | Ekran | Beklenen kanıt |
|---|---|---|
| 0:00–0:40 | `/demo/start` | Problem yeni form değil; parçalı kayıtların ortak olay altında birleşmemesi. |
| 0:40–1:20 | `/citizen/map` | Kırmızı doğrulanmış olay, sarı planlı çalışma, kaynak/güncellik, erişilebilir liste. |
| 1:20–2:30 | `/citizen/report/type` | Privacy-safe medya, konum, kısa açıklama, benzer olay/corroboration. |
| 2:30–3:15 | aynı akış | AI yalnız önerir; ret/yaptırım/yayın insan kararıdır. |
| 3:15–4:30 | `/staff/queues/normal` | Çoklu sinyal, kaynak, gizlilik, insan doğrulaması ve yönlendirme. |
| 4:30–5:20 | `/staff/tasks` + vatandaş detay | Takip no korunur; timeline ve çözüm kanıtı geri döner. |
| 5:20–6:10 | `/staff/data-sources` | Gerçek şema kanıtı, source outage/stale fallback, audited original media. |
| 6:10–7:00 | `/staff/reports` | North-star, hedefler, formül tabanlı ROI, 6 haftalık pilot talebi. |

## Kontrol merkezi

`/demo/scenarios` tek yerde şunları sağlar:

- DemoClock +15 dk / +1 saat (yalnız local demo; shared server saatini değiştirmez),
- `water_events_fixture` kontrollü outage,
- aynı kaynağı refresh ile recovery,
- AI `unavailable` / `success`,
- yetkili demo reset,
- 7 dakikalık adımlara doğrudan geçiş.

## Fallback

- Ağ yok: local demo moduna dön, seed/cached snapshot ile ana hikâyeyi tamamla.
- Kaynak yok: outage kartını göster, cache'in korunduğunu ve freshness'in dürüstçe `unavailable` olduğunu göster.
- AI yok: manuel inceleme fallback'ini göster; kamuya yayın/ret otomatikleşmez.
- Kamera yok/izin reddi: fotoğrafsız erişilebilir akışa devam et.
- Shared server yok: personel mutasyonları read-only olur; vatandaş draft kaybolmaz.

## Kapanış talebi

Pilot birim + anonim örnek veri + 6 haftalık ölçümlü süreç onayı istenir. Üretim yayını, canlı 153 yazımı veya gerçek SLA garantisi istenmez.
