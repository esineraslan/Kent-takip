# İBB Kent Takip — WP-23 / WP-24 Kalite Kanıtı

## Kaynak seviyesinde uygulanan kapılar

Final kaynakta SDK-bağımsız kontroller çalıştırılır:

- source/JSON/XML/Markdown yapı,
- kanonik belge/ADR tutarlılığı,
- TR/EN localization,
- accessibility source invariants,
- security hardening invariants,
- WP-21/22 kabul matrisi,
- WP-23/24 traceability,
- seed checksum,
- design system,
- deterministic AI evaluation,
- Secret/PII scan,
- 10K contract proxy benchmark.

## Runtime blokajı

Flutter/Dart executable bulunmadığı için `dart format`, `flutter analyze`, Dart/Flutter testleri, coverage, golden, Android/iOS/web release build, clean install ve fiziksel/AT cihaz testleri bu ortamda PASS sayılamaz.

## İnsan çıkış kapısı

Teknik lider + ürün sahibi + tasarım sorumlusu + gerekli güvenlik/KVKK rolü yazılı kabul vermeden tag/publish yapılmaz.

## 17 Ağustos 2026 son SDK-bağımsız koşu

- Source/JSON/XML/Dart declaration + Markdown encoding: **PASS**.
- Kanonik belge/ADR tutarlılığı: **PASS — 8 belge / 8 ADR**.
- Localization: **PASS — 753 ortak TR/EN key, hard-coded UI copy yok**.
- Accessibility source invariants: **PASS**.
- Security hardening source invariants: **PASS**.
- WP-21/22 ve WP-23/24 traceability: **PASS**.
- Design system, deterministic AI evaluation, Secret/PII, seed: **PASS**.
- Son 10.000 kayıt Python contract proxy: **32.6 ms**. Bu Flutter runtime performans kanıtı değildir.
- Dependency/license: **BLOCKED** — resolved Flutter dependency graph yok.
- Golden: **BLOCKED** — 16/16 approved baseline ve insan tasarım onayı yok.
