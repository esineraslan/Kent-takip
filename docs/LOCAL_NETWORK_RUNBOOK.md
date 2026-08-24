# Kent Takip shared demo — yerel ağ runbook

## Amaç

Bir telefon vatandaş istemcisi ile bir bilgisayar personel istemcisini aynı atomik JSON runtime'a bağlamak. Bu servis production backend değildir; sentetik demo kimlikleri ve yerel ağ için tasarlanmıştır.

## 1. Sunucuyu başlat

Repo kökünden:

```sh
flutter pub get
KT_DEMO_HOST=0.0.0.0 dart run apps/demo_server/bin/server.dart
```

Güvenli varsayılan bind `127.0.0.1:8080`, runtime `apps/demo_server/runtime/snapshot.json` olur. Fiziksel telefondan erişim için yukarıdaki gibi `KT_DEMO_HOST=0.0.0.0` bilinçli olarak verilir. Değiştirmek için `KT_DEMO_HOST`, `KT_DEMO_PORT`, `KT_DEMO_RUNTIME` ve `KT_DEMO_SEED` ortam değişkenleri kullanılır.

Kontrol:

```sh
curl http://127.0.0.1:8080/health/live
curl http://127.0.0.1:8080/health/ready
```

`ready` yanıtı `schemaVersion` ve güncel `revision` taşır. Bozuk active JSON varsa son geçerli `.bak` okunur; ikisi de geçersizse sentetik seed kullanılır.

## 2. Ağ adresini belirle

Bilgisayarın telefondan erişilen LAN IP'sini bulun; örnek `192.168.1.20`. Telefon ve bilgisayar aynı güvenilir Wi‑Fi ağında olmalıdır. Genel internete port yönlendirmesi yapmayın.

## 3. İstemcileri aç

Vatandaş mobil:

```sh
cd apps/kent_takip_app
flutter run --dart-define=APP_ENV=demo --dart-define=DEMO_DATA_MODE=shared --dart-define=DEMO_API_URL=http://192.168.1.20:8080
```

Personel web:

```sh
cd apps/kent_takip_app
flutter run -d chrome --dart-define=APP_ENV=demo --dart-define=DEMO_DATA_MODE=shared --dart-define=DEMO_API_URL=http://127.0.0.1:8080
```

Android emülatörü host için çoğunlukla `http://10.0.2.2:8080`, iOS Simulator `http://127.0.0.1:8080` kullanır. `tool/bootstrap_platforms.sh`, yalnız Android `debug` manifestine yerel HTTP istisnası bindirir; release manifesti cleartext izni almaz. iOS istemcide ATS gevşetilmez: fiziksel cihaz testi HTTPS reverse proxy ile yapılmalı veya kurumca onaylı, debug'a özel Xcode yapılandırması kullanılmalıdır.

## 4. İki istemci kanıtı

Sentetik vatandaş hesapları: ana `+90 555 000 11 22`, diğer `+90 555 000 22 33`, yeni `+90 555 000 33 44`; hepsi için demo OTP `123456`dır. Personel ekranındaki “Demo hesabını doldur” eylemi sentetik supervisor credential'larını yerleştirir ve MFA `654321`dır. Bu değerler yalnız demo kodunda geçerlidir.

1. Ana vatandaş hesabıyla bildirim oluşturun; takip numarasını kaydedin.
2. Diğer vatandaş hesabında pending gri pinin görünmediğini doğrulayın.
3. Personel kuyruğunda aynı takip numarasını açın.
4. Kategori, sorumlu birim ve insan karar gerekçesini doldurup doğrulayın.
5. Her iki istemcinin revision event sonrası REST snapshot'ı yeniden aldığını doğrulayın.
6. İki vatandaş görünümünde kırmızı public olayın, bildirim sahibinde güncel timeline'ın çıktığını doğrulayın.

WebSocket iş verisi taşımaz; yalnız `type=revision` ve sayı taşır. Güncel veri her zaman yetkili REST snapshot sorgusundan alınır.

## 5. Çatışma ve offline deneyi

- Aynı personel kaydını iki sekmede açın. Birincide karar verin; ikincideki stale karar `409 revision_conflict` dönmeli, güncel snapshot gösterilmeli ve açık retry istenmelidir.
- Vatandaş formunu doldurup ağı kesin. Gönderim başarısız olduğunda taslak cihazda kalmalı; ağ geldikten sonra “Taslağı gönder” aynı `clientMutationId` ile tek report üretmelidir.
- Personel ağı kesildiğinde son snapshot okunabilir kalır fakat mutation butonu devre dışı/salt okunur olmalıdır.

## 6. Sıfırlama ve olay müdahalesi

Runtime sıfırlamak için sunucuyu durdurup `apps/demo_server/runtime/` klasörünü güvenli biçimde başka yere taşıyın; silme yerine arşivleme hata analizi sağlar. Sunucu yeniden başladığında seed'den açılır.

Readiness 503 ise active, `.bak`, dosya izinleri ve seed checksum'u incelenir. Runtime dosyaları gerçek kişisel veri için kullanılmaz.
