# WP-11 — Vatandaş bildirim akışı raporu

## Uygulanan kaynak

- Referans mobil tasarımlara göre beş adım: Tür → Fotoğraf → Konum → Detay → Kontrol.
- Yedi kategori ve “Emin değilim”; fotoğraf çek/yeniden çek/fotoğrafsız devam; İstanbul bounds kontrolü.
- AI processing/failure, öneriyi kullanıcı düzeltmesi, duplicate candidate için mevcut olayı doğrula/yeni bildirim seçimi.
- Gizlilik durumu ve kamusal önizleme davranışı review adımında açıkça gösterilir.
- Report + media ref + AI + timeline + notification + audit tek snapshot revizyonunda commit edilir.
- Media byte upload idempotent iki fazlıdır; ağ hatasında komut ve byte staging store'da korunur.
- `clientMutationId` retry ve on dakikada üçten fazla gönderimin reddedilmeyip manual review'a gitmesi.
- Başarı ekranı tracking numarası ve takip deep-link'i sunar.

## Öz-denetim düzeltmeleri

- WP-06 minimal formu yönlendirmede bırakmak yerine gerçek wizard'a geçirildi; eski ölü form kaynağı kaldırıldı.
- E2E yürüyüş senaryosu yeni fotoğrafsız beş adımlı rota ve detay ekranına taşındı.
- AI/medya yokluğunda sahte başarı yerine insan inceleme bayrağı zorunlu tutuldu.

## Durum

Kaynak akış tamamlandı. Flutter analyzer/widget/E2E ve üç platform smoke kanıtı yok; `BLOCKED`.
