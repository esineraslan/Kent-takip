# WP-20 — VPAT-Lite / Erişilebilirlik Uygunluk Özeti

Tarih: 17 Ağustos 2026
Hedef: WCAG 2.2 AA ve Android/iOS/web kritik akış paritesi.

> Bu belge resmi üçüncü taraf VPAT sertifikası değildir. Kaynak kanıtı ile manuel/runtime kanıtını açıkça ayıran proje içi uygunluk özetidir.

## Uygulanan kaynak kontrolleri

- TR/EN tek katalog; eş anahtar seti, missing-key fallback ve doğrudan UI copy statik kapısı.
- Locale tarih/saat, sayı ve telefon biçimleme; çoğul helper testi.
- Focus traversal ve odaklanmış alanı `Scrollable.ensureVisible` ile görünür tutma.
- En az 48×48 etkileşim hedefi ve padded Material tap target.
- Semantics/live region ve ikon butonlarında erişilebilir etiketler.
- Reduced motion ve high contrast theme yolu.
- Harita için aynı kayıtlara erişen `accessibleList` eşdeğeri; konum/incident bilgisi yalnız renkle verilmez.
- Kamera capture sonrası lifecycle resume + Android lost-data recovery; metadata isteme kapalı.
- Yüzde 200 text widget test kaynağı; sekiz viewport TR/EN/long-text golden matrisi kaynakta mevcut.

## Kanıt durumu

| Alan | Durum |
|---|---|
| Localization key paritesi / hard-coded UI copy | PASS — SDK bağımsız kaynak kapısı |
| 48×48 hedef, focus recovery, reduced motion, high contrast, map/list | PASS — SDK bağımsız kaynak kapısı |
| 200% text widget test | TEST_SOURCE_READY — Flutter SDK yok |
| Web 400% zoom/reflow | BLOCKED — gerçek browser çalıştırılmadı |
| Citizen/staff klavye-only kritik akış | TEST_SOURCE_READY / MANUAL_BLOCKED |
| TalkBack Android | BLOCKED — cihaz/emülatör yok |
| VoiceOver iOS | BLOCKED — macOS/iOS cihaz yok |
| NVDA + Chrome Windows | BLOCKED — Windows/AT ortamı yok |
| VoiceOver + Safari macOS | BLOCKED — macOS/AT ortamı yok |
| TR/EN/long-text golden diff | BLOCKED — Flutter golden baseline üretilmedi/onaylanmadı |
| Camera permission denial/recovery Android/iOS/web | SOURCE_READY / MANUAL_BLOCKED |
| Location permission lifecycle | N/A — mevcut demo location plugin kullanmıyor; kullanıcı harita/koordinat seçimiyle konum verir |

## Erişilebilir authentication / redundant entry

Demo auth ekranlarında alan label'ları localization + semantics üzerinden sağlanır; OTP/MFA demo kodları kullanıcıya gösterilir ve password görünürlük butonları erişilebilir label taşır. Kullanıcının daha önce girdiği report verisini aynı akış içinde zorunlu tekrar girmesini gerektiren yeni bir adım eklenmez.

## Sürükleme alternatifi

Kritik citizen/staff görevleri sürükleme hareketine bağımlı değildir. Harita seçimi dışında kayıt/karar işlemleri button/form yoluyla yürür; harita için erişilebilir liste ve koordinat/form alternatifi korunur.

## Açık karar

Kaynak incelemesinde bilinen P0/P1 erişilebilirlik bug bırakılmadı. Ancak manuel yardımcı teknoloji, gerçek platform permission, golden ve runtime klavye/reflow kanıtları tamamlanmadan WP-20 `COMPLETED` değildir.
