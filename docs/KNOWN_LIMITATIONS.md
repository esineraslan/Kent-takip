# İBB Kent Takip — Bilinen Sınırlar

## Release blocker / kanıt eksikleri

- Bu kaynak arşivinde `.git` metadata yok; gerçek commit hash doğrulanamıyor.
- Flutter/Dart/FVM executable bu çalışma ortamında yok; analyzer ve runtime suite burada çalıştırılamadı.
- Android APK/AAB, iOS build kanıtı ve web release build bu ortamda üretilemedi.
- Golden baseline insan tasarım onayı eksik.
- TalkBack/VoiceOver/NVDA, %200 text ve fiziksel cihaz permission recovery manuel kanıtları eksik.
- Üç tam jüri provası ve clean-device install kanıtı eksik.
- Teknik lider, ürün sahibi, tasarım ve güvenlik/KVKK yazılı son onayı alınmadı; release tag oluşturulmadı.

## Ürün/entegrasyon sınırları

- 153 / İstanbul Senin çift yönlü canlı entegrasyon değildir; `simulated_contract`.
- İETT GTFS demo kanıtı gerçek şemaya dayalı fixture'dır, canlı runtime bağımlılığı değildir.
- Kimlik/MFA demo adaptörüdür; kurumsal üretim kimliği değildir.
- Backend JSON demo server üretim HA/auth/veri saklama sistemi değildir.
- AI deterministic demo/rules veya kontrollü remote adapter sınırındadır; insan kararını devralmaz.
- SLA değerleri demo hedef aralığıdır, kurumsal garanti değildir.
- ROI hesaplayıcı sonuç uydurmaz; gerçek baseline/pilot maliyet girdileri gerekir.

Bu sınırlar P2/P3 iyileştirme olarak gizlenmez; üretim-ready iddiasını açıkça engeller.
