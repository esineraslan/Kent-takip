# WP-00 Raporu

Durum: COMPLETED  
Branch/commit: Arşiv teslimi; git commit oluşturulmadı.  
Kapsam: Çelişkili ürün, AI, veri, demo ve persistence kararlarının tekilleştirilmesi.

## Değişen dosyalar ve kararlar

- Yedi kanonik belge, `EKSTRA.md`, roadmap, arşiv kaynakları ve traceability güncellendi.
- Sekiz ADR ve demo kapsamı onay kaydı oluşturuldu.
- Ürün İstanbul Senin/153 tamamlayıcısı; `UrbanIncident` ortak olay kimliği; vatandaş güven skoru yok; AI yalnız öneri/gizlilik/mükerrer adayı; afet salt okunur yetkili kaynak; persistence atomik olarak donduruldu.
- Beş tasarım ön çıktısı `docs/reference_design/` altında referans olarak korundu.

## Kabul, test ve platform etkisi

- Kanonik belge ve P0 karar matrisi tamamlandı; üretim ile demo sınırı açık.
- `python3 tool/check_doc_consistency.py`: geçti; 8 zorunlu belge ve 8 ADR doğrulandı.
- Bütün Markdown dosyaları UTF-8 BOM + NFC kontrolünden geçti.
- Kod içermediği için Android/iOS/web çalışma zamanı etkisi yoktur.

## Güvenlik, erişilebilirlik ve öz-denetim

- Gerçek kurum erişimi, gerçek kişisel veri ve üretim entegrasyonu kapsam dışı bırakıldı.
- Fotoğrafsız erişilebilir manuel inceleme rotası kanonikleştirildi.
- Öz-denetim 1: iki eski Markdown dosyasında BOM eksikliği bulundu ve düzeltildi.
- Öz-denetim 2: vatandaş/personel AI görünürlüğü, resmî uyarı sınırı ve demo iddiası adversarial olarak kontrol edildi.

## Bilinen P2/P3 sınırlar ve sonraki paket

- Üretim KVKK saklama süresi, kurum rol sahipliği ve gerçek 153 sözleşmesi ayrıca yazılı kurum onayı ister.
- WP-01 kaynakları hazırlanmıştır; SDK doğrulama kapısı beklenmektedir.
