# WP-05 Raporu

## Sonuç

`DESIGN.md` renk, tipografi, spacing, radius, elevation, motion ve breakpoint tokenlarıyla kodun tek tasarım kaynağına bağlandı. Ortak button/input/chip/card/banner/tab/modal/sheet/table/queue/timeline, beş sistem durumu, dört pin + selected + cluster, responsive primitive, focus/shortcut/live-region ve reduced-motion/high-contrast davranışları eklendi. `/demo/components` iç galerisi kuruldu.

## Güvenlik ve erişilebilirlik kararları

- Durum bileşenleri renk yanında ikon ve metin taşır.
- Pin accessible name'i durum + kategori + konum içerir.
- Focus halkası marka magentasıyla 3 px görünürdür; klavye sırası traversal group ile korunur.
- Motion `MediaQuery.disableAnimations` durumunda sıfıra iner, bilgi kaybolmaz.
- Resmî İBB logo/font dosyaları verilmediği için ekrandan türetilmedi. `BRAND_ASSET_MANIFEST.json` onaylı dosya ve checksum kapısıdır.
- Literal marka rengi/font denetimi `tool/validate_design_system.py` ile CI'a bağlandı.

## Kanıt kaynakları

- `test/wp05/design_system_test.dart`: semantics, yüzde 200 metin ve klavye focus.
- `test/goldens/wp05_matrix_test.dart`: 4 citizen + 4 staff viewport, TR/uzun EN matrisi.
- `test/goldens/README.md`: onaylı font sonrası baseline üretme/doğrulama komutları.

## Çıkış kapısı

Kaynak uygulaması tamamlandı. Flutter 3.47.x çalıştırma kanıtı ve onaylı Rubik/Urbanist baseline'ları bu ortamda bulunmadığı için roadmap durumu `BLOCKED` tutulur.
