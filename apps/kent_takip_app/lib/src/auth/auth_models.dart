import 'package:kent_takip_domain/kent_takip_domain.dart';

enum DemoAuthFailureCode {
  invalidIdentity,
  invalidCredential,
  lockedOut,
  requestCooldown,
  expiredChallenge,
}

final class DemoAuthFailure extends Error {
  DemoAuthFailure({
    required this.code,
    required this.message,
    this.retryAt,
  });

  final DemoAuthFailureCode code;
  final String message;
  final DateTime? retryAt;

  @override
  String toString() => 'DemoAuthFailure(${code.name}, $message)';
}

final class DemoPrincipal {
  const DemoPrincipal({
    required this.account,
    required this.displayName,
    required this.maskedIdentity,
  });

  final UserAccount account;
  final String displayName;
  final String maskedIdentity;
}

final class StaffChallenge {
  const StaffChallenge({
    required this.id,
    required this.accountId,
    required this.expiresAt,
  });

  final String id;
  final String accountId;
  final DateTime expiresAt;
}
