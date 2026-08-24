# İBB Kent Takip — Golden test altyapısı

Flutter test bağlamı `flutter_test_config.dart` ile tek noktadan başlatılır. WP-05 matrisi citizen için 320×568, 390×844, 768×1024 ve 1024×768; staff için 1024×768, 1280×800, 1440×900 ve 1600×1000 viewportlarını kapsar. Türkçe ve uzun İngilizce varyantları aynı test fixture'ında çalıştırılır.

Resmî Rubik/Urbanist dosyaları ve lisans kanıtı henüz sağlanmadığı için baseline PNG üretimi bilinçli olarak bloke edilmiştir. Onaylı fontlar eklendikten sonra:

```sh
flutter test apps/kent_takip_app/test/goldens/wp05_matrix_test.dart --update-goldens --dart-define=KT_ENABLE_GOLDENS=true
flutter test apps/kent_takip_app/test/goldens/wp05_matrix_test.dart --dart-define=KT_ENABLE_GOLDENS=true
```

CI, font manifesti `approved` olmadan golden kapısını yeşil saymaz; yapısal viewport, yüzde 200 metin, semantics ve focus testleri her çalışmada aktiftir.
