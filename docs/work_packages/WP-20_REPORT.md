# WP-20 — TR/EN, WCAG 2.2 AA ve platform paritesi

## Uygulananlar

- Uygulama UI yüzeylerindeki doğrudan kullanıcı metinleri ortak TR/EN kataloğa taşındı; iki dil 671 ortak key taşır.
- CI, key set parity, empty/missing key, EN katalogda Türkçe karakter izi, UI içinden bilinmeyen key ve doğrudan hard-coded user copy için fail eder.
- Tarih/saat, sayı ve telefon locale biçimleyicisi eklendi; çoğul helper unit test kaynağı eklendi.
- Kamera ve domain hata kodları locale güvenli mesajlara çevrildi; İngilizce modda ham Türkçe exception gösterilmez.
- Focus traversal, visible focus ve `Scrollable.ensureVisible` ile focus-not-obscured davranışı bağlandı.
- Button/IconButton hedefleri minimum 48×48; padded tap target korunur.
- Semantics/live region, reduced motion ve high contrast yolları kaynak kapısına bağlandı.
- Harita `MapViewMode.accessibleList` ile aynı projection kayıtlarını erişilebilir eş listede sunar.
- Kamera lifecycle resume + `retrieveLostData` recovery ve metadata istememe (`requestFullMetadata:false`) kaynak kanıtına bağlandı.
- 200% text, target size ve high-contrast widget test kaynağı; mevcut 8 viewport TR/EN-long golden matrisi korunur.
- VPAT-Lite, WCAG 2.2 AA ve platform/AT matrisi oluşturuldu.

## Uzman incelemesinde düzeltilenler

- İlk localization turunun kaçırdığı wizard validation, staff queue/sort/decision, planlama formu, semantics/hint/tooltip/banner metinleri de kataloğa alındı.
- Sadece Türkçe karakter taramasıyla kaçabilecek kısa İngilizce/Türkçe ortak literal'lar için doğrudan UI copy CI scanner'ı eklendi.
- Odak alanının sanal klavye altında kalması riskine scroll-to-visible recovery eklendi.
- 48×48 target requirement tema seviyesinde IconButton/FilledButton/OutlinedButton'a bağlandı.
- Kamera raw platform hata mesajlarının locale sızdırması engellendi.

## Test ve kanıt

- `apps/kent_takip_app/test/wp20/localization_accessibility_test.dart`
- `tool/check_localization.py`
- `tool/check_accessibility_source.py`
- `docs/accessibility/VPAT_LITE.md`
- `docs/accessibility/WCAG_2_2_AA_MATRIX.md`
- `docs/accessibility/PLATFORM_AT_MATRIX.md`

## Durum

Kaynak uygulaması tamamlandı. Flutter SDK/device/browser/AT bulunmadığı için 200% runtime widget, 400% web zoom, keyboard-only full-route, TalkBack/VoiceOver/NVDA/Safari, golden diff, native permission recovery ve Android/iOS/web build kapıları çalıştırılamadı. Kanonik durum `BLOCKED`.
