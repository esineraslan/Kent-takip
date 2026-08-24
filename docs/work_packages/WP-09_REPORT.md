# WP-09 — Kamera, medya ve gizlilik raporu

## Uygulanan kaynak

- Flutter ekibi `image_picker 1.2.3` ile Android/iOS/web kamera adaptörü; iOS usage açıklamaları ve Android `retrieveLostData` recovery.
- Çek/yeniden çek/iptal/fotoğrafsız devam; izin reddi, kısıt, kamera yok, kesinti, quota ve geçersiz medya mesajları.
- 8 MB, 4096 px kenar, 12 MP, JPEG/PNG format kapıları.
- JPEG APP1–APP15/COM metadata ve PNG ancillary chunk temizliği.
- `Random.secure` actor-scoped ID, güvenli `media://` göreli referans, immutable/idempotent upload.
- `safe/manualReviewRequired/failed` lifecycle; güvenli olmadığı durumda `publicRef` üretilmez.
- Citizen snapshot'tan `originalRef` çıkarılır; original okuma staff permission + gerekçe + audit ister.
- Reset, snapshot'tan dinamik medya referanslarını kendisi bulup temizler.

## Öz-denetim düzeltmeleri

- Gerçek redaksiyon motoru olmadan “bulanıklaştırıldı” varsayımı güvenli bulunmadı. Gerçek çekim yolu fail-closed `manualReviewRequired` olarak değiştirildi; public kopya yalnız doğrulanmış safe processor senaryosunda oluşur.
- Aynı upload retry'ının immutable kuralına takılması düzeltildi: aynı byte 204, farklı byte 409.
- Snapshot komutunda sunucuda bulunmayan medya referansı kullanımı engellendi.

## Durum

Kaynak ve statik gizlilik kapıları hazırdır. Fiziksel Android/iOS kamera, permission ve background smoke testleri ile Flutter testleri koşturulamadığı için `BLOCKED`.
