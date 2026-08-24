# İBB Kent Takip - AI Ajanları İçin Uygulanabilir Ürün Geliştirme Yol Haritası

Belge durumu: Uygulama ve teslim için bağlayıcı iş paketi planı  
Belge sürümü: 1.0  
Tarih: 17 Ağustos 2026  
Teknoloji: Flutter 3.47.x stable, Dart, yerel/paylaşımlı JSON demo altyapısı  
Hedefler: Android, iOS ve modern web  
Geliştirme modeli: Risk öncelikli, contract-first, test-first, dikey dilimli ve kalite kapılı artımlı teslim  
Yürütücü: İnsan geliştiriciler ve AI kodlama ajanları  

---

## 1. Belgenin amacı

Bu belge, “WP-XX'i yap” komutu verildiğinde bir AI ajanının ek açıklamaya ihtiyaç duymadan:

- doğru kaynak belgeleri okumasını;
- mevcut kodu bozmadan yalnız ilgili kapsamı uygulamasını;
- gerekli testleri yazmasını ve çalıştırmasını;
- güvenlik, erişilebilirlik, veri ve tasarım kurallarını korumasını;
- iki ayrı öz-denetim yapmasını;
- kanıtlanmış, açılabilir ve geri izlenebilir bir checkpoint teslim etmesini

sağlamak için hazırlanmıştır.

Bu roadmap bir fikir listesi değildir. Her iş paketi ayrı bir geliştirme sözleşmesidir. Paket kabul kapısı geçmeden sonraki paket başlatılmaz.

---

## 2. Kullanılan geliştirme metodolojisi

### 2.1 Neden klasik waterfall veya yalnız ekran bazlı geliştirme kullanılmıyor?

Proje; harita, kamera, medya gizliliği, AI, iki rol, offline kullanım, paylaşımlı JSON ve çoklu platform içerir. Katmanları ayrı ayrı tamamen bitirip en sonda birleştirmek, entegrasyon hatalarını geç ortaya çıkarır.

Bu nedenle yöntem:

1. **Kararları dondur.**
2. **Repo ve kalite sistemini kur.**
3. **Domain ve veri sözleşmesini testlerle sabitle.**
4. **En erken aşamada uçtan uca walking skeleton üret.**
5. **Her yeteneği çalışan dikey dilim olarak genişlet.**
6. **Her pakette güvenlik, erişilebilirlik ve test borcunu kapat.**
7. **Son aşamada özellik eklemeyi durdurup adversarial hardening yap.**

Flutter'ın resmî mimari rehberindeki View/ViewModel, repository, service ve gerektiğinde domain/use-case ayrımı korunur. Test piramidi unit, widget ve integration katmanlarını birlikte kullanır. [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide), [Flutter Testing Overview](https://docs.flutter.dev/testing/overview)

### 2.2 Temel ilkeler

- **Contract-first:** Model, repository, API ve JSON sözleşmesi implementasyondan önce testle tanımlanır.
- **Test-first:** Kritik iş kuralında önce kırmızı test, sonra en küçük implementasyon, sonra refactor.
- **Vertical slice:** Her paket kullanıcıya veya operasyona ölçülebilir çalışan sonuç üretir.
- **Risk-first:** Veri kaybı, yetki, gizlilik, AI ve iki istemci senkronu erken çözülür.
- **Secure by design:** Güvenlik son sprint işi değildir.
- **Accessibility by default:** WCAG 2.2 AA her UI paketinin kabul kapısıdır.
- **No hidden debt:** TODO, ölü buton, sahte başarı ve açıklanmamış geçici çözüm paket sonunda kalamaz.
- **Evidence-based delivery:** “Çalışıyor” ifadesi test, ekran görüntüsü, log özeti veya build kanıtı olmadan kabul edilmez.

---

## 3. Kaynak belgeler ve bağlayıcılık

### 3.1 Her ajan için zorunlu okuma

Bir iş paketi başlamadan önce ajan en az şu dosyaları okur:

1. `RULES.md` - tamamı
2. `ROADMAP.md` - genel kurallar + uygulanacak iş paketi + bağımlı paketler
3. `EKSTRA.md` - ilgili stratejik düzeltme bölümleri
4. Paketin “zorunlu alan belgesi” olarak belirttiği dosyalar
5. Önceki bağımlı paketlerin `docs/work_packages/WP-XX_REPORT.md` raporları

Paket bazlı alan belgeleri:

| Alan | Zorunlu belge |
|---|---|
| Ürün ve kapsam | `PRODUCT.md` veya geçiş sürecinde `upload/product.txt` |
| Akış | `USER_FLOWS.md` veya geçiş sürecinde `upload/akış.txt` |
| UI/UX | `DESIGN.md` |
| Teknik yapı | `ARCHITECTURE.md` |
| AI | `AI_SYSTEM.md` |
| Veri | `DATA_SOURCES.md` |

WP-00 tamamlandığında `.txt` kaynaklarının kanonik `.md` sürümleri oluşturulmuş olmalıdır.

### 3.2 Karar çelişkisi

Ajan çelişkiyi kendi tercihiyle gizlice çözemez.

- WP-00 öncesi çelişki kodlamayı durdurur.
- WP-00 sonrası ADR kayıtları ve onaylı belge sürümleri kullanılır.
- Güvenlik/KVKK kararı kronolojik “en yeni dosya” kuralıyla geçersiz kılınamaz.
- Yeni karar gerekiyorsa `docs/decisions/ADR-XXXX-*.md` oluşturulur ve ilgili onay kaydedilir.

---

## 4. “WP-XX'i yap” komutunun yürütme sözleşmesi

Kullanıcı yalnız “WP-08'i yap” veya “İş paketi 8'i uygula” dediğinde ajan aşağıdaki süreci otomatik uygular.

### 4.1 Başlangıç

1. İş paketi kimliğini kesinleştirir.
2. Zorunlu belgeleri tam okur.
3. `git status`, aktif branch, Flutter/Dart sürümü ve repo yapısını inceler.
4. Kullanıcının mevcut/değiştirilmiş dosyalarını korur.
5. Bağımlı paketlerin tamamlandığını rapor ve test kanıtıyla doğrular.
6. Paketin Definition of Ready koşulları sağlanmıyorsa kod yazmaz; eksik bağımlılığı raporlar.
7. Kısa uygulama planı çıkarır ve aynı turn içinde uygulamaya geçer.

### 4.2 Uygulama

1. Yalnız paket kapsamındaki dosyaları değiştirir.
2. Önce sözleşme/test, sonra implementasyon yapar.
3. Mevcut mimariyi dolaşan kısa yol eklemez.
4. UI işinde loading, data, empty, offline ve error durumlarını birlikte tamamlar.
5. Yetki, audit, localization, semantics ve log redaction gereksinimlerini aynı pakette uygular.
6. Generated dosyaları günceller.
7. İlgili belge veya ADR'yi kodla aynı anda günceller.

### 4.3 Öz-denetim 1 - Yapısal inceleme

Ajan implementasyondan sonra diff'i baştan sona inceler:

- mimari sınır ihlali;
- tekrar kod;
- kontrolsüz null/dynamic;
- state transition hatası;
- yarış koşulu;
- yanlış yetki;
- veri kaybı;
- test edilmeyen branch;
- gereksiz bağımlılık;
- platforma özgü kırılma

bulursa düzeltir ve testleri tekrar çalıştırır.

### 4.4 Öz-denetim 2 - Adversarial kullanıcı ve jüri incelemesi

Ajan ikinci turda şu rollerde sistemi sorgular:

- kötü niyetli kullanıcı;
- bağlantısı zayıf vatandaş;
- ekran okuyucu kullanan vatandaş;
- yanlış yetkili personel;
- acele eden incelemeci;
- bozuk/eksik veri kaynağı;
- AI servisi kesintisi;
- jüri üyesi.

Bulduğu P0/P1 sorunu aynı pakette düzeltir. Kapsam dışı P2 bulguyu rapora yazar.

### 4.5 Kapanış

Ajan:

1. zorunlu testleri çalıştırır;
2. başarısız testi gizlemez veya kaldırmaz;
3. `docs/work_packages/WP-XX_REPORT.md` oluşturur/günceller;
4. değişen dosyaları, testleri, sonuçları, riskleri ve kalan işleri yazar;
5. roadmap durum tablosunda yalnız ilgili satırı günceller;
6. kullanıcıya çalışan sonuç, test özeti ve dosya/build yollarını verir.

### 4.6 Kanonik ajan komutu

Kullanıcının vermesi gereken asgari komut şudur:

```text
WP-XX'i uygula.
```

Bu komut; bu belgedeki yürütme sözleşmesini, paketin bağımlılıklarını, görevlerini, kabul ölçütlerini, testlerini ve rapor yükümlülüğünü otomatik olarak içerir. Ajan kullanıcıdan belgede cevabı bulunan ayrıntıları tekrar istemez. Yalnızca aşağıdaki durumlardan biri varsa durur ve tek, karar verilebilir blokaj sorusu sorar:

- bağlayıcı belgeler arasında WP-00 sonrasında ortaya çıkmış yeni ve maddi bir çelişki;
- gerçek kurum erişimi, sertifika, imza veya yazılı onay gereksinimi;
- güvenlik/KVKK açısından ajan yetkisini aşan karar;
- kullanıcının mevcut değişikliklerine zarar vermeden çözülemeyen dosya çakışması.

“WP-XX'i incele” yalnız read-only denetimdir; kod değişikliğine izin vermez. “WP-XX'i uygula” ise paketin implementasyon, test, belge ve rapor işlerinin tamamına yetki verir ancak publish, gerçek sisteme yazma, veri silme veya release tag oluşturma yetkisi vermez.

---

## 5. Global Definition of Ready

Bir paket başlamadan önce:

- [ ] Bütün bağımlı paketler `COMPLETED` durumunda.
- [ ] Bağımlı paket testleri yeşil.
- [ ] Paketin zorunlu belgeleri mevcut ve onaylı.
- [ ] Belirsiz P0 ürün/AI/veri kararı yok.
- [ ] Kullanılacak asset, fixture veya API sözleşmesi erişilebilir.
- [ ] Repo mevcut durumu anlaşılmış ve ilgisiz kullanıcı değişikliği korunmuş.
- [ ] Paket tek PR içinde tamamlanabilir sınırda.

Bu koşullardan biri eksikse ajan sahte implementasyonla devam etmez.

---

## 6. Global Definition of Done

Her paket için:

- [ ] Paket kabul ölçütlerinin tamamı karşılandı.
- [ ] Kod formatlı ve analyzer sıfır hata/sıfır uyarı.
- [ ] İlgili unit, repository, ViewModel, widget, golden ve integration testleri yeşil.
- [ ] Yeni davranış için regresyon testi var.
- [ ] Android, iOS ve web etkisi değerlendirildi.
- [ ] UI varsa WCAG 2.2 AA, klavye, semantics ve yüzde 200 metin kontrol edildi.
- [ ] Türkçe ve İngilizce kullanıcı metinleri tamamlandı.
- [ ] Gerçek kişisel veri veya secret bulunmuyor.
- [ ] Loading, empty, offline ve error durumları tamam.
- [ ] TODO, ölü buton, placeholder ve sahte başarı yok.
- [ ] P0/P1 hata yok.
- [ ] İki öz-denetim tamamlandı.
- [ ] Paket raporu ve karar kayıtları güncel.
- [ ] Önceki paketlerin testleri bozulmadı.

---

## 7. Ortak kalite komutları

Repo kurulduktan sonra her paket etkisine göre aşağıdaki komutların tamamını veya ilgili alt kümesini çalıştırır:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
dart run build_runner build --delete-conflicting-outputs
dart run tool/validate_demo_data.dart
dart run tool/verify_asset_references.dart
flutter test --coverage
flutter test test/goldens
```

Ana dikey akışı etkileyen paketler ayrıca:

```bash
flutter test integration_test
flutter build web --release --dart-define=APP_ENV=demo
flutter build apk --release --dart-define=APP_ENV=demo
```

iOS build macOS CI runner'da `--no-codesign` veya kurumun imzalama akışıyla doğrulanır. Yerel ortam desteklemiyorsa test atlanmış sayılmaz; CI kanıtı beklenir.

Kapsam hedefleri:

- kritik domain/yetki/persistence/AI dalları: en az %90;
- genel satır kapsamı: en az %80;
- hedef yüzdeler davranış ve E2E testlerinin yerine geçmez.

---

## 8. Kanıt ve rapor standardı

Her paket şu raporu üretir:

```text
docs/work_packages/WP-XX_REPORT.md
```

Rapor şablonu:

```markdown
# WP-XX Raporu

Durum: COMPLETED | BLOCKED | FAILED
Branch/commit:
Kapsam:
Değişen dosyalar:
Uygulanan kararlar:
Kabul ölçütleri:
Çalıştırılan testler ve sonuçları:
Android/iOS/web etkisi:
Erişilebilirlik kanıtı:
Güvenlik ve veri etkisi:
Öz-denetim 1 bulguları/düzeltmeleri:
Öz-denetim 2 bulguları/düzeltmeleri:
Bilinen P2/P3 sınırlar:
Sonraki paket için notlar:
```

Ekran/golden/performance çıktıları `artifacts/wp-xx/` altında tutulabilir. Büyük build dosyaları Git'e eklenmez; release teslim alanında saklanır.

---

## 9. Branch, commit ve entegrasyon düzeni

- Branch: `feature/wp-XX-kisa-ad` veya `fix/wp-XX-kisa-ad`
- Ana dala doğrudan commit yok.
- Her paket tek ana PR üretir.
- Commit'ler anlamlı ve geri alınabilir olmalıdır.
- Generated kod değişimi kaynak dosyayla aynı PR'da bulunur.
- Paketler varsayılan olarak sırayla uygulanır.
- Aynı feature, domain veya ortak component dosyalarına dokunan paketler paralel yürütülmez.
- Paralel çalışma yapılırsa dal güncel ana dalla güvenli biçimde eşitlenir ve entegrasyon öncesi bütün ilgili testler yeniden çalıştırılır.
- Force push, geçmişi yeniden yazma ve review kontrollerini atlama yasaktır.

### 9.1 Paket durum makinesi

İzin verilen durumlar:

```text
NOT_STARTED -> IN_PROGRESS -> COMPLETED
                         \-> BLOCKED -> IN_PROGRESS
                         \-> FAILED  -> IN_PROGRESS
```

- Aynı yürütme hattında en fazla bir paket `IN_PROGRESS` olabilir.
- `COMPLETED`, bütün kabul ölçütleri ve zorunlu kanıtlar sağlandığında kullanılır.
- `BLOCKED`, ajanın yetkisi veya erişimi dışındaki açık engel içindir; test hatası için kullanılmaz.
- `FAILED`, uygulama ya da doğrulama denemesi başarısız olduğunda kullanılır.
- `COMPLETED` paket yeniden açılırsa neden, etkilenen downstream paketler ve yeniden çalıştırılan testler rapora yazılır.
- Durum değişikliği hem bu belgedeki tabloda hem paket raporunda aynı commit içinde yapılır.

---

## 10. Fazlar ve sıra

| Faz | Paketler | Amaç |
|---|---|---|
| F0 - Karar ve kalite temeli | WP-00 - WP-01 | Çelişkisiz kaynak ve çalışan repo |
| F1 - Çekirdek ve ilk dikey kesit | WP-02 - WP-06 | Domain, veri, shell ve local walking skeleton |
| F2 - Ortak altyapı | WP-07 - WP-10 | Senkron, harita, medya ve dar AI |
| F3 - Vatandaş deneyimi | WP-11 - WP-12 | Eksiksiz bildirim ve takip |
| F4 - Belediye operasyonu | WP-13 - WP-18 | Olay, karar, saha, planlama, kaynak ve yönetişim |
| F5 - Hardening | WP-19 - WP-22 | Güvenlik, erişilebilirlik, performans ve tam regresyon |
| F6 - Pilot ve teslim | WP-23 - WP-24 | KPI, jüri release'i ve bağımsız son denetim |

### 10.1 Kilometre taşı kalite kapıları

| Kilometre taşı | Paket kapısı | Gösterilebilir kanıt | Sonraki faza geçiş koşulu |
|---|---|---|---|
| M0 - Karar dondurma | WP-00 | Onaylı kanonik belgeler, ADR ve traceability | Açık P0 karar veya belge çelişkisi yok |
| M1 - Mühendislik temeli | WP-01 - WP-05 | CI, domain testleri, atomik JSON, rol shell'leri, tasarım kataloğu | Analyzer/build/test ve erişilebilirlik altyapısı yeşil |
| M2 - Teknik fizibilite | WP-06 - WP-10 | İki istemcili walking skeleton, harita, medya gizliliği, AI evaluation | Veri kaybı/rol sızıntısı yok; offline ve fail-closed rotalar kanıtlı |
| M3 - Vatandaş alfa | WP-11 - WP-12 | Bildirim, mükerrer katkı, takip ve çözüm geri bildirimi | Ana vatandaş E2E'leri üç platformda yeşil |
| M4 - Operasyon alfa | WP-13 - WP-18 | Kuyruk, karar, saha, SLA, kaynak, RBAC ve audit | Yetki matrisi ve citizen/staff projection izolasyonu yeşil |
| M5 - Release hardening | WP-19 - WP-22 | Güvenlik, WCAG, performans, recovery ve tam regresyon | P0/P1 = 0; zorunlu build/testlerin tamamı yeşil |
| M6 - Jüri RC | WP-23 - WP-24 | Tekrarlanabilir demo, release manifest ve bağımsız audit | Yazılı insan onayı ve dondurulmuş RC commit'i |

### 10.2 Kritik risk sicili

| Risk | Olasılık / etki | Erken sinyal | Önleyici paket | Release blokajı |
|---|---|---|---|---|
| Belgelerin birbiriyle çelişmesi | Yüksek / Kritik | Aynı kavram için farklı rol, state veya veri kararı | WP-00 | Evet |
| JSON bozulması veya iki istemcide veri kaybı | Orta / Kritik | Parse hatası, kayıp mutation, farklı revizyon | WP-03, WP-07, WP-21 | Evet |
| Vatandaş/personel verisi sızıntısı | Orta / Kritik | Projection veya route guard testi başarısız | WP-02, WP-04, WP-18, WP-19 | Evet |
| Medyada yüz/plaka/EXIF sızıntısı | Orta / Kritik | Privacy pipeline belirsiz veya bypass edilebilir | WP-09, WP-19 | Evet |
| AI'ın otomatik karar vermesi ya da kötü yönlendirmesi | Orta / Kritik | Human override yok, eşik/versiyon izlenmiyor | WP-00, WP-10, WP-14 | Evet |
| Harita/veri kaynağının jüri anında kesilmesi | Orta / Yüksek | Health check veya cache yok | WP-08, WP-17, WP-21, WP-23 | Ana akışı etkilerse evet |
| Flutter platform paritesi kırılması | Orta / Yüksek | Yalnız bir platformda çalışan plugin/permission | WP-01, WP-09, WP-20, WP-22 | Evet |
| Erişilebilirliğin sona bırakılması | Orta / Kritik | Semantics/golden/a11y testi eksik | WP-05 ve her UI paketi, WP-20 | Evet |
| Demo iddiasının gerçek entegrasyon gibi sunulması | Orta / Yüksek | Fixture/simülasyon etiketi kaybolur | WP-00, WP-17, WP-23 | Evet |
| Kapsam büyümesi ve tek PR'ın denetlenemez olması | Yüksek / Yüksek | Paket dışı refactor, belirsiz kabul ölçütü | DoR, WP raporları, değişiklik politikası | Düzeltilene kadar evet |

Risk sahibi, kalan risk, tetikleyici ve azaltım kanıtı ilgili WP raporunda güncellenir. “Düşük ihtimal” gerekçesi kritik etkiyi kabul edilebilir yapmaz.

---

## 11. Durum tablosu

| Paket | Ad | Bağımlılık | Boyut | Risk | Durum |
|---|---|---|:---:|:---:|---|
| WP-00 | Karar mutabakatı ve belge dondurma | - | L | Kritik | COMPLETED |
| WP-01 | Workspace, toolchain ve CI | WP-00 | M | Yüksek | BLOCKED |
| WP-02 | Domain modeli ve sözleşmeler | WP-01 | L | Kritik | BLOCKED |
| WP-03 | JSON kalıcılık, seed ve migration | WP-02 | L | Kritik | BLOCKED |
| WP-04 | Bootstrap, router, auth ve shell | WP-01, WP-02 | L | Yüksek | BLOCKED |
| WP-05 | Tasarım sistemi ve erişilebilirlik altyapısı | WP-01, WP-04 | L | Yüksek | BLOCKED |
| WP-06 | Local uçtan uca walking skeleton | WP-02 - WP-05 | L | Kritik | BLOCKED |
| WP-07 | Shared JSON server ve senkron | WP-03, WP-06 | L | Kritik | BLOCKED |
| WP-08 | Harita, yer arama ve veri projection'ları | WP-05 - WP-07 | L | Yüksek | BLOCKED |
| WP-09 | Kamera, medya ve gizlilik pipeline'ı | WP-03, WP-05 | L | Kritik | BLOCKED |
| WP-10 | Dar AI sistemi ve değerlendirme harness'i | WP-02, WP-09 | L | Kritik | BLOCKED |
| WP-11 | Vatandaş bildirim akışı | WP-07 - WP-10 | XL | Kritik | BLOCKED |
| WP-12 | Vatandaş takip, bildirim ve çözüm geri bildirimi | WP-11 | L | Yüksek | BLOCKED |
| WP-13 | Belediye dashboard, kuyruk ve olay çalışma alanı | WP-07, WP-08, WP-10 | XL | Kritik | BLOCKED |
| WP-14 | Personel kararları, merge ve yönlendirme | WP-11 - WP-13 | L | Kritik | BLOCKED |
| WP-15 | Birim, saha, SLA ve çözüm kanıtı | WP-12, WP-14 | L | Yüksek | BLOCKED |
| WP-16 | Planlı çalışma ve açıklanabilir etki analizi | WP-08, WP-13 | L | Yüksek | BLOCKED |
| WP-17 | Kaynak adaptörleri, sağlık ve 153 sözleşmesi | WP-07, WP-08, WP-13 | XL | Kritik | BLOCKED |
| WP-18 | Admin, RBAC, audit ve KVKK akışları | WP-14, WP-17 | L | Kritik | BLOCKED |
| WP-19 | Güvenlik ve gizlilik hardening | WP-11 - WP-18 | L | Kritik | BLOCKED |
| WP-20 | TR/EN, erişilebilirlik ve platform paritesi | WP-11 - WP-19 | XL | Kritik | BLOCKED |
| WP-21 | Performans, offline ve dayanıklılık | WP-07 - WP-20 | L | Kritik | BLOCKED |
| WP-22 | Tam E2E, golden ve regresyon kapatma | WP-11 - WP-21 | XL | Kritik | BLOCKED |
| WP-23 | Pilot analitiği, jüri demosu ve release | WP-22 | L | Yüksek | BLOCKED |
| WP-24 | Bağımsız son denetim ve RC freeze | WP-23 | L | Kritik | BLOCKED |

Boyut göreli kapsamdır; takvim taahhüdü değildir. `XL` paket, tek PR içinde bölümlü commit'lerle yürütülür; kabul ölçütü bölünemez.

---

# İŞ PAKETLERİ

## WP-00 - Karar mutabakatı, stratejik düzeltme ve belge dondurma

### Amaç

Kod başlamadan önce bütün ürün, tasarım, mimari, AI, veri ve kural kararlarını tekbilleştirmek; `EKSTRA.md` P0 düzeltmelerini kanonik belgelere geçirmek.

### Bağımlılık

Yok. Bütün paketlerin zorunlu ön koşuludur.

### Zorunlu belgeler

`product.txt`, `akış.txt`, `DESIGN.md`, `ARCHITECTURE.md`, `RULES.md`, `DATA_SOURCES.md`, `AI_SYSTEM_QUESTIONS.md`, `EKSTRA.md`.

### Uygulama görevleri

1. `product.txt` içeriğini güncelleyerek kanonik `PRODUCT.md` oluştur.
2. `akış.txt` içeriğini güncelleyerek kanonik `USER_FLOWS.md` oluştur.
3. Ürün adını her yerde **İBB Kent Takip** olarak sabitle.
4. Ürünü ayrı vatandaş uygulaması değil, üretimde İstanbul Senin/153 ile entegre modül; demoda bağımsız Flutter kabuğu olarak konumlandır.
5. `UrbanIncident/IncidentCluster`, `ExternalApplicationRef`, `ExternalWorkOrderRef`, structured corroboration, resolution evidence ve SLA kavramlarını ürün/akış/mimariye ekle.
6. Vatandaş güven skorunu MVP'den çıkar; kişiye yönelik puan yerine ölçülü güvenlik/rate-limit sinyali tanımla.
7. AI puan görünürlüğünü rol bazlı yap: vatandaşa sade sonuç, personele ayrık skor/gerekçe/sürüm.
8. Doğal afeti yalnız yetkili kaynaktan salt okunur resmî uyarı katmanı olarak ayır.
9. Fotoğrafsız erişilebilir manuel inceleme rotasını ekle.
10. Kaynak önceliğini otorite/lisans/doğruluk öncelikli hâle getir.
11. Tek dosya doğrudan overwrite kararını geri al; atomik yazım ve son geçerli kurtarma kararını dondur.
12. Elektrik kesintisini ya somut kaynakla ekle ya da MVP filtrelerinden çıkar.
13. Türkçe/İngilizce kapsamını tüm belgelerde aynılaştır.
14. Local modu CI/fallback, shared modu iki cihazlı jüri sunumu olarak netleştir.
15. `AI_SYSTEM_QUESTIONS.md` önerileri ve `EKSTRA.md` dar kapsamı kullanılarak nihai `AI_SYSTEM.md` oluştur.
16. `docs/decisions/` altında en az şu ADR'leri oluştur:
    - ürünün İstanbul Senin/153 konumu;
    - AI yetenek sınırı;
    - kişi güven skorunun kaldırılması;
    - rol bazlı AI görünürlüğü;
    - atomik JSON persistence;
    - resmî uyarı/afet sınırı;
    - kaynak otoritesi;
    - demo platform ve veri modları.
17. Belgelerde eski kararı işaretleyen açık “supersedes” notları ekle.
18. Bağlayıcı belge sırasını `RULES.md` içinde ADR tabanlı olarak düzelt.
19. Bütün belgeleri UTF-8 BOM + NFC olarak doğrula.

### Kabul ölçütleri

- Kanonik yedi belge mevcut: PRODUCT, USER_FLOWS, DESIGN, ARCHITECTURE, AI_SYSTEM, DATA_SOURCES, RULES.
- Hiçbir açık P0 karar kalmamış.
- İsim, dil, AI görünürlüğü, persistence, data mode, staff hesabı ve afet sınırında çelişki yok.
- Her `EKSTRA.md` P0 maddesinin belge karşılığı traceability tablosunda bulunuyor.
- AI otomatik ret/yayımlama/yaptırım yapmıyor.
- Üretim ve demo sınırı açık.
- Eski `.txt` dosyaları kaynak geçmişi olarak korunuyor; kanonik kabul edilmiyor.

### Test ve kanıt

- Markdown link ve heading doğrulaması.
- UTF-8/NFC kontrolü.
- `tool/check_doc_consistency.dart` veya eşdeğer belge tutarlılık aracı.
- `docs/TRACEABILITY.md`: ürün kararı -> akış -> ekran -> mimari -> test eşlemesi.

### Kapsam dışı

Uygulama kodu yazmak, Flutter projesi oluşturmak, UI geliştirmek.

### Çıkış kapısı

Teknik lider + ürün sahibi seviyesinde açıkça onaylanmış belge seti. Onay yoksa WP-01 başlamaz.

---

## WP-01 - Workspace, Flutter toolchain, kalite tabanı ve CI

### Amaç

Android, iOS ve webde açılan; analiz/test/build komutları tekrarlanabilir çalışan; daha sonraki paketlerin güvenle büyüteceği repo temeli kurmak.

### Bağımlılık

WP-00.

### Uygulama görevleri

1. Mevcut repo varsa üzerine çalış; yeni repo/uygulama yalnız gerçekten yoksa oluştur.
2. Flutter `3.47.x stable` kesin patch sürümünü sabitle ve belgeye yaz.
3. Dart environment, package sürümleri ve `pubspec.lock` dosyasını sabitle.
4. `ARCHITECTURE.md` klasör yapısını oluştur; boş katman yerine compile edilen minimal scaffold kullan.
5. `analysis_options.yaml` içinde fatal info/warning uyumlu lint'leri kur.
6. Android, iOS ve web platform dosyalarını oluştur/doğrula.
7. Demo/release/test environment config iskeletini kur; secret içerme.
8. Test klasörleri, integration test runner ve golden font yükleme altyapısını kur.
9. CI'da format, analyze, codegen, unit/widget, asset/schema validation ve platform build işlerini tanımla.
10. Dependency lisans envanteri ve temel SBOM üretim komutunu ekle.
11. Secret taraması ve gerçek kişisel veri fixture kontrolü ekle.
12. `README.md` içine setup, run, test ve platform ön koşullarını yaz.

### Kabul ölçütleri

- Temiz checkout sonrası tek README akışıyla proje kuruluyor.
- Minimal uygulama Android, iOS ve webde açılıyor; beyaz ekran yok.
- `flutter analyze` sıfır uyarı.
- Başlangıç testleri yeşil.
- CI branch protection için gerekli check adlarını üretiyor.
- Hiçbir gerçek credential yok.

### Test ve kanıt

- `flutter doctor -v` özeti.
- `flutter pub get`.
- Ortak kalite komutları.
- Android APK, web build ve macOS CI'da iOS no-codesign build.
- `WP-01_REPORT.md` içinde kesin araç sürümleri.

### Kapsam dışı

Ürün ekranları, domain iş kuralları ve veri deposu.

---

## WP-02 - Domain modeli, state machine ve sözleşmeler

### Amaç

Uygulamanın bütün iş kurallarını UI ve depodan bağımsız, immutable ve test edilebilir domain çekirdeğinde sabitlemek.

### Bağımlılık

WP-01.

### Uygulama görevleri

1. Immutable modelleri ve JSON DTO ayrımını kur.
2. Temel varlıkları uygula:
   - `UserAccount`, `Session`;
   - `CitizenReport`;
   - `UrbanIncident/IncidentCluster`;
   - `MunicipalWork`;
   - `SourceRecord`, `SourceAuthority`, `DataSourceHealth`;
   - `MediaRef`, `AiAnalysis`;
   - `CorroborationSignal`;
   - `ExternalApplicationRef`, `ExternalWorkOrderRef`;
   - `SlaClock`, `ResolutionEvidence`;
   - `TimelineEvent`, `AppNotification`, `AuditEvent`;
   - `PrivacyRequest`, `AccountRestriction`, `DemoScenario`.
3. Report, incident ve work state machine'lerini saf fonksiyon/policy olarak uygula.
4. Pin/public/staff/owner projection değişmezlerini uygula.
5. Yetki permission enum ve policy sözleşmelerini tanımla.
6. UTC, WGS84, UUID, tracking no ve enum JSON standardını uygula.
7. Repository, AI, medya, clock, location, map, notification ve source adapter arayüzlerini tanımla.
8. Unknown enum, daha yeni schema ve referans hataları için tipli failure modeli ekle.
9. Domain event kataloğunu oluştur.
10. JSON şema dosyalarını ve örnek sözleşme fixture'larını üret.

### Kabul ölçütleri

- UI veya Flutter plugin bağımlılığı olmayan domain testleri çalışıyor.
- Yasak state transition'lar açık hata üretiyor.
- Pending report başka vatandaşa görünmüyor.
- Kritik vatandaş girdisi otomatik public olamıyor.
- Citizen report merge sonrası takip numarasını koruyor.
- `UrbanIncident` birden fazla report/source/work ref bağlayabiliyor.
- AI kararı tek başına domain state değiştiremiyor.
- Kişiye yönelik vatandaş güven skoru modelde bulunmuyor.

### Test ve kanıt

- Tüm state transition ve yasak transition unit testleri.
- Projection privacy testleri.
- Authorization matrix testleri.
- JSON round-trip ve schema testleri.
- Referans bütünlüğü ve merge cycle testleri.
- Kritik domain dallarında en az %90 kapsam.

### Kapsam dışı

Dosyaya yazım, UI, gerçek ağ ve kamera.

---

## WP-03 - JSON kalıcılık, seed, migration ve medya referans deposu

### Amaç

Veritabanı olmadan güvenli, deterministik, sıfırlanabilir ve bozulmadan kurtarılabilir demo veri katmanı oluşturmak.

### Bağımlılık

WP-02.

### Uygulama görevleri

1. `AppSnapshot` envelope, revision, checksum ve schemaVersion uygula.
2. Mobilde `.tmp -> validate -> backup -> atomic rename` yazımını uygula.
3. Webde iki slot veya eşdeğer atomik commit/kurtarma mekanizması uygula.
4. `InMemorySnapshotStore` ve contract test suite yaz.
5. Tek writer transaction queue oluştur.
6. Seed manifest ve dosya düzenini oluştur.
7. Seed validator ile bütün referans, visibility, enum, asset ve sentetik veri kurallarını kontrol et.
8. Migration registry ve idempotent migration testleri yaz.
9. Import/export için checksum, schema ve synthetic-data doğrulaması ekle.
10. Reset akışını clock, media ve audit ile transaction olarak uygula.
11. Media binary'yi snapshot dışında tutan `MediaStore` sözleşmesini ve platform adaptörlerini kur.
12. Normal seed ve ayrı 10.000 olay fixture generator'ı oluştur.
13. Bozuk active snapshot, yarım yazım, quota ve daha yeni schema senaryolarını ele al.

### Kabul ölçütleri

- Uygulama kapanıp açıldığında veri korunuyor.
- Yazım ortasında hata son geçerli snapshot'ı bozmuyor.
- Bozuk active veri yedek/seed kurtarma ekranı üretiyor.
- Reset aynı seed'i deterministik kuruyor.
- Medya snapshot boyutuna eklenmiyor.
- Migration veri kaybetmiyor ve iki kez uygulanınca aynı sonucu veriyor.
- Import yetkisiz veya bozuk veriyi kabul etmiyor.

### Test ve kanıt

- Store contract testleri: memory, IO, web.
- Corruption ve power-loss simülasyonları.
- Checksum ve revision conflict testleri.
- Migration fixture testleri.
- 10.000 kayıt parse/validate benchmark.

### Kapsam dışı

Paylaşımlı HTTP server ve kullanıcı ekranları.

---

## WP-04 - Uygulama bootstrap, ortam, router, demo auth ve rol shell'leri

### Amaç

Tek Flutter uygulamasında vatandaş ve belediye deneyimlerini güvenli route guard ve ayrı responsive shell'lerle çalıştırmak.

### Bağımlılık

WP-01, WP-02.

### Uygulama görevleri

1. Deterministik bootstrap sırasını uygula: config -> logging -> store -> seed/migration -> repositories -> router.
2. Global tipli hata ve recovery boundary kur.
3. `provider` scope'ları ve repository/service composition root oluştur.
4. `go_router` typed route ağacını kur.
5. Açılışta Vatandaş/Belediye demo rol seçimi uygula.
6. Misafir, vatandaş ve tek demo supervisor girişlerini uygula.
7. Telefon/OTP ve staff password/MFA akışlarını deterministik demo servisleriyle kur.
8. Üç katmanlı authorization başlangıcını uygula.
9. Citizen bottom navigation ve staff desktop shell iskeletini oluştur.
10. Demo environment bandı, role switch ve reset entry point ekle.
11. Türkçe/İngilizce localization altyapısını ve locale switch'i kur.
12. Redacted structured logging ve correlation ID ekle.

### Kabul ölçütleri

- Bütün platformlarda app bootstrap tamamlanıyor veya kontrollü recovery ekranı gösteriyor.
- Unauthorized route URL ile açılamıyor.
- Role switch snapshot'ı silmiyor, oturumu kapatıyor.
- Citizen/staff shell birbirinin menüsünü sızdırmıyor.
- Demo hesaplarıyla giriş ve çıkış çalışıyor.
- Refresh/deep link doğru shell'e gidiyor.

### Test ve kanıt

- Bootstrap success/failure widget testleri.
- Router/returnTo/deep-link testleri.
- Auth retry/lockout testleri.
- Authorization policy + route guard integration testleri.
- Android/iOS/web smoke build.

### Kapsam dışı

Gerçek SMS/kimlik sistemi ve feature ekranlarının içeriği.

---

## WP-05 - Tasarım sistemi, ortak bileşenler ve erişilebilirlik test altyapısı

### Amaç

`DESIGN.md`yi kodda tek kaynak hâline getirmek ve sonraki ekranların görsel/erişilebilirlik drift'ini önlemek.

### Bağımlılık

WP-01, WP-04.

### Uygulama görevleri

1. Renk, tipografi, spacing, radius, elevation ve motion tokenlarını kur.
2. Resmî logo/ikon/font asset pipeline'ını doğrula.
3. Buton, input, chip, card, banner, tab, modal, sheet, table, queue row ve timeline component'lerini oluştur.
4. Dört pin + selected + cluster bileşenlerini semantics ile uygula.
5. `LoadingView`, `EmptyView`, `OfflineView`, `RecoverableErrorView`, `BlockingErrorView` oluştur.
6. Citizen ve staff responsive layout primitive'lerini kur.
7. Focus, keyboard shortcuts, focus trap/return ve live region yardımcılarını oluştur.
8. Reduced motion ve high-contrast davranışını kur.
9. Storybook/component gallery benzeri internal showcase route ekle.
10. Golden test font, cihaz ve diff altyapısını kur.
11. Kritik jüri ekranlarında token/component uyumunu zorunlu kıl.

### Kabul ölçütleri

- Aynı eylem bütün ekranlarda aynı component'i kullanabiliyor.
- Renk tek başına durum taşımıyor.
- Pin semantics durum + kategori + konum içeriyor.
- Yüzde 200 metinde component kırpılmıyor.
- Klavye focus görünür ve mantıklı.
- Reduced motion bilgi kaybettirmiyor.
- Literal marka rengi/font denetimi CI'da yakalanıyor.

### Test ve kanıt

- Component widget ve semantics testleri.
- 4 citizen + 4 staff viewport golden matrisi.
- Contrast/token validation.
- Keyboard/focus testleri.
- TR/EN uzun metin golden varyantları.

### Kapsam dışı

Tam ürün ekranları ve harita altyapısı.

---

## WP-06 - Local uçtan uca walking skeleton

### Amaç

Projenin en erken aşamasında tek cihaz/local JSON üzerinde gerçek state değiştiren tam dikey akışı kanıtlamak.

### Bağımlılık

WP-02, WP-03, WP-04, WP-05.

### Dikey akış

```text
Vatandaş giriş
-> minimal rapor oluştur
-> kişisel gri pin
-> role switch
-> staff kuyruğu
-> insan doğrulaması
-> UrbanIncident
-> kırmızı public pin
-> vatandaş timeline güncellemesi
```

### Uygulama görevleri

1. Sade fakat gerçek repository/command akışı kullan.
2. Kamera, AI ve harita için bu pakette sözleşmeye uygun fake kullan; statik başarı kullanma.
3. `clientMutationId`, tracking no ve audit event üret.
4. Staff kararında kategori, birim ve gerekçe zorunlu olsun.
5. Report -> incident bağını ve projection güncellemesini uygula.
6. Citizen ve other-citizen visibility farkını kanıtla.
7. Local reset sonrası akışı tekrarlanabilir yap.
8. İlk integration testini oluştur ve sonraki paketlerde koru.

### Kabul ölçütleri

- Bir kullanıcı baştan sona akışı tamamlıyor.
- Başka vatandaş pending gri pini görmüyor.
- Staff doğrulamasından sonra kırmızı olay bütün public görünümlerde çıkıyor.
- Tracking no değişmiyor.
- Uygulama kapanıp açıldığında sonuç korunuyor.
- Her mutasyon audit/timeline üretiyor.
- Hiçbir ekran yalnız mock görsel değil.

### Test ve kanıt

- `E2E-WALKING-SKELETON` Android + web.
- Unit/repository/widget testleri.
- Citizen/staff before-after screenshot.
- Reset ve reopen testi.

### Kapsam dışı

Tam medya analizi, gerçek harita tile, bütün kuyruklar ve saha süreçleri.

---

## WP-07 - Shared JSON demo server, iki istemci senkronu ve conflict yönetimi

### Amaç

Telefon vatandaş uygulaması ile bilgisayar belediye panelinin aynı anda aynı durumu güvenilir biçimde görmesini sağlamak.

### Bağımlılık

WP-03, WP-06.

### Uygulama görevleri

1. Dart `shelf` server ve route sözleşmelerini kur.
2. Snapshot query, command, media ve health endpoint'lerini uygula.
3. Tek writer command queue ve revision optimistic concurrency uygula.
4. WebSocket yalnız revision event taşısın; istemci REST ile güncel snapshot alsın.
5. `clientMutationId` idempotency ve replay koruması ekle.
6. Server tarafı authorization policy uygula.
7. Citizen offline draft ve reconnect submit davranışını kur.
8. Staff bağlantı yokken salt okunur ve açık hata durumu göster.
9. Conflict çözümünde sessiz overwrite yapma; güncel kayıt ve retry sun.
10. Server runtime JSON için atomik persistence ve recovery uygula.
11. Health/readiness endpoint ve local network runbook ekle.

### Kabul ölçütleri

- İki istemci revision sonrası aynı state'i görüyor.
- Çift tıklama/retry tek report üretiyor.
- Staff stale state ile sessiz karar veremiyor.
- Server restart veriyi bozmuyor.
- Unauthorized command reddedilip audit ediliyor.
- Ağ gidip geldiğinde citizen draft kaybolmuyor.

### Test ve kanıt

- Server contract testleri.
- İki client integration testi.
- Concurrent command/revision conflict testi.
- Disconnect/reconnect/idempotency testi.
- Corrupt runtime recovery testi.

### Kapsam dışı

Production backend, database, cloud autoscaling.

---

## WP-08 - Harita, adres arama, source provenance ve rol projection'ları

### Amaç

Canlı tile veya çevrimdışı örnek harita üzerinde doğru rol görünürlüğü, kaynak bilgisi ve erişilebilir alternatif liste sağlayan harita deneyimini tamamlamak.

### Bağımlılık

WP-05, WP-06, WP-07.

### Uygulama görevleri

1. `MapSurface` arayüzü altında live tile ve offline map uygula.
2. OSM attribution, config tile URL, timeout ve retry kurallarını uygula.
3. `MapProjectionService` ile report/incident/work/source event projection'larını üret.
4. Kırmızı, sarı, gri ve turuncu pin görünürlüğünü role göre uygula.
5. Trafik yoğunluğunu olay pininden ayrı harita katmanı olarak ele al.
6. Resmî kritik uyarıları salt okunur ve farklı uyarı katmanı olarak uygula.
7. `places.json` ile 39 ilçe ve seçili adres aramasını kur.
8. Türkçe normalizasyon, debounce ve “Bu alanda ara” davranışı ekle.
9. Cluster ve selected marker davranışını uygula.
10. Pin detayında kaynak, tazelik, doğrulama ve son güncelleme göster.
11. Haritanın tam işlevli erişilebilir liste alternatifini kur.
12. Hassas konum public projection yuvarlamasını uygula.

### Kabul ölçütleri

- Offline haritada pin, filtre, arama ve detay çalışıyor.
- Başka vatandaş pending pinini göremiyor.
- Kritik vatandaş kaydı yalnız staff turuncu projection üretiyor.
- Planlı work sarı, aktif work kırmızı.
- Resmî uyarı citizen report ile üretilemiyor.
- Her source event provenance ve freshness taşıyor.
- Klavye/ekran okuyucu ile harita eşdeğer liste üzerinden kullanılabiliyor.

### Test ve kanıt

- Projection unit testleri.
- Map/list widget testleri.
- Pin/cluster golden matrisi.
- Tile timeout/offline fallback integration testi.
- Visibility leakage testi.

---

## WP-09 - Kamera, medya depolama ve privacy fail-closed pipeline

### Amaç

Gerçek kamera ve deterministik demo kamera ile güvenli medya yakalama; orijinal/kamusal kopya ayrımı; fotoğrafsız erişilebilir fallback oluşturmak.

### Bağımlılık

WP-03, WP-05.

### Uygulama görevleri

1. `CameraGateway` gerçek ve demo implementasyonlarını kur.
2. Android/iOS/web izin ve lifecycle durumlarını ele al.
3. Fotoğraf çek, yeniden çek, onayla ve iptal akışını uygula.
4. Fotoğrafsız devam seçeneğini manuel inceleme işaretiyle uygula.
5. EXIF ve gereksiz metadata temizle.
6. Boyut/format/çözünürlük limitleri ve web quota yönetimi ekle.
7. Original/public media çiftini ve `privacyStatus` yaşam döngüsünü uygula.
8. Seed orijinal/maskeli çiftleri ile demo privacy processor oluştur.
9. Gizlilik işleme başarısızsa publicRef üretme.
10. Orijinal medya erişimini permission + reason + audit ile koru.
11. Tahmin edilemeyen media ID ve güvenli relative reference kullan.
12. Kamera reddi, cihaz hatası, background/resume ve quota dolu durumlarını tasarla.

### Kabul ölçütleri

- Kamera izni reddinde uygulama kilitlenmiyor.
- Fotoğrafsız bildirim manuel rotaya devam edebiliyor.
- Original media public response/projection içinde bulunmuyor.
- Blur/privacy failure public media göstermiyor.
- Orijinal erişimi audit olmadan mümkün değil.
- Reset demo medyasını güvenli temizliyor.

### Test ve kanıt

- MediaStore contract testleri.
- Permission/lifecycle widget testleri.
- EXIF temizleme testi.
- Original URL/ID leakage testi.
- Privacy failure E2E.
- Android/iOS/web kamera smoke ve demo gateway integration.

---

## WP-10 - AI analiz sistemi, deterministik demo motoru ve evaluation harness

### Amaç

AI'ı üç dar, açıklanabilir ve insan denetimli yetenekte güvenilir biçimde çalıştırmak; gerçek servis olmasa da aynı sözleşmeyi test etmek.

### Bağımlılık

WP-02, WP-09 ve nihai `AI_SYSTEM.md`.

### Kesin yetenekler

1. Kategori ve sorumlu birim önerisi
2. Gizlilik tespiti/maskeleme sonucu
3. Mükerrer olay adayı

Risk yalnız “dikkat sinyali”; nihai doğruluk veya otomatik karar değildir.

### Uygulama görevleri

1. `AiAnalysisService` tipli giriş/çıkış sözleşmesini uygula.
2. Scenario ID'ye göre deterministik `DemoAiAnalysisService` oluştur.
3. Opsiyonel gerçek servis adaptörünü feature flag arkasında kur; jüri ana rotasını bağımlı yapma.
4. Timeout, unavailable, partial result ve schema error durumlarını uygula.
5. Reason code, confidence, model/config version ve createdAt alanlarını ekle.
6. Citizen projection'da sade açıklama; staff projection'da ayrık skor/gerekçe göster.
7. Vatandaş güven skoru veya kişi profili üretme.
8. AI sonucu tek başına state transition/ret/publication yapamasın.
9. Evaluation fixture seti ve metrik hesaplayıcı oluştur.
10. Kategori top-1/top-3, critical attention recall, privacy miss, duplicate precision/recall ve latency raporu üret.
11. Staff override event ve neden kodunu audit/metric olarak kaydet.

### Kabul ölçütleri

- Aynı input/scenario aynı output'u üretiyor.
- AI yokken report kaybolmuyor ve manuel akış devam ediyor.
- Citizen ham kötüye kullanım/personel iç sinyali görmüyor.
- Privacy failure fail-closed.
- Mükerrer yalnız aday; otomatik merge yok.
- Evaluation raporu CI'da üretilebiliyor.
- Model/config değişimi version alanında izleniyor.

### Test ve kanıt

- Service contract testleri: demo/real fake.
- Timeout/partial/malformed output testleri.
- Human-in-the-loop invariant testleri.
- Evaluation metrics snapshot.
- Role projection tests.

---

## WP-11 - Eksiksiz vatandaş sorun bildirme ve corroboration akışı

### Amaç

Kategori seçiminden takip numarasına kadar bütün vatandaş bildirim akışını, offline ve hata durumları dahil üretmek.

### Bağımlılık

WP-07, WP-08, WP-09, WP-10.

### Uygulama görevleri

1. Bildirim türü/kategori ve “Emin değilim” ekranını tamamla.
2. Kamera veya fotoğrafsız erişilebilir rota ekle.
3. Konum önerisi, manuel seçim ve İstanbul dışı uyarı uygula.
4. Açıklama validation ve TR/EN metinlerini ekle.
5. AI analiz aşamalarını gerçek service state'iyle göster; sahte yüzde kullanma.
6. Kullanıcının kategori/konum önerisini düzeltmesini sağla.
7. Mükerrer aday ekranını ve yapılandırılmış “Bunu ben de yaşıyorum / yeni bildirim” kararını uygula.
8. Gönderim öncesi public privacy preview ve veri özeti göster.
9. Tek transaction içinde report, media refs, AI result, timeline, notification ve audit oluştur.
10. `clientMutationId` ile çift gönderimi engelle.
11. Offline draft, “bağlantı gelince gönder” ve conflict davranışını tamamla.
12. Başarı ekranında tracking no ve kişisel gri pin bağlantısı göster.
13. Hız sınırı ve kötüye kullanım sinyalinde otomatik ret yerine insan kuyruğu kullan.

### Kabul ölçütleri

- Fotoğraflı ve fotoğrafsız akış tamamlanıyor.
- Kamera/konum/AI/ağ reddi veri kaybetmiyor.
- Mükerrer adayı seçmek mevcut olaya corroboration ekliyor.
- Yeni bildirim seçmek bağımsız report oluşturuyor.
- Hızlı çift dokunma tek report.
- Kullanıcı kendi gri pinini görüyor; diğer vatandaş görmüyor.
- Gönderim sonucu server/local commit olmadan başarı göstermiyor.

### Test ve kanıt

- E2E-02, 03, 04, 06, 13, 14, 15, 16 güncel sürümleri.
- Form/ViewModel/command unit ve widget testleri.
- Offline/retry/idempotency integration.
- %200 text, keyboard ve screen reader ana rota.
- Android/iOS/web golden ve smoke.

---

## WP-12 - Vatandaş takip, bildirim merkezi, ek bilgi ve çözüm doğrulama

### Amaç

Vatandaşın gönderimden kapanışa kadar süreci anlamasını ve belediye çözümüne yapılandırılmış geri bildirim vermesini sağlamak.

### Bağımlılık

WP-11.

### Uygulama görevleri

1. Bildirimlerim liste, filtre, durum ve empty/offline state'lerini tamamla.
2. Report detail içinde tracking, source, unit, timeline ve tahmini SLA aralığını göster.
3. Ek bilgi isteği ve vatandaş yanıt akışını uygula.
4. Merge sonrası ana olayı takip numarasını koruyarak göster.
5. Ret/kapsam dışı insan gerekçesini ve itiraz girişini göster.
6. Uygulama içi notification merkezi, unread badge ve deep link uygula.
7. Çözüm açıklaması ve resolution evidence göster.
8. “Sorun gerçekten çözüldü / devam ediyor” yapılandırılmış geri bildirimi ekle.
9. Devam ediyor sinyalini otomatik reopen yerine personel incelemesine gönder.
10. Source stale ve ETA/SLA değişikliği açıklamasını göster.

### Kabul ölçütleri

- Timeline tüm durumları anlaşılır ve kronolojik gösteriyor.
- Notification doğru kullanıcıya tek kez üretiliyor.
- Ek bilgi yanıtı eski veriyi silmiyor.
- Merge tracking no kaybettirmiyor.
- Çözüm geri bildirimi audit/timeline üretiyor.
- Tahmini aralık garanti gibi sunulmuyor.

### Test ve kanıt

- E2E-07, 08, 09, 10 güncel vatandaş tarafı.
- Notification dedup/deep-link testleri.
- Timeline projection tests.
- Long text/TR/EN/offline golden.

---

## WP-13 - Belediye dashboard, kuyruklar ve olay çalışma alanı

### Amaç

Tek tek başvuru listesi yerine ortak `UrbanIncident` merkezli, veri yoğun ve erişilebilir belediye çalışma alanı oluşturmak.

### Bağımlılık

WP-07, WP-08, WP-10.

### Uygulama görevleri

1. Staff dashboard metriklerini kaynak veriden türet.
2. Kritik, yüksek, normal, düşük güven/manual, privacy ve abuse kuyruklarını kur.
3. Filtre, sort, search, pagination/virtualization ve URL state uygula.
4. Üç panelli queue/detail/map responsive düzenini uygula.
5. Incident workspace içinde bağlı report, source record, corroboration ve work ref'lerini göster.
6. AI'ın staff ayrıntı kartını gerekçe/sürümle göster.
7. Source authority, freshness ve conflict durumunu göster.
8. Public preview ve original/public media karşılaştırmasını yetkiye göre göster.
9. İnceleme kilidi/lease ve stale record uyarısı ekle.
10. Klavye ile sıradaki kayıt, karar alanı ve geri dönüş akışını kur.
11. Empty/loading/offline/error ve 10.000 kayıt durumlarını tamamla.

### Kabul ölçütleri

- Kuyruk sayıları domain state ile tutarlı.
- Kritik kayıt normal/lower queue nedeniyle kaybolmuyor.
- Staff incident altında bütün kaynakları ayırt edebiliyor.
- Yetkisiz original media görünmüyor.
- Aynı kaydı iki personel sessizce değiştiremiyor.
- 10.000 kayıtta UI kullanılabilir kalıyor.

### Test ve kanıt

- Queue projection/filter/sort unit testleri.
- Staff responsive/golden matrisi.
- Keyboard + NVDA/VoiceOver web ana rota.
- Lease conflict integration.
- 10.000 kayıt performance profile.

---

## WP-14 - Belediye kararları, merge, yönlendirme ve public projection

### Amaç

Personelin bildirimi gerekçeli biçimde doğrulaması, reddetmesi, ek bilgi istemesi, birleştirmesi ve doğru birime yönlendirmesini tamamlamak.

### Bağımlılık

WP-11, WP-12, WP-13.

### Uygulama görevleri

1. Ortak command pipeline: authorize -> validate -> stale check -> mutate -> invariant -> persist -> audit -> event.
2. Verify ile `UrbanIncident` oluştur/bağla ve public red projection üret.
3. Reject/out-of-scope için seçili neden + insan açıklaması zorunlu yap.
4. Additional info request ve response dönüşünü kur.
5. Merge candidate karşılaştırma ve cycle-safe merge uygula.
6. İBB birimi ve ilçe belediyesi yönlendirmesini aynı tracking ile uygula.
7. AI önerisini değiştirmede override reason zorunlu yap.
8. Public preview ve publish onayı ekle.
9. Citizen notification/timeline ve staff audit event üret.
10. Yanlış yönlendirmede geri aktarım ve sorumluluk geçmişini koru.

### Kabul ölçütleri

- AI tek başına hiçbir command çalıştıramıyor.
- Verify sonrası red pin doğru role açılıyor.
- Ret public incident üretmiyor.
- Merge veri ve tracking kaybettirmiyor.
- Transfer süreci sıfırlamıyor.
- Her karar actor/time/reason ile audit ediliyor.
- Unauthorized/stale command reddediliyor.

### Test ve kanıt

- E2E-05, 07, 08, 09, 17.
- Command unit/repository contract testleri.
- Merge cycle ve concurrent decision testleri.
- Public projection privacy tests.

---

## WP-15 - Birim operasyonu, saha ataması, SLA ve çözüm kanıtı

### Amaç

Doğrulanan olayın birim ve saha sürecini; ölçülebilir süreler ve vatandaşa doğrulanabilir kapanışla tamamlamak.

### Bağımlılık

WP-12, WP-14.

### Uygulama görevleri

1. Birim görev listesi ve permission filtrelerini oluştur.
2. Saha ekibi/assignee ve external work order reference ekle.
3. `assigned -> field_assigned -> in_progress -> resolved` transition'larını uygula.
4. Kategori/birim bazlı SLA config ve clock başlat/durdur kurallarını uygula.
5. Gecikme nedeni ve yeniden tahmin aralığı ekle.
6. Yanlış birime geri aktarımı audit ile uygula.
7. Çözüm açıklaması zorunlu; sonuç fotoğrafı opsiyonel/gizlilik kontrollü olsun.
8. Resolution evidence ve citizen feedback'i incident'a bağla.
9. “Devam ediyor” sinyalini reopen review kuyruğuna gönder.
10. Dashboard için first-review/routing/resolution metrics event'leri üret.

### Kabul ölçütleri

- Yasak state geçişi yok.
- Resolved açıklamasız kaydedilemiyor.
- SLA garanti değil hedef aralık olarak gösteriliyor.
- Citizen çözüm güncellemesini ve kanıtı görüyor.
- Reopen otomatik public karar vermiyor.
- External work order yoksa demo ref açıkça simüle.

### Test ve kanıt

- E2E-10 genişletilmiş.
- SLA clock/fake time unit testleri.
- Transfer/reopen/resolution integration.
- Media privacy testleri.

---

## WP-16 - Planlı çalışma, yayınlama ve açıklanabilir etki analizi

### Amaç

Belediye çalışmasını oluşturmak, uzamsal/zamansal çakışmayı açıklamak, sarı olarak yayımlamak ve zamanı gelince kırmızı aktife geçirmek.

### Bağımlılık

WP-08, WP-13.

### Uygulama görevleri

1. Work draft formu: tür, alan, zaman, birim, açıklama.
2. Otomatik taslak kaydı ve validation.
3. Yol segmenti, durak/hat buffer'ı ve diğer work zaman çakışmasını hesapla.
4. “Tahmin” yerine açıklanabilir overlap sonuçları göster.
5. Alternatif zaman/güzergâhı kural tabanlı ve gerekçeli öner.
6. Citizen bilgilendirme metni taslağı üret; personel onayı olmadan yayımlama.
7. Public preview ve publish command uygula.
8. `published_planned -> active -> completed` geçişini `DemoClock` ile uygula.
9. Sarı -> kırmızı -> haritadan kaldır/geçmişte koru projection'ını uygula.
10. Publish/transition failure'ı admin alert ve audit'e yaz.

### Kabul ölçütleri

- Yayınlanmamış draft public görünmüyor.
- Çakışma hesabı hangi veriden çıktığını açıklıyor.
- Yellow/red geçişi app resume sonrası doğru.
- Complete olay canlı haritadan kalkıyor, geçmiş korunuyor.
- AI trafik tahmini gibi yanıltıcı ifade yok.

### Test ve kanıt

- E2E-11, 12.
- Geometry/time overlap unit testleri.
- Work state machine/fake clock testleri.
- Publish preview golden.

---

## WP-17 - Veri kaynağı adaptörleri, kaynak sağlığı, manuel giriş ve 153 sınırı

### Amaç

Seed ile güvenilir demo sürerken en az bir gerçek/gerçek şemalı veri kaynağını kanıtlamak ve mevcut İBB ekosistemiyle entegrasyon dikişini göstermek.

### Bağımlılık

WP-07, WP-08, WP-13.

### Uygulama görevleri

1. Source adapter contract: fetch/decode/validate/normalize/freshness/provenance.
2. Kaynak otorite sırasını uygula; kolay erişim resmî otoritenin önüne geçmesin.
3. En az bir gerçek veya gerçek şemaya dayalı açık veri adaptörü oluştur.
4. Su, trafik, ulaşım, planlı çalışma ve resmî uyarı için deterministik fixture adaptörleri oluştur.
5. Bilinmeyen/eksik kayıtları quarantine et; sessiz “Diğer” yapma.
6. Retry/backoff/jitter/circuit breaker ve stale cache uygula.
7. `DataSourceHealth` staff ekranını tamamla.
8. Yetkili manual event/work girişini provenance ve audit ile uygula.
9. JSON/CSV fixture import ve export'u doğrulamalı yap.
10. 153/İstanbul Senin için gerçek erişim gerektirmeyen contract adapter/mock oluştur:
    - external application ID;
    - status sync;
    - source timestamp;
    - citizen report/incident link;
    - sync error.
11. Gerçek entegrasyon yapılmadığını UI ve dokümanda açıkça etiketle.
12. Elektrik verisi kararını uygula: somut kaynak yoksa filtreyi kapat.
13. Resmî afet uyarısını salt okunur ve yetkili kaynağa bağlı tut.

### Kabul ölçütleri

- En az bir adapter gerçek schema mapping kanıtı taşıyor.
- Seed ve canlı/fixture kaynak etiketleri ayrılıyor.
- Kaynak kesintisi uygulamayı kapatmıyor.
- Stale veri zaman etiketiyle kalıyor.
- Üçüncü taraf veri İBB doğrulanmış gibi görünmüyor.
- 153 mock'u ürünün tamamlayıcı konumunu teknik olarak gösteriyor.

### Test ve kanıt

- Adapter contract tests.
- Schema/mapping/quarantine fixtures.
- Retry/rate-limit/stale integration.
- Source license/provenance validation.
- E2E data source unavailable/manual entry.

---

## WP-18 - Admin, RBAC, audit, privacy request ve demo supervisor

### Amaç

Tek demo hesabıyla hızlı sunum sağlarken gerçek permission modelini, denetimi ve vatandaş veri haklarını görünür biçimde tamamlamak.

### Bağımlılık

WP-14, WP-17.

### Uygulama görevleri

1. Tek `demo_supervisor` hesabına gerekli permission setini ver; her eylemde aktif rol bağlamını göster.
2. Reviewer, unit officer, planner ve system admin permission'larını domain policy'de ayrı tut.
3. User/role/unit yönetim ekranlarını demo kapsamına uygun tamamla.
4. Audit explorer filtre, detail ve export ekle.
5. Orijinal medya erişim nedenini ve audit kaydını göster.
6. KVKK erişim/düzeltme/silme ve otomatik değerlendirme itirazı akışlarını uygula.
7. Hesap silme talebinde re-auth, tracking no ve yeni report engelini uygula.
8. Abuse review, kademeli geçici restriction ve appeal uygula; otomatik kalıcı ceza yok.
9. Demo reset/import/export izinlerini ve confirmation'ı tamamla.
10. Security/data source alerts ve failed automation bildirimlerini ekle.

### Kabul ölçütleri

- Tek supervisor demo akışını tamamlıyor fakat permission bypass etmiyor.
- Rol bağlamı ve permission audit'te görünüyor.
- Citizen privacy request takip numarası alıyor.
- Account deletion pending durumunda yeni report engelleniyor.
- Restriction insan kararı ve itiraz taşıyor.
- Audit geçmişi UI'dan değiştirilemiyor.

### Test ve kanıt

- Authorization matrix integration.
- E2E-17, 21, 22.
- Original media audit test.
- Reset/import permission testleri.

---

## WP-19 - Güvenlik ve gizlilik hardening

### Amaç

Demo istemci ve server yüzeylerini tehdit modeline göre sertleştirmek; güvenlik iddialarını test kanıtına bağlamak.

### Bağımlılık

WP-11 - WP-18.

### Uygulama görevleri

1. `docs/security/THREAT_MODEL.md` oluştur; assets, actors, trust boundaries ve abuse cases tanımla.
2. STRIDE veya eşdeğer yöntemle route, JSON, media, server, AI ve source adapter tehditlerini analiz et.
3. OWASP MASVS client ve ASVS-benzeri server kontrol matrisi oluştur.
4. Secret/PII log redaction ve fixture scanning'i CI'da zorunlu yap.
5. Session expiry, re-auth, brute-force delay ve CSRF/CORS/origin ihtiyaçlarını demo server için ele al.
6. Media ID enumeration, path traversal ve unauthorized original access testleri yaz.
7. Import JSON ile role/audit escalation'ı engelle.
8. GPS spoof/replay/same-image/rate abuse sinyallerini ölçülü uygula.
9. Prompt/model injection içeriğini veri olarak izole et.
10. EXIF, thumbnail ve error payload leakage testleri yaz.
11. Dependency audit ve lisans raporu üret.
12. P0/P1 bulguları kapat; P2 için sahip/tarih ata.

### Kabul ölçütleri

- Threat model bütün trust boundary'leri kapsıyor.
- Secret/PII scan temiz.
- Yetkisiz route/media/import denemeleri reddediliyor ve audit ediliyor.
- Public payload içinde internal note, full phone, trust/abuse profil puanı veya original ref yok.
- OWASP değerlendirme raporu kapsam ve başarısız kontrolleri dürüstçe gösteriyor.

### Test ve kanıt

- Security test suite.
- Static/dependency/secret scan sonuçları.
- Manual authenticated role review; OWASP, her rol için test hesabı ve kapsamın açık raporlanmasını önerir. [OWASP MASVS Assessment](https://mas.owasp.org/MASVS/04-Assessment_and_Certification/)
- `docs/security/SECURITY_REVIEW.md`.

---

## WP-20 - Türkçe/İngilizce, WCAG 2.2 AA ve platform paritesi

### Amaç

Bütün tanımlı akışların Android, iOS ve webde; Türkçe/İngilizce ve yardımcı teknolojilerle işlev kaybetmeden çalışmasını sağlamak.

### Bağımlılık

WP-11 - WP-19.

### Uygulama görevleri

1. Bütün hard-coded kullanıcı metinlerini localization'a taşı.
2. Türkçe ve İngilizce çevirileri tamamla; fallback ve missing-key CI kontrolü ekle.
3. Tarih, saat, sayı, telefon ve çoğul biçimlerini locale göre uygula.
4. Yüzde 200 text ve web yüzde 400 zoom/reflow denetimi yap.
5. Klavye ile citizen/staff ana rotalarını tamamla.
6. TalkBack, VoiceOver, NVDA/Chrome ve VoiceOver/Safari manuel testlerini yürüt.
7. Focus not obscured, target size, accessible authentication ve redundant entry kriterlerini kontrol et.
8. Drag gerektiren etkileşimlere düğme alternatifi ver.
9. Reduced motion, high contrast ve screen orientation durumlarını test et.
10. Camera/location plugin lifecycle'ını Android/iOS/webde doğrula.
11. Bütün viewport golden'larını TR/EN ve long-text varyantlarıyla güncelle.
12. `docs/accessibility/VPAT_LITE.md` veya erişilebilirlik uygunluk raporu oluştur.

### Kabul ölçütleri

- Eksik localization key yok.
- Ana akış yalnız klavyeyle tamamlanıyor.
- Haritanın eşdeğer listesi tam işlevli.
- P0/P1 accessibility bug 0.
- Android/iOS/webde kritik akış aynı sonucu üretiyor.
- Native permission denial/recovery çalışıyor.
- WCAG 2.2 AA kontrol matrisi kanıtlı. W3C, WCAG 2.2'yi güncel standart olarak önerir. [W3C WCAG 2 Overview](https://www.w3.org/WAI/standards-guidelines/wcag/)

### Test ve kanıt

- Semantics tree snapshots.
- Keyboard/focus integration.
- Automated accessibility checks.
- Manuel cihaz/AT matrisi.
- TR/EN golden diff onayı.

---

## WP-21 - Performans, offline, recovery ve kaos senaryoları

**Durum: BLOCKED** — Kaynak uygulaması ve SDK-bağımsız benchmark/kaos testleri hazırdır; Flutter profile trace, DevTools memory/jank ve gerçek plugin/platform kanıtı beklenir.

### Amaç

Uygulamayı yavaş cihaz, 10.000 kayıt, kesintili ağ, bozuk veri ve plugin lifecycle koşullarında kararlı hâle getirmek.

### Bağımlılık

WP-07 - WP-20.

### Uygulama görevleri

1. Cold/warm start, route, list/filter, map projection, JSON parse ve AI latency benchmark'larını ölç.
2. 10.000 olay fixture ile staff queue ve map performansını optimize et.
3. Rebuild, memory, image cache ve jank profili çıkar.
4. Lazy list, memoized projection, thumbnail ve gerektiğinde isolate/compute uygula.
5. Offline state matrixini bütün ekranlarda test et.
6. Ağ flapping, timeout, 429, malformed JSON, stale source ve server restart kaos testleri yap.
7. Camera background/resume, low storage ve media quota testleri yap.
8. Active snapshot corruption ve migration failure recovery'yi test et.
9. Shared client revision loss/reconnect ve conflict'i test et.
10. AI timeout/unavailable durumunda manuel akışı doğrula.
11. Performance bütçesi ihlalini CI veya benchmark raporunda bloklayıcı yap.

### Kabul ölçütleri

- ARCHITECTURE performans bütçeleri sağlanıyor veya ADR ile kanıtlı revize edilmiş.
- Görünür jank yok.
- 10.000 kayıtta filtre/sort hedefi sağlanıyor.
- Ağ kesintisi veri kaybettirmiyor.
- Bozuk snapshot güvenli kurtarılıyor.
- App background/resume akışı bozmuyor.
- Tile/AI/source kesintisi tüm uygulamayı blocking error'a düşürmüyor.

### Test ve kanıt

- Integration performance traces.
- Benchmark JSON raporu.
- Memory/jank screenshots veya DevTools export.
- Chaos scenario test sonuçları.

---

## WP-22 - Tam E2E, golden, regresyon ve bug burn-down

**Durum: BLOCKED** — E2E-01–30 izlenebilirliği, coverage/golden/build CI kapıları ve regresyon test kaynakları hazırdır; onaylı golden baseline, analyzer/test coverage ve Android/iOS/web release build kanıtı beklenir.

### Amaç

Özellik geliştirmeyi dondurup bütün ürün akışlarını temiz ortamda uçtan uca doğrulamak ve açık P0/P1 hatayı sıfırlamak.

### Bağımlılık

WP-11 - WP-21.

### Uygulama görevleri

1. `ARCHITECTURE.md` E2E-01 - E2E-30 senaryolarını yeni ürün kararlarıyla güncelle ve `docs/acceptance_matrix.json` ile teste bağla.
2. Aşağıdaki yeni senaryoları ekle:
   - UrbanIncident altında çoklu kaynak/report;
   - 153 external ref mock sync;
   - structured corroboration;
   - photo-free accessibility route;
   - resolution confirmation/reopen review;
   - official read-only alert;
   - role-specific AI visibility;
   - real-schema source adapter.
3. Bütün ekranlarda state matrix testlerini tamamla.
4. Golden matrisi ve semantic snapshots'ı review et.
5. Full regression Android, iOS ve webde çalıştır.
6. Clean install, upgrade/migration, reset ve restore testleri yap.
7. P0/P1 bug burn-down yap; root cause + regression test olmadan kapatma.
8. Flaky testleri düzelt; retry ile gizleme.
9. Coverage ve untested critical branch raporu çıkar.
10. `docs/ACCEPTANCE_REPORT.md` oluştur.

### Kabul ölçütleri

- Bütün zorunlu E2E yeşil.
- P0/P1 bug 0.
- Analyzer warning 0.
- Unhandled exception/browser console error 0.
- Golden değişiklikleri tasarım sorumlusu review'undan geçmiş.
- Kritik branch coverage en az %90, genel en az %80.
- Üç platform release build başarılı.

### Kapsam dışı

Yeni özellik. Yalnız kabulü engelleyen düzeltme yapılır.

---

## WP-23 - Pilot analitiği, KPI/ROI, jüri senaryosu ve release paketi

### Amaç

Çalışan ürünü ölçülebilir pilot ve hatasız jüri sunumu için paketlemek.

### Bağımlılık

WP-22.

### Uygulama görevleri

1. Privacy-safe domain metrics event'lerini uygula:
   - first human review;
   - first-pass routing;
   - duplicate cluster;
   - staff override;
   - resolution;
   - repeat status request;
   - citizen resolution feedback.
2. Demo/pilot KPI dashboard'ını gerçek hesap formülleriyle oluştur; sahte üretim metriği kullanma.
3. Baseline, hedef ve go/no-go rapor şablonlarını ekle.
4. ROI hesaplayıcısını değişken/formül tabanlı yap.
5. 7 dakikalık `EKSTRA.md` demo rotasını `DemoScenario` olarak hazırla.
6. Demo reset, clock advance, source outage ve AI failure kontrollerini tek yerde topla.
7. Sunum runbook'u oluştur:
   - cihazlar;
   - ağ;
   - server başlatma;
   - hesaplar;
   - reset;
   - fallback;
   - beklenen ekranlar;
   - kurtarma.
8. Android APK/AAB ihtiyaca göre, iOS build kanıtı ve web release üret.
9. Build checksum, SBOM, dependency/license listesi ve release notes üret.
10. Demo verisi ve simüle AI etiketlerini son kez doğrula.
11. Üç tam prova yap; süre ve hata logunu raporla.

### Kabul ölçütleri

- KPI dashboard türetilmiş gerçek demo olaylarından hesaplanıyor.
- ROI rakamı girdi olmadan uydurulmuyor.
- 7 dakikalık akış üç kez reset sonrası aynı sonucu veriyor.
- İnternet yoksa ana hikâye tamamlanıyor.
- Bir gerçek/gerçek şemalı source kanıtı gösterilebiliyor.
- Release dosyaları checksum ve sürüm bilgisi taşıyor.
- Jüriye üretim-ready iddiası yapılmıyor.

### Test ve kanıt

- Release build smoke tests.
- Demo rehearsal report.
- KPI formula unit tests.
- Clean device install.
- Offline fallback rehearsal.

---

## WP-24 - Bağımsız son denetim, hata kapatma ve release candidate freeze

### Amaç

Projeyi geliştiren ajan varsayımlarından bağımsız biçimde yeniden incelemek; doküman-kod-test uyumunu kanıtlamak ve son release candidate'ı dondurmak.

### Bağımlılık

WP-23.

### Denetim ilkesi

Mümkünse bu paket önceki uygulamaları yapmamış ayrı bir AI ajanı veya insan reviewer tarafından yürütülür. Aynı ajan yürütürse önceki çözümü doğru kabul etmeden temiz checkout üzerinden adversarial denetim yapar.

### Uygulama görevleri

1. Temiz checkout ve temiz dependency cache ile kurulumu doğrula.
2. Kanonik belgeleri tam okuyup code-to-requirement traceability denetimi yap.
3. Her WP raporunun kabul ölçütü ve test kanıtını kontrol et.
4. Bütün kalite komutlarını sıfırdan çalıştır.
5. Android/iOS/web release build'lerini temiz ortamda doğrula.
6. İki cihaz shared demo, local fallback ve offline rotayı tekrar çalıştır.
7. Yetki, privacy, source authority, AI failure ve data corruption senaryolarına odaklı red-team turu yap.
8. Klavye, ekran okuyucu, yüzde 200 text ve reduced motion ana rotasını tekrar doğrula.
9. Jüri demo provasını izleyip ölü zaman, belirsiz mesaj ve çelişkili iddiayı düzelt.
10. Yalnız P0/P1 ve release blocker düzeltmesi yap; yeni özellik ekleme.
11. Her düzeltmeye regresyon testi ekle ve tüm suite'i tekrar çalıştır.
12. `FINAL_AUDIT.md`, `RELEASE_MANIFEST.md` ve bilinen sınırlar listesini üret.
13. RC sürüm numarasını ve commit hash'ini dondur.
14. İnsan onayı sonrası release tag oluştur; onay olmadan tag/publish yapma.

### Kabul ölçütleri

- Temiz ortam kurulumundan jüri demosuna kadar bloklayıcı sorun yok.
- P0/P1 hata 0.
- Docs-code-test traceability eksiksiz.
- Bütün zorunlu test/build kontrolleri yeşil.
- Güvenlik ve erişilebilirlik açık blocker yok.
- Release manifest bütün artifact checksum'larını taşıyor.
- Bilinen P2/P3 sınırlar dürüstçe listelenmiş.
- RC sonrasında kod değişimi yalnız yeni fix paketi ve yeniden tam testle yapılabiliyor.

### Son çıkış kapısı

Teknik lider, ürün sahibi, tasarım sorumlusu ve gerekli güvenlik/KVKK rolünün yazılı kabulü.

---

## 12. Paketler arası kabul zinciri

Bir sonraki paket, öncekinin koduna değil **kanıtlanmış sözleşmesine** dayanır:

```text
Karar -> Repo -> Domain -> Persistence -> Shell -> Design -> Walking Skeleton
      -> Shared Sync -> Map/Media/AI -> Citizen -> Staff -> Operations
      -> Data/Admin -> Security/A11y/Performance -> Full E2E -> Release -> Audit
```

Kritik geri dönüş kuralları:

- Domain modeli değişirse WP-02 ve etkilenen bütün contract testleri yeniden açılır.
- JSON schema değişirse migration ve import/export testleri zorunludur.
- Tasarım tokenı değişirse etkilenen bütün golden'lar görsel review ister.
- Yetki değişirse full authorization matrix yeniden çalışır.
- AI output schema değişirse evaluation ve role projection testleri yeniden çalışır.
- Source mapping değişirse provenance/quarantine ve incident dedup testleri yeniden çalışır.

---

## 13. Hata ve blokaj politikası

### 13.1 Ajanın yapmaması gerekenler

- Bağımlılık geçmeden sonraki pakete atlamak.
- Testi silerek veya skip ederek yeşil görünmek.
- Çalışmayan entegrasyonu statik success ile gizlemek.
- Kullanıcı değişikliğini geri almak.
- Kapsamı genişletmek için büyük refactor yapmak.
- Gerçek servis anahtarını repoya koymak.
- Gerçek İBB sistemine izin olmadan yazmak.
- Demo fake'ini canlı servis gibi etiketlemek.
- UI'yı screenshot/mock ile “tamamlandı” saymak.
- P0/P1 bulguyu yalnız raporlayıp paket tamamlamak.

### 13.2 Blocked durum

Paket yalnız şu durumlarda `BLOCKED` olur:

- onay gerektiren ürün/AI/KVKK kararı yok;
- zorunlu kurum verisi/asset/API sağlanmamış ve güvenli fixture ile sözleşme kanıtlanamıyor;
- platform build ortamı veya permission erişimi yok;
- önceki paket kabulü başarısız;
- güvenlik/policy gereği işlem yapılamıyor.

Blocked raporu kesin engel, denenmiş güvenli yollar ve kullanıcıdan gereken tek kararı içermelidir.

---

## 14. Değişiklik yönetimi

Yeni özellik talebi geldiğinde doğrudan mevcut WP'ye sıkıştırılmaz.

1. Ürün etkisi değerlendirilir.
2. ADR gerekir mi belirlenir.
3. Hangi paket ve testlerin etkilendiği çıkarılır.
4. Roadmap'e `WP-XXA` ek paket veya sonraki faz olarak eklenir.
5. Kabul zinciri yeniden hesaplanır.

Kritik güvenlik veya veri hatası için `FIX-WP-XX-NN` oluşturulur; düzeltme sonrası etkilenen bütün downstream testleri çalıştırılır.

---

## 15. Nihai teslim içeriği

WP-24 sonunda teslim paketi en az şunları içerir:

- Flutter kaynak kodu;
- demo server kaynak kodu;
- kanonik belgeler ve ADR'ler;
- seed/fixture ve lisans manifesti;
- Android release APK/AAB;
- iOS build/test kanıtı;
- web release build;
- full test ve coverage raporu;
- golden/visual review kanıtı;
- accessibility raporu;
- security/threat model raporu;
- data source/provenance raporu;
- AI evaluation raporu;
- pilot KPI/ROI şablonu;
- demo runbook ve hesaplar;
- release manifest, checksum ve SBOM;
- bilinen sınırlar;
- final audit ve onay kaydı.

---

## 16. Başarı hükmü

Proje yalnız uygulama açıldığı için tamamlanmış sayılmaz. Başarı:

- vatandaşın erişilebilir biçimde bildirim oluşturması;
- bildirimin gizlilik ve AI yardımcı analizinden geçmesi;
- aynı olayla güvenli biçimde ilişkilendirilmesi;
- personelin doğru kaynak ve gerekçeyle karar vermesi;
- olayın doğru role doğru pinle yansıması;
- saha/çözüm bilgisinin vatandaşa geri dönmesi;
- iki cihazın aynı durumu görmesi;
- offline/hata koşulunda veri kaybolmaması;
- gerçek/simüle veri ayrımının dürüst olması;
- bütün bunların Android, iOS ve webde test kanıtıyla doğrulanması

ile ölçülür.

WP-00 - WP-24 zinciri eksiksiz geçmeden proje release candidate kabul edilmez.

---

## 17. Metodoloji ve kalite dayanakları

- [Flutter - Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter - Testing overview](https://docs.flutter.dev/testing/overview)
- [W3C - WCAG 2 Overview](https://www.w3.org/WAI/standards-guidelines/wcag/)
- [W3C - What's New in WCAG 2.2](https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/)
- [OWASP Mobile Application Security Verification Standard](https://mas.owasp.org/MASVS/)
- [OWASP MASVS Assessment and Certification Guidance](https://mas.owasp.org/MASVS/04-Assessment_and_Certification/)
