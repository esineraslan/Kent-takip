# İBB Kent Takip — RC1 Release Notes

**Sürüm:** `0.2.0-rc.1+1`  
**Tarih:** 17 Ağustos 2026  
**Durum:** Release Candidate kaynak adayı — **BLOCKED**, production-ready değildir.

## Öne çıkanlar

- WP-00–WP-22 ürün, domain, local/shared demo, harita, medya, AI, vatandaş/personel/saha/planlama, veri yönetişimi, RBAC/KVKK, güvenlik, TR/EN, erişilebilirlik, performans ve E2E kabul kaynakları korunur.
- WP-23: privacy-safe pilot metrikleri, snapshot/audit türevli KPI dashboard'u, değişken ROI, baseline/target/go-no-go, 7 dakikalık jüri senaryosu ve tek demo kontrol merkezi.
- WP-24: adversarial final audit, release evidence/manifest, bilinen sınırlar, RC version freeze ve insan onayı çıkış kapısı.

## Bilinen blokajlar

Flutter/Dart toolchain ve gerçek cihaz/browser bu hazırlama ortamında yoktur. Üç tam jüri provası, Android/iOS/web release artifact'leri, LCOV/golden/runtime performance, gerçek AT testi, clean-checkout dependency cache kanıtı ve yazılı final insan onayı yoktur. Kaynak arşivinde `.git` metadata olmadığı için gerçek commit hash/tag üretilemez.

Bu sürüm gerçek İBB/153 production entegrasyonu, gerçek credential veya üretim kişisel verisi içermez; 153/İstanbul Senin ve seçili dış sistemler demo/simüle sınırıyla etiketlidir.
