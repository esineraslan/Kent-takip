import 'package:flutter/foundation.dart';
import 'package:kent_takip_app/src/auth/auth_models.dart';

final class AuthFlowController extends ChangeNotifier {
  String? _citizenPhone;
  StaffChallenge? _staffChallenge;

  String? get citizenPhone => _citizenPhone;
  StaffChallenge? get staffChallenge => _staffChallenge;

  void beginCitizenVerification(String phone) {
    _citizenPhone = phone;
    _staffChallenge = null;
    notifyListeners();
  }

  void beginStaffMfa(StaffChallenge challenge) {
    _staffChallenge = challenge;
    _citizenPhone = null;
    notifyListeners();
  }

  void clear() {
    _citizenPhone = null;
    _staffChallenge = null;
    notifyListeners();
  }
}
