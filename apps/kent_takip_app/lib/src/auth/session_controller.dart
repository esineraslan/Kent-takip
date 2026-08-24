import 'package:flutter/foundation.dart';
import 'package:kent_takip_app/src/auth/auth_models.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

final class SessionController extends ChangeNotifier {
  SessionController({required this.clock});

  final Clock clock;
  DemoPrincipal? _principal;
  DateTime? _expiresAt;
  bool _guest = false;

  DemoPrincipal? get principal => _principal;
  UserRole get role => _principal?.account.role ?? UserRole.guest;
  bool get isGuest => _guest && _principal == null;
  bool get isAuthenticated => _principal != null && !_isExpired;
  bool get isCitizen => isAuthenticated && role == UserRole.citizen;
  bool get isStaff => isAuthenticated && {
    UserRole.reviewer,
    UserRole.unitOfficer,
    UserRole.planner,
    UserRole.systemAdmin,
    UserRole.demoSupervisor,
  }.contains(role);

  bool get _isExpired {
    final expiresAt = _expiresAt;
    return expiresAt != null && !expiresAt.isAfter(clock.nowUtc());
  }

  bool can(Permission permission) {
    return isAuthenticated &&
        (_principal?.account.permissions.contains(permission) ?? false);
  }

  void continueAsGuest() {
    _principal = null;
    _expiresAt = null;
    _guest = true;
    notifyListeners();
  }

  void signIn(DemoPrincipal principal) {
    _principal = principal;
    _guest = false;
    _expiresAt = clock.nowUtc().add(const Duration(hours: 8));
    notifyListeners();
  }

  void signOut() {
    _principal = null;
    _expiresAt = null;
    _guest = false;
    notifyListeners();
  }

  void switchRole() => signOut();
}
