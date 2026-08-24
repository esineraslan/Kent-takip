# WP-19 — Tehdit Modeli

Tarih: 17 Ağustos 2026

## Amaç ve kapsam

Bu model Kent Takip demo istemcisi, shared demo server, local persistence, medya, veri kaynağı adaptörleri, AI adaptörü ve personel/vatandaş projection sınırlarını kapsar. Model, demo yüzeylerini üretim kimlik sağlayıcısı veya gerçek 153 entegrasyonu varmış gibi değerlendirmez.

## Korunan varlıklar

- Vatandaş report ve tracking verisi; telefon/e-posta gibi hesap verileri.
- Orijinal medya, privacy-safe public medya ve EXIF/metadata sınırı.
- Personel kararları, immutable audit olayları, aktif rol bağlamı ve KVKK talepleri.
- Session/bearer bağlamı, revision/idempotency bilgisi ve server mutation hattı.
- Resmî/simüle veri kaynağı provenance, source/ingestion zamanı, quarantine ve stale cache.
- AI girdisi/çıktısı ve vatandaş serbest metninin “talimat değil veri” sınırı.
- Atomik snapshot, checksum, seed ve demo recovery kanıtı.

## Aktörler

| Aktör | Normal yetki | Tehdit örneği |
|---|---|---|
| Vatandaş | Kendi bildirimi, takip, KVKK/itiraz | Başka vatandaş verisini okuma, replay/spam, prompt-benzeri metin |
| Reviewer | İnceleme ve karar | Original media veya admin route yetki aşımı |
| Unit officer | Birim/saha operasyonu | Yetkisiz rol değişimi veya privacy kaydı okuma |
| Planner | Planlı çalışma | Source/admin yetkisi olmadan import veya kullanıcı yönetimi |
| System admin | Yönetişim | Gerekçesiz original media erişimi, audit değişikliği |
| Demo supervisor | Geniş demo izinleri, aktif rol bağlamı | Permission bypass varsayımı |
| Guest/geçersiz istemci | Public/demo giriş yüzeyi | Bearer brute force, route enumeration, oversized body |
| Veri kaynağı | Fixture/simüle/otorite dereceli veri | Şema bozulması, provenance spoof, role/audit import escalation |
| AI sağlayıcısı | Dar typed analiz | Prompt/model injection, hatalı/eksik cevap |

## Trust boundary'ler

1. **Flutter istemci ↔ demo server:** JSON, bearer, revision, idempotency, CORS/origin ve güvenli hata gövdesi.
2. **İstemci ↔ local persistence:** atomik snapshot/dual-slot, checksum, migration ve actor-scoped projection.
3. **Kamera/medya ↔ public projection:** boyut/format, EXIF strip, original/public ref ayrımı, privacy fail-closed ve gerekçeli original access.
4. **Source adapter/import ↔ domain snapshot:** şema, authority rank, quarantine, provenance, recursive reserved-key guard ve stale cache.
5. **Citizen free text ↔ AI:** typed schema + `untrusted_citizen_data`; içerik talimat olarak yürütülmez.
6. **Staff projection ↔ citizen projection:** internal note, audit, full phone, trust/abuse profili ve original media ayrımı.
7. **Runtime ↔ log/CI/evidence:** secret/PII redaction, fixture scan, dependency/SBOM/license kanıtı.

## STRIDE matrisi

| Yüzey | S | T | R | I | D | E | Kontrol |
|---|---|---|---|---|---|---|---|
| Route/server | Bearer taklidi | Body/revision değişimi | Denied olayını inkâr | Güvenli olmayan hata/projection | Oversized body/brute force | Role bypass | Server-side actor/permission, 8 saat session epoch, progressive delay, 128 KB body limiti, safe failure, denied audit |
| Browser origin | Sahte origin | Cross-origin mutation | — | Response paylaşımı | Preflight abuse | CSRF-benzeri mutation | Wildcard CORS yok; localhost allow-list; mutating foreign Origin fail-closed; cookie auth kullanılmıyor |
| JSON/import | Sahte provenance | role/audit/token alanı inject | Import kaynağını inkâr | Internal alanı public'e taşıma | Büyük/bozuk fixture | manageSources bypass | Recursive case-insensitive reserved-key guard, şema/izin doğrulama, quarantine, audit |
| Media | Media ID tahmini | Path traversal/metadata | Erişimi inkâr | EXIF/original ref sızıntısı | Büyük medya | Gerekçesiz original access | Actor-scoped ID, media ID validator, 8 MB limit, EXIF strip, publicRef, permission+reason+audit |
| AI | Model kimliği taklidi | Prompt/model injection | AI önerisini insan kararı sanma | Serbest metin sızıntısı | Timeout/invalid response | State transition yaptırma | Typed contract, untrusted-data wrapper, fail-closed adapter, AI yalnız öneri, insan karar hattı |
| Source adapter | Sahte otorite | Şema/provenance değişimi | Kaynak zamanını inkâr | Kaynak içeriği sızması | Kesinti/retry storm | Lower authority overwrite | Authority rank, source+ingestion time, retry/backoff/jitter, circuit breaker, stale cache, quarantine |
| Logs/audit | Actor spoof | Audit düzenleme | Denied olayı inkâr | PII/secret loglama | Log flood | Audit silme | Active role context, immutable audit UI, structured redaction, secret/PII CI taraması |

## Abuse sinyalleri

Aşağıdaki sinyaller yalnız açıklanabilir **insan incelemesi** üretir; otomatik ret, kalıcı ceza veya vatandaş güven skoru üretmez:

- kısa zaman aralığında yüksek bildirim hızı,
- aynı medya referansının tekrar kullanımı,
- aynı kategori + yaklaşık aynı konumda çok kısa aralıklı mutation replay,
- fiziksel olarak imkânsız hız gerektiren konum sıçraması,
- prompt-benzeri vatandaş metni.

GPS spoof tek başına kesin olarak ispatlanamaz; burada yalnız tutarsız hareket sinyali ölçülür.

## Demo sınırları ve artık risk

- Sabit demo bearer kimlikleri gerçek üretim authentication değildir. Server process session epoch'i sekiz saatle sınırlıdır; üretimde kurumsal IdP/OAuth gerekir.
- Dış bağımlılık vulnerability registry taraması bu hazırlama ortamında çalıştırılamadı; SBOM ve license gate CI'a bağlandı.
- Gerçek cihaz/browser authenticated role ve penetration turu Flutter/platform toolchain'i olmayan bu ortamda çalıştırılmadı.
- Orijinal gerçek vatandaş medyasının üretim public yayını ayrı yüz/plaka redaksiyon motoru ve kurum onayı gelene kadar fail-closed kalır.
