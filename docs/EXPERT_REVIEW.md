# İBB Kent Takip — Uzman Öz-Denetim Kaydı

## Tur 1 — Mobil mimari ve veri dayanıklılığı

İncelenen başlıklar: paket sınırları, immutable veri, kontrollü null/dynamic, state geçişleri, yarış koşulları, yetki, veri kaybı, bağımlılık ve platform ayrımı.

Bulunan ve düzeltilen önemli konular:

- IO recovery sırasında bozuk active dosyanın sağlam backup üzerine dönmesi engellendi.
- Web dual-slot store, bozuk pointed slot durumunda geçerli fallback'i ezmek yerine bozuk slotu onaracak şekilde düzeltildi.
- Web medya byte dizilerinin metne kayıplı çevrilmesi yerine base64 kullanıldı.
- Resolution evidence, insan ret gerekçesi, media/analysis/incident/source referansları ve citizen trust alan yasağı codec kapısına alındı.
- Auxiliary JSON kayıtları derin immutable ve collection-specific doğrulamalı hâle getirildi.
- Transaction queue'nun bir hata sonrasında zehirlenmemesi için regresyon testi eklendi.

## Tur 2 — Adversarial kullanıcı ve jüri

- Kötü niyetli kullanıcı: yetkisiz import/export ve kişi güven puanı alanı reddediliyor.
- Zayıf bağlantı/yarım yazım: pointer son adımda değişir; IO temp doğrulanmadan aktif olmaz; son geçerli kopya korunur.
- Yanlış yetkili personel: permission policy fail-closed çalışır.
- AI kesintisi/yanılgısı: AI state transition yetkisine sahip değildir; sonuçları sürüm/gerekçe taşır.
- Bozuk veri kaynağı: kaynak health/provenance ve referans doğrulaması zorunludur.
- Jüri: demo/sentetik veri sınırı, local/shared ayrımı ve gerçek entegrasyon iddiası açıkça etiketlidir.

## Son kalite kararı

Kaynak seviyesinde bilinen P0/P1 açık bırakılmadı. Ancak Flutter/Dart SDK bulunmayan bu ortamda analyzer, unit/widget/integration testleri ve platform build'leri koşturulamadığı için WP-01–04 roadmap anlamında tamamlanmış sayılamaz. CI bu kanıtları üretmeden release veya çalışan üç-platform iddiası verilmemelidir.

## Tur 3 — WP-04 mobil uygulama mimarisi ve güvenlik

- URL, rol ve permission olmak üzere üç katmanlı guard matrisi fail-closed kuruldu; dış/protokol-relative `returnTo` değerleri reddedildi.
- OTP verilmeden doğrulama ve başarılı OTP'nin yeniden kullanımı engellendi; OTP/MFA denemeleri 5 hata sonrasında 60 saniye kilitlenir.
- Demo credential'larının release ortamında kullanılmaması için üretim auth adaptörü gelene kadar bootstrap fail-closed kapatıldı.
- Oturum, auth challenge ve snapshot ömürleri ayrıldı; rol değişimi yalnız oturumu kapatır, store'u sıfırlamaz.
- Structured log alanlarında telefon, OTP, parola, MFA, token, authorization ve original media referansları redakte edilir.
- Personel menüsü permission ile filtrelenir; citizen ve staff shell birbirinin navigasyonunu üretmez.

## Tur 4 — WP-04 çalışma zamanı ve tasarım denetimi

- `MaterialApp.builder` üstündeki demo bandından context-router erişimi güvenilir olmadığı için yönlendirici doğrudan enjekte edildi.
- Build içinde tekrar tekrar Future üreten ekranlar sonsuz yeniden yükleme riski nedeniyle tek seferlik snapshot Future'ına çevrildi.
- Demo yardımcı sayfalarının `go` + `pop` yığın hatası `push` ve güvenli geri dönüş ile düzeltildi.
- Dar ekranda gizlenen senaryo/sıfırlama işlemleri taşma menüsüne alındı; personel drawer'ına çıkış ve rol değiştirme eklendi.
- Auth submit ve demo reset eylemlerine tekrar dokunma yarışı engeli eklendi; reset sonrası eski snapshot Future'ına dönmek yerine çağıran route taze okunur.
- Referansların 56 px mobil başlığı, 72 px üçlü alt navigasyonu, 232/80 px personel menüsü, 64 px üst barı, renk/spacing/radius hiyerarşisi kaynakta eşlendi.
- Resmî İBB logo dosyası verilmediği için ekrandan türetilmiş veya yeniden çizilmiş sahte logo kullanılmadı; kurumsal onaylı asset gelene kadar erişilebilir nötr kent işareti kullanıldı.

## WP-04 kalan risk kararı

- P0/P1 kaynak bulgusu bırakılmadı.
- P2: feature ekranlarının işleme özgü içeriği WP-05 ve sonraki paketlerin kapsamıdır; WP-04 ekranları güvenli navigasyon sınırlarını gösterir.
- Blokaj: Flutter 3.47.x SDK olmadan analyzer, widget/integration testleri ve Android/iOS/web smoke build kanıtı üretilemedi.

## Tur 5 — WP-05 tasarım ve erişilebilirlik

- İlk incelemede renk/font literal'larının ekranlara dağılması ve eski harita pininin durum+konum semantics'i taşımaması P1 drift riski olarak bulundu; tek token dosyası, CI scanner ve `KtMapPin` ile düzeltildi.
- Durumun yalnız renkle taşınması riski icon + text + semantics üçlüsüyle kapatıldı.
- Yüzde 200 metin, uzun TR/EN, sekiz viewport, görünür focus, reduced motion ve high contrast test kaynakları eklendi.
- Marka dosyası eksikliğinde ekran görüntüsünden logo/font türetmenin kurumsal risk olduğu teyit edildi; manifest onayı olmadan binary asset kapısı açılmadı.

## Tur 6 — WP-06 mobil walking skeleton

- UI içinde doğrudan snapshot değiştirme yaklaşımının shared modda kural drift'i yaratacağı tespit edildi; komut/idempotency/projection ortak saf Dart application paketine taşındı.
- İlk taslakta local bootstrap'ın in-memory kalması reopen kabulünü bozuyordu; IO application-support atomik store ve web dual-slot localStorage ile düzeltildi.
- Başka vatandaşın pending pin görmesi projection seviyesinde engellendi; public olay yalnız insan verify komutundan sonra oluşur.
- Tracking, client mutation, audit ve timeline aynı atomik snapshot commit'inin parçası yapıldı.

## Tur 7 — WP-07 server ve senkron adversarial inceleme

- Request body `actorId` değerine güvenme riski server bearer eşlemesiyle kapatıldı.
- Full snapshot'ın citizen'a verilmesiyle başka vatandaş report/audit sızıntısı riski bulundu; rol bazlı server projection eklendi.
- Hidden report'a bağlı public incident referansının checksum codec'ini bozduğu ikinci turda bulundu; incident için PII içermeyen sentetik doğrulanmış projection source üretildi.
- WebSocket üzerinden tam state taşımanın auth/cache drift riski engellendi; kanal yalnız revision event taşır.
- Stale personel kararı `409 + current snapshot + explicit retry` ile fail-closed; unauthorized command denied audit ile kayıtlıdır.
- Guest açılan WebSocket'in login sonrasında bağlı kalmaması riski token değişiminde reconnect ile düzeltildi.
- Public/citizen snapshot'ta başka hesaba ait media, AI analysis ve corroboration metadatasının kalması ikinci projection turunda kapatıldı; filtrelenmiş snapshot yeniden checksum'lanıp strict codec ile doğrulanır.
- İnsan doğrulaması sonrasında sahibin haritasında aynı kaydın hem gri report hem kırmızı incident pini olarak görünmesi projection kuralıyla tek kanonik kırmızı pine indirildi.
- WebSocket kesintisinin başarılı REST erişimini yanlışlıkla offline göstermesi engellendi; personel salt-okunur kararı yalnız mutation erişimine göre verilir.
- Yerel HTTP istisnası Android debug manifestiyle sınırlandı; release ve iOS güvenlik politikaları gevşetilmedi.

## WP-05–07 kalan risk kararı

- Kaynak incelemesinde bilinen P0 bırakılmadı.
- P1 doğrulama riski: Flutter/Dart SDK yok; analyzer, formatter, saf Dart/widget/integration/server testleri gerçek toolchain ile henüz çalıştırılmadı.
- P1 marka riski: resmî logo ve lisanslı font dosyaları yok; golden baseline kapısı bilinçli olarak açık bırakılmadı.
- Bu iki kanıt gelmeden WP-05–07 `COMPLETED` veya release-ready sayılmaz.

## Tur 8 — WP-08–12 mobil uzman ve adversarial inceleme

- Eski statik harita preview'su gerçek tile/fallback, 39 ilçe araması, cluster, source/freshness detayı ve erişilebilir eş listeyle değiştirildi. Test ortamında dış ağ beklemesi deterministik offline yüzeye çevrildi.
- Aktif belediye çalışmasının planlanan sarı pin olarak kalma hatası düzeltildi; `active` kırmızı, `publishedPlanned` sarıdır. Pending citizen pin başka vatandaşta görünmez; kritik turuncu yalnız staff'tadır.
- Kamera plugin'i fiziksel yaşam döngüsüne bağlandı; Android process recreation verisi geri alınır. Gerçek redaksiyon motoru olmadan güvenli public kopya iddia etmenin P0 gizlilik riski olduğu kabul edilerek gerçek çekim fail-closed manual review'a alındı.
- Citizen snapshot'tan original media ref ve iç AI confidence/reason/duplicate ID alanları çıkarıldı. Original medya yalnız staff permission, gerekçe ve başarılı erişim audit'iyle okunur.
- Aynı byte medya retry'ının 409 üretip offline retry'ı kırması idempotent 204 ile düzeltildi; farklı byte immutable 409 kalır. Komut öncesi sunucuda bulunmayan medya ref'i reddedilir.
- AI fixture'ın seed'de olmayan duplicate incident'a işaret etmesi düzeltildi. AI override insan gerekçesi olmadan commit edilemez; AI domain state geçişi çalıştıramaz.
- Rate limit vatandaş bildirimini kaybetmez veya otomatik yaptırım yapmaz; insan manual review kuyruğuna yükseltir.
- Notification read, ek bilgi, çözüm geri bildirimi ve itiraz UI-local bırakılmadı; owner-scoped revision/idempotency/audit komutlarına taşındı. “Sorun sürüyor” sinyali otomatik reopen yapmaz.
- WP-06 eski minimal form ve private harita bileşenleri ölü kod olarak bulundu, kaldırıldı; E2E kaynağı yeni beş adımlı akışa geçirildi.

## WP-08–12 kalan risk kararı

- Statik Python kapılarında seed, belge, secret/PII, tasarım sistemi, 10.000 kayıt benchmark ve AI evaluation yeşildir.
- P1 doğrulama riski: Flutter/Dart SDK yok; analyzer, unit/widget/integration testleri koşturulamadı.
- P1 platform riski: gerçek Android/iOS kamera permission, background/process recovery ve web camera smoke testi bekliyor.
- P1 gizlilik entegrasyon riski: üretim yüz/plaka redaksiyon motoru bağlanana kadar gerçek çekim public'e çıkmaz. Bu kısıt güvenli ve bilinçli fail-closed davranıştır.
- P1 marka/golden riski önceki paketlerdeki gibi resmî font/logo baseline'ı bekliyor. Bu kanıtlar olmadan WP-08–12 `COMPLETED` veya release-ready sayılmaz.

## Tur 9 — WP-13–14 belediye operasyonu ve karar güvenliği

- Dashboard/kuyruk sayaçlarının ayrı mutable state olarak tutulması yerine snapshot domain verisinden okunma anında türetilmesi sağlandı; kritik kayıt normal/lower kuyruk mantığında kaybolmuyor.
- Geniş ekran panel yorumunda ROADMAP'in `queue/detail/map` ifadesi ile `DESIGN.md` W-02/W-03 çelişkili görünüyordu. `RULES.md` §3.1 karar önceliği tekrar uygulanınca `DESIGN.md` daha yüksek öncelikli olduğu için nihai yapı 260 px filtre + 440 px kuyruk + ≥480 px detay olarak düzeltildi; gerçek 240 px `MapSurface` W-03'e uygun biçimde detay içine yerleştirildi.
- Domain `UrbanIncident.workOrderRefs` içerirken snapshot DTO’nun bu bağı kopardığı görüldü. Geriye uyumlu `ExternalWorkOrderRefDto` eklendi; boş listede JSON alanı emit edilmediği için mevcut seed checksum değişmedi, staff workspace varsa work-order source/id/sync bilgisini gösteriyor.
- Review lease olaylarının yalnız timestamp ile sıralanması sabit saatli/eşzamanlı testte release/takeover sonucunu belirsiz bırakabiliyordu; monoton snapshot revision birincil sıralama anahtarı yapıldı.
- İlk routing taslağında doğrulama öncesi `ibbReview -> assignedUnit` mümkün olabiliyor ve incident kurulmadan verify yolunu kapatabiliyordu; reroute yalnız doğrulanmış incident bağlı `assignedUnit` kayda daraltıldı. İlk yönlendirme verify komutunda kalır.
- Transfer-back ilk taslakta eski sorumlu birimi incident üzerinde aktif bırakıyordu; önceki sorumluluk audit geçmişine taşınırken aktif `responsibleUnitId` temizlenir ve tracking korunur.
- Personel mutasyonları aynı transaction kuyruğunu, actor permission, current revision, aktif lease, invariant, audit/timeline/notification ve idempotency hattını paylaşır; AI hiçbir komutu kendi başına çalıştıramaz.
- Public preview insan onayı verify için zorunlu; original media izni olmayan rolde ref yalnız gizlenmiyor, widget ağacına hiç üretilmiyor.

- Uzman kod turunda `createReport` içindeki `now` değişkeninin yanlışlıkla düşmesi ve lease takeover audit map'inde yinelenen `expiresAt` anahtarı yakalanıp düzeltildi.
- 10k kuyruğunda report başına media/analysis/incident/source/audit koleksiyonlarının tekrar taranması ölçek riskiydi; `_StaffProjectionLookup` indeksleri ile bounded lookup yapısına çevrildi.
- Doğrulanmış `assignedUnit` report üzerinde reject/out-of-scope yapılabilmesinin mevcut public incident'i yetim bırakabileceği görüldü; karar action/state matrisi doğrulama öncesi ve sonrası eylemleri kesin ayıracak şekilde fail-closed sıkılaştırıldı.
- Reject/out-of-scope için serbest metin tek başına yeterli görülmedi; yapılandırılmış `reasonCode` + insan açıklaması ikilisi komut ve audit kontratına eklendi.
- Son UI kaynak taramasında `StaffQueueFilters` çağrısında yinelenen `minDuplicateConfidence` named argument bulundu; Flutter analyzer olmasa bile derleme engeli olacağı için kaldırıldı. Aynı turda kullanılmayan `_entry` snapshot parametresi de analyzer gürültüsü oluşturmaması için temizlendi.
- Ret/kapsam-dışı reason code'ları yalnız UI dropdown'ına güvenmek yerine application katmanında allow-list ile doğrulanır; doğrudan HTTP istemcisi sözleşme dışı kod gönderemez.

## WP-13–14 kalan risk kararı

- SDK-bağımsız kaynak/seed/belge/secret-PII/design/AI evaluation/10k contract kapıları yeşildir.
- P1 doğrulama riski: bu ortamda Flutter/Dart SDK yoktur; yeni Dart projection/command testleri, staff widget/golden/a11y, server integration, E2E ve Android/iOS/web build kapıları gerçek toolchain ile çalıştırılamadı.
- Bu nedenle kaynak uygulaması mevcut olmasına rağmen WP-13–14 `COMPLETED` veya release-ready olarak işaretlenmez; kanonik ROADMAP durumu `BLOCKED` kalır.


## Tur 10 — WP-15–16 saha operasyonu ve planlı çalışma

- WP-14 yönlendirmesinin saha SLA saatini başlatmaması ilk entegrasyonda operasyon metriğini koparıyordu; yönlendirme artık kategori/birim SLA hedef aralığını incident üzerinde atomik başlatır, transfer-back ise aktif saha sahibi/ekip/SLA bağını temizler.
- Saha çözümü zorunlu insan açıklaması olmadan terminal state'e geçemez. Opsiyonel sonuç medyası yalnız `PrivacyStatus.safe` ve `publicRef` taşıyorsa citizen projection'a girer; çözüm anında `slaPausedAt` ile SLA saati durdurulur.
- External work-order entegrasyonu yoksa açıkça `DEMO_SIMULATED_WORK_ORDER` referansı üretilir; gerçek/mevcut referans varken ikinci bir sahte referans eklenmez.
- “Sorun devam ediyor” çözüm geri bildirimi incident/report state'ini otomatik reopen etmez; insan review kuyruğuna yüksek öncelikli sinyal üretir ve lease ile ele alınabilir.
- Planlı çalışma taslağı public projection'a girmez. Konum/zaman/alan değişikliği impact sonucunu geçersiz kılar; yeniden analiz olmadan review/publish ilerlemez.
- Etki analizi trafik tahmini değildir: kullanılan demo yol segmenti/transit buffer kaynağını, mesafeyi, zaman çakışmasını ve kuralı kayıt bazında açıklar; alternatifler de aynı kural tabanlı gerekçeyi taşır.
- W-07 yayın önizlemesinde yalnız metinle “sarı pin” anlatmak yerine ortak `KtMapPin` bileşeniyle gerçek planlı pin önizlemesi gösterilir; vatandaş metni değişince yayın butonu anlık doğrulanır.
- DemoClock, uygulama plan bitiminden sonra açıldığında geçersiz `published_planned → completed` sıçraması yapmaz; audit/timeline içinde `published_planned → active → completed` ardışık geçişlerini üretir. Public map projection ise saatten etkin durumu hesapladığı için stale persisted state olsa bile sarı/kırmızı/tamamlandı görünümü doğru kalır.
- Kaynak denetiminde `FieldOperationCommand.reestimateMinMinutes` alanının yinelenen deklarasyonu bulundu ve kaldırıldı; static delimiter kontrolünün yakalamadığı bu tür derleme hatası için gerçek Dart analyzer kapısının neden zorunlu olduğu tekrar doğrulandı.

## WP-15–16 kalan risk kararı

- SDK-bağımsız kaynak/seed/belge/secret-PII/design/AI/10k contract kapıları çalıştırılabilir ve teslim kanıtında raporlanır.
- Flutter/Dart executable bu çalışma ortamında mevcut değildir; bu nedenle Dart formatter/analyzer, yeni WP-15/16 unit-integration/server testleri, widget/golden/a11y ve Android/iOS/web build kapıları PASS sayılmaz.
- WP-15–16 kaynak uygulaması tamamlanmış olsa da kanonik ROADMAP durumu gerçek toolchain kanıtı üretilene kadar `BLOCKED` tutulur.


## Tur 11 — WP-17–18 kaynak yönetişimi, RBAC ve KVKK

- Gerçek-şema kanıtı ile canlı entegrasyon iddiası ayrıldı: GTFS `stops.txt` mapping'i yürütülebilir fixture kanıtıdır; UI ve doküman canlı İETT bağlantısı demiyor. 153/İstanbul Senin de aynı şekilde `simulated_contract` olarak sınırlandı.
- Kaynak kesintisinin snapshot'ı bozması engellendi: retry/backoff/jitter + circuit-breaker son geçerli cache'i korur; health kaydı fresh/stale/unavailable/quarantined ayrımını ve source/ingestion zamanlarını taşır.
- Son kaynak turunda `SourceOperationAction` enumunda yinelenen `refreshGtfsSchema` değeri bulundu; delimiter/declaration scripti enum üyelerini kontrol etmediğinden ek enum-member taramasıyla kapatıldı.
- Kolay erişilen üçüncü taraf verinin resmî kaynak üzerine yazılması, authority-rank policy ile fail-closed engellendi. Bilinmeyen kayıtlar sessiz kategoriye dönüştürülmeyip quarantine edilir.
- Yönetim route'ları yalnız UI menüsüyle gizlenmedi; application command ve shared server actor/permission kontrolü aynı kurala bağlandı. Import `manageSources`, user access `manageUsers`, privacy resolution `managePrivacyRequests`, original media `viewOriginalMedia` ister.
- Demo supervisor geniş izinli olmasına rağmen bypass değildir; staff topbar aktif rolü gösterir ve yeni core/staff/field/work/source/admin audit kayıtları `activeRoleContext` taşır.
- Hesap silme yalnız UI flag'i değildir: re-auth + confirmation sonrası account state'e yazılır ve `createReport` application katmanında fail-closed engellenir. Restriction kademeli/geçici ve insan onaylıdır; kalıcı otomatik ceza yoktur, appeal insan incelemesine gider.
- WP-16 clock transition hatasının yalnız audit'e yazılıp yöneticiye görünmemesi entegrasyon açığıydı; `admin_alert` WP-18 governance alert ve dashboard uyarısına bağlandı.
- Orijinal medya erişimi için gerekçe UI'da zorunlu, server/application katmanında tekrar doğrulanır ve başarılı erişim immutable audit üretir.

## WP-17–18 kalan risk kararı

- SDK-bağımsız kaynak/seed/belge/secret-PII/design/AI/10k contract kapıları çalıştırılabilir ve teslim kanıtında raporlanır.
- Bu ortamda Flutter/Dart executable yoktur; formatter/analyzer, yeni adapter/admin/server/route testleri, E2E ve platform build kapıları gerçek toolchain ile koşturulamadı.
- Bu nedenle WP-17–18 kaynak uygulaması tamamlanmış olsa da kanonik ROADMAP durumu `BLOCKED` kalır; `COMPLETED`/release-ready iddiası verilmez.


## Tur 12 — WP-19–20 güvenlik, localization ve erişilebilirlik

- Demo server wildcard CORS ile başlıyordu; browser mutation yüzeyi localhost/127.0.0.1 allow-list + fail-closed Origin kontrolüne çevrildi. Sekiz saat session epoch'i, başarısız bearer denemelerinde kademeli gecikme, security headers, body/media limitleri ve safe error payload eklendi.
- Fixture import ilk halinde yalnız üst seviye reserved alanları kontrol ediyordu; nested JSON içinden ve `Role`/`AUDIT` gibi case varyantlarıyla role/audit/token/originalRef escalation'a izin vermemek için recursive case-insensitive guard eklendi.
- Original-media authorization denial bazı exception yollarında immutable audit'e düşmüyordu; başarı ve denial aynı güvenlik audit hattına bağlandı.
- Abuse sinyallerinde enumda bulunan replay davranışı gerçek rule üretmiyordu; rate/same-media/replay/impossible-location sinyalleri açıklanabilir ve yalnız human-review olacak şekilde bağlandı. Vatandaş güven skoru veya otomatik yaptırım eklenmedi.
- AI sınırında citizen free text `untrusted_citizen_data` olarak sarıldı; prompt-benzeri içerik talimat değil veri olarak değerlendirilir.
- İlk localization sweep yalnız görünür `Text` yüzeylerini kapsama riski taşıyordu; hint/tooltip/banner/semantics/validation/staff-planlama/component-gallery dahil doğrudan UI copy tarandı ve ortak TR/EN kataloğa taşındı. TR ve EN aynı 671 key setini taşır.
- Ham kamera/domain exception metinlerinin locale ve iç detay sızdırma riski hata-kodu → localized-safe-message yolu ile kapatıldı.
- Focus-not-obscured için odak alanı scroll-to-visible, minimum 48×48 target, reduced motion/high contrast ve map/list eşdeğeri kaynak kapılarına bağlandı.
- Dependency license strict gate'in first-party workspace paketlerini dış lisans eksiği sanma riski düzeltildi; gate yalnız resolved üçüncü taraf paketlerde lisans kanıtı arar.

## WP-19–20 kalan risk kararı

- SDK-bağımsız security/localization/accessibility/source/seed/secret-PII/design/AI kapıları final teslimde yeniden çalıştırılır.
- Flutter/Dart executable olmadığı için formatter/analyzer, Dart/server/widget/integration testleri, 200% runtime ve golden testleri çalıştırılamaz.
- TalkBack, VoiceOver, NVDA/Chrome, VoiceOver/Safari, web 400% zoom ve Android/iOS/web native camera permission denial/recovery gerçek cihaz/browser olmadan PASS sayılmaz.
- Bu nedenle kaynak uygulaması tamamlanmış olsa da WP-19–20 kanonik durumu `BLOCKED`; release-ready/OWASP-certified/WCAG-conformant iddiası verilmez.


## Tur 13 — WP-21–22 performans, recovery ve kabul kapanışı

- 10K staff dashboard/queue aynı build içinde projection lookup'larını tekrar kuruyordu; `StaffOperationsProjectionIndex` ile revision-scoped tek lookup'a indirildi. Harita source/incident taramaları indekslendi ve role/revision/work-clock anahtarlı memoization eklendi.
- Shared gateway yalnız process içi son snapshot'a güveniyordu; uygulama yeniden açıldıktan sonra ağ yoksa son başarılı shared snapshot kaybolabiliyordu. Remote gateway mevcut atomik `SnapshotStore`'u persistent cache olarak kullanacak şekilde bağlandı ve cache fallback UI'ı yanlışlıkla online göstermiyor.
- 408/429/5xx/timeout için bounded exponential backoff + deterministic jitter, malformed JSON için fail-safe cache fallback ve revision WebSocket için reconnect/backoff eklendi. Mutation retry yalnız aynı `clientMutationId` ile yapılır; duplicate state üretmez.
- Web/IO media quota/low-storage failure'ı ham storage exception olarak sızabiliyordu; domain storage failure'a çevrildi. Active-slot corruption ve migration failure backup/seed recovery testleri güçlendirildi.
- WP-22 eski E2E-01–22 seti veri kaynağı/yönetişim/güvenlik/accessibility kararlarının bir kısmını kapsamıyordu; E2E-23–30 ile çoklu kaynak/report, 153 mock, corroboration, fotoğrafsız rota, reopen review, official alert, role-AI ve GTFS gerçek şema kabulü eklendi.
- Coverage ve golden kanıtının yalnız belge olması release riskiydi; genel %80/kritik %90 LCOV ve 16 approved golden baseline CI'da fail-closed kapı yapıldı. Baseline veya coverage sonucu bu ortamda üretilmediği için yeşil kanıt uydurulmadı.
- Final failover turunda başarılı remote snapshot'ın opsiyonel cache yazma/read hatasıyla zehirlenebildiği görüldü; cache persist best-effort `on Object` korumasına alındı ve regresyon testi eklendi.
- Media `PUT` çağrısı request timeout/retry hattı dışında kalmıştı; stable media ID + aynı bytes ile idempotent bounded retry eklendi. Controller da ilk snapshot doğrulanana kadar staff için fail-closed/read-only başlatıldı.
- "Bütün ekranlarda state matrix" şartı yalnız ortak state widget testine bırakılmadı; W-00–W-10 izlenebilir `docs/screen_state_matrix.json` ve validator kapısına bağlandı.
- Coverage/golden kırmızı olduğunda kanıt artifact'lerinin upload adımına hiç ulaşamama riski vardı; SBOM gate'lerden önce üretildi ve evidence upload `if: always()` yapıldı.

## WP-21–22 kalan risk kararı

- SDK-bağımsız kaynak/belge/localization/accessibility/security/design/AI/PII/E2E-traceability kapıları final teslimde yeşildir.
- Dart/Flutter executable bulunmadığı için gerçek `benchmark_wp21.dart`, formatter/analyzer, Dart/server/widget/integration testleri ve LCOV çalıştırılamadı.
- DevTools memory/jank, approved golden baseline/design review, gerçek kamera lifecycle ve Android/iOS/web release/regresyon kanıtı bekleniyor.
- Bu nedenle WP-21 ve WP-22 kanonik ROADMAP statüsü `BLOCKED`; kaynak uygulaması hazır olsa da release-ready iddiası verilmez.

## Tur 14 — WP-23–24 pilot analitiği ve final RC denetimi

- KPI dashboard için yeni mutable sayaç tablosu yaratılmadı; first-review/routing/override/duplicate/resolution/status-request/feedback sinyalleri snapshot ve immutable audit olaylarından türetilir. North-star özellikle başvuru değil **tekil incident** paydasından hesaplanır; duplicate report sayısı oranı şişiremez. Repeat-status oranı da geçerli rapor tabanı üzerinden sınırlı bir oran olarak türetilir. Böylece demo metrikleri üretim metriği gibi uydurulmaz.
- Repeat status request, mevcut olay önceliğini veya state'ini otomatik değiştirmez; privacy-safe metric event üretir. Duplicate cluster ve AI/staff override de insan kararından sonra metric olarak kaydedilir.
- ROI hesaplayıcı varsayılan para değeri taşımıyor; bütün değişkenler kullanıcı girişi olmadan sonuç üretmiyor. Negatif “tasarruf” kalemleri sıfıra kırpılır ve maliyetler açıkça düşülür.
- Jüri kontrol merkezinde local DemoClock, kaynak outage/recovery, AI failure/recovery ve reset tek yüzeyde toplandı. Shared modda clock'ın yalnız local istemciyi etkilediği açıkça gösterilir; server saati değiştirilmiş gibi sunulmaz.
- Kaynak outage simülasyonu cache'i silmez; source health `unavailable` olur, son geçerli kayıtlar stale olarak korunur ve normal refresh ile recover edilebilir.
- Final auditte `MutationResult.toJson()` içindeki yinelenen `revision` map anahtarı bulundu ve kaldırıldı. Static delimiter kontrolünün semantik duplicate map-key hatalarını yakalayamayacağı yeniden doğrulandı.
- RC için sürüm `0.2.0-rc.1+1` sabitlendi fakat kaynak arşivinde `.git` olmadığı için commit hash/tag uydurulmadı. Source-tree SHA-256 release kanıtı olarak kullanılır; insan onayı olmadan tag/publish yapılmaz.

## WP-23–24 kalan risk kararı

- SDK-bağımsız kaynak/belge/localization/accessibility/security/E2E/seed/design/AI kapıları çalıştırılabilir; release evidence generator eksik artifact'leri `missing` olarak fail-safe raporlar.
- Flutter/Dart/cihaz/browser olmadığı için formatter/analyzer/full suite, LCOV/golden, runtime performance, Android/iOS/web release build ve clean-device install kanıtı üretilemez.
- Üç tam jüri provası yürütülmüş kanıtı ve son teknik/ürün/tasarım/güvenlik-KVKK yazılı onayı yoktur. Bu nedenle WP-23 ve WP-24 `BLOCKED`; production-ready veya final release iddiası yoktur.


## Tur 15 — 19 Ağustos P1 harita/auth/sidebar hotfix

- Kullanıcı ekran görüntülerindeki harita sorunu CSS/gesture engeli değil, `NeverScrollableScrollPhysics` kullanan sabit 2×2 OSM tile grid mimarisiydi. Bu yüzey kaldırıldı; citizen ve staff aynı `FlutterMap` + `MapController` harita bileşenini kullanıyor. Marker/cluster/official-alert katmanları coğrafi koordinatla kamera hareketine bağlandı.
- Arama daha önce yalnız `_center` state'ini güncelliyor, hiçbir gerçek kamera komutu vermiyordu. Exact district/place eşleşmesi, Enter ve sonuç tıklaması artık programatik kamera focus komutu üretir; kullanıcı haritayı elle taşıdığında yeni viewport `Bu alanda ara` için ayrıca tutulur.
- Citizen OTP ve staff MFA sabit demo kodlarını görünür kılan `_DemoCodeNotice` iki giriş akışından çıkarıldı. Deterministik demo fixture credential test akışını bozmayacak şekilde servis seviyesinde kalır fakat kullanıcı arayüzünde açığa çıkmaz.
- Staff sidebar'ın RenderFlex overflow kök nedeni tüm destinasyonların footer ile birlikte sabit `Column` içinde olmasıydı. Brand/footer sabit, navigasyon `Expanded + Scrollbar + ListView` yapıldı; 48 px minimum hedef korunurken KVKK/Ayarlar her viewport yüksekliğinde erişilebilir.
- Hotfix için ayrı widget regresyon kaynağı ve SDK-bağımsız `validate_hotfix_2026_08_19.py` CI kapısı eklendi. App candidate `0.2.0-rc.2+1` oldu.

## Hotfix kalan risk kararı

- Kaynak yapısı, belge, localization, accessibility, security, WP-21/22 ve WP-23/24 traceability, design, AI, Secret/PII ve seed kapıları hotfix sonrası yeniden yeşildir.
- Çalışma ortamında `flutter`, `dart` ve `fvm` executable bulunmadığı için yeni harita dependency çözümü, `dart format`, `flutter analyze` ve gerçek widget/integration/platform build çalıştırması yerelde doğrulanamadı. Bu nedenle release/production-ready durumu değişmez; runtime kapısı `BLOCKED` kalır.
