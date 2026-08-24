# İBB Kent Takip - Stratejik Eleştiri, Tutarlılık Denetimi ve 9/10 Jüri Planı

Belge durumu: Stratejik değerlendirme ve bağlayıcı düzeltme önerisi  
Belge sürümü: 1.0  
Tarih: 17 Ağustos 2026  
İncelenen kaynaklar: `product.txt`, `akış.txt`, `DESIGN.md`, `ARCHITECTURE.md`, `RULES.md`, `DATA_SOURCES.md`  
Bakış açısı: 20 yıllık IT girişimcisi + 15 yıllık kurumsal teknoloji ve jüri değerlendirme deneyimi  

---

## 1. Yönetici özeti

### Kısa hüküm

Proje şu an **iyi tasarlanmış, kapsamlı ve gösterilebilir bir demo**; fakat henüz güçlü biçimde farklılaştırılmış, kurumsal sahipliği belirlenmiş ve ölçülebilir değeri kanıtlanmış bir ürün değildir.

Bugünkü hâliyle tahmini jüri puanı: **6,2/10**  
Bu belgedeki P0 ve P1 kararları uygulanırsa gerçekçi hedef: **9,1/10**

### Sert gerçek

Jürinin ilk sorusu büyük olasılıkla şudur:

> “Vatandaş zaten İstanbul Senin ve 153 Çözüm Merkezi üzerinden başvuru yapıp başvurusunu takip edebiliyorsa neden ayrı bir uygulamaya ihtiyaç var?”

İBB'nin güncel Çözüm Merkezi yüzeyi, İstanbul Senin üzerinden başvuru, canlı destek ve başvuru sorgulama sunduğunu açıkça belirtiyor. İstanbul Senin de tüm İBB hizmetlerini tek uygulamada toplama iddiasıyla konumlanıyor. Bu nedenle “fotoğraf ve konumla sorun bildir, takip et” tek başına farklılaştırıcı değildir. [İBB Çözüm Merkezi](https://cozummerkezi.ibb.istanbul/), [İstanbul Senin](https://istanbulsenin.istanbul/)

Daha kritik ikinci gerçek: İBB Afet İşleri ve Risk Yönetimi Dairesi, 2026 itibarıyla AI destekli risk analizi, CBS, gerçek zamanlı görüntü, komuta paneli ve Android/iOS saha uygulamalarını kapsayan “Akıllı Acil Durum Müdahale Sistemi” projesini yürütüyor. Dolayısıyla projenin doğal afet/AI tarafı da “ilk kez yapılan çözüm” gibi sunulamaz. [AKOM - Afet Yönetimi Sürecine Yapay Zekâ Desteği](https://akom.ibb.istanbul/haberler/afet-yonetimi-surecine-yapay-zeka-destegi/)

### Doğru stratejik dönüşüm

İBB Kent Takip ayrı bir “şikâyet uygulaması” olarak değil, şu şekilde konumlanmalıdır:

> **İstanbul Senin ve 153 başvuru kanallarını; açık/kurumsal kent verileri, planlı çalışmalar ve belediye operasyonlarıyla birleştiren, doğrulanmış ortak olay görünümü ve insan denetimli karar desteği katmanı.**

Başka bir ifadeyle:

- 153'ün alternatifi değil;
- İstanbul Senin'in yerine geçen yeni bir super-app değil;
- AKOM'un afet komuta sisteminin rakibi değil;
- mevcut kanallardan gelen sinyalleri ortak bir kent olayı altında birleştiren ve sonucu vatandaşa kapalı döngüyle geri taşıyan entegrasyon katmanıdır.

### 9/10'a çıkaracak beş temel hamle

1. **Ürünü ayrı uygulamadan İstanbul Senin/153 üzerine oturan modül olarak yeniden konumlandırın.**
2. **AI kapsamını daraltın ve üç kanıtlanabilir işe odaklayın:** kategori/birim önerisi, gizlilik maskeleme, mükerrer aday bulma.
3. **“Vatandaş güven skoru” ve herkese açık AI puanları kararını geri alın.** Bunlar jüri önünde adalet, KVKK ve güven sorunu üretir.
4. **Bir gerçek veri kaynağı + bir gerçek operasyon senaryosu + ölçülebilir pilot planı gösterin.** Yedi sahte kaynak yerine bir doğrulanmış entegrasyon daha değerlidir.
5. **Demo sonunda yalnız ekran değil, sonuç metriği gösterin:** daha hızlı ilk inceleme, daha doğru yönlendirme, daha az mükerrer iş ve daha şeffaf vatandaş takibi.

---

## 2. Mevcut skor kartı

| Boyut | Ağırlık | Mevcut puan | Sert değerlendirme |
|---|---:|---:|---|
| Problemin önemi | %15 | 8,5 | İstanbul ölçeğinde gerçek ve önemli problem. |
| Farklılaşma | %15 | 4,0 | 153/İstanbul Senin ile ciddi fonksiyon çakışması var. |
| Kurumsal uyum ve sahiplik | %10 | 5,5 | Hangi birimin ürün sahibi ve bütçe sahibi olduğu net değil. |
| Ürün bütünlüğü | %10 | 7,5 | Akışlar güçlü; kapsam gereğinden geniş ve bazı kararlar çelişkili. |
| Teknik uygulanabilirlik | %10 | 8,0 | Demo mimarisi güçlü; bazı son RULES kararları güvenilirliği geriye götürüyor. |
| AI inandırıcılığı | %10 | 4,5 | Çok fazla AI iddiası, veri ve değerlendirme kanıtı yok. |
| Veri inandırıcılığı | %10 | 4,5 | Gerçek endpoint, sahip, lisans ve sözleşme henüz yok. |
| UX ve erişilebilirlik | %8 | 8,5 | Belgelerin en güçlü taraflarından biri. |
| Güvenlik/KVKK/yönetişim | %7 | 6,5 | İyi ilkeler var; güven skoru ve puan görünürlüğü riski artırıyor. |
| Pilot ve ölçülebilir etki | %5 | 4,0 | KPI listesi var, baseline ve deney tasarımı yok. |
| **Ağırlıklı toplam** | **%100** | **6,2/10** | Teknik demo güçlü; ürün savunması zayıf. |

Bu puan “fikir kötü” anlamına gelmez. Jüriye sunulan ürün tanımının, mevcut kurumsal gerçekliğe göre yeterince keskin olmadığını gösterir.

---

## 3. Projenin gerçekten güçlü tarafları

Jüri anlatısında korunması gereken güçlü yönler:

### 3.1 Doğrulanmış ve doğrulanmamış bilgiyi ayırması

- Vatandaşın bekleyen kaydı yalnız kendisine gri pin olarak görünür.
- Kamuya yalnız belediye doğrulamasından geçmiş kırmızı olay çıkar.
- Kritik fakat doğrulanmamış olay personele turuncu görünür.
- Planlı çalışma sarı pinle ayrılır.

Bu, yanlış bilginin halka yayılması riskini iyi yönetir.

### 3.2 Kapalı döngü takip

Vatandaş yalnız başvuru yapmıyor; aynı takip numarasıyla:

- inceleme;
- yönlendirme;
- saha çalışması;
- çözüm;
- sonuç açıklaması

aşamalarını izleyebiliyor. Bu yön, “şikâyet formu”ndan daha değerlidir.

### 3.3 İnsan denetimli AI

AI'ın nihai ret, yaptırım veya yayımlama yapmaması doğru karardır. Kritik olayın insan incelemesini atlayamaması korunmalıdır.

### 3.4 Gizlilik tasarımı

Orijinal ve kamusal medya ayrımı, yüz/plaka maskeleme, maskeleme başarısızsa medyayı halka açmama ve orijinal erişimini audit etme güçlüdür.

### 3.5 Erişilebilirlik

WCAG 2.2 AA, klavye, ekran okuyucu, reduced motion, yüzde 200 metin ve haritanın liste alternatifi projeyi ortalama hackathon çözümünden ayırır.

### 3.6 Gerçek durum değiştiren demo

Vatandaş bildiriminin belediye kuyruğuna düşmesi, personel doğrulaması ve gri pinin kırmızı genel olaya dönüşmesi, yalnız statik ekran göstermeyen iyi bir demo omurgasıdır.

---

## 4. Jüri gözünde neden zayıfız?

### 4.1 P0 - Mevcut hizmetle ürün çakışması

**Sorun:** İstanbul Senin ve Çözüm Merkezi hâlihazırda başvuru, talep, canlı destek ve başvuru sorgulama sunuyor. İBB, İstanbul Senin'i vatandaşın tüm hizmetlere ulaştığı ana uygulama olarak konumluyor. [İBB Çözüm Merkezi](https://cozummerkezi.ibb.istanbul/), [İstanbul Senin - Ana Platform](https://istanbulsenin.istanbul/)

**Jürinin duyacağı şey:**

> “Var olan uygulamanın daha görsel bir kopyası.”

**Çözüm:** Ayrı uygulama iddiasını bırakın. Mobil yüzeyi “İstanbul Senin içinde Kent Takip mini uygulaması veya entegre modül” olarak sunun. Flutter demo bağımsız çalışabilir; fakat ürün stratejisi bağımsız dağıtım olmamalıdır.

### 4.2 P0 - Değer önerisi özellik listesi düzeyinde

**Sorun:** Harita, fotoğraf, pin, AI, kuyruk ve bildirim anlatılıyor; fakat belediyeye hangi operasyon maliyetini ne kadar düşürdüğü anlatılmıyor.

**Jürinin duyacağı şey:**

> “Çok özellik var, fakat hangi darboğazı çözdüğü belli değil.”

**Çözüm:** Tek ana problem cümlesi kullanın:

> “Aynı kent olayı farklı kanallardan tekrar tekrar geliyor; farklı birimlere dağılıyor; ortak doğrulanmış olay kaydı oluşmadığı için hem personel zamanı kayboluyor hem vatandaş güncel durumu göremiyor.”

### 4.3 P0 - AI iddiası aşırı geniş

AI'dan aynı anda şunlar bekleniyor:

- kategori;
- birim;
- risk;
- öncelik;
- kalite;
- fotoğraf-açıklama-konum-zaman uyumu;
- mükerrerlik;
- kötüye kullanım;
- yüz/plaka/telefon maskeleme;
- çözüm süresi;
- trafik ve toplu taşıma etki analizi.

Bu, tek demo için inandırıcı değildir. Eğitim verisi, ground truth, hata analizi ve model sahipliği olmadan “AI her şeyi yapıyor” izlenimi verir.

**Çözüm:** İlk jüri sürümünde yalnız üç AI yeteneğini kanıtlayın:

1. Kategori ve sorumlu birim önerisi
2. Kamusal görsel için gizlilik maskeleme
3. Mükerrer olay adayı bulma

Risk sinyali kural tabanlı “dikkat etiketi” olsun. ETA ve trafik etkisi AI tahmini değil, açıkça etiketli kural/uzamsal çakışma hesabı olsun.

### 4.4 P0 - Vatandaş güven skoru ürünü zayıflatıyor

**Sorun:** Geçmiş belediye kararlarına göre vatandaş puanlamak; hatalı belediye kararını, bölgesel eşitsizliği, cihaz/erişim farkını ve yeni kullanıcı dezavantajını sisteme taşıyabilir.

Bu puanın vatandaş ekranında gösterilmesi:

- kullanıcıyı sistemi “oynamaya” teşvik eder;
- düşük puanlı kişide dışlanma algısı yaratır;
- AI'ın gerçeği değil kişiyi değerlendirdiği izlenimi verir;
- KVKK ve otomatik değerlendirme itirazı yükünü artırır;
- jüriye gereksiz etik saldırı alanı açar.

**Çözüm:** MVP'den vatandaş güven skorunu çıkarın. Gerekirse yalnız spam hız sınırı, tekrar medya hash'i ve doğrulanmış kötüye kullanım kararını kullanan hesap güvenliği sinyali tutun. Bu sinyal:

- olayın doğruluk puanına katılmamalı;
- vatandaş ekranında puan olmamalı;
- kalıcı profil oluşturmamalı;
- insan kararı ve itirazla yönetilmelidir.

### 4.5 P0 - Tüm AI puanlarını iki role aynı gösterme kararı hatalı

`RULES.md` içinde bütün AI puanlarının vatandaşa ve personele aynı gösterilmesi kabul edilmiştir. Bu karar `DESIGN.md` ve ilk ürün ilkeleriyle çelişir.

**Neden yanlış:**

- Personel operasyon sinyaline, vatandaş ise anlaşılır süreç bilgisine ihtiyaç duyar.
- Risk skoru, kötüye kullanım skoru ve model güveni vatandaşa ham gösterildiğinde yanlış yorumlanır.
- Aynı sayı iki rol için aynı anlamı taşımaz.
- Model puanları kesinlik gibi algılanabilir.

**Çözüm:**

- Vatandaş: “Fotoğraf yeterli”, “Kategori önerildi”, “Benzer olay bulundu”, “İnsan incelemesi gerekiyor”.
- Personel: ayrı skorlar, gerekçe kodları, veri kalitesi ve model sürümü.
- Vatandaşa itiraz edilebilir sonuç ve sade açıklama; personele operasyon ayrıntısı.

### 4.6 P0 - Veri kaynağında “en kolay erişilen” önceliği belediye için savunulamaz

`DATA_SOURCES.md`, demo kaynağında teknik erişilebilirliği resmî otoritenin önüne koyuyor.

**Jüri riski:**

> “Resmî kent haritasında üçüncü taraf verisini hangi hukuki ve operasyonel yetkiyle yayımlıyorsunuz?”

**Çözüm:** Kaynak otoritesi şöyle olmalıdır:

1. Olay sahibi yetkili kurum/birim
2. İBB veya iştirakinin onaylı kaynağı
3. Lisanslı açık veri
4. Üçüncü taraf veri - yalnız yardımcı/teyitsiz katman
5. Vatandaş bildirimi - kamuya çıkmadan insan doğrulaması

Teknik erişilebilirlik kaynak seçiminin koşulu olabilir, otorite sırasının önüne geçmemelidir.

### 4.7 P0 - Gerçek entegrasyon kanıtı yok

Veri belgeleri iyi tasarlanmış, ancak endpoint, gerçek örnek kayıt, lisans, teknik sahip ve başarıyla çekilmiş tek bir güncel kaynak yok.

**Jürinin duyacağı şey:**

> “Bütün veri seed ise bu çalışan ürün değil, iyi hazırlanmış senaryo.”

**Çözüm:** Yedi kaynağı simüle etmek yerine bir kaynağı gerçekten entegre edin. En iyi adaylar:

- bir açık planlı çalışma veri seti;
- trafik yoğunluk/olay verisi;
- kurumca sağlanan anonim örnek kesinti verisi.

Canlı kaynak yoksa gerçek İBB açık veri şeması üzerinden kayıtlı fixture ve doğrulanmış import gösterin; “canlı” demeyin.

### 4.8 P0 - Kurumsal ürün sahibi ve bütçe sahibi yok

Teknik roller var, fakat ürünün gerçek hayatta sahibi net değil.

Sorular:

- Ürünün iş sahibi 153 Çözüm Merkezi mi?
- Bilgi İşlem mi?
- Yol Bakım mı?
- AKOM mu?
- Veri ve harita operasyonunu kim 7/24 yönetecek?
- Yanlış kırmızı pin için kim sorumlu?
- Birim SLA'sını kim tanımlayacak?

**Çözüm:** RACI ekleyin. Önerilen:

- İş sahibi: 153 Çözüm Merkezi/Halkla İlişkiler
- Teknik platform sahibi: İBB Bilgi İşlem
- Veri sahibi: ilgili kaynak birim
- Kritik olay danışmanı: AKOM
- KVKK sahibi: kurum veri sorumlusu
- Pilot sponsor: seçilen operasyon dairesi

Gerçek birimler kurumla teyit edilmeden kesinmiş gibi sunulmamalıdır.

### 4.9 P0 - Pilot yok, yalnız KPI listesi var

`PRODUCT` ölçülecek metrikleri listeliyor; ancak:

- mevcut baseline;
- hedef değer;
- örneklem;
- kontrol grubu;
- pilot ilçe/kategori;
- süre;
- karar eşiği

yok.

**Çözüm:** Bölüm 13'teki pilot tasarımını kullanın.

### 4.10 P1 - Kapsam bir MVP için aşırı büyük

Tek demo şu anda:

- iki kullanıcı dünyası;
- 42 akış;
- 27 ekran;
- altı kuyruk;
- AI;
- medya gizliliği;
- harita;
- offline;
- shared server;
- çoklu dil;
- üç platform;
- veri entegrasyonları;
- planlama/etki analizi;
- saha iş emri;
- KVKK ve itiraz

içeriyor.

Bu genişlik kaliteyi ve ana hikâyeyi zayıflatır.

**Çözüm:** Kodda yüzeyler bulunabilir; jüri hikâyesi tek dikey kesit olmalıdır:

> vatandaş bildirimi -> gizlilik -> mükerrer aday -> insan doğrulaması -> doğru birime yönlendirme -> ortak kırmızı olay -> vatandaşa çözüm güncellemesi

Diğer özellikleri “hazır yetenek” olarak gösterin, ana demoda dolaşmayın.

### 4.11 P1 - Doğal afet ile kent sorunu aynı ürün sınırında karışıyor

Ürün “acil çağrı sistemi değildir” diyor; `DATA_SOURCES.md` ise deprem, sel, yangın gibi doğal afet olaylarını zorunlu kaynak yapıyor. AKOM'un 7/24 ve kurumsal koordinasyon görevi bulunuyor. [AKOM Kuruluş ve Görevler](https://akom.ibb.istanbul/kurulus/)

**Risk:** Vatandaş kırmızı pini acil müdahale garantisi sanabilir.

**Çözüm:** İki katman kesin ayrılmalıdır:

- **Kent olayları:** Kent Takip'in vatandaş ve operasyon alanı
- **Resmî kritik uyarılar:** Yalnız yetkili kaynaktan salt okunur, farklı banner/katman; vatandaş bildirimiyle üretilemez

Afet komuta fonksiyonu ürün kapsamı dışında kalmalıdır.

### 4.12 P1 - Zorunlu anlık fotoğraf erişilebilirlik ve kullanım engeli

Kamera zorunluluğu spam azaltır; fakat:

- görme veya motor engeli olan kullanıcı;
- kamerası arızalı/düşük kaliteli cihaz;
- güvenli biçimde fotoğraf çekilemeyen konum;
- daha sonra bildirim ihtiyacı;
- ağ/kamera izin sorunu

için başvuruyu tamamen engeller.

**Çözüm:**

- Fotoğraflı hızlı rota ana rota olsun.
- “Fotoğrafsız devam et” erişilebilir alternatif olsun ve manuel kuyruğa gitsin.
- Galeri yalnız metadata/provenance uyarısı ve daha yüksek inceleme gereksinimiyle opsiyonel olabilir.
- Acil durumda kullanıcı fotoğraf çekmeye teşvik edilmemelidir.

### 4.13 P1 - Çözüm süresi tahmini için veri yok

Tarihsel iş emri ve çözüm süresi verisi olmadan AI ETA inandırıcı değildir.

**Çözüm:** İlk sürümde:

- ilgili birimin konfigüre ettiği hizmet aralığı;
- mevcut kuyruk yükü;
- kategori bazlı basit SLA

üzerinden aralık gösterin. “AI tahmini” yerine “operasyonel tahmini aralık” deyin. Geçmiş veri oluşunca model değerlendirilir.

### 4.14 P1 - Etki analizi iddiası fazla büyük

Trafik ve toplu taşıma etkisi için yol ağı, hat geometrisi, zaman çizelgesi ve çakışma verisi gerekir. Seed üzerinde “trafik etkisi yüksek” yazmak ikna edici değildir.

**Çözüm:** İlk demo “tahmin” değil, açıklanabilir uzamsal çakışma gösterir:

- çalışma poligonu hangi yol segmentlerini kesiyor;
- hangi durak/hat buffer içinde;
- aynı zaman aralığında hangi planlı işlerle çakışıyor;
- önerilen alternatif zaman yalnız kural tabanlıdır.

### 4.15 P1 - Tek süper yetkili hesap demo için kolay, kurumsal gerçeklik için riskli

Tek hesap demo akışını hızlandırır; ancak jüride gerçek rol yönetimi yok izlenimi verebilir.

**Çözüm:** Tek “demo supervisor” hesabı kullanılabilir; ekranda işlem sırasında aktif rol bağlamı gösterilir:

- İncelemeci görünümü
- Birim personeli görünümü
- Planlama görünümü

Audit'te gerçek permission adı kaydedilir. Üretim tasarımında ayrı görevler korunur.

### 4.16 P1 - Tek dosyaya doğrudan overwrite gereksiz kalite gerilemesi

`ARCHITECTURE.md` atomik yazım ve yedek kurtarma tanımlarken `RULES.md` daha sonra tek dosya overwrite'ı kabul ediyor.

Bu değişiklik hiçbir kullanıcı değeri yaratmıyor; yalnız veri bozulması riskini artırıyor.

**Çözüm:** Atomik geçici dosya + doğrulama + son geçerli yedek yaklaşımına dönün. Webde çift slot veya eşdeğer güvenli commit kullanın. “Demo” veri bütünlüğünü önemsiz yapmaz.

### 4.17 P1 - Dağıtım stratejisi yanlış

Yeni bir vatandaş uygulamasını indirtmek pahalıdır. İBB'nin zaten İstanbul Senin super-app stratejisi varken bağımsız uygulama:

- kullanıcı edinme;
- tekrar giriş;
- güven;
- bakım;
- mağaza operasyonu;
- bildirim izni

maliyetini ikiye katlar.

**Çözüm:** Vatandaş yüzeyini İstanbul Senin mini-app/entegre hizmet olarak konumlandırın. Belediye paneli ayrı iç uygulama olabilir.

### 4.18 P2 - Elektrik kesintisi ürün filtresinde var, veri planında yok

`PRODUCT` ve kullanıcı akışlarında elektrik kesintisi bulunuyor; `DATA_SOURCES.md` zorunlu kaynakları arasında yok. Elektrik dağıtımı İBB dışı kurumları da kapsar.

**Çözüm:** Ya yetkili veri ve sözleşme bulunana kadar elektrik filtresini MVP'den çıkarın ya da kaynağı, sahipliği ve doğrulama statüsünü ekleyin.

### 4.19 P2 - Çoklu dil kararları uyumsuz

`PRODUCT` çoklu dili MVP dışı bırakıyor; `RULES.md` Türkçe ve İngilizceyi zorunlu yapıyor.

**Çözüm:** Jüri sürümü için Türkçe tam; İngilizce yalnız sunum rotası veya tüm ekranlarda tamamlanmış gerçek localization olmalıdır. Yarım çeviri kabul edilmemelidir.

### 4.20 P2 - Ürün adı ve kapsam belgelerde güncel değil

`product.txt` eski “İstanbul Kent Sorunları Yönetim Platformu” adını ve hâlâ açık teknoloji kararlarını içeriyor; `DESIGN.md` “İBB Kent Takip” adını kesinleştiriyor.

**Çözüm:** Nihai belgeler tek ad, tek kapsam ve tek karar kaynağına göre sürümlenmelidir.

---

## 5. Belgeler arası tutarsızlık matrisi

| Konu | Çelişen belgeler | Risk | Kesin çözüm önerisi |
|---|---|---|---|
| Ürün adı | `product.txt` / `DESIGN.md` | Sunumda dağınık marka | Her yerde **İBB Kent Takip** |
| Ürün konumu | Ayrı mobil uygulama / İstanbul Senin ilişkisi | Mevcut ürünü tekrar etme | İstanbul Senin içinde modül; demo bağımsız shell |
| Veri deposu | PRODUCT “veritabanına aktarılır” / ARCHITECTURE “veritabanı yok” | Demo kapsam belirsiz | Demo JSON; üretim API/DB geçiş dikişi |
| Ana veri modu | ARCHITECTURE local varsayılan / DATA shared ana sunum | Çalıştırma belirsizliği | CI local; jüri shared; ikisi açık runbook |
| JSON güvenliği | ARCHITECTURE atomik/dual-slot / RULES overwrite | Veri bozulması | ARCHITECTURE güvenli yazımına dön |
| AI görünürlüğü | PRODUCT/DESIGN rol bazlı / RULES herkese aynı | Güven ve etik riski | Vatandaşta sade sonuç; personelde ayrıntı |
| AI çalışma şekli | ARCHITECTURE deterministik fake / RULES harici servis zorunlu olabilir | Çevrimdışı demo riski | Jüri rotası deterministic; gerçek servis opsiyonel yan demo |
| Çoklu dil | PRODUCT MVP dışı / RULES TR+EN | Eksik ekran/çeviri | Tek kesin kapsam belirle |
| Staff hesapları | ARCHITECTURE 5 rol / DATA tek yetkili | Yetki modelinin görünmemesi | Tek supervisor + rol bağlamı simülasyonu |
| Kaynak önceliği | Kurumsal doğrulama / kolay erişim | Resmî bilgi riski | Otorite ve lisans önce |
| Elektrik kesintisi | PRODUCT/flow var / DATA yok | Ölü filtre | Kaynak ekle veya MVP'den çıkar |
| Afet sınırı | Ürün acil değil / DATA afet zorunlu | Yanlış güven ve sorumluluk | Resmî salt okunur uyarı katmanı |
| Kamera | Zorunlu / erişilebilirlik iddiası | Kullanıcı dışlama | Fotoğrafsız manuel alternatif |
| Vatandaş desteği | PRODUCT MVP dışında / DATA “Bunu da yaşıyorum” | Akış çelişkisi | Kontrollü corroboration kararını açıkça ekle |
| Tasarım kesinliği | DESIGN token kabulü / RULES yaklaşık uyum | Görsel drift | Kritik jüri ekranları birebir; ikincil ekranlar toleranslı |

### Belge yönetimi için yeni kural

“En yeni belge otomatik kazanır” yaklaşımı tehlikelidir. Yanlış yazılmış yeni dosya güvenlik kararını sessizce geçersiz kılabilir.

Yerine:

1. Her önemli karar `ADR-XXX` kaydı taşımalıdır.
2. Değişiklik sahibi ve onaylayan yazılmalıdır.
3. Hangi eski kararın geçersiz olduğu açıkça belirtilmelidir.
4. Güvenlik/KVKK kararı tarih sırasıyla geçersiz kılınamaz.
5. CI, belge başlıklarındaki ad/sürüm/kapsam uyumsuzluklarını kontrol etmelidir.

---

## 6. Yeni ürün konumlandırması

### 6.1 Ürün adı

**İBB Kent Takip**

Alt tanım:

> Doğrulanmış Kentsel Olay ve Operasyon Koordinasyon Katmanı

### 6.2 Tek cümlelik değer önerisi

> İBB Kent Takip, 153 ve İstanbul Senin üzerinden gelen vatandaş bildirimlerini resmî kent verileri ve planlı çalışmalarla aynı olay kaydında birleştirerek mükerrer işi azaltır, doğru birime yönlendirmeyi hızlandırır ve doğrulanmış çözüm durumunu harita üzerinden vatandaşa geri taşır.

### 6.3 Rakip değil tamamlayıcı

| Mevcut yapı | Rolü | Kent Takip'in eklediği değer |
|---|---|---|
| İstanbul Senin | Vatandaş giriş ve hizmet dağıtım kanalı | Kent Takip mini-app/harita yüzeyi |
| 153 Çözüm Merkezi | Başvuru, iletişim ve talep yönetimi | Ortak olay, mükerrer kümeleme, harita ve kapalı döngü projection |
| İBB Açık Veri/kurum servisleri | Kaynak veri | Provenance, tazelik, normalization ve olay birleştirme |
| AKOM | Afet ve kritik koordinasyon | Yalnız yetkili resmî uyarı katmanı; afet komutasını üstlenmez |
| Birim iş emri sistemleri | Saha operasyonu | Vatandaşa sade durum ve çözüm geri bildirimi |

### 6.4 Savunulabilir farklılaştırıcı

Ürünün asıl yeniliği **Verified Urban Incident Graph - Doğrulanmış Kentsel Olay Grafiği** olmalıdır.

Bir olay grafiği şunları tek kimlik altında bağlar:

- bir veya daha fazla vatandaş bildirimi;
- 153 başvuru referansları;
- resmî veri kaydı;
- planlı belediye çalışması;
- mükerrer adaylar;
- sorumlu birim;
- saha iş emri referansı;
- kamusal durum;
- çözüm kanıtı;
- audit ve veri kaynağı.

Böylece ürün “yeni başvuru formu” değil, parçalı sinyallerden ortak operasyon gerçeği üreten katman olur.

---

## 7. 9/10 ürün omurgası

### 7.1 Vatandaş yüzeyi

Jüri/MVP için zorunlu:

- İstanbul Senin/153 entegrasyonu anlatısı;
- doğrulanmış aktif ve planlı olay haritası;
- kaynak ve son güncelleme bilgisi;
- fotoğraflı veya erişilebilir fotoğrafsız bildirim;
- gizlilik önizlemesi;
- benzer olayı görme;
- kontrollü “Bunu ben de yaşıyorum” doğrulaması;
- takip numarası ve timeline;
- çözüm kanıtı ve “Sorun gerçekten çözüldü mü?” geri bildirimi;
- resmî uyarılar için ayrı salt okunur katman.

### 7.2 Belediye yüzeyi

Jüri/MVP için zorunlu:

- olay odaklı kuyruk; yalnız tek tek başvuru listesi değil;
- aynı olay altındaki kaynak ve vatandaş sinyalleri;
- AI önerisi + gerekçe + belirsizlik;
- kaynak otoritesi ve tazeliği;
- mükerrer birleştirme;
- tek tık doğru birim yönlendirme;
- SLA saatinin başlangıcı ve gecikme riski;
- public preview;
- çözüm kanıtı;
- audit;
- demo supervisor içinde rol bağlamı.

### 7.3 Yeni eklenmesi gereken bileşenler

#### A. Ortak olay kimliği

`IncidentCluster` veya `UrbanIncident` modeli:

```text
UrbanIncident
├─ source records
├─ citizen reports
├─ confirmations
├─ municipal work/order references
├─ responsible unit
├─ public projection
├─ SLA/timeline
├─ resolution evidence
└─ audit/provenance
```

#### B. Kaynak otorite rozeti

Her olayda:

- Belediye doğruladı
- Resmî veri kaynağı
- Vatandaş bildirimi - incelemede
- Kaynak gecikmiş

gibi açık rozet bulunmalıdır.

#### C. Kontrollü corroboration

“Beğeni/upvote” değil:

- Aynı sorun burada devam ediyor
- Artık görünmüyor
- Konum farklı

gibi yapılandırılmış, kötüye kullanıma dayanıklı sinyal.

#### D. Çözüm kanıtı

Kapanışta:

- personel çözüm açıklaması;
- opsiyonel sonuç fotoğrafı;
- çözüm zamanı;
- vatandaş doğrulaması;
- tekrar açma nedeni

bulunmalıdır.

#### E. SLA ve eskalasyon

AI ETA yerine:

- kategori/birim hedef aralığı;
- ilk inceleme süresi;
- yönlendirme süresi;
- saha başlangıcı;
- çözüm süresi;
- gecikme nedeni

ölçülmelidir.

#### F. Entegrasyon sözleşmesi

En az mock düzeyinde:

- `externalApplicationId`
- `externalWorkOrderId`
- `sourceSystem`
- `sourceUpdatedAt`
- `syncStatus`
- `lastSyncError`

alanları eklenmelidir.

---

## 8. AI sistemi için zorunlu daraltma

`AI_SYSTEM.md` tamamlanmadan proje AI ürünü olarak jüriye sunulmamalıdır.

### 8.1 Jüri sürümünde gösterilecek AI

| Yetenek | Girdi | Çıktı | İnsan rolü | Kanıt |
|---|---|---|---|---|
| Kategori/birim önerisi | Fotoğraf + açıklama + konum | İlk 3 öneri ve gerekçe | Personel seçer/değiştirir | Etiketli test seti, top-1/top-3 doğruluk |
| Gizlilik maskeleme | Fotoğraf | Kamusal kopya + bulunan alanlar | Başarısızsa manuel inceleme | Yüz/plaka kaçırma oranı |
| Mükerrer aday | Konum + zaman + kategori + görsel/text benzerliği | Aday olaylar | Personel birleştirir | Precision/recall ve yanlış merge=0 |

### 8.2 Kural tabanlı olarak sunulacaklar

- kritik dikkat sinyali;
- fotoğraf kalite kontrolü;
- kategori bazlı SLA aralığı;
- planlı çalışma çakışması;
- hız limiti/spam sinyali.

### 8.3 Jüri sürümünde ertelenecekler

- kişiye ait vatandaş güven puanı;
- otomatik kötü niyet kararı;
- AI çözüm süresi tahmini;
- AI trafik etkisi tahmini;
- serbest metin üretimiyle otomatik kamu duyurusu;
- otomatik kritik olay doğrulaması.

### 8.4 AI kabul eşikleri - önerilen pilot hedefleri

Bu değerler mevcut başarı iddiası değil, pilot kapısıdır:

| Metrik | Pilot hedefi |
|---|---:|
| Kategori top-1 doğruluk | ≥ %85 |
| Kategori top-3 doğruluk | ≥ %95 |
| Kritik dikkat recall | ≥ %95 |
| Gizlilikte yüz/plaka kaçırma | Kamuya çıkan örnekte 0 kritik kaçırma |
| Mükerrer aday precision | ≥ %85 |
| Yanlış otomatik merge | 0; çünkü otomatik merge yok |
| Staff override oranı | Ölçülür; ilk pilotta ≤ %20 hedef |
| P95 analiz süresi | ≤ 5 saniye |
| AI yokken veri kaybı | 0 |

Tüm metrikler kategori, ilçe, gece/gündüz, fotoğraf kalitesi ve cihaz kırılımında incelenmelidir.

---

## 9. Veri stratejisi

### 9.1 Jüri için minimum gerçeklik

Demo şu üç veri sınıfını aynı anda göstermelidir:

1. **Gerçek şemaya bağlı bir kaynak:** En az bir İBB/açık veri örneği
2. **Deterministik seed:** Sunumun bozulmaması için
3. **Canlı vatandaş işlemi:** Demo sırasında oluşturulan kayıt

Üçü de kaynak rozetiyle ayrılmalıdır.

### 9.2 Kaynak kayıt kartı

Her kaynak için jüriye gösterilebilecek tek sayfalık kart:

```text
Kaynak adı:
Kaynak sahibi:
Kullanım hakkı:
Erişim yöntemi:
Şema sürümü:
Son başarılı çekim:
Güncellik hedefi:
Karantina oranı:
Fallback:
Ürün sorumlusu:
Teknik sorumlu:
```

### 9.3 Öncelik

Jüri sürümünde bütün entegrasyonları taklit etmek yerine:

- bir gerçek kaynak;
- bir geciken kaynak senaryosu;
- bir yetkili manuel giriş;
- bir vatandaş bildirimi

göstermek yeterlidir.

### 9.4 Doğal afet verisi

Doğal afet katmanı yalnız:

- AKOM/AFAD veya kurumca onaylı kaynak;
- salt okunur;
- açık kaynak ve zaman damgası;
- “acil çağrı yerine geçmez” sınırı;
- vatandaş bildirimiyle resmîleşmeme

kurallarıyla çalışmalıdır.

---

## 10. Güvenlik, etik ve kötüye kullanım ekleri

### 10.1 Tehdit modeli eklenmeli

En az şu saldırılar incelenmelidir:

- aynı fotoğrafın yeniden kullanılması;
- GPS spoofing;
- bot/otomatik bildirim;
- aşırı gönderim;
- uygunsuz/şiddet içeren medya;
- EXIF ve gizli metadata sızıntısı;
- yüz/plaka maskeleme kaçırması;
- belediye hesabı yetki yükseltme;
- orijinal medya URL'sinin tahmin edilmesi;
- JSON/import ile yetki veya audit manipülasyonu;
- model/prompt enjeksiyonu içeren açıklama;
- yanlış veri kaynağının resmî gibi sunulması;
- mükerrer birleştirme ile yanlış olay kapatma.

### 10.2 Koruma kararları

- Medyadan EXIF varsayılan olarak temizlenir.
- Orijinal medya kimliği tahmin edilemez ve süreli yetkiyle açılır.
- Kamu projection'ında telefon, hesap ve tam hassas adres bulunmaz.
- İnsan override gerekçesi zorunludur.
- Kritik değişiklikte dört göz ilkesi uygulanır.
- İçe aktarılan JSON imza/checksum, schema ve sentetik veri kontrolünden geçer.
- AI açıklama metni komut değil veri olarak ele alınır.
- Rate limit hesap + cihaz + IP sinyallerini ölçülü biçimde kullanır.

### 10.3 Adalet kontrolü

Vatandaşın hizmete erişimi:

- ilçe;
- cihaz kalitesi;
- fotoğraf kalitesi;
- yeni/eski kullanıcı;
- dil;
- engel durumu

nedeniyle sistematik olarak düşmemelidir. Pilot raporunda bu kırılımlar zorunludur.

---

## 11. Kurumsal işletim modeli

### 11.1 RACI önerisi

| İş | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| Vatandaş başvuru deneyimi | Ürün ekibi/153 operasyonu | Ürün sahibi | Tasarım + KVKK | İlgili birimler |
| Teknik platform | Yazılım ekibi | Teknik lider/Bilgi İşlem | Güvenlik | Ürün sahibi |
| Kaynak entegrasyonu | Veri entegrasyon ekibi | Kaynak sahibi birim | Teknik lider | Operasyon |
| AI değerlendirme | AI/ML ekibi | Teknik lider + ürün sahibi | KVKK + saha uzmanı | İnceleme personeli |
| Kritik uyarı katmanı | Yetkili afet/operasyon birimi | Kurumsal yetkili | Hukuk + teknik ekip | Vatandaş |
| Kamuya yayımlama | Yetkili inceleme personeli | Operasyon yöneticisi | Kaynak sahibi | Vatandaş |
| Pilot ölçüm | Ürün analitiği | Pilot sponsor | Personel + kullanıcı araştırması | Yönetim |

Gerçek kurum rolleri teyit edilince tablo güncellenmelidir.

### 11.2 İşletim soruları cevaplanmadan üretim iddiası yok

- 7/24 kritik kuyruğu kim izleyecek?
- Yanlış yayımlanan olayı kim geri çekecek?
- Birim yönlendirme sözlüğünü kim güncelleyecek?
- SLA aralıklarını kim onaylayacak?
- Kaynak kesintisini kim takip edecek?
- Model drift'ini kim ölçecek?
- İtirazı kim çözecek?
- Audit erişimini kim denetleyecek?

---

## 12. Ölçülebilir değer ve ROI

### 12.1 North-star metric

> **Doğru birime ilk seferde yönlendirilip hedef sürede ilk insan incelemesi alan tekil kent olayı oranı**

Bu metrik başvuru sayısını değil, çözüme giden kaliteli operasyonu ölçer.

### 12.2 Ana metrikler

| Boyut | Metrik |
|---|---|
| Hız | Medyan ilk insan inceleme süresi |
| Doğruluk | İlk yönlendirmede doğru birim oranı |
| Verim | Tekil olay başına mükerrer başvuru sayısı |
| Şeffaflık | Vatandaşa güncel durum gösterilen olay oranı |
| Çözüm | Hedef aralıkta kapanan olay oranı |
| Kalite | Staff AI override oranı |
| Güven | Kamuya yanlış/kişisel veri içeren medya çıkma oranı |
| Deneyim | Tekrar durum sorma başvurusu oranı |
| Memnuniyet | Çözüm sonrası CSAT ve “gerçekten çözüldü” oranı |

### 12.3 ROI formülü

İlk pilotta parasal iddia yerine ölçülebilir formül kullanılmalıdır:

```text
Aylık operasyon kazancı =
  (azalan triage dakikası × aylık başvuru × dakika personel maliyeti)
+ (azalan yanlış yönlendirme × yeniden işlem maliyeti)
+ (azalan mükerrer kayıt × kayıt başına işlem maliyeti)
+ (azalan tekrar durum sorma çağrısı × çağrı maliyeti)
- (altyapı + AI + harita + SMS + destek + operasyon maliyeti)
```

Gerçek veri olmadan “yüzde X tasarruf” iddiası yapılmamalıdır.

---

## 13. Önerilen pilot

### 13.1 Pilot kapsamı

| Alan | Öneri |
|---|---|
| Süre | 6 hafta |
| Bölge | 1 pilot ilçe veya sınırları net bir operasyon bölgesi |
| Kategori | Yol çukuru/yüzey hasarı + su kaçağı/su birikmesi |
| Personel | 5-10 inceleme/operasyon kullanıcısı |
| Veri | Anonimleştirilmiş geçmiş örnek + sentetik edge-case + canlı kontrollü test |
| Karşılaştırma | AI destekli grup ile mevcut süreç/baseline |
| Vatandaş | Kontrollü kullanıcı testi; gerçek yayın için kurum onayı |

Pilot ilçe ürün kararıyla değil, veri ve operasyon erişimi en güçlü birimle seçilmelidir.

### 13.2 Pilot başlangıç ölçümü

İlk hafta yalnız baseline:

- başvuru hacmi;
- kategori dağılımı;
- yanlış yönlendirme;
- ilk inceleme süresi;
- mükerrer oranı;
- tekrar durum sorma;
- ortalama personel işlem süresi

ölçülür.

### 13.3 Başarı kapıları

Önerilen hipotezler:

- Medyan triage süresinde en az %30 iyileşme
- İlk yönlendirme doğruluğunda en az 15 yüzde puan artış
- Mükerrer kayıt başına personel işleminde en az %30 azalma
- Kritik dikkat senaryolarında en az %95 recall
- Kamuya çıkan medyada sıfır kritik kişisel veri kaçağı
- Staff AI override oranı en fazla %20
- Vatandaşların en az %85'inin durum/timeline'ı doğru anlaması
- P0/P1 erişilebilirlik ve güvenlik hatası 0

Bu değerler başarılmış sonuç olarak değil, test edilecek hipotez olarak sunulmalıdır.

### 13.4 Go/No-Go

Pilot sonunda:

- Gizlilik kaçağı varsa: **No-Go**
- Kritik olay recall hedefi karşılanmıyorsa: risk sinyali üretimde kullanılmaz
- Yönlendirme iyileşmiyorsa: AI devreden çıkarılır, kategori sözlüğü yeniden çalışılır
- Personel süre kazanmıyorsa: UI/queue tasarımı yeniden değerlendirilir
- Kullanıcı timeline'ı anlamıyorsa: kamu projection dili sadeleştirilir

---

## 14. Jüri demosu - 7 dakikalık ideal akış

### 0:00-0:40 - Problem ve mevcut sistemle fark

> “İBB'nin başvuru kanalı zaten var. Sorun yeni bir form eksikliği değil; aynı olaya ait başvuruların, planlı çalışmaların ve kaynak verilerinin tek doğrulanmış operasyon kaydında birleşmemesi.”

Mevcut 153/İstanbul Senin yapısını rakip değil giriş kanalı olarak gösterin.

### 0:40-1:20 - Ortak kent görünümü

- Kırmızı doğrulanmış olay
- Sarı planlı çalışma
- Kaynak rozeti
- Son güncelleme
- Erişilebilir liste görünümü

### 1:20-2:30 - Vatandaş bildirimi

- Örnek fotoğraf
- Yüz/plaka maskeleme karşılaştırması
- Konum
- Kısa açıklama
- Benzer olay önerisi
- “Yeni bildir” veya kontrollü “Bunu ben de yaşıyorum”

### 2:30-3:15 - AI'ın sınırı

Yalnız üç yeteneği gösterin. Açıkça söyleyin:

> “AI karar vermiyor; personelin önündeki araştırma ve sınıflandırma yükünü azaltıyor.”

### 3:15-4:30 - Belediye olay çalışma alanı

- Aynı olaya bağlı birden fazla sinyal
- Resmî veri + vatandaş kaydı
- Kategori/birim önerisi
- Gizlilik sonucu
- Personel doğrulaması ve yönlendirme

### 4:30-5:20 - Kapalı döngü

- Vatandaşın gri pini kırmızı ortak olaya bağlanır
- Takip numarası korunur
- Timeline güncellenir
- Çözüm kanıtı eklenir

### 5:20-6:10 - Kaynak kesintisi ve güven

- Bir canlı/gerçek şema kaynağı
- Bayat kaynak etiketi
- Sistem çalışmaya devam ediyor
- Orijinal medyanın audit erişimi

### 6:10-7:00 - Ölçüm ve pilot

- North-star metric
- 6 haftalık pilot
- Hedef iyileşmeler
- Tek net talep: pilot veri ve operasyon sponsoru

Demo sonunda “uygulamayı beğendiniz mi?” değil şu istek yapılmalı:

> “Bir pilot birim, anonim örnek veri ve 6 haftalık ölçümlü süreç için onay istiyoruz.”

---

## 15. Jürinin soracağı zor sorular ve cevap omurgası

### 15.1 “Bu zaten 153 değil mi?”

**Cevap:**

> “153 başvuru ve iletişim kanalıdır; Kent Takip onun yerine geçmez. Kent Takip, 153 dahil farklı kanallardan gelen kayıtları resmî kaynaklar ve planlı çalışmalarla aynı olay kimliğinde birleştirir, mükerrer operasyonu azaltır ve doğrulanmış kent durumunu harita/timeline olarak vatandaşa geri taşır.”

### 15.2 “Neden ayrı uygulama?”

**Cevap:**

> “Üretim stratejimiz ayrı uygulama değil, İstanbul Senin içinde modüldür. Bağımsız Flutter kabuğu jüri ve entegrasyon testleri içindir.”

### 15.3 “AI neyi gerçekten yapıyor?”

**Cevap:**

> “Üç dar iş: kategori/birim önerisi, kamusal medya gizlilik maskelemesi ve mükerrer aday bulma. Ret, yaptırım ve kamuya yayımlama insan kararıdır.”

### 15.4 “AI yanlışsa ne olur?”

**Cevap:**

> “AI sonucu öneridir. Düşük güven manuel kuyruğa gider; kritik sinyal insan incelemesini atlayamaz; maskeleme başarısızsa fotoğraf kamuya çıkmaz; personel override'ı audit edilir.”

### 15.5 “Gerçek veri var mı?”

**Cevap:**

> “Demo deterministik seed ile güvenli çalışıyor; ayrıca bir gerçek/açık veri şemasını adaptör üzerinden bağlıyoruz. Her kayıtta kaynak, güncellik ve doğrulama statüsü gösteriliyor. Diğer entegrasyonları canlıymış gibi göstermiyoruz.”

### 15.6 “Yanlış vatandaş bildirimi kamuya yayılır mı?”

**Cevap:**

> “Hayır. Bekleyen bildirim yalnız sahibine gri görünür. Kamuya ancak yetkili insan doğrulaması sonrası ortak kırmızı olay çıkar.”

### 15.7 “Acil durumda insanlar bunu kullanırsa?”

**Cevap:**

> “Kent Takip acil kanal değildir. Resmî uyarı katmanı salt okunurdur. Kritik vatandaş girdisi kamuya yayınlanmaz ve kullanıcı kurumca onaylı acil kanala yönlendirilir.”

### 15.8 “KVKK açısından fotoğraflar?”

**Cevap:**

> “Orijinal ve kamusal kopya ayrıdır. Yüz/plaka maskeleme başarısızsa kamusal medya yoktur. Orijinale yalnız yetkili personel gerekçeli ve audit edilen erişim sağlar.”

### 15.9 “Belediyeye somut fayda?”

**Cevap:**

> “İlk yönlendirme doğruluğu, triage süresi, mükerrer işlem ve tekrar durum sorma çağrılarını ölçüyoruz. Pilotumuz bu dört maliyetteki değişimi baseline ile karşılaştıracak.”

### 15.10 “Üretime hazır mı?”

**Cevap:**

> “Bu, uçtan uca çalışan ve üretim entegrasyon sınırlarını kanıtlayan demo/pilot sürümüdür. Gerçek kimlik, backend, kurum entegrasyonu, veri saklama ve operasyon SLA'ları üretim öncesi kurumsal onay gerektirir.”

---

## 16. Sunum/pitch deck yapısı

| Slayt | Başlık | Tek mesaj |
|---:|---|---|
| 1 | Aynı olay, parçalı kayıtlar | Problem başvuru kanalı değil, ortak operasyon gerçeği eksikliği |
| 2 | Bugünkü ekosistem | İstanbul Senin + 153 + veri kaynakları + birim sistemleri |
| 3 | Eksik bağlantı | Kaynaklar aynı olay altında birleşmiyor |
| 4 | İBB Kent Takip | Doğrulanmış olay ve koordinasyon katmanı |
| 5 | Vatandaş deneyimi | Gör, bildir, takip et; belirsizliği azalt |
| 6 | Belediye deneyimi | Birleştir, doğrula, yönlendir, çöz |
| 7 | AI'ın dar ve güvenli rolü | Üç yardımcı yetenek, insan kararı |
| 8 | Güven/KVKK/erişilebilirlik | Public/private medya, audit, WCAG |
| 9 | Pilot ve metrikler | 6 hafta, iki kategori, ölçümlü karar |
| 10 | Talep | Pilot sponsor + anonim veri + operasyon erişimi |

Slaytlarda uzun özellik listesi kullanılmamalıdır.

---

## 17. Uygulama öncelikleri

### P0 - Jüri öncesi zorunlu

| İş | Çıktı | Jüri etkisi |
|---|---|---|
| Konumlandırmayı değiştir | PRODUCT ve pitch'te 153/İstanbul Senin entegrasyon katmanı | “Kopya uygulama” itirazını kapatır |
| AI kapsamını daralt | AI_SYSTEM'de üç kanıtlanabilir yetenek | İnandırıcılığı artırır |
| Güven skorunu kaldır | UI, domain ve pitch'ten kişi puanı çıkar | Etik/KVKK saldırı alanını azaltır |
| AI rol görünürlüğünü düzelt | Vatandaş sade, personel ayrıntılı | UX ve güveni düzeltir |
| Bir gerçek veri kanıtı | Adapter + fixture/live sample + source card | “Her şey mock” itirazını azaltır |
| Pilot planı | Baseline, hedef, örneklem, go/no-go | Ürünü uygulanabilir yapar |
| Ortak olay modeli | Incident altında çoklu report/source | Gerçek farklılaştırıcıyı gösterir |
| Atomik persistence | Güvenli commit + recovery | Demo veri kaybını engeller |
| Afet sınırı | Resmî salt okunur katman | Sorumluluk riskini azaltır |
| Belge tutarlılığı | İsim, dil, veri modu, hesap ve kapsam | Jüri sorularında çelişkiyi önler |

### P1 - 9/10 için güçlü katkı

| İş | Çıktı |
|---|---|
| Kontrollü corroboration | “Bunu ben de yaşıyorum / artık görünmüyor” |
| Çözüm kanıtı | Sonuç fotoğrafı + vatandaş doğrulaması |
| SLA saatleri | İlk inceleme/yönlendirme/çözüm ölçümü |
| Rol bağlamı | Tek supervisor içinde permission gösterimi |
| Fotoğrafsız erişilebilir rota | Manuel inceleme fallback'i |
| Uzamsal etki açıklaması | Yol/hat/çalışma çakışma listesi |
| Kaynak sağlık kartı | Tazelik, gecikme, karantina ve sahip |
| ROI hesap ekranı | Baseline ve pilot farkı |

### P2 - Pilot sonrası

- gerçek 153 çift yönlü entegrasyonu;
- birim iş emri sistemi entegrasyonu;
- daha fazla veri kaynağı;
- çoklu ilçe pilotu;
- gerçek push/SMS;
- geçmiş veri yeterliyse ETA modeli;
- model drift ve fairness dashboard;
- üretim backend ve yüksek erişilebilirlik.

---

## 18. Eklenmemesi gereken özellikler

9/10 puan daha fazla özellik ekleyerek gelmez. Şunları jüri öncesi eklemeyin:

- genel amaçlı chatbot;
- puan, rozet veya vatandaş gamification;
- doğrulanmamış olayları halka açma;
- tam afet komuta merkezi;
- 3D dijital ikiz;
- otomatik ceza/yaptırım;
- otomatik olay doğrulama;
- 39 ilçede canlı entegrasyon iddiası;
- veri olmadan gelişmiş ETA modeli;
- veri olmadan trafik tahmin modeli;
- sosyal medya benzeri yorum/like sistemi;
- ayrı bir vatandaş kimlik ekosistemi;
- jüri demosunda gereksiz admin ayar ekranları.

---

## 19. Mevcut belgelerde yapılması gereken değişiklikler

### 19.1 `PRODUCT.md`

Eklenmeli/değiştirilmeli:

- İstanbul Senin/153 tamamlayıcısı konumlandırması
- Ortak `UrbanIncident` modeli
- Ürün sahibi ve bütçe sahibi
- Pilot kapsamı ve baseline
- Kontrollü corroboration
- Çözüm kanıtı
- SLA tabanlı süre
- Afet katmanı sınırı
- Elektrik kesintisi kararı
- Çoklu dil kesin kapsamı
- Ayrı app yerine mini-app/entegrasyon stratejisi

Çıkarılmalı/ertelenmeli:

- vatandaş güven skoru
- veri olmadan AI ETA
- veri olmadan AI trafik etkisi
- geniş kötüye kullanım profillemesi

### 19.2 `USER_FLOWS.md`

Eklenmeli:

- 153'ten gelen başvurunun ortak olaya bağlanması
- “Bunu ben de yaşıyorum” yapılandırılmış doğrulaması
- fotoğrafsız erişilebilir bildirim
- çözüm kanıtı ve yeniden açma
- kaynak gecikmesi açıklaması
- resmî uyarı katmanı

### 19.3 `DESIGN.md`

Düzeltilmeli:

- vatandaşa ham AI puanı değil sade durum
- personelde kaynak otoritesi ve tazelik
- olay kümesi/incident workspace
- çözüm kanıtı bileşeni
- SLA/gecikme göstergesi
- İstanbul Senin mini-app giriş bağlamı

### 19.4 `ARCHITECTURE.md`

Eklenmeli:

- `UrbanIncident/IncidentCluster`
- `ExternalApplicationRef`
- `ExternalWorkOrderRef`
- structured corroboration
- source authority modeli
- gerçek adapter contract testi
- atomic/backup persistence kararının yeniden üstün kılınması

### 19.5 `RULES.md`

Değiştirilmeli:

- “en yeni belge kazanır” yerine ADR/onaylı override
- bütün AI puanları aynı görünür kararı kaldırılmalı
- doğrudan overwrite kaldırılmalı
- harici AI jüri ana rotasında zorunlu olmamalı
- kritik jüri ekranlarında tasarım token ve component uyumu zorunlu olmalı

### 19.6 `DATA_SOURCES.md`

Değiştirilmeli:

- resmî/otoritatif kaynak kolay erişimin önüne alınmalı
- en az bir somut kaynak kartı doldurulmalı
- elektrik kesintisi eklenmeli veya kapsamdan çıkarılmalı
- doğal afet salt okunur yetkili kaynak olarak ayrılmalı
- 1 dakikalık refresh gibi kaynaksız iddialar gerçek sözleşme gelene kadar “hedef” olarak yazılmalı

### 19.7 `AI_SYSTEM.md`

Henüz tamamlanmamış olması jüri öncesi P0 blokerdir. En az:

- kesin yetenek kapsamı;
- giriş/çıkış sözleşmesi;
- model/fake ayrımı;
- değerlendirme veri seti;
- metrikler;
- eşikler;
- human-in-the-loop;
- privacy fail-closed;
- drift ve override;
- yasak kararlar

bulunmalıdır.

---

## 20. 9/10 hedef skor kartı

| Boyut | Mevcut | Hedef | Hedefe götüren kanıt |
|---|---:|---:|---|
| Problemin önemi | 8,5 | 9,0 | Baseline ve gerçek operasyon örneği |
| Farklılaşma | 4,0 | 9,5 | 153 üstü doğrulanmış olay grafiği |
| Kurumsal uyum | 5,5 | 9,2 | İstanbul Senin entegrasyonu + RACI + pilot sponsor |
| Ürün bütünlüğü | 7,5 | 9,0 | Dar jüri dikeyi ve tutarlı belgeler |
| Teknik uygulanabilirlik | 8,0 | 9,0 | Atomik veri, shared demo ve contract test |
| AI inandırıcılığı | 4,5 | 9,0 | Üç yetenek + değerlendirme seti + metrik |
| Veri inandırıcılığı | 4,5 | 9,0 | Bir gerçek kaynak + provenance + fallback |
| UX/erişilebilirlik | 8,5 | 9,2 | Fotoğrafsız rota + kullanıcı testi |
| Güvenlik/KVKK | 6,5 | 9,2 | Güven skoru kaldırma + threat model + audit |
| Pilot/ölçülebilir etki | 4,0 | 9,2 | 6 haftalık kontrollü pilot ve go/no-go |
| **Ağırlıklı hedef** | **6,2** | **9,1** | P0 + P1 tamamlanması |

---

## 21. Jüriye girmeden önce son kontrol

### Strateji

- [ ] “Neden 153 değil?” sorusuna 20 saniyelik net cevap var.
- [ ] Ürün ayrı app değil İstanbul Senin/153 modülü olarak anlatılıyor.
- [ ] Tek cümlelik değer önerisi herkes tarafından aynı söyleniyor.
- [ ] Kurumsal iş sahibi ve pilot sponsor rolü tanımlı.

### Ürün

- [ ] Ortak olay modeli demoda görünür.
- [ ] Birden fazla bildirim aynı olay altında birleşiyor.
- [ ] Vatandaş timeline ve çözüm kanıtını görüyor.
- [ ] Afet uyarısı vatandaş bildiriminden kesin ayrılmış.
- [ ] Fotoğrafsız erişilebilir alternatif var.

### AI

- [ ] Yalnız üç temel AI yeteneği öne çıkarılıyor.
- [ ] Vatandaş güven puanı yok.
- [ ] Vatandaşa ham AI/kötüye kullanım skoru gösterilmiyor.
- [ ] Model başarısızlığında ana veri akışı devam ediyor.
- [ ] Değerlendirme metrikleri ve örnek test seti hazır.

### Veri

- [ ] En az bir gerçek veya gerçek şemalı kaynak kanıtı var.
- [ ] Her olayda kaynak ve son güncelleme görünür.
- [ ] Bayat/kesik kaynak senaryosu çalışıyor.
- [ ] Resmî olmayan veri doğrulanmış gibi gösterilmiyor.
- [ ] JSON bozulma ve kurtarma testi geçiyor.

### Demo

- [ ] 7 dakikalık prova üç kez hatasız tamamlandı.
- [ ] İnternet olmasa aynı ana hikâye çalışıyor.
- [ ] Telefon ve web aynı state'i görüyor.
- [ ] Demo reset tek eylemle çalışıyor.
- [ ] Hiçbir buton sahte veya ölü değil.
- [ ] Android, iOS ve web ana rota test edildi.

### Kanıt

- [ ] Baseline ve pilot hipotezleri tek slaytta.
- [ ] KPI dashboard gerçek hesap formülleriyle çalışıyor.
- [ ] KVKK/gizlilik ve erişilebilirlik kanıtı gösterilebilir.
- [ ] Bilinen sınırlar dürüstçe listelenmiş.
- [ ] Jüriden istenen sonraki adım net.

Bu kontrol listesindeki P0 maddeler tamamlanmadan “9/10 hazır” denmemelidir.

---

## 22. Son karar

Projenin problemi güçlü, tasarım ve demo mühendisliği ortalamanın üzerinde. Zayıflık fikirde değil; **ürünün kurumsal ekosistemdeki yerinin yanlış anlatılması, AI'ın gereğinden fazla genişletilmesi ve etkinin kanıtlanmamasıdır.**

Jüriyi etkileyecek versiyon:

> Yeni bir şikâyet uygulaması değil; mevcut 153 ve İstanbul Senin akışlarını değiştirmeden, parçalı kayıtları tek doğrulanmış kent olayında birleştiren, insan denetimli AI ile operasyon yükünü azaltan ve çözüm durumunu vatandaşa geri taşıyan bir koordinasyon katmanı.

Bu konumlandırma, tek gerçek veri entegrasyonu, dar AI kanıtı, ortak olay modeli ve ölçümlü pilot planıyla desteklenirse proje 9/10 seviyesine çıkabilir. Bunlar yapılmadan yalnız ekran kalitesiyle 9/10 beklemek gerçekçi değildir.

---

## 23. Araştırma dayanakları

- [İBB Çözüm Merkezi - İstanbul Senin üzerinden başvuru, canlı destek ve sorgulama](https://cozummerkezi.ibb.istanbul/)
- [İstanbul Senin - İBB hizmetlerini tek uygulamada sunan ana platform](https://istanbulsenin.istanbul/)
- [İBB Mobil Uygulamalar](https://www.ibb.istanbul/ibb/mobil-uygulamalar/)
- [AKOM - AI, CBS, gerçek zamanlı görüntü ve mobil saha uygulamalarını kapsayan proje](https://akom.ibb.istanbul/haberler/afet-yonetimi-surecine-yapay-zeka-destegi/)
- [AKOM'un kurumsal görev ve koordinasyon kapsamı](https://akom.ibb.istanbul/kurulus/)
- [İBB Açık Veri Portalı](https://data.ibb.gov.tr/)

