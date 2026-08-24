# İBB Kent Takip — AI Sistem Sözleşmesi

Belge durumu: Demo geliştirmesi için onaylı kanonik kaynak  
Belge sürümü: 1.0  
Tarih: 17 Ağustos 2026

## 1. Yetki sınırı

AI yalnız karar desteğidir. Report/incident/work state değiştiremez; ret, yaptırım, merge, yönlendirme veya kamusal yayın yapamaz. İnsan override'ı ve gerekçesi audit edilir. AI unavailable olduğunda vatandaş verisi kaybolmaz ve manuel inceleme devam eder.

## 2. İzinli yetenekler

| Yetenek | Girdi | Çıktı | Nihai karar |
|---|---|---|---|
| Kategori/birim önerisi | Kamusal medya veya fotoğrafsız metin, konum bağlamı | Top-3 kategori/birim, confidence, reason codes | Personel |
| Privacy maskeleme | Orijinal medya | Kamusal kopya, tespit türleri, sonuç | Fail-closed pipeline |
| Mükerrer aday | Konum, zaman, kategori, metin/görsel fingerprint | Aday olaylar ve confidence | Personel |

Kritik dikkat, kalite, rate limit, SLA ve uzamsal çakışma kural tabanlıdır.

## 3. Yasak çıktılar

- Vatandaş güven skoru veya kişisel doğruluk profili;
- otomatik kötü niyet kararı;
- otomatik kamuya yayımlama veya merge;
- veri olmadan ETA/trafik tahmini;
- serbest metinle onaysız kamu duyurusu;
- otomatik acil durum doğrulaması.

## 4. Tipli sözleşme

Her analiz: `analysisId`, `status`, `capabilities`, `suggestions`, `privacyResult`, `duplicateCandidates`, `reasonCodes`, `modelVersion`, `configVersion`, `createdAt` ve güvenli hata kodu taşır. Confidence değerleri yetenek bazında ayrıdır; tek “doğruluk” skoru yoktur.

## 5. Rol projection'ı

- Vatandaş: “Kategori önerildi”, “Fotoğraf güvenli hâle getirildi”, “Benzer olay bulundu” veya “İnsan incelemesi gerekiyor”. Ham confidence, abuse sinyali ve model iç ayrıntısı gösterilmez.
- Personel: ayrık confidence, reason code, veri eksikleri, sürüm ve override alanlarını görür.

## 6. Privacy fail-closed

Privacy işlemi tamamlanmadan `publicRef` üretilemez. Timeout, şema hatası veya tespit belirsizliğinde medya `manual_review_required` olur. Orijinal medya yalnız permission + reason + audit ile açılır. EXIF ve gereksiz metadata temizlenir.

## 7. Demo ve gerçek adaptör

`DemoAiAnalysisService` senaryo kimliğine göre deterministiktir ve jüri ana rotasını ağdan bağımsız tutar. Gerçek servis yalnız feature flag arkasındadır; veri aktarımı KVKK/onay olmadan açılamaz. Her iki implementasyon aynı contract testlerini geçer.

## 8. Hata modeli

Desteklenen durumlar: `complete`, `partial`, `unavailable`, `timeout`, `invalid_response`, `privacy_failed`. Partial sonuç yalnız tamamlanan yetenekleri sunar. Kullanıcıdan aynı report'u veya fotoğrafı yeniden göndermesi istenmez.

## 9. Evaluation harness

Sürüm kontrollü sentetik/lisanslı fixture seti aşağıdaki metrikleri üretir:

- kategori top-1 ve top-3 doğruluk;
- privacy kritik kaçırma sayısı;
- duplicate precision/recall;
- kritik dikkat kuralı recall;
- staff override oranı;
- p50/p95 analiz süresi;
- AI yokken veri kaybı.

Pilot hedefleri başarı iddiası değildir: top-1 ≥ %85, top-3 ≥ %95, duplicate precision ≥ %85, p95 ≤ 5 sn, kamuya çıkan medyada kritik privacy kaçağı 0 ve AI yokken veri kaybı 0.

## 10. İzlenebilirlik

Model/config değişimi sürüm alanında görünür, evaluation snapshot'ını yeniden üretir ve rol projection testlerini tetikler. Drift/fairness üretim pilotu öncesi ilçe, cihaz, fotoğraf kalitesi, dil ve erişilebilir rota kırılımlarında değerlendirilir.
