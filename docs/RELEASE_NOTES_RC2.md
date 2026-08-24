# İBB Kent Takip — RC2 Hotfix Release Notes

**Aday sürüm:** `0.2.0-rc.2+1`  
**Tarih:** 19 Ağustos 2026  
**Durum:** BLOCKED — runtime CI/insan onayı olmadan tag/publish yok

## Düzeltilen P1 sorunlar

- Citizen ve staff haritası gerçek interaktif kamera yüzeyine geçirildi: pan/drag, pinch, mouse-wheel ve zoom düğmeleri.
- İlçe/mahalle/adres araması haritayı seçilen koordinata programatik olarak odaklıyor; exact match, Enter ve sonuç seçimi aynı akışı kullanıyor.
- Citizen OTP ve staff MFA ekranlarında sabit demo doğrulama kodu artık gösterilmiyor.
- Desktop staff sidebar taşması giderildi; KVKK ve Ayarlar kaydırılabilir navigasyon içinde erişilebilir.

## Regresyon koruması

- `test/map_auth_sidebar_regression_test.dart`
- `integration_test/wp04_auth_shell_test.dart`
- `tool/validate_hotfix_2026_08_19.py`
- CI: `2026-08-19 map/auth/sidebar regression gate`

## Release sınırı

Bu RC2, WP-00–WP-24 kapsamını değiştirmeyen client P1 hotfix aday sürümüdür. Flutter/Dart toolchain bu çalışma ortamında bulunmadığından analyzer/widget/integration/build kanıtları üretilmiş sayılmaz; eksik runtime kanıtları nedeniyle release kararı `BLOCKED` kalır.
