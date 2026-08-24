# WP-01 Raporu

Durum: BLOCKED  
Branch/commit: Arşiv teslimi; git commit oluşturulmadı.  
Kapsam: Flutter workspace, platform bootstrap, lint, test ve CI kaynakları.

## Uygulanan kaynaklar

- Flutter hedefi `.fvmrc` ve CI içinde kesin olarak `3.47.0 stable` sabitlendi.
- Dart workspace, üç saf Dart paketi, minimal Flutter uygulaması, web bootstrap, environment config, widget/integration/golden başlangıç yapısı oluşturuldu.
- CI; SDK doğrulama, platform üretimi, dependency çözümü, format, belge/codegen/seed/asset/secret kontrolleri, analyzer, unit/widget testleri, web/APK/iOS no-codesign build ve SBOM adımlarını içerir.
- Bağımlılık/lisans gerekçeleri `docs/DEPENDENCIES.md` içinde kayıtlıdır.

## Kabul ölçütleri ve testler

- Geçen yerel kontroller: Bash syntax, YAML/JSON parse, secret/PII taraması, doküman ve seed kontrolleri.
- Çalıştırılamayan zorunlu kontroller: `flutter doctor -v`, `flutter pub get`, `dart format`, `flutter analyze`, Dart/Flutter testleri ve üç platform build'i.
- Nedeni: çalışma ortamında Flutter/Dart SDK yoktur. Bu nedenle `pubspec.lock` ve Flutter'ın ürettiği Android/iOS shell dosyaları uydurulmamış; `tool/bootstrap_platforms.sh` ve CI ile üretilecek şekilde bırakılmıştır.

## Android/iOS/web, erişilebilirlik ve güvenlik

- Platform shell üretimi yalnız Flutter 3.47.0 ile çalışır; Android/web Linux CI, iOS macOS CI kapısı tanımlıdır.
- Minimal ekran `SafeArea` ve header semantics kullanır; ürün UI erişilebilirlik kapsamı WP-05'tedir.
- Credential yok; fixture sentetik ve kaynak taraması temizdir.

## Öz-denetim ve kalan sınırlar

- Öz-denetim 1: CI'da saf Dart test komutları Flutter testlerinden ayrıldı; codegen/asset guard eklendi.
- Öz-denetim 2: yanlış SDK sürümü, eksik secret ve platform paritesi fail-closed kapılarıyla ele alındı.
- P0/P1 kaynak bulgusu bilinmiyor; analyzer/build çalışmadan paket `COMPLETED` yapılamaz.
- Sonraki adım: Flutter 3.47.0 bulunan runner'da CI'yı yeşile getirip lock/platform dosyalarını kaynak paketine almak.
