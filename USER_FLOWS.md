# İBB Kent Takip — Kanonik Kullanıcı Akışları

Belge durumu: Demo geliştirmesi için onaylı kanonik kaynak  
Belge sürümü: 1.1  
Tarih: 17 Ağustos 2026  
Yerine geçtiği kaynak: `docs/archive/akış.txt`

## 1. Genel ilkeler

- Doğrulanmamış vatandaş girdisi başka vatandaşa görünmez.
- AI önerir; insan doğrular, birleştirir, reddeder veya yayımlar.
- Takip numarası merge ve yönlendirmede korunur.
- Her mutasyon timeline ve gerekiyorsa audit üretir.
- Commit tamamlanmadan başarı gösterilmez.
- Acil tehlikede uygulama resmî acil kanala yönlendirir; otomatik çağrı başlatmaz.

## 2. Misafir haritası

1. Kullanıcı izin vermeden İstanbul haritasını açar.
2. Kırmızı doğrulanmış olayları ve sarı planlı işleri görür.
3. Resmî uyarılar ayrı salt okunur katmanda, kaynak ve zamanla görünür.
4. Arama, filtre ve erişilebilir liste kullanılabilir.
5. Bildir veya Bildirimlerim seçildiğinde telefon doğrulamasına gider ve dönüş rotası korunur.

## 3. Vatandaş girişi

1. Telefon girilir ve kısa KVKK bilgisi gösterilir.
2. Demo ortamında deterministik OTP, üretimde haricî kimlik servisi kullanılır.
3. Hatalı denemeler ölçülü bekleme üretir.
4. Başarılı doğrulama kullanıcının başladığı adıma döner.

## 4. Sorun bildirimi

1. Kullanıcı kategori veya “Emin değilim” seçer.
2. Fotoğraf çekebilir veya **Fotoğrafsız devam** seçer.
3. Fotoğrafta kalite ve gizlilik işlenir; başarısız privacy işlemi kamusal kopya üretmez.
4. Konum önerilir; izin yoksa haritadan/adresten seçilir.
5. Açıklama doğrulanır.
6. AI varsa kategori/birim ve mükerrer aday önerir; yoksa manuel rota devam eder.
7. Yakın olay varsa kullanıcı “Bunu ben de yaşıyorum”, “Artık görünmüyor”, “Konum farklı” veya “Yeni bildirim” seçer.
8. Kamusal önizleme ve veri özeti onaylanır.
9. Tek transaction `CitizenReport`, medya referansı, analiz, timeline, bildirim ve audit kayıtlarını oluşturur.
10. Takip numarası ve yalnız sahibine görünen gri pin gösterilir.

Hata davranışları:

- Kamera reddi: fotoğrafsız manuel rota açık kalır.
- Konum reddi: manuel seçim yapılır.
- AI hatası: aynı veriyle manuel inceleme, tekrar gönderim yoktur.
- Bağlantı hatası: taslak korunur; aynı `clientMutationId` ile tek gönderim yapılır.
- İstanbul dışı konum: uyarı ve manuel inceleme; otomatik ret yoktur.

## 5. 153/haricî başvurunun ortak olaya bağlanması

1. Adaptör `ExternalApplicationRef` ve kaynak zamanını getirir.
2. Kayıt doğrulanır ve provenance ile saklanır.
3. Sistem olası `UrbanIncident` adaylarını gösterir.
4. Personel yeni olay veya mevcut olaya bağlama kararını verir.
5. Haricî başvuru kimliği ile Kent Takip kimliği birlikte korunur.
6. Gerçek entegrasyon yoksa durum açıkça “simüle sözleşme” olarak etiketlenir.

## 6. Belediye incelemesi

1. Personel olay odaklı kuyruğu açar.
2. Bağlı vatandaş bildirimlerini, kaynak kayıtlarını, doğrulama sinyallerini ve iş referanslarını görür.
3. Kamusal medya varsayılan; orijinal medya yalnız izin + gerekçe + audit ile açılır.
4. AI önerisi personel kararından ayrı gösterilir.
5. Personel doğrular, gerekçeli reddeder/kapsam dışı bırakır, ek bilgi ister, birleştirir veya yönlendirir.
6. Stale kayıt sessizce güncellenemez.

## 7. Doğrulama ve yayın

1. Kategori, sorumlu birim, gerekçe ve SLA aralığı doğrulanır.
2. Yeni `UrbanIncident` oluşturulur veya mevcut olaya bağlanır.
3. Kamusal projection yalnız güvenli alanları içerir.
4. Genel kırmızı pin yayımlanır.
5. Vatandaşın takip numarası korunur, timeline ve bildirimi güncellenir.

## 8. Merge ve corroboration

- AI/kural motoru yalnız aday verir; otomatik merge yoktur.
- Personel ana olayı seçer; döngü engellenir.
- Her vatandaş kendi takip numarasını korur.
- Yapılandırılmış doğrulama bir sosyal beğeni değildir ve kişi kimliği kamusal olmaz.

## 9. Yönlendirme, saha ve SLA

1. Olay İBB birimine veya gerekli minimum veriyle ilçe belediyesine yönlendirilir.
2. Takip numarası ve sorumluluk geçmişi korunur.
3. Saha ekibi/haricî iş emri referansı atanır.
4. SLA ilk inceleme, yönlendirme, saha başlangıcı ve çözüm saatlerini ölçer.
5. Gecikme gerekçesi ve yeni tahmini aralık görünür; garanti dili kullanılmaz.

## 10. Çözüm ve vatandaş geri bildirimi

1. Personel çözüm açıklamasını ve opsiyonel gizlilik kontrollü sonucu ekler.
2. Vatandaş timeline'da çözüm kanıtını görür.
3. “Çözüldü” veya “Devam ediyor” geri bildirimi verir.
4. “Devam ediyor” otomatik reopen yapmaz; inceleme kuyruğu ve audit üretir.

## 11. Planlı çalışma

1. Personel alan, zaman, birim ve açıklama girer.
2. Sistem yol/hat/diğer iş çakışmalarını kural tabanlı ve açıklanabilir gösterir.
3. Personel kamusal önizlemeyi onaylar.
4. Sarı planlı pin yayımlanır; saat geldiğinde kırmızı aktif olur.
5. Tamamlandığında canlı haritadan kalkar, geçmiş korunur.

## 12. Resmî uyarı

1. Yalnız kurumca onaylı adaptör salt okunur uyarı üretir.
2. Kaynak, zaman ve acil çağrı sınırı açıkça gösterilir.
3. Vatandaş bildirimi uyarıyı oluşturamaz veya değiştiremez.

## 13. Privacy ve hesap talepleri

KVKK erişim/düzeltme/silme ve otomatik değerlendirme itirazları ayrı takip numarası alır. Hesap silme yeniden doğrulama ister ve bekleme durumunda yeni report'u engeller. Gerçek imha süreci üretim hukuk/operasyon onayı gerektirir.

## 14. Temel görünürlük değişmezleri

| Kayıt | Sahibi | Diğer vatandaş | Personel |
|---|---:|---:|---:|
| Bekleyen report | Gri | Görmez | Yetkiye/kuyruğa göre |
| Kritik dikkat report'u | Gri + acil sınır | Görmez | Turuncu |
| Doğrulanmış aktif incident | Kırmızı | Kırmızı | Kırmızı |
| Yayımlanmış planlı iş | Sarı | Sarı | Sarı |
| Resmî uyarı | Salt okunur | Salt okunur | Kaynak ayrıntılı |
