# WP-20 — WCAG 2.2 AA Kontrol Matrisi

Tarih: 17 Ağustos 2026

| Kriter / tema | Durum | Kaynak / kanıt |
|---|---|---|
| 1.1 Text alternatives | SOURCE_PASS | Semantics label'ları, ikon butonları, map pin semantics |
| 1.3 Adaptable / reflow | PARTIAL | Responsive shell + 200% test kaynağı; 400% browser manuel BLOCKED |
| 1.4.1 Use of Color | SOURCE_PASS | State = icon + text + semantics; yalnız renk değil |
| 1.4.3 Contrast | SOURCE_PASS | Design token/contrast gate; runtime screenshot/manual doğrulama BLOCKED |
| 1.4.10 Reflow | PARTIAL | Responsive kaynak; 400% web runtime BLOCKED |
| 1.4.11 Non-text Contrast | SOURCE_PASS | Theme/high-contrast ve focus ring |
| 1.4.12 Text Spacing | PARTIAL | Flexible layouts; manuel browser doğrulaması BLOCKED |
| 2.1 Keyboard | PARTIAL | FocusTraversalGroup + keyboard action + test kaynakları; full-route runtime/manual BLOCKED |
| 2.4.7 Focus Visible | SOURCE_PASS | `KtFocusRegion` focus ring |
| 2.4.11 Focus Not Obscured (Minimum) | SOURCE_PASS | `Scrollable.ensureVisible` odak kurtarma |
| 2.5.7 Dragging Movements | SOURCE_PASS | Kritik işlemler button/form alternatifi; map equivalent list |
| 2.5.8 Target Size (Minimum) | SOURCE_PASS | Minimum 48×48 hedef |
| 3.2 Consistent Navigation | SOURCE_PASS | Citizen/staff shell route yapısı |
| 3.3.7 Redundant Entry | SOURCE_PASS | Wizard state korunur; kritik tekrar giriş zorunluluğu yok |
| 3.3.8 Accessible Authentication (Minimum) | PARTIAL | Password görünürlük/label/semantics; gerçek AT auth turu BLOCKED |
| 4.1 Name, Role, Value | SOURCE_PASS | Material controls + explicit Semantics/liveRegion |
| Localization / language | SOURCE_PASS | TR/EN 671 ortak key; fallback/missing-key/direct-copy CI gate |
| Reduced motion | SOURCE_PASS | `MediaQuery.disableAnimations` ile token süreleri azaltılır |
| High contrast | SOURCE_PASS | `AppTheme.highContrast(...)` |
| Orientation | PARTIAL | Responsive layoutta sabit orientation lock yok; gerçek cihaz rotasyonu BLOCKED |
| Map equivalent content | SOURCE_PASS | `MapViewMode.accessibleList` aynı projection verisini listeler |

`PARTIAL` satırları başarısızlık gizlemez; kaynak uygulaması bulunur ancak zorunlu runtime/manuel kanıt bu ortamda üretilememiştir.
