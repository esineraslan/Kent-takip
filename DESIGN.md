---
version: "alpha"
name: "İBB Kent Takip"
description: "İstanbul'daki doğrulanmış aktif ve planlanan kent olaylarını haritada gösteren, vatandaş bildirimlerini alan ve belediye inceleme sürecini yöneten mobil uygulama ve web paneli tasarım sistemi."
colors:
  brand-blue-900: "#003378"
  brand-blue-800: "#0E3B83"
  brand-blue-700: "#1457A6"
  brand-blue-100: "#DCE8F7"
  brand-blue-050: "#F2F7FF"
  brand-magenta-700: "#A91850"
  brand-magenta-600: "#C31E60"
  brand-magenta-100: "#F8DCE8"
  white: "#FFFFFF"
  surface-page: "#F4F7FB"
  surface-subtle: "#EAF0F7"
  text-strong: "#172033"
  text-default: "#30394D"
  text-muted: "#5D687C"
  border-default: "#D7DFEA"
  border-strong: "#AEB9C9"
  event-active: "#C12637"
  event-active-dark: "#7E1321"
  event-planned: "#F4C542"
  event-planned-ink: "#3B3000"
  event-pending: "#687386"
  event-pending-dark: "#394254"
  event-critical: "#B84A00"
  event-critical-dark: "#713000"
  success: "#1D7A55"
  success-surface: "#E4F4ED"
  warning-surface: "#FFF4D6"
  danger-surface: "#FBE7EA"
  info-surface: "#E6F0FC"
  focus: "#C31E60"
  map-water: "#CFE4F5"
  map-land: "#F4F3EF"
  map-road: "#FFFFFF"
  map-road-outline: "#D6DBE3"
typography:
  display:
    fontFamily: "Rubik, Urbanist, system-ui, sans-serif"
    fontSize: "2.5rem"
    fontWeight: 700
    lineHeight: "3rem"
    letterSpacing: "-0.02em"
  h1:
    fontFamily: "Rubik, Urbanist, system-ui, sans-serif"
    fontSize: "2rem"
    fontWeight: 700
    lineHeight: "2.5rem"
    letterSpacing: "-0.015em"
  h2:
    fontFamily: "Rubik, Urbanist, system-ui, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 700
    lineHeight: "2rem"
  h3:
    fontFamily: "Urbanist, system-ui, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 700
    lineHeight: "1.75rem"
  body-lg:
    fontFamily: "Urbanist, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 500
    lineHeight: "1.75rem"
  body:
    fontFamily: "Urbanist, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 500
    lineHeight: "1.5rem"
  body-sm:
    fontFamily: "Urbanist, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 500
    lineHeight: "1.25rem"
  label:
    fontFamily: "Urbanist, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 700
    lineHeight: "1.125rem"
  caption:
    fontFamily: "Urbanist, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 600
    lineHeight: "1rem"
rounded:
  none: "0px"
  xs: "4px"
  sm: "6px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  full: "999px"
spacing:
  0: "0px"
  1: "4px"
  2: "8px"
  3: "12px"
  4: "16px"
  5: "20px"
  6: "24px"
  8: "32px"
  10: "40px"
  12: "48px"
  16: "64px"
components:
  button-primary-mobile:
    backgroundColor: "{colors.brand-blue-800}"
    textColor: "{colors.white}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 20px"
    height: "48px"
  button-primary-web:
    backgroundColor: "{colors.brand-blue-800}"
    textColor: "{colors.white}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "40px"
  button-primary-hover:
    backgroundColor: "{colors.brand-blue-900}"
    textColor: "{colors.white}"
  button-primary-pressed:
    backgroundColor: "{colors.brand-blue-900}"
    textColor: "{colors.white}"
  button-secondary:
    backgroundColor: "{colors.white}"
    textColor: "{colors.brand-blue-800}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "40px"
  button-danger:
    backgroundColor: "{colors.event-active}"
    textColor: "{colors.white}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "40px"
  input-mobile:
    backgroundColor: "{colors.white}"
    textColor: "{colors.text-strong}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "0 14px"
    height: "48px"
  input-web:
    backgroundColor: "{colors.white}"
    textColor: "{colors.text-strong}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.md}"
    padding: "0 12px"
    height: "40px"
  card-default:
    backgroundColor: "{colors.white}"
    textColor: "{colors.text-default}"
    rounded: "{rounded.lg}"
    padding: "16px"
  card-compact:
    backgroundColor: "{colors.white}"
    textColor: "{colors.text-default}"
    rounded: "{rounded.md}"
    padding: "12px"
  bottom-sheet:
    backgroundColor: "{colors.white}"
    textColor: "{colors.text-default}"
    rounded: "{rounded.xl}"
    padding: "20px 16px"
  map-control-mobile:
    backgroundColor: "{colors.white}"
    textColor: "{colors.brand-blue-800}"
    rounded: "{rounded.md}"
    size: "44px"
  map-control-web:
    backgroundColor: "{colors.white}"
    textColor: "{colors.brand-blue-800}"
    rounded: "{rounded.md}"
    size: "36px"
  pin-active:
    backgroundColor: "{colors.event-active}"
    textColor: "{colors.white}"
    rounded: "{rounded.full}"
    size: "36px"
  pin-planned:
    backgroundColor: "{colors.event-planned}"
    textColor: "{colors.event-planned-ink}"
    rounded: "{rounded.full}"
    size: "36px"
  pin-pending:
    backgroundColor: "{colors.event-pending}"
    textColor: "{colors.white}"
    rounded: "{rounded.full}"
    size: "36px"
  pin-critical:
    backgroundColor: "{colors.event-critical}"
    textColor: "{colors.white}"
    rounded: "{rounded.xs}"
    size: "40px"
  status-chip:
    typography: "{typography.caption}"
    rounded: "{rounded.full}"
    padding: "4px 8px"
    height: "24px"
  table-row:
    backgroundColor: "{colors.white}"
    textColor: "{colors.text-default}"
    typography: "{typography.body-sm}"
    height: "52px"
  navigation-mobile:
    backgroundColor: "{colors.white}"
    textColor: "{colors.text-muted}"
    height: "72px"
  navigation-web:
    backgroundColor: "{colors.brand-blue-900}"
    textColor: "{colors.white}"
    width: "232px"
---

# İBB Kent Takip — Tasarım Sistemi ve Ekran Spesifikasyonu

Belge durumu: Uygulamaya hazır tasarım kaynağı  
Kapsam: Vatandaş mobil uygulaması + belediye masaüstü web paneli  
Dayanak belgeler: `PRODUCT.md`/`product.txt` ve `USER_FLOWS.md`/`akış.txt`  
Hedef standart: WCAG 2.2 AA  
Dil: Türkçe, cümle düzeni (sentence case)

Kanonik düzeltme (17 Ağustos 2026): Üretim yüzeyi İstanbul Senin/153 içindeki Kent Takip modülüdür; bağımsız kabuk demodur. Vatandaşa ham AI puanı veya kişi güven skoru gösterilmez. Fotoğraflı akış ana rota olmakla birlikte “Fotoğrafsız devam” erişilebilir manuel inceleme rotası zorunludur. Olay çalışma alanı `UrbanIncident` altında çoklu report/source/work referansı, SLA ve çözüm kanıtını gösterir.

## Overview

### 1. Ürün adı

Kesin ürün adı **İBB Kent Takip** olacaktır.

Kısa kullanım: **Kent Takip**  
Tanımlayıcı alt satır: **Şehirde olanı gör, bildirimini takip et.**

Ad seçim gerekçesi:

- “Kent” kapsamı yalnızca trafik veya şikâyetle sınırlamaz.
- “Takip” hem aktif/planlanan olayları görmeyi hem vatandaş bildirimlerinin çözüm sürecini izlemeyi karşılar.
- İBB hizmet adlandırmalarındaki doğrudan ve işlevsel dile uyar; soyut teknoloji veya yapay zekâ iddiası taşımaz.
- Belediye web panelinde de aynı ad kullanılabilir: “İBB Kent Takip Yönetim Paneli”.

### 2. Marka mimarisi

Kent Takip bağımsız bir belediye logosu üretmez. Resmî İBB logosu ile ürün adı iki ayrı öğedir.

- Mobil üst çubukta resmî İBB amblemi/logo varlığı ile “Kent Takip” metni arasında 1 px ayırıcı bulunur.
- Ürün adı, resmî logonun güvenli alanının dışında yer alır; logoyla birleşik yeni bir lock-up oluşturulmaz.
- Açılış ekranı, telefonla giriş ve belediye paneli girişinde resmî logo eksiksiz kullanılır.
- Dar mobil başlıkta yalnızca resmî olarak onaylanmış amblem varyantı kullanılabilir; geliştirme ekibi logoyu kırpamaz veya logotype'ı kendisi yeniden yazamaz.
- Koyu zeminde resmî dişi/beyaz logo; açık zeminde resmî eril/mavi logo kullanılır.
- Logo döndürülemez, gölgelendirilemez, degrade edilemez, yeniden renklendirilemez ve başka yazıyla birleştirilemez.
- Nihai uygulama ikonu ve mağaza görselleri İBB Kurumsal İletişim onayına gider. Prototipte resmî logo, `brand-blue-900` zemin üzerinde güvenli alanıyla kullanılır.

### 3. Tasarım yönü

Tasarımın adı: **Sivil netlik, İstanbul derinliği**.

Arayüz bir kampanya sitesi değil, günlük kullanılan bir kamu hizmetidir. Bu nedenle:

- Mobil uygulama harita merkezli, sakin ve tek elle kullanılabilir olur.
- Belediye paneli veri yoğun, hızlı taranabilir ve klavyeyle yönetilebilir olur.
- Marka hissi büyük dekorasyonlardan değil; mavi-magenta dengesi, tipografi, ölçülü köşeler, net düğmeler ve resmî dil tutarlılığından gelir.
- Derinlik; kart yığını veya cam efektiyle değil, yüzey katmanları, kontrollü gölge, sabit araç çubukları ve harita üzerindeki okunaklı kontrollerle kurulur.
- İstanbul'a özgülük; gerçek harita, semt/mahalle adları, resmî logo ve gerektiğinde sade Boğaz kıyı çizgisi illüstrasyonuyla verilir. Dekoratif martı, skyline veya köprü görseli her ekrana tekrarlanmaz.

### 4. Ürün deneyimi ilkeleri

1. **Harita ilk bakışta işe yarar olmalı.** Kullanıcı giriş yapmadan güncel ve planlanan olayları görebilir.
2. **Resmî ve doğrulanmamış bilgi karışmamalı.** Renk, ikon, metin ve görünürlük kuralları birlikte çalışır.
3. **Vatandaş doğru kurumu bilmek zorunda değildir.** Form, birim seçtirmez; kategori önerir ve İBB yönlendirir.
4. **Yapay zekâ yardımcıdır.** AI çıktısı öneri, sinyal veya ön inceleme olarak etiketlenir; karar gibi sunulmaz.
5. **İzinler bağlamında istenir.** Konum, kamera ve bildirim izinleri ilk açılışta topluca istenmez.
6. **Kritik durum yanlış güven yaratmamalı.** Uygulamanın acil çağrı sistemi olmadığı görünür ve anlaşılır biçimde anlatılır.
7. **Her işlem sonuç üretir.** Gönderim, yönlendirme, hata, taslak ve çözüm durumları kullanıcıya açıkça bildirilir.
8. **Yoğunluk hiyerarşiyle çözülür.** Daha fazla kart veya renk değil, doğru sıralama ve filtreleme kullanılır.

### 5. Arayüz modları

- **Mobil vatandaş uygulaması: Operate.** Kullanıcı haritada bilgi bulur, bildirim gönderir, süreci takip eder.
- **Belediye paneli: Operate.** Personel kuyruk tarar, kanıt inceler, karar verir, yönlendirir ve günceller.
- **Yardım/KVKK sayfaları: Read.** Uzun metinlerde okunabilir ölçü, içindekiler ve sade tipografi önceliklidir.
- **Tanıtım veya yarışma açılış ekranı: Persuade, sınırlı.** Yalnızca açılış/landing yüzeyinde daha güçlü görsel kimlik kullanılabilir; operasyon ekranlarına taşınmaz.

## Colors

### 1. Kurumsal ana palet

| Rol | Token | Değer | Kullanım |
|---|---|---:|---|
| Ana koyu mavi | `brand-blue-900` | `#003378` | Belediye paneli yan menüsü, koyu başlık, güçlü kurumsal zemin |
| Ana etkileşim mavisi | `brand-blue-800` | `#0E3B83` | Birincil düğme, aktif navigasyon, bağlantı, odak dışı ana ikon |
| Etkileşim hover | `brand-blue-700` | `#1457A6` | Hover, seçili açık tonlu yüzeyin koyu öğesi |
| Açık mavi | `brand-blue-100` | `#DCE8F7` | Seçili satır, bilgi paneli, ikincil durum zemini |
| Çok açık mavi | `brand-blue-050` | `#F2F7FF` | Giriş/boş durum ve sakin vurgu yüzeyi |
| Magenta vurgu | `brand-magenta-600` | `#C31E60` | Odak halkası, ikincil marka vurgusu, özel giriş/İstanbul Senin bağlantısı |
| Magenta koyu | `brand-magenta-700` | `#A91850` | Magenta hover/pressed |

Magenta, ikinci bir ana eylem rengi değildir. Aynı ekranda mavi ve magenta iki eşit CTA olarak yarıştırılmaz. Magenta yalnızca marka vurgusu, odak, İstanbul Senin ilişkisi veya tekil ikincil kampanya öğesi olarak kullanılır.

### 2. Nötr palet

| Rol | Token | Değer |
|---|---|---:|
| Sayfa zemini | `surface-page` | `#F4F7FB` |
| Kart/alan zemini | `white` | `#FFFFFF` |
| İkincil yüzey | `surface-subtle` | `#EAF0F7` |
| Güçlü metin | `text-strong` | `#172033` |
| Gövde metni | `text-default` | `#30394D` |
| Yardımcı metin | `text-muted` | `#5D687C` |
| Standart sınır | `border-default` | `#D7DFEA` |
| Güçlü sınır | `border-strong` | `#AEB9C9` |

Saf siyah uzun gövde metninde kullanılmaz. Nötrler mavi alt tonludur; böylece ürün İBB paletinden kopmadan sakin kalır.

### 3. Olay ve inceleme paleti

| Durum | Renk | İkon | Kim görür | Anlam |
|---|---:|---|---|---|
| Doğrulanmış aktif | `#C12637` | `!` | Herkes + personel | Belediye doğruladı, olay aktif |
| Planlanan | `#F4C542` | Saat | Herkes + personel | Belediye yayınladı, henüz başlamadı |
| Doğrulama bekliyor | `#687386` | `?` | Bildirimi yapan kişi; kurala göre personel | Resmî doğrulama yok |
| Kritik inceleme | `#B84A00` | Uyarı üçgeni | Yalnızca yetkili personel | Yüksek/kritik risk sinyali, insan incelemesi şart |

Kurallar:

- Durum yalnızca renkle anlatılmaz; ikon, kısa etiket ve erişilebilir ad birlikte kullanılır.
- Kırmızı pin “tehlike kesin” demek değildir; “belediyece doğrulanmış aktif olay” demektir.
- Turuncu pin “doğrulanmış kritik olay” değil, “kritik inceleme sinyali” demektir ve vatandaşa gösterilmez.
- Sarı pin üzerinde ikon ve metin koyu `event-planned-ink` kullanır; beyaz ikon kullanılmaz.
- Harita lejantı ilk kullanımda açık, sonraki kullanımlarda tek satırlık “Simgeler” düğmesi olarak kapalı tutulabilir.

### 4. Semantik durumlar

- Başarı: `success` / `success-surface`
- Uyarı: `event-planned-ink` / `warning-surface`
- Hata ve geri döndürülemez işlem: `event-active-dark` / `danger-surface`
- Bilgi: `brand-blue-800` / `info-surface`

Olay kırmızısı ile form hatası aynı renk ailesini paylaşabilir, ancak bağlamları ikon ve bileşen türüyle ayrılır. Form hatasında pin simgesi kullanılmaz.

### 5. Harita tabanı

Harita özel stili görsel gürültüyü azaltır:

- Su: `map-water`
- Kara: `map-land`
- Ana yollar: beyaz, `map-road-outline` konturlu
- Yerel yollar: düşük kontrastlı gri
- Park/yeşil alan: doygun olmayan `#DCEAD8`
- Yapı kütleleri: `#E8E6E1`
- İlçe adı: `text-strong`, mahalle adı: `text-muted`
- Ticari POI ikonları varsayılan olarak kapalıdır; belediye hizmetleri ve ulaşım düğümleri filtreyle açılır.
- Trafik yoğunluk katmanı açıldığında pin renkleri beyaz halo ve koyu konturla ayrışır.

### 6. Kontrast kuralları

- Normal metin kontrastı en az 4.5:1.
- 18 pt/24 px veya 14 pt/18.67 px kalın büyük metin en az 3:1.
- İkon, sınır, seçili durum ve odak gibi metin dışı öğeler en az 3:1.
- Placeholder tek başına etiket değildir ve `text-muted` değerinden daha açık olamaz.
- Fotoğraf veya harita üzerine doğrudan metin konmaz; opak yüzey veya sabit bilgi kartı kullanılır.

## Typography

### 1. Yazı tipi ailesi

- **Rubik:** Açılış, H1 ve sınırlı sayıda H2. İBB Çözüm Merkezi'ndeki güçlü, kamusal başlık hissini taşır.
- **Urbanist:** Gövde, navigasyon, form, tablo ve işletim arayüzü. Güncel İBB ana web arayüzüyle aynı aileyi sürdürür ve Türkçe karakter desteği vardır.
- Lisans veya yükleme engelinde sistem fallback'i kullanılır; metrik değişimi sebebiyle tasarım görsel testten geçirilir.
- Belediye paneli sayısal sütunlarında `font-variant-numeric: tabular-nums` kullanılır.

### 2. Mobil tipografi ölçeği

| Stil | Boyut / satır | Ağırlık | Kullanım |
|---|---|---:|---|
| Mobil display | 32/38 | 700 Rubik | İlk açılış veya tek cümlelik kritik başlık |
| Mobil H1 | 24/30 | 700 Rubik | Ekran başlığı |
| Mobil H2 | 20/26 | 700 Rubik | Bölüm başlığı |
| Mobil H3 | 18/24 | 700 Urbanist | Kart veya alt bölüm |
| Gövde | 16/24 | 500 Urbanist | Ana açıklama ve form değeri |
| Küçük gövde | 14/20 | 500 Urbanist | Metadata ve yardımcı açıklama |
| Etiket | 14/18 | 700 Urbanist | Düğme, alan etiketi, sekme |
| Açıklama | 12/16 | 600 Urbanist | Zaman, kaynak, kısa yardımcı metin |

### 3. Web tipografi ölçeği

- Sayfa H1: 32/40, Rubik 700
- Bölüm H2: 24/32, Rubik 700
- Panel H3: 20/28, Urbanist 700
- Tablo/kompakt gövde: 14/20, Urbanist 500
- Form etiketi: 14/18, Urbanist 700
- Sayaç/metric: 24/28, Urbanist 700, tabular numerals

### 4. Tipografi davranışı

- Başlıklar sentence case yazılır: “Gelen bildirimler”; tamamı büyük harf kullanılmaz.
- Kısa durum etiketlerinde tamamı büyük harf kullanılmaz.
- Metin satır uzunluğu yardım sayfalarında 65–75 karakter, form açıklamalarında en fazla 55 karakterdir.
- Bir ekranda en fazla dört görünür yazı boyutu bulunur.
- Hiyerarşi yalnızca ağırlıkla değil boyut ve boşlukla kurulur.
- Uzun Türkçe ilçe/birim adları iki satıra kırılır; üç noktaya yalnızca tablo hücresinde ve tam değer tooltip/accessible name ile erişilebildiğinde izin verilir.

## Layout

### 1. Temel grid ve boşluk

4 px taban birimi kullanılır. Ana aralıklar: 8, 12, 16, 20, 24, 32, 40, 48 ve 64 px.

Mobil:

- Ekran yatay iç boşluğu: 16 px
- Dar ekran (320–359 px): 12 px
- Kartlar arası: 12 px
- Bölümler arası: 24–32 px
- Üst çubuk: 56 px + safe area
- Alt navigasyon: 72 px + safe area
- Form ekranında içerik genişliği: tam genişlik, 16 px kenar boşluğu

Tablet:

- 600–1023 px arası 8 kolon
- 24 px kenar boşluğu, 16 px kolon aralığı
- Harita ayrıntısı sabit sağ panel veya alt sheet olabilir.

Web:

- 1024–1279 px: dar yan menü 80 px, 12 kolon, 20 px gutter
- 1280 px ve üstü: yan menü 232 px, içerik 12 kolon, 24 px gutter
- Üst çubuk: 64 px
- Sayfa yatay iç boşluğu: 24 px; 1600 px üstünde 32 px
- İçerik maksimum genişliği rapor/ayar sayfalarında 1440 px; harita ve kuyruk yüzeylerinde tam kullanılabilir genişlik

### 2. Mobil alt menü

Alt menü tam olarak üç ana hedef içerir:

1. **Harita** — map ikonu
2. **Bildir** — kamera + pin ikonu
3. **Bildirimlerim** — liste/takip ikonu

Kurallar:

- Üç öğe eşit genişliktedir.
- “Bildir” ayrı bir yüzen balon değildir; diğer sekmelerle aynı geometrik sistemdedir.
- Aktif öğe `brand-blue-800`, pasif öğe `text-muted` olur.
- Aktif öğenin üstünde 3 px mavi gösterge bulunur; yalnızca renk değil ikon doluluğu ve `aria-current` da değişir.
- Her hedefin dokunma alanı en az 64×56 px'tir.
- Bildirim sayısı varsa `Bildirimlerim` ikonunda 18 px sayaç görünür; `99+` üstü gösterilmez.
- Kamera veya klavye açıldığında alt menü gizlenebilir; ekranın geri davranışı akışı bozmaz.

### 3. Mobil harita yerleşimi

Katman sırası:

1. 56 px beyaz üst çubuk: İBB işareti + Kent Takip, profil/ayar düğmesi
2. Harita üzerinde 16 px kenarlı 48 px arama alanı
3. Aramanın altında yatay kaydırılabilir filtreler
4. Sağ kenarda konumuma git ve katmanlar kontrolleri
5. Sol altta kapalı lejant düğmesi ve veri güncellik etiketi
6. Harita pinleri/kümeleri
7. Pin seçilince açılan alt bilgi sheet'i
8. Sabit alt navigasyon

Harita, üst çubuk ile alt navigasyon arasında tam alanı kullanır. Harita üzerinde ayrı “Bildir” FAB'ı yoktur; aynı iş alt navigasyonda zaten vardır.

### 4. Web uygulama kabuğu

- Sol yan menü: 232 px, `brand-blue-900`, sabit.
- Üst çubuk: 64 px, beyaz, alt sınır çizgili.
- Ana içerik: `surface-page`.
- Kritik uyarı varsa üst çubuğun altında 40 px durum bandı; sürekli yanıp sönmez.
- Sağ detay paneli 480–560 px arası yeniden boyutlanabilir.
- Kompleks inceleme bir modal içinde yapılmaz; ayrı detay rotası veya split panel kullanılır.
- Kullanıcının rolü ve birimi üst çubukta görünür; rol dışı menüler gizlenir, yalnızca devre dışı bırakılmaz.

### 5. Kırılım noktaları

| Aralık | Davranış |
|---|---|
| 320–359 | Dar mobil; iki sütunlu kategori listesi tek sütuna düşebilir |
| 360–599 | Standart mobil |
| 600–839 | Küçük tablet; harita + geniş alt sheet |
| 840–1023 | Tablet; iki panel mümkün |
| 1024–1279 | Dar masaüstü; ikon yan menü, filtre çekmecesi |
| 1280–1599 | Standart belediye paneli |
| 1600+ | Geniş panel; split view ve daha fazla tablo kolonu |

## Elevation & Depth

### 1. Derinlik ölçeği

| Seviye | Gölge | Kullanım |
|---|---|---|
| 0 | Yok; 1 px `border-default` | Kart, tablo, form yüzeyi |
| 1 | `0 2px 6px rgba(0,28,68,.10)` | Küçük açılır menü, harita kontrolü |
| 2 | `0 8px 20px rgba(0,28,68,.14)` | Alt sheet, sağ panel, tarih seçici |
| 3 | `0 16px 36px rgba(0,28,68,.18)` | Modal; yalnızca zorunlu kısa kararlar |

### 2. Derinlik kuralları

- Bir bileşende hem belirgin 1 px sınır hem geniş/difüz gölge birlikte kullanılmaz.
- Varsayılan kartlar gölgesizdir; sayfa zemininden sınırla ayrılır.
- Harita üstü beyaz kontroller seviye 1, alt sheet seviye 2 kullanır.
- Basılı düğme durumu yalnızca renk koyulaşması ve en fazla 1 px aşağı hareketle gösterilir.
- İç içe kart yapılmaz. Bir kart içinde gruplanma gerekiyorsa başlık, ayırıcı ve boşluk kullanılır.
- Blur/glassmorphism yalnızca işletim sistemi kaynaklı sheet arkasında ve okunabilirliği bozmuyorsa kullanılabilir; içerik kartlarında yasaktır.

## Shapes

### 1. Köşe yarıçapları

- 4 px: küçük tablo kontrolü, kod hücresi
- 6 px: kompakt web bileşeni
- 8 px: düğme, input, harita kontrolü
- 12 px: kart
- 16 px: mobil alt sheet üst köşeleri ve büyük modal
- Tam pill: yalnızca chip, badge ve çok kısa segment kontrolü

Kartlarda 16 px üstü yarıçap kullanılmaz. Tüm arayüz “yumuşak blob” görünümüne sokulmaz.

### 2. İkon dili

- Tek ikon seti: Material Symbols Rounded veya Phosphor; proje başında biri seçilir ve karıştırılmaz.
- Standart ikon 20 px; harita pini içi 18 px; mobil ana işlem 24 px.
- Stroke ağırlığı 1.75–2 px.
- İkonlar anlamlı etiketle eşleşir. Tek başına ikon kullanılan kontrolde tooltip ve erişilebilir ad zorunludur.
- İkonu dekoratif yuvarlak kare içine koymak varsayılan değildir.
- Emoji, el çizimi SVG maskot, 3D parlak ikon ve stil olarak birbirinden kopuk görseller kullanılmaz.

### 3. Pin geometrisi

#### Aktif pin

- 36×44 px standart damla formu
- Dolgu `event-active`, 2 px beyaz iç kontur, 1 px `event-active-dark` dış kontur
- Merkezde 18 px beyaz ünlem
- Seçili durumda 44×54 px; 2 px mavi seçim halkası ve beyaz halo
- Erişilebilir ad örneği: “Doğrulanmış aktif yol çalışması, Kadıköy, 300 metre”

#### Planlanan pin

- 36×44 px standart damla formu
- Dolgu `event-planned`, 2 px beyaz iç kontur, 1 px koyu altın dış kontur
- Merkezde koyu saat ikonu
- Zamanı gelince aniden yok olup kırmızı doğmaz; 180 ms crossfade + 0.96→1 scale ile dönüşür.

#### Vatandaşın bekleyen pini

- 36×44 px damla formu
- Dolgu `event-pending`, beyaz soru işareti
- Dışında 2 px kesik çizgili halo; resmî olmadığı şekille de anlaşılır.
- Yalnızca bildirimi yapan vatandaşın kişisel haritasında görünür.

#### Kritik inceleme pini

- 40×40 px yuvarlatılmış üçgen + kısa konum ucu
- Dolgu `event-critical`, beyaz uyarı ikonu, koyu dış kontur
- Yalnızca yetkili personelin haritasında görünür.
- Yanıp sönmez; seçilmemiş halde bile diğer pinlerden şekil olarak ayrılır.

#### Kümeler

- 40 px daire; beyaz merkez, 3 px çoğunluk durum halkası, mavi koyu metin.
- Tek renk çoğunluğu kritik kaydı gizleyemez; kümede kritik varsa turuncu üçgen mini gösterge eklenir.
- “27” gibi sayı dışında ekran okuyucu adı: “27 olay; 2 kritik inceleme, 8 aktif, 17 planlanan”.

## Components

### 1. Düğmeler

#### Birincil

- Mobil 48 px, web 40 px yükseklik
- 8 px radius
- Mavi zemin, beyaz metin
- Fiil + nesne: “Bildirimi gönder”, “Çalışmayı yayınla”, “Birime yönlendir”
- Aynı görünür alanda en fazla bir birincil düğme

#### İkincil

- Beyaz zemin, 1 px `brand-blue-800` sınır, mavi metin
- İptal değil alternatif eylem için: “Taslak kaydet”, “Ek bilgi iste”

#### Tersiyer/ghost

- Şeffaf zemin, mavi metin
- Düşük öncelikli: “Daha sonra”, “Filtreleri temizle”

#### Tehlikeli

- Kırmızı; yalnızca reddetme, silme, uzun süreli kısıtlama gibi sonuçlu işler
- İşlem öncesi kısa ve eylem odaklı onay
- “Tamam” yerine “Bildirimi reddet”

#### Devre dışı

- Opacity tek başına kullanılmaz; `surface-subtle` zemin + `text-muted` metin
- Neden uygun yerde yardımcı metinle açıklanır.

### 2. Form alanları

- Etiket her zaman alanın üstündedir.
- Zorunluluk “Zorunlu” metni veya `*` ve sayfa başı açıklamasıyla belirtilir; yalnızca kırmızı renge güvenilmez.
- Yardımcı metin alanın altında, hata aynı yerde fakat hata ikonu ve çözüm önerisiyle görünür.
- Mobil yükseklik 48 px, web 40 px.
- Focus: 2 px `focus` dış çizgi + 2 px beyaz offset.
- Textarea açıklaması 3–6 satır; karakter sayacı yalnızca sınıra 40 karakter kala görünür.
- Telefon alanı `+90` sabit önek ve `5xx xxx xx xx` biçimi kullanır.
- Adres araması sonucu klavyeyle seçilebilir ve haritada karşılığı vurgulanır.

### 3. Filtre chip'leri

- Mobil 36 px, web 32 px yükseklik.
- Seçili: açık mavi zemin, koyu mavi metin, solunda onay ikonu.
- Seçili olmayan: beyaz zemin, 1 px sınır.
- Haritada ilk sıra en fazla dört görünür chip; devamı yatay kaydırılır.
- Filtreler kategori rengiyle boyanmaz; olay durum renkleri pinlere ayrılmıştır.
- “Filtreler (3)” düğmesi ayrıntılı sheet/drawer açar.

### 4. Kartlar

- Kart varsayılan olarak beyaz, 1 px sınır, 12 px radius, gölgesiz.
- Başlık, metadata ve eylem sırası sabittir.
- Kart içine ikinci kart konmaz; alt grup `surface-subtle` şerit veya ayırıcıyla ayrılır.
- Mobil olay kartı: ikon/pin, başlık, konum, durum, son güncelleme, chevron.
- Tıklanabilir kartın tamamı tek odak hedefidir; içinde birden fazla ayrı eylem varsa kart link olmaz.

### 5. Bildirim ve banner

- Toast kısa ve geri döndürülebilir sonuçlar içindir; 4–6 saniye kalır.
- Kullanıcı müdahalesi isteyen hata toast olarak kaybolmaz; inline banner olur.
- Çevrimdışı banner ekranın üstünde sabit, 40 px: “Çevrimdışısınız — son güncel bilgiler gösteriliyor.”
- Kritik acil durum uyarısı turuncu yüzey, uyarı ikonu, açık metin ve iki eylem içerir.
- Başarı ekranı sadece yeşil tik ve takip numarası içerir; konfeti kullanılmaz.

### 6. Tabs ve segment kontrolü

- Alt navigasyon ile sayfa içi tab birbirine benzemez.
- Sayfa tabı metin + alt çizgi kullanır; aktif tab mavi ve 2 px alt göstergelidir.
- Segment kontrolü yalnızca iki veya üç kısa seçenek için kullanılır: “Liste / Harita”.
- Beş inceleme kuyruğu tek segmentte sıkıştırılmaz; yatay tab + sayaç veya yan liste kullanılır.

### 7. Alt sheet, drawer ve modal

- Mobil pin detayı iki snap noktasına sahiptir: yaklaşık %38 ve %78 ekran yüksekliği.
- Sheet sürükleme kolu görsel öğedir; aynı iş için “Kapat” erişilebilir düğmesi bulunur.
- Web ayrıntısı sağ drawer veya split paneldir; karar işlemleri panel içinde kalır.
- Modal yalnızca kısa onay, tek alanlı işlem veya yasal uyarı içindir.
- Scroll bar gerektiren üç kolonlu form modal içine konmaz.

### 8. Stepper

Vatandaş bildirimi beş anlamlı adımdan oluşur:

1. Tür
2. Fotoğraf
3. Konum ve açıklama
4. Kontrol
5. Sonuç

Mobilde “2 / 5 Fotoğraf” metni ve ince ilerleme çubuğu kullanılır. Beş küçük daire veya süslü ikon zinciri kullanılmaz. Geri gidildiğinde veri korunur.

### 9. Timeline

- Dikey zaman çizelgesi; en yeni önemli durum üstte, tam işlem geçmişi açılabilir.
- Durum ikonu + başlık + tarih/saat + açıklama.
- Tamamlanan adım mavi/yeşil, mevcut adım mavi, gelecek adım gösterilmez.
- “AI ön incelemesi” ile “İBB incelemesi” ayrı ve açık adlandırılır.
- Tahmini çözüm “Tahmin: 2–4 iş günü” gibi aralıkla ve “garanti değildir” açıklamasıyla sunulur.

### 10. Tablo

- Başlık satırı sticky; sıralanan sütunda yön ikonu ve `aria-sort`.
- Varsayılan satır 52 px; kullanıcı isterse 44 px kompakt moda geçebilir.
- Satır checkbox'ı 20 px, hedef alanı en az 36×36 px.
- Sayısal değerler sağa, metin sola hizalıdır.
- Durum sütununda küçük renk noktası tek başına kullanılmaz; ikon + metin bulunur.
- Yatay scroll son çaredir. Dar ekranda düşük öncelikli kolonlar gizlenir ve “Kolonlar” menüsüyle açılır.
- Toplu işlem yalnızca en az bir satır seçildiğinde görünür.

### 11. AI analiz bloğu

Personel ekranında üç sonuç birbirinden ayrı gösterilir:

- **İçerik uyumu:** 0–100 + gerekçeler
- **Olay riski:** Düşük / Orta / Yüksek / Kritik sinyal + tetikleyen kanıtlar
- **Vatandaş güven sinyali:** 0–100 + tarihsel bağlam; varsayılan kuyruk satırında gösterilmez

Kurallar:

- Başlık her zaman “AI ön analiz önerisi”dir.
- “Doğru”, “sahte”, “kesin” veya “AI onayladı” ifadeleri kullanılmaz.
- Tek birleşik skor üretilmez.
- Her skor yanında “Bu sonuç nihai karar değildir” kısa metni bulunur.
- Personelin değiştirdiği kategori/risk için neden seçimi ve serbest not alanı bulunur.
- Vatandaş ekranında sayısal AI veya güven skoru gösterilmez.

### 12. Fotoğraf gizlilik karşılaştırması

- Yetkili personelde varsayılan sekme “Halka açık kopya”dır.
- “Orijinali görüntüle” ayrı, yetki kontrollü eylemdir ve erişimin kaydedileceği belirtilir.
- Orijinal açıldığında üstte kalıcı “Kişisel veri içerebilir” bandı görünür.
- Yan yana karşılaştırma yalnızca 1280 px üstünde; dar ekranda iki tab kullanılır.
- Bulanıklaştırma başarısızsa halka açık önizleme yerine kilitli boş durum gösterilir.

## Do's and Don'ts

### Yap

- Gerçek ürün görevini ekranın ana hiyerarşisi yap.
- İBB mavisini yapısal, magentayı sınırlı vurgu olarak kullan.
- Her ekranda tek bir ana eylem belirle.
- Doğrulanmış/doğrulanmamış farkını renk + ikon + metinle anlat.
- Harita bilgisinin liste alternatifini sağla.
- Kayıt kaynağı ve son güncellenme zamanını göster.
- Hata mesajında ne olduğunu ve kullanıcının ne yapacağını söyle.
- Yoğun panelde filtreleri, kolonları ve seçim durumunu URL/state ile koru.
- Uzun isim, boş veri, gecikme, çevrimdışı ve AI hatasıyla tasarımı test et.

### Yapma

- Mor-mavi gradient, gradient metin, neon glow veya dekoratif ışık halesi kullanma.
- Glassmorphism'i kart stili yapma.
- Kart içinde kart, her bölümde aynı kart grid'i veya solda kalın renk şeridi kullanma.
- Küçük kartları 24–44 px radius ile blob hâline getirme.
- Her başlığın üstüne küçük uppercase “AI destekli” etiketi koyma.
- “Geleceğin akıllı şehri” gibi ürün kanıtı olmayan jenerik slogan kullanma.
- İkonu içerikten büyük dekoratif kutuya koyma.
- İşlevsel ekranda dev hero başlığı veya büyük boş alan kullanma.
- Harita pinlerini zıplatma, titreştirme veya sürekli pulse ettirme.
- Kritik durumları sadece renkle, animasyonla veya sesle anlatma.
- Yapay zekâ sonucunu insan kararı gibi gösterme.
- Vatandaşa başka kişilerin gri pinlerini veya güven skorlarını gösterme.
- Teknik hata kodunu ana mesaj yapma.
- “Tamam”, “Devam”, “Gönder” gibi bağlamsız CTA kullanma.

## Mobile Application Screens

### M-00 Açılış ve ilk kullanım

Amaç: Kullanıcıyı geciktirmeden haritaya ulaştırmak ve acil çağrı kapsamını doğru anlatmak.

Yerleşim:

- Üst üçte birlik alanda resmî İBB logosu ve ayrı “Kent Takip” ürün adı.
- Altında tek cümle: “İstanbul'daki güncel çalışmaları görün, karşılaştığınız sorunu bildirin.”
- 3 maddelik kısa değer: güncel harita, anlık bildirim, şeffaf takip.
- `Haritayı aç` birincil düğme.
- “Bu uygulama acil çağrı hizmeti değildir.” görünür bilgi satırı ve ayrıntı bağlantısı.
- KVKK kısa aydınlatma bağlantısı; açık rıza checkbox'ıyla birleştirilmez.

Davranış:

- Konum izni bu ekranda istenmez.
- Kullanıcı bir kez gördükten sonra doğrudan haritaya gider; acil kapsam metni Ayarlar/Yardım'dan erişilebilir kalır.
- Yarışma prototipinde üstte küçük ama kalıcı “Demo verisi” bandı bulunur.

### M-01 Şehir haritası

Üst çubuk:

- Sol: resmî işaret + Kent Takip
- Sağ: profil/ayar

Harita üstü:

- Arama placeholder: “İlçe, mahalle veya adres ara”
- Hızlı filtreler: “Aktif”, “Planlanan”, “Trafik”, “Altyapı”; devamı “Filtreler”
- Konumuma git, katmanlar
- Son güncelleme: “Veriler 4 dk önce güncellendi”

Etkileşim:

- Harita hareketi bitince “Bu alanda ara” düğmesi görünür; sürekli otomatik istek atılmaz.
- Pin dokunması sheet açar ve pini seçili hâle getirir.
- Kümeye dokunma yakınlaştırır; aynı zoom'da kalıyorsa küme içi liste açılır.
- Veri eskiyse sarı bilgi bandı: “Bazı kaynaklar güncel olmayabilir — son güncelleme 10:42.”

### M-02 Pin kısa detayı

Kısa sheet:

- Durum ikonu + “Doğrulanmış aktif” / “Planlandı”
- Olay türü
- Mahalle + açık adres
- Başlangıç ve tahmini bitiş
- “Ayrıntıyı gör”

Geniş sheet:

- Sorumlu birim
- Etkilenen alan/yol/toplu taşıma
- Alternatif güzergâh varsa ayrı bilgi bloğu
- Veri kaynağı ve güncelleme zamanı
- Belediye açıklaması
- Halka açık güvenli fotoğraf varsa 16:9 önizleme

Kendi gri pininde resmî olmayan durum açık metinle anlatılır: “Bildiriminiz alındı — belediye doğrulaması bekleniyor.”

### M-03 Filtreler

- Alt sheet veya tam sayfa.
- Bölümler: Durum, olay türü, zaman, veri katmanları.
- Çoklu seçim checkbox; seçim sayısı görünür.
- Alt sabit eylem: “23 olayı göster”.
- “Temizle” tersiyer.
- Kullanıcının kendi bekleyen bildirimleri ayrı switch: “Bekleyen bildirimlerimi göster”. Başka kişilerin kayıtlarını açamaz.

### M-04 Telefonla giriş

Başlık: “Bildirim göndermek için giriş yapın”  
Açıklama: “Haritayı giriş yapmadan kullanmaya devam edebilirsiniz.”

- Telefon alanı ve ülke kodu
- `Doğrulama kodu gönder`
- Telefon numarasının kullanım amacı kısa metinle açıklanır.
- KVKK aydınlatma metni bağlantısı.
- “Haritaya dön” tersiyer.
- Kullanıcı girişten sonra başladığı akışın aynı adımına döner.

Hatalar:

- Geçersiz: “Telefon numarasını 5xx xxx xx xx biçiminde girin.”
- Hız sınırı: “Çok sık kod istendi. 14 dakika sonra yeniden deneyin.”
- Servis: “Kod şu anda gönderilemiyor. Numaranız kaydedilmedi; daha sonra tekrar deneyin.”

### M-05 Kod doğrulama

- Başlıkta maskeli numara: “+90 5•• ••• •• 42 numarasına gelen kodu girin.”
- Altı haneli tek semantik input; görsel olarak altı hücre.
- SMS autofill desteklenir.
- Geri sayım bittikten sonra “Yeni kod gönder”.
- Numara değiştirme bağlantısı.
- Hatalı kod alanı sarsılmaz; inline hata ve kalan deneme bilgisi gösterilir.

### M-06 Bildirim türü

Başlık: “Ne bildirmek istiyorsunuz?”

- Liste düzeni; ikon solda, başlık ve kısa örnek sağda.
- Öncelikli kategoriler: Yol, altyapı, su, elektrik, trafik işareti, toplu taşıma, haritada olmayan çalışma, diğer.
- “Emin değilim” görünür son seçenek; kullanıcıyı kategori seçmeye zorlamaz.
- Arama yalnızca kategori sayısı 10'u aşarsa eklenir.

### M-07 Kamera

Tam ekran koyu kamera yüzeyi:

- Üst: geri, “Fotoğraf 2 / 5”, flaş
- Merkez: sorunu kadraja alma rehberi; dekoratif çerçeve değil, yarı saydam köşe işaretleri
- Alt: 72 px çekim düğmesi, kısa yardım “Sorun ve çevresi net görünsün”
- Galeri düğmesi yoktur.
- İlk girişte tek seferlik açıklama sheet'i ve ardından işletim sistemi kamera izni.

Kamera izni reddedilirse:

- Kamera siyah boş kalmaz; izin açıklama ekranı görünür.
- `Ayarları aç` ve `Haritaya dön`.
- “Fotoğraf zorunlu olduğu için bildirime devam edilemiyor.”

### M-08 Fotoğraf kontrolü ve AI ön analizi

Fotoğraf çekildiğinde:

- Tam genişlik önizleme
- `Yeniden çek` ikincil, `Bu fotoğrafı kullan` birincil
- Kalite sorunu varsa doğrudan, düzeltilebilir mesaj: “Fotoğraf çok karanlık. Işığı arkanıza alıp yeniden çekin.”

Analiz fotoğraf onayından sonra arka planda başlar. Sahte yüzde ilerleme gösterilmez. Aşama listesi:

- Fotoğraf kalitesi kontrol ediliyor
- Yüz ve plakalar güvenli hâle getiriliyor
- Olası sorun türü inceleniyor

Tamamlanan satır tik alır. Kullanıcı konum/açıklama adımına geçebilir; analiz arka planda sürer.

AI önerisi hazırsa:

- “Önerilen tür: Yol hasarı”
- “Değiştir” eylemi
- “Bu yalnızca ön analizdir.”

Bulanıklaştırılmış halka açık kopya küçük önizlemeyle gösterilir. Kullanıcı “Halka açık görünüm”ü inceleyebilir; orijinali silmeden manuel blur aracı MVP'de sunulmaz.

### M-09 Konum ve açıklama

- Üst yarı: 220–280 px harita ve merkezde sabit konum hedefi.
- Alt: seçilen adres, “Konumuma git”, açıklama textarea.
- Konum izni yoksa adres arama ve haritadan seçim tam işlevlidir.
- Yardımcı metin: “Kişisel adresinizi değil, sorunun bulunduğu yeri seçin.”
- Açıklama önerisi: “Ne görüyorsunuz ve ulaşımı nasıl etkiliyor?”
- AI kategori önerisi düzenlenebilir küçük satır olarak bulunur.

### M-10 Gönderim kontrolü

Tek sayfa özet:

- Halka açık bulanık fotoğraf
- Tür
- Konum
- Açıklama
- Veri kullanımı: “Orijinal fotoğrafı yalnızca yetkili personel görebilir.”
- Acil kapsam kısa uyarısı
- `Bildirimi gönder` sabit alt eylem
- Her bölümde “Düzenle” metin bağlantısı

Gönderim sırasında düğme devre dışı olur ve metin “Gönderiliyor…” olur; aynı işlem kimliğiyle çift gönderim engellenir.

### M-11 Başarılı gönderim

- Yeşil onay ikonu
- Başlık: “Bildiriminiz alındı”
- Takip numarası büyük ve kopyalanabilir
- “Belediye doğrulamasına kadar yalnızca siz gri pin olarak görebilirsiniz.”
- `Bildirimimi görüntüle` birincil
- `Haritaya dön` ikincil
- Bildirim izni henüz sorulmadıysa bağlamsal istek: “Durum değişikliklerinden haberdar olmak ister misiniz?”

### M-12 Kritik sinyal uyarısı

AI yüksek/kritik sinyal algıladığında fotoğraf akışının üstüne tam ekran modal değil, ayrı erişilebilir uyarı sayfası gelir:

- Turuncu uyarı ikonu
- “Bu durum acil yardım gerektirebilir”
- “Kent Takip acil çağrı hizmeti değildir. Hayati tehlike varsa uygun resmî acil yardım kanalına başvurun.”
- Birincil: “112 Acil'i ara” — yalnızca kullanıcı dokununca telefon arayüzünü açar; otomatik arama yapmaz.
- İkincil: “Belediye bildirimine devam et”
- Tersiyer: “İptal et”

Metin ve numara, İBB hukuk/operasyon onayından sonra uzaktan yapılandırılabilir olmalıdır.

### M-13 Bildirimlerim listesi

- Başlık + filtre: “Tümü”, “Açık”, “Ek bilgi”, “Çözüldü”
- Kart: küçük güvenli fotoğraf/ikon, kategori, mahalle, durum, son güncelleme, takip numarası
- “Ek bilgi gerekli” kayıtları listenin üstünde ve uyarı ikonu ile görünür.
- Varsayılan sıralama son güncelleme; kullanıcı gönderim tarihine göre değiştirebilir.
- Pull-to-refresh yanında görünür son güncelleme zamanı bulunur.

### M-14 Bildirim ayrıntısı

- Üstte durum ve takip numarası
- Haritada konum ve pin durumu
- Timeline
- Tahmini çözüm aralığı
- Sorumlu birim ve varsa ilçe belediyesine yönlendirme
- Belediye açıklaması
- Kullanıcının gönderdiği güvenli fotoğraf
- Çözümde sonuç fotoğrafı ve açıklama
- Birleştiyse: “Bu bildirim aynı olayla birleştirildi” ve ana olay bağlantısı
- Ret/kapsam dışıysa kısa gerekçe ve yeniden inceleme/itiraz bağlantısı

### M-15 Ek bilgi gönderme

- Belediye talebi üstte alıntı blokta.
- Açıklama ve isteğe bağlı yeni anlık kamera fotoğrafı.
- Eski bilgi silinmez; yeni yanıt timeline'a eklenir.
- Başarı sonrası durum “İBB incelemesinde” olarak güncellenir.

### M-16 Ayarlar ve kişisel veriler

Bölümler:

- Hesap ve telefon
- İzinler: konum, kamera, bildirim
- Erişilebilirlik: yazı boyutu sistem ayarını izler; yüksek kontrast bağlantısı
- Kişisel verilerim ve KVKK başvurusu
- Otomatik değerlendirmeye itiraz
- Hesabımı sil
- Yardım ve acil kapsamı
- Veri kaynakları hakkında

Hesap silme ayrı sayfadır; etkileri açıklanır, yeniden doğrulama ve açık onay gerekir.

## Municipal Web Panel

### W-00 Kurumsal giriş

- Sol %55: sakin açık mavi yüzey, resmî logo, ürün adı ve tek cümle açıklama.
- Sağ %45: giriş formu.
- Kurumsal hesap, parola/SSO ve ikinci doğrulama.
- “İstanbul Senin” veya vatandaş girişi bu ekranda yer almaz.
- Yardım, erişilebilirlik ve gizlilik bağlantıları alt kısımda.
- Hata kullanıcı adı veya hesap varlığını ifşa etmez.

### W-01 Ana panel

Amaç: Personelin neye önce bakacağını göstermektir; pazarlama dashboard'u değildir.

Üst sıra:

- Tek yatay operasyon özeti bandı: Kritik, yüksek öncelik, normal, düşük güven, kötüye kullanım.
- Her sayı kuyruk bağlantısıdır.
- Kritik bölüm turuncu ikon ve açık turuncu arka planla diğerlerinden ayrılır; animasyon yoktur.

Ana alan:

- Sol 8 kolon: “İncelenecekler” kompakt tablo
- Sağ 4 kolon: görev yaşı dağılımı, veri kaynaklarının güncelliği, birim açık işleri
- Alt: aktif ve planlanan çalışmalar için küçük harita; tam işlem harita sayfasında yapılır.

### W-02 İnceleme kuyrukları

Üç bölmeli düzen:

1. Sol filtre alanı 240–280 px
2. Orta liste/tablo 420–560 px
3. Sağ detay paneli kalan alan, en az 480 px

Kuyruk sırası:

1. Kritik inceleme
2. Yüksek öncelikli
3. Normal
4. Düşük güvenli
5. Kötüye kullanım
6. Manuel inceleme — AI teknik hatası

Filtreler:

- İlçe, mahalle, kategori, tarih
- Risk seviyesi
- İçerik uyumu aralığı
- Öncelik ve durum
- Sorumlu/önerilen birim
- Mükerrer ihtimali
- Bekleme süresi
- Veri kaynağı

Liste sütunları:

- Seçim
- Öncelik ikonu
- Takip no
- Kategori
- İlçe/mahalle
- Oluşturulma
- Bekleme süresi
- Risk
- İçerik uyumu
- Mükerrer
- Atanan personel

Vatandaş güven skoru listede gösterilmez; ilk izlenim yanlılığını azaltmak için ayrıntıda, gerekçesiyle ve sınırlı rolde açılır.

### W-03 Bildirim inceleme ayrıntısı

Başlık alanı:

- Takip no, durum, kuyruk, kayıt yaşı
- Önceki/sonraki kayıt kontrolleri
- Kayıt kilidi: başka personel inceliyorsa ad ve zaman

İçerik sırası:

1. Vatandaş açıklaması
2. Konum + 240 px harita
3. Halka açık kopya / yetkili orijinal fotoğraf
4. AI ön analiz önerisi
5. Benzer kayıtlar
6. İşlem geçmişi
7. Karar paneli

Karar paneli sağda sticky veya sayfa sonunda sabittir:

- Doğrula
- Kategori/risk/öncelik değiştir
- İBB birimine yönlendir
- İlçe belediyesine yönlendir
- Saha ekibine ata
- Ek bilgi iste
- Birleştir
- Kapsam dışı
- Kötüye kullanım incelemesine gönder
- Reddet

Her karar sonrası sonuç özeti gösterilir; geri alınabilir işlemlerde kısa süreli “Geri al” bulunur. Ret, birleştirme ve kritik risk düşürme gerekçe ister.

### W-04 Belediye haritası

- Tam içerik alanı harita.
- Sol üst: arama ve görünüm seçici.
- Sol filtre drawer: pin durumu, kategori, risk, güven, tarih, birim.
- Sağ üst: katmanlar, konum/extent, çizim aracı.
- Alt: seçili kaydın kompakt bilgi paneli.
- Düşük güvenli bildirimler varsayılan kapalıdır; açıldığında görünür banner “Düşük güvenli kayıtlar gösteriliyor”.
- Turuncu kritik pin genel kırmızı pinle karışmaz.
- Liste alternatifi her zaman mevcuttur ve aynı filtreleri paylaşır.

### W-05 Çalışma planlama

İki panel:

- Sol 5 kolon: çalışma formu
- Sağ 7 kolon: harita ve etkilenecek alan çizimi

Form sırası:

1. Çalışma türü
2. Konum/etki alanı
3. Başlangıç ve tahmini süre
4. Etkilenecek yol/bölgeler
5. Sorumlu birim
6. Açıklama
7. Etki analizi

Taslak otomatik kaydedilir; yayın ayrı adımdır.

### W-06 Etki analizi

Sonuçlar kart grid'i yerine tek rapor yüzeyinde hiyerarşik gösterilir:

- Üst özet: tahmini etki düzeyi, en riskli saat, çakışma sayısı
- Harita: etkilenen yollar ve toplu taşıma hatları
- Zaman şeridi: önerilen/mevcut saat karşılaştırması
- Çakışmalar tablosu
- Alternatif tarih/saat ve güzergâh önerileri
- Vatandaş bilgilendirme metni taslağı

AI önerileri ayrı “Öneri” etiketiyle gelir. Personel öneriyi kabul, düzenle veya reddedebilir; yayın insan onayı ister.

### W-07 Yayınlama kontrolü

- Planlanan çalışma önizlemesi vatandaş görünümüne yakın gösterilir.
- Pin sarı saat olarak önizlenir.
- Zorunlu alan kontrolü, çakışma uyarıları ve veri kaynağı özeti.
- `Çalışmayı yayınla` tek ana eylem.
- Başlangıç zamanı gelince otomatik aktif dönüşümü görünür kuralla tanımlanır; başarısız otomasyon sistem yöneticisine düşer.

### W-08 Birim görevleri ve saha çözümü

- Kanban varsayılan değildir; durumlar çok ve kayıtlar yoğun olduğu için tablo/listedir.
- Filtre: atanmamış, bana atanmış, saha ekibinde, devam ediyor, süresi aşan.
- Detayda ekip atama, tahmini müdahale aralığı, çözüm açıklaması, sonuç fotoğrafı.
- Vatandaşa gidecek metin ayrıca önizlenir.
- “Çözüldü” kararı sonuç açıklaması olmadan verilemez.

### W-09 Veri kaynakları

Sistem yöneticisi görünümü:

- Kaynak adı
- API/CSV türü
- Son başarılı çekim
- Kaynak zaman damgası
- Sisteme aktarım zamanı
- Güncellik durumu
- Son hata
- Kayıt sayısı

Durumlar: Güncel, gecikiyor, erişilemiyor, manuel veri. Renk + ikon + metin kullanılır. Eski veri vatandaş ekranında kesin güncel gibi görünmez.

### W-10 Kullanıcı, rol ve denetim

- Rol tabanlı kullanıcı tablosu.
- Yetki düzenleme ayrı sayfa; kritik yetki değişiklikleri ikinci onay ister.
- Denetim günlüğü değiştirilemez görünümde; tarih, kullanıcı, eylem, kayıt, önceki/yeni değer, gerekçe.
- Orijinal fotoğraf erişimi özel filtre ve ikonla görünür.
- Yetkisiz erişim denemesi kullanıcıya sade mesaj, yöneticide güvenlik kaydı üretir.

## Review Queue Rules

### 1. Görsel öncelik

- Kritik: turuncu üçgen + “Kritik sinyal” + kayıt yaşı
- Yüksek: turuncu/koyu sarı yukarı ok + “Yüksek risk”
- Normal: gri soru pin + “Doğrulama bekliyor”
- Düşük güven: gri kesik halo + “Düşük içerik uyumu”
- Kötüye kullanım: kalkan ikonu + “İnsan incelemesi gerekli”
- Manuel: anahtar/servis ikonu + “AI analizi tamamlanamadı”

### 2. Sıralama

Varsayılan sıralama yalnızca AI skoruna dayanmaz:

1. Kritik/yüksek risk
2. Kayıt yaşı
3. Etki alanı ve kategori önceliği
4. Yakındaki benzer bağımsız kayıt sayısı
5. İçerik uyumu

Vatandaş güven sinyali tie-breaker düzeyinde, sınırlı etkiyle kullanılabilir; liste sırasının ana belirleyicisi olmaz.

### 3. Personel karar güvenliği

- AI önerisi ile personel kararı görsel olarak ayrıdır.
- Risk düşürme ve ret gerekçe ister.
- Kritik kaydı kapatma ikinci onay ve yetki gerektirir.
- Birleştirmede ana kayıt önizlenir; vatandaş kimlikleri gösterilmez.
- Toplu ret yoktur.
- Toplu birime yönlendirme yalnızca aynı kategori ve sorumluluk doğrulamasıyla yapılır.

## Accessibility

### 1. Hedef

Mobil ve web yüzeyleri WCAG 2.2 AA hedefler. Yerel native bileşenlerde iOS VoiceOver ve Android TalkBack; webde NVDA + Chrome, JAWS + Edge ve VoiceOver + Safari test edilir.

### 2. Dokunma ve hedef boyutu

- Mobil tüm etkileşim hedefleri en az 44×44 px.
- Web minimum hedef 24×24 px olsa da ürün standardı ikon düğmesinde 36×36, standart kontrolde 40 px yüksekliktir.
- Yan yana tehlikeli/normal eylemler arasında en az 8 px boşluk.
- Harita pininin görseli 36 px olsa bile dokunma alanı 48×48 px.

### 3. Klavye ve odak

- Tüm web işlevleri klavyeyle kullanılabilir.
- Tab sırası görsel sırayı izler.
- Odak göstergesi en az 2 px kalınlığında, kontrastlı ve hiçbir sticky öğe tarafından örtülmez.
- Modal ve sheet odak tuzağı uygular; Escape kapatır; kapanınca odak çağıran öğeye döner.
- Harita klavye ile pan/zoom destekler; ayrıca eşdeğer liste görünümü vardır.
- Tek harfli global kısayollar yoktur; kısayollar modifier ile çalışır ve yardım ekranında açıklanır.

### 4. Ekran okuyucu

- Her pin tam durum, kategori, konum ve mesafe adı taşır.
- Kümeler içerik özetini söyler.
- Harita tek başına dev bir odak alanı olmaz; “Haritayı atla, olay listesine geç” bağlantısı bulunur.
- Toast ve gönderim sonucu `aria-live=polite`; kritik bağlantı/hata `assertive` yalnızca gerçekten kritikse.
- Yükleniyor durumu kontrol adına eklenir; sadece spinner seslendirilmez.
- Tablo başlıkları, sıralama ve seçili satır semantik olarak işaretlenir.

### 5. Renk, kontrast ve metin

- Pinler ikon ve etiketle desteklenir.
- Metin %200 büyütmede kırpılmaz.
- Web 320 CSS px eşdeğer reflow ve %400 zoom testinden geçer; zorunlu iki boyutlu tablolar kontrollü yatay scroll kullanabilir.
- Kullanıcının sistem yazı boyutu tercihi mobilde izlenir.
- Satır yüksekliği ve alan yüksekliği büyük metinde içeriğe göre büyüyebilir; sabit yükseklik metni kesmez.

### 6. Hareket ve duyusal çıktı

- `prefers-reduced-motion` / sistem “Hareketi azalt” ayarı izlenir.
- Haptik, ses veya animasyon tek başına durum kanalı değildir.
- Otomatik oynayan video/animasyon yoktur.
- Pin pulse, parallax ve harita üzerinde sürekli hareket yoktur.

### 7. Kamera erişilebilirliği

- Kamera düğmeleri erişilebilir ad taşır.
- Çekim sonrası fotoğraf için otomatik kısa betimleme personel kararı yerine kullanılmaz; kullanıcıya görüntü kalite sonucu metinle verilir.
- Motor kısıtı olan kullanıcı için çekim düğmesi büyük ve alt merkezde sabittir.
- Fotoğraflı rota varsayılandır; kamera kullanamayan kişi “Fotoğrafsız devam” ile manuel incelemeye gidebilir. İzin reddinde neden, alternatif rota ve geri dönüş açıkça sunulur.

## Motion

### 1. Amaç

Hareket yalnızca durum değişimini, mekânsal ilişkiyi veya geri bildirimi açıklar. Gösteriş için animasyon kullanılmaz.

### 2. Süreler

| Token | Süre | Kullanım |
|---|---:|---|
| Immediate | 100 ms | Hover, basılı durum |
| Fast | 160 ms | Chip, satır seçimi, küçük fade |
| Standard | 220 ms | Sheet, drawer, dropdown |
| Slow | 300 ms | Büyük görünüm geçişi; üst sınır |

Easing:

- Giriş: `cubic-bezier(.2,.8,.2,1)`
- Çıkış: `cubic-bezier(.4,0,1,1)`
- Doğal küçük spring yalnızca drag sheet sonlanmasında; bounce yok.

### 3. Özel hareketler

- Pin seçimi: 160 ms scale 1→1.12 + halo fade.
- Sarıdan kırmızıya dönüşüm: 180 ms crossfade; kullanıcı konumu değişmez.
- Alt sheet: transform + opacity, 220 ms.
- Satır açma: içerik yüksekliği yerine mümkünse opacity/transform; tablo reflow'u ani olabilir.
- Başarı: tik stroke animasyonu 220 ms; reduced motion'da statik.
- Skeleton shimmer reduced motion'da sabit ton olur.

### 4. Performans

- Öncelik `transform` ve `opacity` animasyonlarındadır.
- Harita pan sırasında React/UI yeniden çizimleri sınırlandırılır.
- Aynı anda 20'den fazla bağımsız öğe animasyonu başlatılmaz.
- Animasyon paketi lazy-load edilir; temel harita ve form ilk boyasını geciktirmez.

## Empty, Loading, Offline and Error States

### 1. Durum matrisi

| Yüzey | Boş | Yükleniyor | Çevrimdışı | Hata |
|---|---|---|---|---|
| Harita | “Bu bölgede seçili filtrelere uygun güncel kayıt yok.” + filtre temizle | Soluk harita tabanı + üstte ince progress; pin skeleton yok | Son önbellek + zaman damgası + banner | Harita tabanı açılamazsa liste alternatifi + tekrar dene |
| Bildirimlerim | “Henüz bildirim göndermediniz.” + `Sorun bildir` | 3 gerçekçi liste skeleton'ı | Yerel kayıtlar + senkron bekliyor etiketi | Liste alınamadı; taslaklar korunur |
| Kuyruk | “Bu kuyrukta kayıt yok.” + diğer kuyruk bağlantısı | Tablo satır skeleton'ı | Panel işlemleri kapalı; veri yalnızca görüntülenebilir | Filtreleri koruyarak tekrar dene |
| Fotoğraf analizi | Uygulanmaz | Aşama listesi; sahte yüzde yok | Şifreli taslak; analiz bağlantıda devam | Manuel incelemeye gönder, yeniden fotoğraf isteme |
| Veri kaynağı | “Henüz kaynak eklenmedi” | Tablo skeleton | Son bilinen durum | Kaynak adı, son başarı, hata özeti |

### 2. Boş durum dili

Boş durum üç parçadan oluşur:

1. Ne olmadığı
2. Bunun ne anlama geldiği
3. Uygunsa bir sonraki eylem

Örnek: “Bu bölgede planlanan çalışma bulunamadı. Haritayı taşıyabilir veya tarih filtresini genişletebilirsiniz.”

Dekoratif büyük illüstrasyon yalnızca ilk kullanım ve tüm sayfa boşluklarında kullanılabilir; veri yoğun panelin her boş tablosuna illüstrasyon konmaz.

### 3. Yükleme

- 400 ms'den kısa işlemde spinner gösterilmez.
- 400 ms–2 sn arası küçük progress.
- 2 sn üstünde aşama veya açıklama.
- Bilinmeyen süreye yüzde verilmez.
- İçerik yeniden yüklenirken mevcut veri silinmez; üstte ince progress gösterilir.

### 4. Çevrimdışı

- Son güncelleme zamanı her zaman görünür.
- Kullanıcı bildirimini şifreli yerel taslak olarak saklayabilir.
- Bağlantı geldiğinde kullanıcı gönderimi açıkça başlatır veya daha önce onayladıysa kontrollü otomatik gönderim yapılır; çift kayıt engellenir.
- “Gönderildi” durumu yalnızca sunucu onayından sonra kullanılır.
- Harita verisi eskiyse pin ayrıntısında “Son bilinen bilgi” etiketi bulunur.

### 5. Hata mesajı kalıbı

**Başlık:** Kullanıcı dilinde sonuç  
**Açıklama:** Veri kaybı olup olmadığı  
**Eylem:** Tekrar dene veya alternatif yol  
**Teknik ayrıntı:** Yalnızca kopyalanabilir referans numarası

Örnek:

> Bildiriminiz gönderilemedi. Fotoğraf ve açıklamanız taslak olarak saklandı. Bağlantınızı kontrol edip yeniden deneyin. Referans: KT-2041.

## Content Design

### 1. Ses ve ton

- Sakin, açık, kamusal ve yargılamayan.
- Vatandaşın kurumsal yapıyı bilmesini beklemeyen.
- Yapay zekâyı abartmayan.
- Kesin olmayan süreyi garanti gibi göstermeyen.
- Kötüye kullanım şüphesinde suçlayıcı olmayan.

### 2. Terim sözlüğü

| Kullan | Kullanma |
|---|---|
| Bildirim | Şikâyet kaydı (yalnızca kurum içi resmî terim zorunluysa) |
| Doğrulama bekliyor | Şüpheli |
| AI ön analizi | AI kararı |
| İçerik uyumu | Doğruluk oranı |
| Kritik sinyal | Kesin tehlike |
| Tahmini çözüm aralığı | Çözüm tarihi |
| Kapsam dışı | Geçersiz (her durumda) |
| Birime yönlendirildi | Başka yere gönderildi |

### 3. Düğme metinleri

- `Bildirimi gönder`
- `Fotoğrafı yeniden çek`
- `Konumu kullan`
- `Ek bilgiyi gönder`
- `Birime yönlendir`
- `Çalışmayı yayınla`
- `Bildirimi reddet`
- `Filtreleri temizle`

“Tamam”, “İleri”, “Devam” yalnızca bağlam ekranda tartışmasızsa kullanılabilir; stepper'da tercihen sonraki adım adı yazılır.

## Privacy and Trust UI

### 1. Veri görünürlüğü

- Telefon numarası vatandaşın kendi hesap ekranı dışında maskeli gösterilir.
- Genel haritada vatandaş kimliği bulunmaz.
- Orijinal fotoğraf yetkili personel eylemiyle açılır ve erişim loglanır.
- İlçe belediyesine aktarım özetinde “Yalnızca gerekli bilgiler paylaşılır” metni bulunur.
- Konum izni ekranı “hareket geçmişi tutulmaz” bilgisini açıkça verir.

### 2. Güven skoru

- Vatandaşa gamification puanı olarak gösterilmez.
- Belediye ayrıntısında skorun ne olmadığı anlatılır.
- Ret tek başına kötüye kullanım sayılmaz.
- İtiraz ve insan incelemesi bağlantısı ayarlarda ve ilgili karar ayrıntısında bulunur.
- Yeni kullanıcı “düşük güven” etiketi almaz.

### 3. Demo/prototip

- Gerçek telefon, kesin kişisel konum veya gerçek vatandaş fotoğrafı kullanılmaz.
- Tüm demo ekranlarında küçük “Demo verisi” etiketi bulunur.
- Simüle AI skorları tooltip'te “Yarışma demosu için simüle edilmiştir” diye açıklanır.
- Demo etiketi olay durum chip'i gibi görünmez; üst düzey ortam bandıdır.

## Prototype Demonstration Route

Yarışma sunumunda önerilen sabit demo rotası:

1. Misafir olarak şehir haritasını aç.
2. Kırmızı aktif ve sarı planlanan pini göster.
3. “Bildir”e geç, sentetik telefon doğrulamasını tamamla.
4. Haritada olmayan çalışma kategorisini seç.
5. Örnek anlık fotoğraf çekimini göster.
6. Yüz/plaka bulanıklaştırılmış kopyayı göster.
7. Konum ve açıklama ekle.
8. İçerik uyumu, risk ve nötr vatandaş güven sinyalinin ayrı hesaplandığını göster.
9. Vatandaşın gri pinini ve başka vatandaş görünümünde görünmediğini göster.
10. Belediye panelinde kritik/normal kuyruğa düşüşünü göster.
11. Personelin AI önerisini inceleyip doğrulamasını göster.
12. Gri pinin tüm kullanıcılar için kırmızı aktif pine dönüşmesini göster.
13. Vatandaş timeline'ında “İBB tarafından doğrulandı” durumunu göster.

Demo sırasında her rol değişiminde üstte 2 saniyelik rol etiketi gösterilir: “Vatandaş görünümü”, “Diğer vatandaş görünümü”, “Belediye personeli görünümü”.

## Design QA and Acceptance Criteria

### 1. Görsel sistem

- Tüm renkler token kullanır; literal renk denetimi CI'da yapılır.
- Tüm radius değerleri tanımlı ölçekten gelir.
- Rubik ve Urbanist dışında üretim fontu yoktur.
- Aynı niyetli bileşenler ayrı ayrı yeniden çizilmez.
- Harita pinleri dört durumda ekran görüntüsü karşılaştırma testine sahiptir.
- Logo dosyaları resmî paketten gelir; yeniden çizilmiş SVG yoktur.

### 2. Mobil test matrisi

- 320×568, 360×800, 390×844, 430×932
- iOS safe area ve Android gesture/navigation bar
- Sistem yazısı %100, %130, %200
- Açık tema; MVP'de koyu tema zorunlu değildir ve yarım uygulanmaz.
- Konum/kamera/bildirim izni: ilk kez, reddedildi, kalıcı reddedildi
- Çevrimdışı açılış, gönderim ortasında bağlantı kaybı, tekrar bağlantı
- Uzun ilçe, mahalle ve birim adı

### 3. Web test matrisi

- 1024×768, 1280×800, 1440×900, 1920×1080
- %100, %200, %400 zoom
- Klavye-only tam inceleme akışı
- NVDA/Chrome ve VoiceOver/Safari temel rota
- 0, 1, 100, 10.000 kuyruk kaydı
- 60 karakter kategori/birim adı
- Fotoğraf yok, blur başarısız, AI hatası, veri kaynağı gecikmesi
- Split panel en dar/en geniş durum

### 4. Erişilebilirlik kabulü

- WCAG 2.2 AA otomatik tarama + manuel test.
- Normal metin 4.5:1, metin dışı öğe 3:1.
- Görünür 2 px odak; sticky alan altında kaybolmaz.
- Her pin ve ikon düğmesi erişilebilir ada sahiptir.
- Harita işlemlerinin liste alternatifi vardır.
- Reduced motion'da bilgi kaybı yoktur.
- Form hataları alanla programatik ilişkilidir.

### 5. Anti-AI-slop denetimi

Teslim öncesi her ekran şu sorularla incelenir:

- Bu ekran kart ekleyerek mi, hiyerarşi kurarak mı çözülmüş?
- Gradient, glow, blur veya büyük radius gerçek bir görevi çözüyor mu?
- Aynı boyutta tekrar eden kartlar içerik önceliğini yok ediyor mu?
- Başlık ve yardımcı metin aynı şeyi iki kez mi söylüyor?
- İkon içerikten büyük mü?
- Birden fazla ana CTA var mı?
- Animasyon durum değişimini mi açıklıyor, yalnızca dikkat mi çekiyor?
- Tasarım İBB ürün ailesine mi ait görünüyor, jenerik SaaS şablonuna mı?

Herhangi bir sorunun cevabı olumsuzsa ekran üretime hazır değildir.

## Component and File Naming

### 1. Tasarım bileşenleri

- `Button/Primary/{Default|Hover|Pressed|Disabled|Loading}`
- `Button/Secondary/...`
- `Field/Text/{Default|Focus|Error|Disabled}`
- `Map/Pin/{Active|Planned|Pending|Critical|Selected}`
- `Map/Cluster/{Default|CriticalPresent}`
- `Navigation/Mobile/{Map|Report|MyReports}`
- `Report/Status/{Received|AIReview|IBBReview|Assigned|InProgress|InfoRequired|Merged|Resolved|Rejected}`
- `Queue/Row/{Default|Selected|Locked|Critical}`
- `AI/Analysis/{Complete|Partial|Failed}`
- `State/{Empty|Loading|Offline|Error}`

### 2. Kod eşlemesi

- Token adları platformlar arasında anlamı korur; Flutter/React isimleri teknolojiye göre dönüştürülebilir ama yeni anlam üretmez.
- Durum enum'ları görsel addan bağımsız iş anlamıyla adlandırılır: `verified_active`, `planned`, `pending_verification`, `critical_review_signal`.
- `redPin` veya `orangeWarning` gibi yalnızca renk tabanlı isim kullanılmaz.
- Her ekran analytics adıyla değil kullanıcı göreviyle adlandırılır.

## Research Basis and Decision Traceability

### 1. İncelenen İBB dijital aileleri

| Kaynak | Gözlenen ortaklık | Bu sisteme etkisi |
|---|---|---|
| [İBB ana portalı](https://ibb.istanbul/) | Urbanist; `#0E3B83` mavi; magenta vurgu; 8 px ve yaklaşık 52 px yüksek CTA; ölçülü gölge | Ana dijital renk, gövde fontu, 8 px kontrol radius'u |
| [İBB Çözüm Merkezi](https://cozummerkezi.ibb.istanbul/) | `#003378` koyu mavi, `#C31E60` magenta, `#F2F7FF` açık yüzey, Rubik güçlü başlık, 8 px düğme | Giriş/başlık karakteri ve mavi-magenta dengesi |
| [İBB Açık Veri Portalı](https://data.ibb.gov.tr/) | Veri odaklı navigasyon, mavi başlık, geniş arama, 16 px kartlar | Veri panelinde arama ve kaynak görünürlüğü; aşırı gölge kopyalanmadı |
| [Ulaşım Yönetim Merkezi](https://uym.ibb.gov.tr/) | Urbanist, koyu mavi bilgi akışı, olay/duyuru yoğunluğu | Harita olay akışı ve güncellik metadata'sı |
| [Metro İstanbul](https://www.metro.istanbul/) | Kompakt 36–38 px kontroller, koyu mavi/kırmızı, 4 px radius, yoğun görev yüzeyi | Belediye panelinde kompakt mod ve hızlı görev kontrolü |
| [İETT](https://www.iett.istanbul/) | Koyu mavi + kırmızı, 5–6 px radius, ulaşım arama odağı | Ulaşım katmanı ve kompakt arama dili |
| [Spor İstanbul](https://spor.istanbul/) | Koyu lacivert, canlı ikincil renkler, görünür erişilebilirlik araçları, pill CTA | Erişilebilirlik görünürlüğü; pill biçimi yalnızca chip'lerle sınırlandı |
| [Kültür İstanbul](https://kultur.istanbul/) | İçerik odaklı renk çeşitliliği ve görsel kartlar | Operasyon ekranına taşınmadı; yalnızca tanıtım yüzeylerinde kontrollü görsel zenginlik |
| [Kariyer İBB](https://kariyer.ibb.istanbul/) | Mavi-magenta, yoğun arama formu ve kurumsal giriş | Web formu ve kurumsal giriş hiyerarşisi |
| [İstanbul Senin](https://istanbulsenin.istanbul/) | Hizmetleri tek çatı altında sunan ana İBB uygulama dili | Ürün, İBB ekosisteminin alt hizmeti gibi konumlandı; paralel marka yaratılmadı |
| [AKOM](https://akom.ibb.istanbul/) | Kritik şehir bilgisinde doğrudanlık ve operasyon odağı | Kritik durum metni ve gösterişsiz uyarı yaklaşımı |
| [Şehir Planlama Müdürlüğü](https://sehirplanlama.ibb.istanbul/) | Katılımcı şehir dili ve İstanbul bağlamı | Kent odaklı, teknik olmayan vatandaş metni |

### 2. Resmî kimlik dayanağı

[İBB Basın Materyalleri ve Kurumsal Kimlik Kılavuzu](https://ibb.istanbul/ibb/basin-materyalleri/) temel alınmıştır.

- Logo oranı ve güvenli alanı korunur.
- Koyu zeminde dişi, açık zeminde eril resmî varyant kullanılır.
- Logo yeniden renklendirilmez, döndürülmez, eğilip bükülmez, farklı fontla yeniden yazılmaz veya efektlendirilmez.
- Kılavuzdaki Pantone 200 C / RGB 193-38-55 değeri `event-active` için de kurumsal uyumlu aktif kırmızı olarak kullanılmıştır.

### 3. Dış tasarım ve kalite kaynakları

- [Google Labs DESIGN.md formatı](https://github.com/google-labs-code/design.md): YAML token + insan tarafından okunabilir gerekçe yapısı; bu dosyanın üst bilgisi ve bölüm sistemi buna göre hazırlanmıştır.
- [Impeccable tasarım yaklaşımı](https://impeccable.style/designing/): ürün bağlamı, “Operate” yüzeylerinde taranabilirlik ve gerçek görev önceliği.
- [Impeccable AI-slop kataloğu](https://impeccable.style/slop/): kart içinde kart, aşırı radius, gradient/glow, ikon kutusu, tekrar eden grid ve anlamsız hareket açık yasaklara dönüştürülmüştür.
- [Motion performans rehberi](https://motion.dev/docs/performance): animasyonda transform ve opacity önceliği.
- [Motion erişilebilir hareket rehberi](https://motion.dev/docs/react-accessibility): reduced motion politikasının ürün çapında uygulanması.
- [21st.dev](https://21st.dev/): bileşenler tek tek ilham/referans olarak değerlendirilebilir; çok yazarlı stiller tek üründe karıştırılmaz ve her bileşen bu token sistemine uyarlanır.
- [Refero Styles](https://styles.refero.design/): gerçek ürün akışlarını inceleme yöntemi; bu belge herhangi bir tekil moda stilini kopyalamak yerine İBB örneklerinden türetilmiş tutarlı sistemi korur.
- [W3C WCAG 2.2 hızlı referansı](https://www.w3.org/WAI/WCAG22/quickref/): klavye, odak, kontrast, reflow, hedef boyutu ve durum mesajı kabul ölçütleri.

## Institutional Approval Notes

Bu maddeler tasarım açığı değil, üretim öncesi kurumsal onay noktalarıdır:

1. Resmî logo varyantı, uygulama ikonu ve mağaza görselleri İBB Kurumsal İletişim tarafından onaylanır.
2. “112 Acil'i ara” metni ve kritik yönlendirme akışı hukuk/operasyon tarafından onaylanır ve uzaktan yapılandırılır.
3. KVKK kısa metinleri, saklama süreleri ve açık rıza gerektiren alanlar hukuk tarafından kesinleştirilir.
4. Panel rol/yetki matrisi ilgili İBB birimleriyle eşleştirilir; görsel davranış bu belgede tanımlandığı gibi kalır.
5. Erişilebilirlik, gerçek kullanıcılarla ve yardımcı teknolojilerle kabul testinden geçirilir.

Bu onaylar beklenirken tasarım ve geliştirme, bu dosyadaki varsayılanlarla kesintisiz ilerleyebilir.
