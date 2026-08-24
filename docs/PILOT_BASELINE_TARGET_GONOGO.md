# İBB Kent Takip — Pilot Baseline, Hedef ve Go/No-Go Şablonu

## İlke

Bu dosyadaki hedefler **başarılmış sonuç değildir**. Gerçek pilot verisi girilmeden yüzde tasarruf, ROI veya üretim başarısı iddiası yapılmaz.

## Pilot kapsamı

- Süre: 6 hafta.
- Bölge: veri ve operasyon erişimi onaylanmış tek pilot ilçe/alan.
- Kategoriler: yol yüzey hasarı ve su kaçağı/su birikmesi.
- Personel: 5–10 inceleme/operasyon kullanıcısı.
- Karşılaştırma: baseline süreç ile kontrollü pilot süreç.

## Baseline formu

| Metrik | Baseline | Ölçüm kaynağı | Örneklem | Not |
|---|---:|---|---:|---|
| Medyan ilk insan inceleme süresi | GİRİLMEDİ | operational_metric:first_review | GİRİLMEDİ | |
| İlk yönlendirmede doğru birim oranı | GİRİLMEDİ | report_verified / report_transferred_back | GİRİLMEDİ | |
| Tekil olay başına mükerrer işlem | GİRİLMEDİ | incident.reportIds | GİRİLMEDİ | |
| Tekrar durum sorma oranı | GİRİLMEDİ | operational_metric:repeat_status_request | GİRİLMEDİ | |
| Çözüm sonrası gerçekten çözüldü oranı | GİRİLMEDİ | citizen_resolution_feedback | GİRİLMEDİ | |

## Hipotez hedefleri

- Medyan triage süresinde en az %30 iyileşme.
- İlk yönlendirme doğruluğunda en az 15 yüzde puan artış.
- Mükerrer kayıt başına personel işleminde en az %30 azalma.
- Kritik dikkat senaryolarında en az %95 recall.
- Kamuya çıkan medyada 0 kritik kişisel veri kaçağı.
- Staff AI override oranı en fazla %20.
- Timeline doğru anlama oranı en az %85.
- P0/P1 erişilebilirlik ve güvenlik hatası 0.

## North-star

**Doğru birime ilk seferde yönlendirilip hedef sürede ilk insan incelemesi alan tekil kent olayı oranı.**

Uygulamadaki `PilotAnalyticsProjection` bu oranı snapshot + immutable audit olaylarından türetir. İlk inceleme hedefi kodda açık parametredir; pilot kararıyla değiştirilebilir, gizli sabit değildir.

## Go/No-Go

- Gizlilik kaçağı varsa: **NO-GO**.
- Kritik recall ölçülmemişse: **YETERSİZ KANIT**.
- Yönlendirme, personel süresi veya timeline anlaşılırlığı ölçülmemişse: **YETERSİZ KANIT**.
- Ölçülmüş zorunlu hedeflerden biri karşılanmıyorsa: **NO-GO**.
- Bütün zorunlu kanıtlar ölçülmüş ve hedefler karşılanmışsa: **GO adayı**; kurumsal insan onayı yine zorunludur.

Kod karşılığı: `PilotGoNoGoPolicy`.
