import 'package:kent_takip_app/src/auth/auth_models.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

final class DemoAuthService {
  DemoAuthService({
    required this.clock,
    required this.logger,
  });

  static const citizenOtp = '123456';
  static const supervisorEmail = 'belediye@demo.invalid';
  static const supervisorPassword = 'KentTakip!2026';
  static const supervisorMfa = '654321';
  static const Map<String, ({String id, String name})> _citizenPhones = {
    '+905550001122': (id: 'usr_citizen_demo_001', name: 'Ana vatandaş'),
    '+905550002233': (id: 'usr_citizen_demo_002', name: 'Diğer vatandaş'),
    '+905550003344': (id: 'usr_citizen_demo_003', name: 'Yeni vatandaş'),
  };

  final Clock clock;
  final StructuredLogger logger;
  final Map<String, _AttemptState> _attempts = {};
  final Map<String, DateTime> _lastOtpRequest = {};
  final Map<String, StaffChallenge> _challenges = {};
  int _challengeSequence = 0;

  Future<void> requestCitizenOtp(String rawPhone) async {
    final phone = normalizePhone(rawPhone);
    if (!_citizenPhones.containsKey(phone)) {
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.invalidIdentity,
        message: 'Bu numara demo hesapları arasında bulunmuyor.',
      );
    }
    _requireNotLocked('citizen:$phone');
    final now = clock.nowUtc();
    final lastRequest = _lastOtpRequest[phone];
    if (lastRequest != null && now.difference(lastRequest).inSeconds < 30) {
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.requestCooldown,
        message: 'Yeni kod istemeden önce kısa bir süre bekleyin.',
        retryAt: lastRequest.add(const Duration(seconds: 30)),
      );
    }
    _lastOtpRequest[phone] = now;
    logger.info('auth.citizen.otp_requested', fields: {'channel': 'demo'});
  }

  Future<DemoPrincipal> verifyCitizenOtp(
    String rawPhone,
    String otp,
  ) async {
    final phone = normalizePhone(rawPhone);
    final identity = _citizenPhones[phone];
    if (identity == null) {
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.invalidIdentity,
        message: 'Bu numara demo hesapları arasında bulunmuyor.',
      );
    }
    final key = 'citizen:$phone';
    _requireNotLocked(key);
    final issuedAt = _lastOtpRequest[phone];
    if (issuedAt == null ||
        clock.nowUtc().difference(issuedAt) > const Duration(minutes: 5)) {
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.expiredChallenge,
        message: 'Doğrulama kodu oturumu sona erdi.',
      );
    }
    if (otp.trim() != citizenOtp) {
      _recordFailure(key);
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.invalidCredential,
        message: 'Doğrulama kodu geçersiz.',
      );
    }
    _attempts.remove(key);
    _lastOtpRequest.remove(phone);
    logger.info('auth.citizen.succeeded', fields: {'role': 'citizen'});
    return DemoPrincipal(
      account: UserAccount(
        id: identity.id,
        role: UserRole.citizen,
        permissions: const {
          Permission.viewPublicMap,
          Permission.submitReport,
          Permission.viewOwnReport,
        },
      ),
      displayName: identity.name,
      maskedIdentity: '+90 ••• ••• ${phone.substring(phone.length - 4)}',
    );
  }

  Future<StaffChallenge> verifyStaffPassword(
    String rawEmail,
    String password,
  ) async {
    final email = rawEmail.trim().toLowerCase();
    if (email != supervisorEmail) {
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.invalidIdentity,
        message: 'Demo yetkili hesabı bulunamadı.',
      );
    }
    const key = 'staff:supervisor';
    _requireNotLocked(key);
    if (password != supervisorPassword) {
      _recordFailure(key);
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.invalidCredential,
        message: 'Parola geçersiz.',
      );
    }
    _attempts.remove(key);
    _challengeSequence += 1;
    final challenge = StaffChallenge(
      id: 'staff-challenge-$_challengeSequence',
      accountId: 'usr_supervisor_demo_001',
      expiresAt: clock.nowUtc().add(const Duration(minutes: 5)),
    );
    _challenges[challenge.id] = challenge;
    logger.info('auth.staff.password_succeeded', fields: {'role': 'supervisor'});
    return challenge;
  }

  Future<DemoPrincipal> verifyStaffMfa(
    StaffChallenge challenge,
    String code,
  ) async {
    const key = 'staff:supervisor';
    _requireNotLocked(key);
    final active = _challenges[challenge.id];
    if (active == null || !active.expiresAt.isAfter(clock.nowUtc())) {
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.expiredChallenge,
        message: 'İkinci doğrulama oturumu sona erdi.',
      );
    }
    if (code.trim() != supervisorMfa) {
      _recordFailure(key);
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.invalidCredential,
        message: 'İkinci doğrulama kodu geçersiz.',
      );
    }
    _challenges.remove(challenge.id);
    _attempts.remove(key);
    logger.info('auth.staff.succeeded', fields: {'role': 'demo_supervisor'});
    return DemoPrincipal(
      account: UserAccount(
        id: active.accountId,
        role: UserRole.demoSupervisor,
        unitId: 'unit_road_maintenance',
        permissions: Permission.values.toSet(),
      ),
      displayName: 'Demo supervisor',
      maskedIdentity: supervisorEmail,
    );
  }

  String normalizePhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp('[^0-9+]'), '');
    if (digits.startsWith('+90') && digits.length == 13) {
      return digits;
    }
    if (digits.startsWith('90') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length == 11) {
      return '+90${digits.substring(1)}';
    }
    throw DemoAuthFailure(
      code: DemoAuthFailureCode.invalidIdentity,
      message: 'Telefon numarası biçimi geçersiz.',
    );
  }

  void _requireNotLocked(String key) {
    final retryAt = _attempts[key]?.lockedUntil;
    if (retryAt != null && retryAt.isAfter(clock.nowUtc())) {
      throw DemoAuthFailure(
        code: DemoAuthFailureCode.lockedOut,
        message: 'Çok sayıda hatalı deneme yapıldı.',
        retryAt: retryAt,
      );
    }
  }

  void _recordFailure(String key) {
    final current = _attempts[key] ?? const _AttemptState();
    final failures = current.failures + 1;
    final lockedUntil = failures >= 5
        ? clock.nowUtc().add(const Duration(seconds: 60))
        : null;
    _attempts[key] = _AttemptState(
      failures: failures >= 5 ? 0 : failures,
      lockedUntil: lockedUntil,
    );
    logger.warning(
      'auth.failed',
      fields: {'attempt': failures, 'locked': lockedUntil != null},
    );
  }
}

final class _AttemptState {
  const _AttemptState({this.failures = 0, this.lockedUntil});

  final int failures;
  final DateTime? lockedUntil;
}
