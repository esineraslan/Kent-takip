# WP-04 Tasarım Eşleme Notu

Dayanak: `DESIGN.md` ve `docs/reference_design/` altındaki beş ön çıktı. Bu belge görselleri ürün gerçeği gibi çoğaltmaz; WP-04 kapsamındaki uygulama kabuğu, auth ve responsive navigasyon kararlarını izlenebilir kılar.

| Referans | WP-04 karşılığı | Kaynak kanıtı |
|---|---|---|
| Mobil harita | 56 px beyaz başlık, marka/hesap alanı, üçlü 72 px alt navigasyon, kırmızı/sarı/gri anlam sistemi | `CitizenShell`, `CitizenMapScreen`, `AppColors` |
| Sorun bildir | “Bildir” ana sekmesi, giriş gerektiren route ve sonraki akış için güvenli modül sınırı | `AppPaths.citizenReport`, `AppRoutePolicy`, `CitizenReportEntryScreen` |
| Fotoğraf analizi | WP-04'te içerik uygulanmaz; auth/shell, ilerideki beş adımlı akışın route sınırını bozmadan barındırır | `CitizenShell`, route testi |
| Bildirim detayı | “Bildirimlerim” sahibiyle sınırlı route ve snapshot'tan yalnız oturum sahibinin kayıt projection'ı | `CitizenReportsScreen`, `Permission.viewOwnReport` |
| Personel kuyruğu | 232 px geniş / 80 px kompakt mavi sidebar, 64 px üst bar, magenta aktif çizgi, 840 px altında drawer | `StaffShell`, `AppColors.brandBlue900`, `AppColors.magenta600` |

## Responsive kararlar

| Aralık | Citizen | Staff |
|---|---|---|
| `<600 px` | Demo yardımcı işlemleri taşma menüsünde; üç ana sekme korunur | Drawer menü; rol değiştir ve çıkış dahil özellik kaybı yok |
| `600–839 px` | Üç ana sekme ve genişleyen içerik | Drawer menü |
| `840–1279 px` | Geniş harita + özet düzeni uygun alanda devreye girer | 80 px ikon sidebar + 64 px üst bar |
| `>=1280 px` | Maksimum okunabilir içerik ölçüleri | 232 px etiketli sidebar + 64 px üst bar |

## Görsel ve davranış kapıları

- Renkler, radius ve spacing değerleri kanonik `DESIGN.md` tokenlarından alınır.
- Renk tek başına durum belirtmez; pinlerde ikon ve semantics etiketi birlikte bulunur.
- Citizen/staff navigasyonları aynı widget ağacında karıştırılmaz.
- Gerçek İBB logosu onaylı ayrı asset olarak sağlanmadan ekran görüntüsünden logo türetilmez; nötr kent işareti geçici ama açık bir marka güvenliği kararıdır.
- WP-05; font assetleri, focus/golden/a11y matrisi ve component catalog kapısını tamamlar.
