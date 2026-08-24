# WP-08 — Harita, arama ve projection raporu

## Uygulanan kaynak

- `MapSurface`: ayarlanabilir HTTPS OSM tile URL, 4 sn timeout, iki deneme ve yerel offline altlık.
- OSM attribution, trafik katmanı, resmî uyarılar için yetkili-source kontrolü, pin cluster ve selected detail.
- Incident/work/report projection'larında kırmızı/sarı/gri/turuncu rol kuralları; aktif work kırmızı, planlanan work sarı.
- 39 ilçe + seçili adres fixture'ı, Türkçe karakter normalizasyonu, 280 ms debounce ve “Bu alanda ara”.
- Pin detayı kaynak, tazelik, doğrulanma ve güncelleme bilgisi taşır; aynı veri tam erişilebilir listede bulunur.
- `sensitiveLocation=true` kaynakları server citizen projection'ında yaklaşık 3 ondalığa yuvarlanır.

## Öz-denetim düzeltmeleri

- İlk eski grid preview yönlendirmeden çıkmasına rağmen private sınıfları kaynakta kalmıştı; analyzer debt oluşturmaması için tamamen kaldırıldı.
- Test ortamında dış tile beklemesinin widget testini 4 saniye kilitleme riski kapatıldı; kontrollü offline yüzey kullanılır.
- Work `active` durumunun yalnız planned filtresine sıkışması düzeltildi.

## Durum

Kaynak uygulaması hazırdır. Flutter widget/golden, gerçek tile kesintisi ve Android/iOS/web smoke kanıtları bu ortamda SDK bulunmadığı için koşturulamadı; roadmap durumu `BLOCKED`.
