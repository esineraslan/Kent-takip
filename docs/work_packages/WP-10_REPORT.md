# WP-10 — Dar AI ve evaluation raporu

## Uygulanan kaynak

- Yetenek, en fazla üç kategori/birim önerisi, privacy sonucu, duplicate adayları, risk sinyali, model/config sürümü ve latency taşıyan typed sözleşme.
- Deterministik `complete`, `partial`, `unavailable`, `timeout`, `invalidResponse` demo motoru.
- Varsayılan kapalı, timeout ve strict JSON parse ile fail-closed remote adapter seam'i.
- Citizen sade projeksiyonu ve staff ayrıntılı projeksiyonu; server citizen yanıtından confidence/internal reason/duplicate ID çıkarılır.
- Staff AI override'ında gerekçe zorunlu ve audit alanı; `AiAuthorityPolicy` otomatik state değişimini reddeder.
- Yedi fixture'lı evaluation gate: kategori doğruluğu 0.833333, privacy false-negative 0, duplicate recall 1, valid response 0.857143.

## Öz-denetim düzeltmeleri

- AI duplicate fixture'ının seed'de bulunmayan incident ID üretmesi düzeltildi.
- Citizen snapshot'ta internal AI reason code ve confidence sızıntısı kapatıldı.
- Rate limit otomatik ret yerine `manualReviewRequired` ve yüksek riskli insan kuyruğuna yönlendirildi.

## Durum

Deterministik evaluation Python kapısı yeşildir. Dart unit test ve platform integration kanıtı SDK yokluğu nedeniyle üretilemedi; `BLOCKED`.
