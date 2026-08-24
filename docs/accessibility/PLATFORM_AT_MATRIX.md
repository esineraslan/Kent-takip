# WP-20 — Platform / Yardımcı Teknoloji Matrisi

Tarih: 17 Ağustos 2026

| Platform | AT / giriş | Kritik senaryo | Sonuç |
|---|---|---|---|
| Android | TalkBack + switch/keyboard | Giriş → bildirim → harita/list → takip | BLOCKED — cihaz/emülatör yok |
| Android | Kamera permission deny/allow + process recovery | Fotoğraf adımı | SOURCE_READY; MANUAL BLOCKED |
| iOS | VoiceOver | Giriş → bildirim → harita/list → takip | BLOCKED — macOS/iOS cihaz yok |
| iOS | Kamera permission deny/allow | Fotoğraf adımı | SOURCE_READY; MANUAL BLOCKED |
| Windows web | NVDA + Chrome + keyboard | Citizen/staff ana rotalar, 400% zoom | BLOCKED — Windows/NVDA yok |
| macOS web | VoiceOver + Safari + keyboard | Citizen/staff ana rotalar, 400% zoom | BLOCKED — macOS/Safari yok |
| Generic Flutter test | 200% text, 48×48 target, high contrast | WP-20 widget kaynakları | TEST_SOURCE_READY; SDK yok |
| Golden matrix | 8 viewport × TR/EN-long | Reflow/layout drift | SOURCE_READY; baseline/golden run BLOCKED |

## Kamera/location notu

Kamera adaptörü `requestFullMetadata:false`, `retrieveLostData()` ve `AppLifecycleState.resumed` recovery yolunu taşır. Gerçek platform permission davranışı cihaz/browser olmadan PASS sayılmaz.

Mevcut demo GPS/location plugin kullanmaz; vatandaş konumu harita/koordinat seçimi ile verir. Bu nedenle native location permission lifecycle bu sürüm için uygulanabilir test değildir; ileride location plugin eklenirse ayrı Android/iOS/web permission matrisi zorunludur.
