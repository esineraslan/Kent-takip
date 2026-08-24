# İBB Kent Takip — Release Manifest

**RC sürümü:** `0.2.0-rc.2+1`  
**Demo server:** `0.2.0-rc.1`  
**Tarih:** 19 Ağustos 2026  
**Release durumu:** **BLOCKED — tag/publish yok**

## Kaynak kimliği

- Kaynak modu: `source_archive_without_git_metadata`
- Git commit: **yok / doğrulanamaz**; kaynak ZIP `.git` metadata taşımıyor.
- Kaynak ağacı SHA-256 (bu manifest ve deterministik source-evidence JSON'u hariç): `c7feca9df83e0f6dc566f9df5010b5cb385a19c9f7b55c0f1ca18ba91f812715`
- Kanonik seed checksum: `sha256:21dc27ab91e20cefda362d58d9ab18dc9bb1ab337aaf0f408b6da4d7d91a06ee`
- Seed dosya SHA-256: `299486f45e9d507af53f0ad8fee11b67a235309d94857a2a2b60d9a1ca85d2de`
- Source evidence JSON SHA-256: `af7b3ca6f63ba115f6c4e72840eaffec7ecaa7f28398d98ad023815c22faf3d1`
- App pubspec SHA-256: `136d1c148d894cb2c4a6ff30a7a0ac0ec2b14de57ae5f16f4c11aa4f2a136bf9`
- Demo server pubspec SHA-256: `30950eb28c9bd003d449a48378c61a199fde39fa28c12570eb6238b92b33ecd8`

## Artifact kanıtı

| Artifact | Durum | SHA-256 | Karar |
|---|---|---|---|
| Kaynak ağacı | present | `c7feca9df83e0f6dc566f9df5010b5cb385a19c9f7b55c0f1ca18ba91f812715` | RC kaynak adayı |
| Android APK | missing | — | BLOCKED: Flutter/Android toolchain yok |
| Android AAB | missing | — | BLOCKED: Flutter/Android toolchain yok |
| iOS app/build kanıtı | missing | — | BLOCKED: macOS/Xcode yok |
| Web release | missing | — | BLOCKED: Flutter SDK yok |
| Dependency SBOM | missing | — | BLOCKED: `flutter pub get` çözümlemesi yok |
| LCOV coverage | missing | — | BLOCKED: Dart/Flutter testleri çalışmadı |
| Runtime performance report | missing | — | BLOCKED: Flutter/Dart runtime benchmark çalışmadı |
| Approved golden baseline | missing | — | BLOCKED: tasarım insan onayı yok |

Makine-okunur durum `docs/release/RELEASE_EVIDENCE_SOURCE.json` içindedir. Eksik artifact hiçbir şekilde `present` veya `PASS` olarak gösterilmez.

## SDK-bağımsız son ölçüm

10.000 kayıt Python contract proxy son koşusu: **28.8 ms**. Bu değer Flutter runtime benchmark veya üç platform release performans kanıtı değildir.

## RC2 P1 hotfix kapsamı

19 Ağustos RC2 adayı; citizen/staff interaktif harita pan/zoom, arama sonucu kamera odaklama, giriş yüzeylerinden sabit demo kodu kaldırma ve desktop staff sidebar overflow/KVKK-Ayarlar erişimi düzeltmelerini içerir. Bu değişiklik sonrası kaynak checksum ve regresyon kanıtları yeniden üretilmiştir.

## Release çıkış kapısı

Release tag/publish ancak temiz CI'da zorunlu analyzer/test/coverage/golden/Android-iOS-web build kapıları yeşil olduktan, üç tam jüri provası kanıtlandıktan ve teknik lider + ürün sahibi + tasarım sorumlusu + gerekli güvenlik/KVKK rolü yazılı onay verdikten sonra yapılabilir. RC sonrasında yapılan her kaynak değişikliği yeni checksum ve tam regresyon gerektirir.

Bu manifest **production-ready** iddiası değildir.
