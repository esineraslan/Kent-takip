# 19 Ağustos 2026 — Harita / Auth / Sidebar Hotfix

## Kapsam

Bu hotfix WP-00–WP-24 kaynak tabanını değiştirmeden dört kullanıcı tarafından gözlenen P1 kullanılabilirlik/regresyon sorununu giderir.

1. Citizen ve staff haritasında pan/zoom çalışmaması.
2. İlçe/mahalle/adres aramasının harita kamerasını sonuç koordinatına taşımaması.
3. Citizen OTP ve staff MFA sabit demo kodlarının giriş yüzeyinde görünmesi.
4. Staff sidebar alt taşmasının KVKK/Ayarlar destinasyonlarını kapatması.

## Uygulanan çözüm

- Sabit 2x2 tile grid kaldırıldı ve kanonik mimaride seçilmiş `flutter_map` ortak harita yüzeyi runtime'a alındı.
- Touch drag, pinch, mouse-wheel ve paket keyboard map interactions açık; ayrıca 48x48 yakınlaştır/uzaklaştır kontrolleri bulunur.
- `MapController` ile arama sonucu seçimi/Enter/exact-match sonucu ilgili koordinata zoom 13.2 ile odaklanır. “Bu alanda ara” ve “Tüm İstanbul’u göster” kamera/filtre durumuyla uyumludur.
- Marker/cluster/official alert overlay artık coğrafi koordinat katmanında haritayla birlikte hareket eder.
- OTP/MFA sabit kodu gösteren `_DemoCodeNotice` kaldırıldı. Auth servisinde sabit fixture credential kalması demo determinism'i içindir; UI bunu açığa çıkarmaz.
- Desktop sidebar navigasyonu `Expanded + Scrollbar + ListView` oldu; footer ayrı tutulur ve 48 px minimum navigation target korunur.

## Regresyon kanıtı

- `test/map_auth_sidebar_regression_test.dart`
  - interaktif map widget + zoom kontrolleri
  - pan sonrası “Bu alanda ara”
  - `Sancaktepe` exact search focus
  - demo kodu görünmeme
  - 1600x800 desktop staff shell'de KVKK/Ayarlar erişimi ve overflow exception olmaması
- `integration_test/wp04_auth_shell_test.dart` sabit demo kodunun citizen/staff doğrulama yüzeylerinde görünmediğini ayrıca kontrol eder.

## Kalite sınırı

Bu çalışma ortamında Flutter/Dart executable olmadığı için yeni bağımlılık çözümü, `dart format`, `flutter analyze` ve gerçek widget/integration çalıştırması yerelde kanıtlanamaz. Kaynak statik kapıları çalıştırılır; runtime kapısı release için BLOCKED kalır.
