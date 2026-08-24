import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/auth/auth_models.dart';
import 'package:kent_takip_app/src/auth/demo_auth_service.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

void main() {
  late _MutableClock clock;
  late DemoAuthService auth;

  setUp(() {
    clock = _MutableClock(DateTime.utc(2026, 8, 17, 9));
    auth = DemoAuthService(
      clock: clock,
      logger: StructuredLogger(writer: (_) {}),
    );
  });

  test('citizen demo OTP creates least-privilege principal', () async {
    await auth.requestCitizenOtp('+90 555 000 11 22');

    final principal = await auth.verifyCitizenOtp(
      '+90 555 000 11 22',
      DemoAuthService.citizenOtp,
    );

    expect(principal.account.role, UserRole.citizen);
    expect(
      principal.account.permissions,
      {
        Permission.viewPublicMap,
        Permission.submitReport,
        Permission.viewOwnReport,
      },
    );
    expect(principal.maskedIdentity, isNot(contains('5550001122')));
  });

  test('OTP request cooldown is deterministic', () async {
    await auth.requestCitizenOtp('+905550001122');

    await expectLater(
      auth.requestCitizenOtp('+905550001122'),
      throwsA(
        isA<DemoAuthFailure>().having(
          (failure) => failure.code,
          'code',
          DemoAuthFailureCode.requestCooldown,
        ),
      ),
    );

    clock.advance(const Duration(seconds: 30));
    await auth.requestCitizenOtp('+905550001122');
  });

  test('OTP cannot be verified before issuance or replayed', () async {
    await expectLater(
      auth.verifyCitizenOtp(
        '+905550001122',
        DemoAuthService.citizenOtp,
      ),
      throwsA(
        isA<DemoAuthFailure>().having(
          (failure) => failure.code,
          'code',
          DemoAuthFailureCode.expiredChallenge,
        ),
      ),
    );

    await auth.requestCitizenOtp('+905550001122');
    await auth.verifyCitizenOtp(
      '+905550001122',
      DemoAuthService.citizenOtp,
    );
    await expectLater(
      auth.verifyCitizenOtp(
        '+905550001122',
        DemoAuthService.citizenOtp,
      ),
      throwsA(isA<DemoAuthFailure>()),
    );
  });

  test('five invalid OTP attempts activate a 60-second lockout', () async {
    await auth.requestCitizenOtp('+905550001122');
    for (var attempt = 0; attempt < 5; attempt++) {
      await expectLater(
        auth.verifyCitizenOtp('+905550001122', '000000'),
        throwsA(isA<DemoAuthFailure>()),
      );
    }

    await expectLater(
      auth.verifyCitizenOtp(
        '+905550001122',
        DemoAuthService.citizenOtp,
      ),
      throwsA(
        isA<DemoAuthFailure>().having(
          (failure) => failure.code,
          'code',
          DemoAuthFailureCode.lockedOut,
        ),
      ),
    );

    clock.advance(const Duration(seconds: 61));
    final principal = await auth.verifyCitizenOtp(
      '+905550001122',
      DemoAuthService.citizenOtp,
    );
    expect(principal.account.role, UserRole.citizen);
  });

  test('wrong MFA does not consume a valid challenge', () async {
    final challenge = await auth.verifyStaffPassword(
      DemoAuthService.supervisorEmail,
      DemoAuthService.supervisorPassword,
    );

    await expectLater(
      auth.verifyStaffMfa(challenge, '000000'),
      throwsA(isA<DemoAuthFailure>()),
    );
    final principal = await auth.verifyStaffMfa(
      challenge,
      DemoAuthService.supervisorMfa,
    );

    expect(principal.account.role, UserRole.demoSupervisor);
    expect(principal.account.permissions, Permission.values.toSet());
  });
}

final class _MutableClock implements Clock {
  _MutableClock(this.value);

  DateTime value;

  void advance(Duration duration) {
    value = value.add(duration);
  }

  @override
  DateTime nowUtc() => value;
}
