# WP-02 Raporu

Durum: BLOCKED  
Branch/commit: Arşiv teslimi; git commit oluşturulmadı.  
Kapsam: Domain modelleri, state machine'ler, projection/yetki politikaları, portlar ve strict JSON sözleşmeleri.

## Uygulanan kaynaklar

- Report, incident, work, account/session, source, media/AI, doğrulama, dış referans, SLA/çözüm, timeline/notification/audit/privacy/restriction/demo modelleri immutable olarak kuruldu.
- Report/incident/work geçiş politikaları; owner/staff/public pin projection; authorization, merge-cycle ve AI yetki sınırı uygulandı.
- UTC, WGS84, UUID, takip numarası ve snake_case enum standartları; tipli failure modeli; repository/service/clock/location/map/notification/source/event portları eklendi.
- Domain event kataloğu, strict DTO katmanı, JSON Schema ve sentetik örnek sözleşme yolu oluşturuldu.

## Kabul ölçütleri ve testler

- Unit/contract test kaynakları; izin reddi, terminal state, kritik projection, gizlilik, AI state yasağı, merge cycle, UUID/takip, unknown enum ve UTC dallarını kapsar.
- Python kaynak/seed sözleşme kontrolleri geçti.
- Dart testleri ve coverage çalıştırılamadı; WP-01 SDK kapısı blokajdır. Bu nedenle yüzde 90 kritik dal kapsam kanıtı henüz yoktur.

## Platform, erişilebilirlik ve güvenlik

- Domain paketi Flutter/plugin bağımsız saf Dart'tır; Android/iOS/web davranışı ortaktır.
- UI olmadığı için görsel erişilebilirlik etkisi yoktur.
- Pending report başka vatandaşa açılmaz; AI otomatik state değiştiremez; vatandaş güven skoru modeli ve snapshot alanı yasaktır.

## Öz-denetim ve kalan sınırlar

- Öz-denetim 1: koordinat sistemi, UTC/tarih aralığı, resolution evidence ve referans bütünlüğü doğrulamaları sıkılaştırıldı; auxiliary JSON derin immutable yapıldı.
- Öz-denetim 2: yanlış yetkili personel, kritik vatandaş girdisi, bilinmeyen enum ve merge-cycle saldırıları için fail-closed testleri eklendi.
- P2: auxiliary snapshot kayıtları collection-specific doğrulanır ancak core kayıtlar gibi adlandırılmış DTO sınıflarına ayrılması sonraki sözleşme evriminde yararlı olabilir.
- Sonraki adım: SDK runner'da analyzer, unit test ve coverage kanıtı.
