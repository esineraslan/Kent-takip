# Bağımlılık kararı

| Bağımlılık | Amaç | Neden SDK yeterli değil | Lisans/riski |
|---|---|---|---|
| `crypto 3.0.6` | SHA-256 snapshot checksum | Dart core güvenilir SHA-256 sunmaz | BSD-3; küçük, saf Dart |
| `flutter_lints 6.0.0` | Resmî Flutter lint tabanı | SDK lint kural seti sağlamaz | BSD-3; yalnız geliştirme |
| `test 1.26.3` | Saf Dart unit/contract testleri | Dart SDK assertion runner değildir | BSD-3; yalnız geliştirme |
| `go_router 17.5.0` | URL, deep link, redirect ve iki ayrı shell | Navigator API tek başına merkezi guard/shell ağacını gereksiz karmaşıklaştırır | BSD-3; Flutter ekibi yayıncısı |
| `flutter_map 8.3.1` | Android/iOS/web ortak interaktif harita, pan/zoom, kamera ve marker katmanları | Sabit raster grid gerçek harita etkileşimi, programatik odak ve klavye/mouse zoom gereksinimini karşılamıyordu | BSD-3; vendor-neutral saf Flutter harita istemcisi |
| `latlong2 0.10.1` | Harita kamera/marker koordinat modeli | `flutter_map` ile kullanılan coğrafi `LatLng` tipi uygulama sınırında doğrudan referanslanır | Apache-2.0; küçük saf Dart geometri bağımlılığı |
| `provider 6.1.5+1` | Composition root ve dinlenen session/locale scope'ları | Manuel InheritedWidget yaşam döngüsü ve dispose yükünü azaltır | MIT; yaygın, küçük yüzey |
| `flutter_localizations` | Türkçe/İngilizce Material ve Widgets yerelleştirmesi | SDK'nın yerel bileşen metinleri delegeler olmadan yalnız İngilizcedir | Flutter SDK; BSD-3 |
| `path_provider 2.1.6` | Android/iOS/desktop kalıcı uygulama dizini | Mobil sandbox yolu platform API'sinden güvenle alınmalıdır | BSD-3; Flutter ekibi yayıncısı |
| `web 1.1.1` | Web localStorage adaptörü | `dart:html` yerine güncel JS interop binding'i gerekir | BSD-3; Dart ekibi yayıncısı |
| `http 1.6.0` | Shared REST istemcisi | Platformlar arası test edilebilir HTTP client gerekir | BSD-3; Dart ekibi yayıncısı |
| `image_picker 1.2.3` | Android/iOS/web kamera ve kesilen çekimi geri alma | Sistem kamerası, izin ve Android lost-data yaşam döngüsü platform kanalı gerektirir | Apache-2.0/BSD-3; Flutter ekibi yayıncısı |
| `web_socket_channel 3.0.3` | Revision event kanalı | Mobil/web ortak WebSocket API'si gerekir | BSD-3; Dart ekibi yayıncısı |
| `shelf 1.4.2` | Local demo HTTP server | Dart core düşük seviye HttpServer routing/middleware sağlamaz | BSD-3; yalnız demo server |
| `shelf_router 1.1.4` | REST route eşleme | Parametreli route sözleşmesini sadeleştirir | Apache-2.0; yalnız demo server |
| `shelf_web_socket 3.0.0` | Shelf WebSocket upgrade | Revision kanalını Shelf pipeline'ına bağlar | BSD-3; yalnız demo server |

Provider ve router WP-04'te; kalıcılık/senkron bağımlılıkları WP-06–07'de, kamera adaptörü WP-09'da kabul edilmiştir. 19 Ağustos 2026 harita hotfix'inde kanonik mimaride zaten seçilmiş `flutter_map` gerçek runtime bağımlılığına alınmış; `latlong2` koordinat tipi doğrudan kullanıldığı için açık bağımlılık olarak pinlenmiştir. Konum için ayrı bir cihaz-konum plugin'i eklenmemiştir.
