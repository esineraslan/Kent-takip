# İBB Kent Takip — Kanonik Ürün Tanımı

Belge durumu: Demo geliştirmesi için onaylı kanonik kaynak  
Belge sürümü: 1.1  
Tarih: 17 Ağustos 2026  
Yerine geçtiği kaynak: `docs/archive/product.txt`

## 1. Ürün konumu

**İBB Kent Takip**, 153 ve İstanbul Senin üzerinden gelen vatandaş bildirimlerini; resmî kent verileri, planlı çalışmalar ve belediye operasyonlarıyla tek bir `UrbanIncident` altında birleştiren doğrulanmış olay ve koordinasyon katmanıdır.

- Üretimde ayrı bir vatandaş uygulaması değildir; İstanbul Senin/153 içinde entegre modül olarak konumlanır.
- Jüri ve entegrasyon testlerinde bağımsız Flutter kabuğu olarak çalışır.
- 153'ün, İstanbul Senin'in veya AKOM'un yerine geçmez.
- Acil çağrı ya da otomatik müdahale hizmeti değildir.

Tek cümlelik değer önerisi:

> Parçalı kent sinyallerini tek doğrulanmış olayda birleştirir, mükerrer işi azaltır, doğru birime yönlendirmeyi hızlandırır ve çözüm durumunu vatandaşa geri taşır.

## 2. Ana problem

Aynı kent olayı farklı kanallardan tekrar tekrar gelebilir, farklı birimlere dağılabilir ve ortak doğrulanmış olay kaydı oluşmadığı için hem personel zamanı kaybolur hem vatandaş güncel durumu göremez.

## 3. Kullanıcılar ve yüzeyler

- Misafir: doğrulanmış aktif olayları, planlı çalışmaları ve resmî salt okunur uyarıları görür.
- Vatandaş: bildirim oluşturur, kendi bekleyen bildirimini görür, yapılandırılmış doğrulama sinyali verir ve çözümü takip eder.
- İncelemeci: kanıtı, kaynak otoritesini ve AI önerisini inceler; nihai kararı verir.
- Birim personeli: yönlendirme, saha ataması, SLA ve çözüm kanıtını yönetir.
- Planlama personeli: planlı çalışmayı ve açıklanabilir uzamsal/zamansal çakışmayı yönetir.
- Sistem yöneticisi: yetki, kaynak sağlığı, audit ve privacy taleplerini yönetir.
- `demo_supervisor`: yalnız demo ortamında izinleri rol bağlamıyla kullanan kurgu hesaptır.

## 4. Ürün omurgası

### 4.1 Ortak olay modeli

`UrbanIncident` aşağıdakileri tek kimlikte bağlar:

- bir veya daha fazla `CitizenReport`;
- 153/haricî başvuru referansları;
- resmî veya açık veri `SourceRecord` kayıtları;
- planlı çalışma ve iş emri referansları;
- yapılandırılmış `CorroborationSignal` kayıtları;
- sorumlu birim, SLA ve durum geçmişi;
- kamusal projection ve çözüm kanıtı;
- audit ve provenance.

Birleştirme vatandaşın takip numarasını değiştirmez.

### 4.2 Harita anlamları

| Gösterim | Anlam | Görünürlük |
|---|---|---|
| Kırmızı ünlem | İnsan tarafından doğrulanmış aktif olay | Vatandaş + personel |
| Sarı saat | Yayımlanmış planlı çalışma | Vatandaş + personel |
| Gri soru işareti | Kullanıcının doğrulama bekleyen kendi bildirimi | Sahibi + yetkili personel |
| Turuncu uyarı | Kritik dikkat sinyali; doğrulanmış olay değildir | Yalnız yetkili personel |

Renk tek başına anlam taşımaz; ikon, etiket ve semantics birlikte kullanılır.

### 4.3 Bildirim rotası

Fotoğraflı rota ana ve hızlı rotadır. Kamera kullanamayan veya güvenli biçimde fotoğraf çekemeyen kullanıcı **fotoğrafsız devam** edebilir; kayıt `manualReviewRequired=true` ile insan incelemesine gider. Galeri MVP kapsamı dışındadır.

Her gönderim:

1. kategori veya “Emin değilim” seçimi;
2. opsiyonel anlık fotoğraf ve gizlilik işlemi;
3. konum ve açıklama;
4. olası mükerrer olay seçimi veya yeni bildirim kararı;
5. kamusal gizlilik önizlemesi;
6. atomik kayıt;
7. değişmeyen takip numarası ve kişisel gri pin

üretir. Sunucu/yerel commit tamamlanmadan başarı gösterilmez.

### 4.4 Kapalı döngü

Vatandaş; alınma, inceleme, yönlendirme, saha, çözüm ve gerekçe adımlarını timeline üzerinden görür. Çözümde açıklama zorunlu, sonuç fotoğrafı opsiyonel ve gizlilik kontrollüdür. “Sorun devam ediyor” geri bildirimi otomatik yeniden açma yapmaz; insan incelemesine gider.

## 5. AI kapsamı

Jüri/MVP sürümünde AI yalnız üç dar yetenek sunar:

1. kategori ve sorumlu birim önerisi;
2. kamusal görsel için gizlilik tespiti/maskelemesi;
3. mükerrer olay adayı bulma.

Kritik dikkat, fotoğraf kalitesi, spam hızı, SLA aralığı ve planlı çalışma çakışması kural tabanlıdır. AI; ret, yaptırım, birleştirme, yayımlama veya durum geçişi yapamaz. Vatandaşa sade sonuç; personele skor, gerekçe ve model/config sürümü gösterilir.

Kişiye ait **vatandaş güven skoru yoktur**. Güvenlik için olay doğruluğuna katılmayan, kalıcı profil oluşturmayan ölçülü hız/tekrar sinyalleri kullanılabilir; insan kararı ve itiraz zorunludur.

## 6. Veri ve kaynak otoritesi

Kaynak önceliği:

1. olay sahibi yetkili kurum/birim;
2. İBB veya iştirakinin onaylı kaynağı;
3. lisanslı açık veri;
4. üçüncü taraf yardımcı/teyitsiz katman;
5. vatandaş bildirimi;
6. AI önerisi.

Teknik erişilebilirlik bir ön koşuldur, otorite sırasını değiştirmez. Her olay kaynak, zaman, tazelik, lisans ve doğrulama statüsü taşır. Elektrik kesintisi için yetkili kaynak/sözleşme bulunmadığından MVP filtresi kapalıdır.

Doğal afet ve kritik resmî uyarılar yalnız kurumca onaylı kaynaktan, salt okunur ve ayrı katmanda gösterilir. Vatandaş bildirimi resmî uyarı üretemez.

## 7. Demo ve üretim sınırı

- Flutter `3.47.0` ile Android, iOS ve modern web hedeflenir.
- Local mod CI ve çevrimdışı fallback'tir.
- Shared JSON mod iki cihazlı jüri ana sunumudur.
- Demo verisi deterministik ve sentetiktir; gerçek kişisel veri yoktur.
- Gerçek SMS, SSO, üretim backend'i, gerçek 153 çift yönlü entegrasyonu ve kurumsal iş emri entegrasyonu demo değildir.
- Bir gerçek veya gerçek şemaya bağlı kaynak kanıtı, sonraki WP-17 kabul kapısıdır.

## 8. Dil ve erişilebilirlik

Türkçe ve İngilizce tüm kullanıcı yüzeylerinde eksiksizdir; eksik veya yarım çeviri kabul edilmez. WCAG 2.2 AA, klavye, ekran okuyucu, reduced motion, %200 metin ve haritanın eşdeğer liste görünümü zorunludur.

## 9. Pilot ve ölçüm

North-star metric:

> Doğru birime ilk seferde yönlendirilip hedef sürede ilk insan incelemesi alan tekil kent olayı oranı.

Önerilen pilot: 6 hafta, tek operasyon bölgesi, yol yüzey hasarı ve su kaçağı/su birikmesi kategorileri, ilk hafta baseline. Ölçümler; ilk inceleme süresi, doğru yönlendirme, mükerrer işlem, çözüm aralığı, tekrar durum sorma, privacy kaçağı ve personel override oranıdır. Hedefler başarı iddiası değil pilot hipotezidir.

## 10. Kurumsal işletim varsayımı

RACI önerisi üretim onayı değildir:

- İş sahibi: 153/ilgili vatandaş deneyimi operasyonu;
- Teknik platform: İBB Bilgi İşlem;
- Kaynak verisi: ilgili kaynak birim;
- Kritik uyarı danışmanı: AKOM/kurumca yetkili operasyon;
- KVKK: kurumun veri sorumlusu;
- Pilot sponsor: seçilen operasyon dairesi.

Gerçek birim, bütçe ve 7/24 sorumluluklar yazılı insan onayı olmadan kesinleşmiş sayılmaz.

## 11. MVP kapsam dışı

- Ayrı vatandaş uygulaması dağıtımı;
- vatandaş güven puanı/gamification;
- otomatik olay doğrulama, ret veya ceza;
- AI ETA ve AI trafik tahmini;
- tam afet komuta sistemi;
- elektrik kesintisi filtresi;
- sosyal yorum/like sistemi;
- gerçek 153, SMS, SSO ve iş emri entegrasyonları;
- üretim backend'i ve gerçek veri saklama politikası.
