import 'package:flutter/widgets.dart';
import 'package:kent_takip_app/src/localization/app_text_catalog.dart';

final class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  bool get _tr => locale.languageCode == 'tr';

  String select(String tr, String en) => _tr ? tr : en;

  String text(String key) {
    final catalog = _tr ? appTextTr : appTextEn;
    final value = catalog[key];
    assert(value != null, 'Missing localization key: $key');
    return value ?? appTextTr[key] ?? key;
  }

  String format(String key, Map<String, Object?> values) {
    var value = text(key);
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return value;
  }

  String plural({
    required int count,
    required String oneTr,
    required String manyTr,
    required String oneEn,
    required String manyEn,
  }) {
    if (_tr) return count == 1 ? oneTr : manyTr;
    return count == 1 ? oneEn : manyEn;
  }

  String get appName => 'İBB Kent Takip';
  String get tagline => _tr
      ? 'Şehirde olanı gör, bildirimini takip et.'
      : 'See what is happening, track your report.';
  String get chooseRole => _tr
      ? 'Nasıl devam etmek istiyorsunuz?'
      : 'How would you like to continue?';
  String get chooseRoleHint => _tr
      ? 'Bu demo yalnız sentetik veri kullanır. Rolünüzü daha sonra değiştirebilirsiniz.'
      : 'This demo uses synthetic data only. You can switch roles later.';
  String get citizen => _tr ? 'Vatandaş' : 'Citizen';
  String get municipalOfficer =>
      _tr ? 'Belediye yetkilisi' : 'Municipal officer';
  String get continueAsGuest => _tr ? 'Misafir devam et' : 'Continue as guest';
  String get signInDemo =>
      _tr ? 'Demo hesabıyla giriş yap' : 'Sign in with demo account';
  String get demoData => _tr ? 'Demo verisi' : 'Demo data';
  String get switchRole => _tr ? 'Rolü değiştir' : 'Switch role';
  String get scenarios => _tr ? 'Senaryolar' : 'Scenarios';
  String get resetData => _tr ? 'Veriyi sıfırla' : 'Reset data';
  String get map => _tr ? 'Harita' : 'Map';
  String get report => _tr ? 'Bildir' : 'Report';
  String get myReports => _tr ? 'Bildirimlerim' : 'My reports';
  String get overview => _tr ? 'Genel görünüm' : 'Overview';
  String get reviewQueues => _tr ? 'İnceleme kuyrukları' : 'Review queues';
  String get plannedWorks => _tr ? 'Planlanan çalışmalar' : 'Planned works';
  String get reports => _tr ? 'Raporlar' : 'Reports';
  String get teamManagement => _tr ? 'Ekip yönetimi' : 'Team management';
  String get settings => _tr ? 'Ayarlar' : 'Settings';
  String get signOut => _tr ? 'Çıkış yap' : 'Sign out';
  String get phone => _tr ? 'Telefon numarası' : 'Phone number';
  String get sendCode =>
      _tr ? 'Doğrulama kodu gönder' : 'Send verification code';
  String get verificationCode => _tr ? 'Doğrulama kodu' : 'Verification code';
  String get verifyAndContinue =>
      _tr ? 'Doğrula ve devam et' : 'Verify and continue';
  String get staffEmail => _tr ? 'Kurumsal demo hesabı' : 'Demo staff account';
  String get password => _tr ? 'Parola' : 'Password';
  String get continueAction => _tr ? 'Devam et' : 'Continue';
  String get secondFactor => _tr ? 'İkinci doğrulama' : 'Second verification';
  String get demoAccountFill =>
      _tr ? 'Demo hesabını doldur' : 'Fill demo account';
  String get back => _tr ? 'Geri' : 'Back';
  String get tryAgain => _tr ? 'Tekrar dene' : 'Try again';
  String get recoverBackup => _tr ? 'Yedekten kurtar' : 'Recover backup';
  String get bootstrapLoading => _tr ? 'Demo hazırlanıyor' : 'Preparing demo';
  String get bootstrapFailure =>
      _tr ? 'Demo verisi açılamadı' : 'Demo data could not be opened';
  String get technicalReference =>
      _tr ? 'Teknik referans' : 'Technical reference';
  String categoryLabel(String category) {
    final labels = _tr
        ? const {
            'road_surface_damage': 'Yol yüzeyi hasarı',
            'water_leak': 'Su kaçağı',
            'traffic_signal': 'Trafik işareti / sinyal',
            'water_infrastructure': 'Su altyapısı',
            'lighting': 'Aydınlatma',
            'park_green': 'Park ve yeşil alan',
          }
        : const {
            'road_surface_damage': 'Road surface damage',
            'water_leak': 'Water leak',
            'traffic_signal': 'Traffic sign / signal',
            'water_infrastructure': 'Water infrastructure',
            'lighting': 'Lighting',
            'park_green': 'Parks and green areas',
          };
    return labels[category] ?? category.replaceAll('_', ' ');
  }

  String get resetConfirmTitle =>
      _tr ? 'Demo verileri sıfırlansın mı?' : 'Reset demo data?';
  String get cancel => _tr ? 'Vazgeç' : 'Cancel';
  String get reset => _tr ? 'Sıfırla' : 'Reset';
  String get resetCompleted =>
      _tr ? 'Demo verileri yenilendi.' : 'Demo data was reset.';
  String get language => _tr ? 'EN' : 'TR';
  String get publicMapTitle =>
      _tr ? 'İstanbul kent görünümü' : 'Istanbul city view';
  String get publicMapDescription => _tr
      ? 'Doğrulanmış olaylar ve planlanan çalışmalar için güvenli genel görünüm.'
      : 'A safe public view for verified incidents and planned works.';
  String get authRequired => _tr
      ? 'Bu alan için telefon doğrulaması gerekiyor.'
      : 'Phone verification is required for this area.';
  String get moduleBoundary => _tr
      ? 'Bu ekran WP-04 kapsamındaki güvenli navigasyon ve rol sınırını çalışır durumda sunar; işleme özgü içerik ilgili özellik paketinin kapsamındadır.'
      : 'This screen provides the working WP-04 secure navigation and role boundary; operation-specific content belongs to its feature package.';
  String get currentRole => _tr ? 'Aktif görünüm' : 'Active view';
  String get noNotifications =>
      _tr ? 'Henüz bildiriminiz yok.' : 'You have no reports yet.';
  String get systemHealthy =>
      _tr ? 'Sistemler çalışıyor' : 'Systems operational';
  String get syntheticNotice => _tr
      ? 'Gerçek SMS gönderilmez ve gerçek kişisel veri kullanılmaz.'
      : 'No real SMS is sent and no real personal data is used.';
  String get invalidIdentity => _tr
      ? 'Demo hesap bilgisi bulunamadı.'
      : 'Demo account information was not found.';
  String get invalidCredential => _tr
      ? 'Doğrulama bilgisi geçersiz.'
      : 'The verification credential is invalid.';
  String get lockedOut => _tr
      ? 'Çok sayıda hatalı deneme yapıldı.'
      : 'There have been too many failed attempts.';
  String get requestCooldown => _tr
      ? 'Yeni kod istemeden önce bekleyin.'
      : 'Wait before requesting a new code.';
  String get expiredChallenge => _tr
      ? 'Doğrulama oturumu sona erdi.'
      : 'The verification session has expired.';
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings(Localizations.localeOf(this));
}
