import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

enum StaffQueueType {
  critical,
  high,
  normal,
  lowConfidence,
  privacy,
  abuse,
  manualAiError,
}

abstract final class AppPaths {
  static const root = '/';
  static const demoStart = '/demo/start';
  static const demoScenarios = '/demo/scenarios';
  static const demoReset = '/demo/reset';
  static const demoComponents = '/demo/components';
  static const citizenWelcome = '/citizen/welcome';
  static const citizenMap = '/citizen/map';
  static const citizenLogin = '/citizen/login';
  static const citizenVerify = '/citizen/verify';
  static const citizenReport = '/citizen/report/type';
  static const citizenReports = '/citizen/reports';
  static const citizenNotifications = '/citizen/notifications';
  static const citizenSettings = '/citizen/settings';
  static const staffLogin = '/staff/login';
  static const staffMfa = '/staff/mfa';
  static const staffDashboard = '/staff/dashboard';
  static const staffQueues = '/staff/queues/critical';
  static const staffMap = '/staff/map';
  static const staffPlanning = '/staff/planning';
  static const staffPlanningNew = '/staff/planning/new';
  static const staffTasks = '/staff/tasks';
  static const staffReports = '/staff/reports';
  static const staffTeam = '/staff/team';
  static const staffSettings = '/staff/settings';
  static const staffDataSources = '/staff/data-sources';
  static const staffUsers = '/staff/users';
  static const staffAudit = '/staff/audit';
  static const staffPrivacyRequests = '/staff/privacy-requests';

  static String citizenReportDetail(String reportId) => '/citizen/reports/$reportId';

  static String staffQueue(StaffQueueType type) {
    return '/staff/queues/${type.name}';
  }
}

final class AppRoutePolicy {
  const AppRoutePolicy();

  String? redirect({
    required AppConfig config,
    required SessionController session,
    required Uri uri,
  }) {
    final path = uri.path;
    if (path == AppPaths.root) {
      return config.isDemo ? AppPaths.demoStart : AppPaths.citizenMap;
    }
    if (path.startsWith('/demo/') && !config.isDemo) {
      return AppPaths.citizenMap;
    }
    if (path == AppPaths.demoReset && !session.can(Permission.resetDemo)) {
      return AppPaths.demoStart;
    }

    final returnTo = safeReturnTo(uri.queryParameters['returnTo']);
    if (_isCitizenAuth(path) && session.isCitizen) {
      return returnTo ?? AppPaths.citizenMap;
    }
    if (_isStaffAuth(path) && session.isStaff) {
      return returnTo ?? AppPaths.staffDashboard;
    }
    if (_requiresCitizen(path)) {
      if (!session.isAuthenticated) {
        return _loginUri(AppPaths.citizenLogin, uri);
      }
      if (!session.isCitizen) {
        return AppPaths.staffDashboard;
      }
      final permission = _citizenPermission(path);
      if (permission != null && !session.can(permission)) {
        return AppPaths.citizenMap;
      }
    }
    if (_requiresStaff(path)) {
      if (!session.isAuthenticated) {
        return _loginUri(AppPaths.staffLogin, uri);
      }
      if (!session.isStaff) {
        return AppPaths.citizenMap;
      }
      final permission = _staffPermission(path);
      if (permission != null && !session.can(permission)) {
        return AppPaths.staffDashboard;
      }
      if (path.startsWith('/staff/queues/') && !_isKnownQueue(path)) {
        return AppPaths.staffQueues;
      }
    }
    return null;
  }

  String? safeReturnTo(String? raw) {
    if (raw == null || raw.isEmpty || !raw.startsWith('/') || raw.startsWith('//')) {
      return null;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.hasAuthority || uri.scheme.isNotEmpty) {
      return null;
    }
    return uri.toString();
  }

  bool _isCitizenAuth(String path) {
    return path == AppPaths.citizenLogin || path == AppPaths.citizenVerify;
  }

  bool _isStaffAuth(String path) {
    return path == AppPaths.staffLogin || path == AppPaths.staffMfa;
  }

  bool _requiresCitizen(String path) {
    return path.startsWith('/citizen/report') ||
        path.startsWith('/citizen/reports') ||
        path.startsWith('/citizen/notifications') ||
        path.startsWith('/citizen/settings');
  }

  bool _requiresStaff(String path) {
    return path.startsWith('/staff/') && !_isStaffAuth(path);
  }

  Permission? _citizenPermission(String path) {
    if (path.startsWith('/citizen/report/')) {
      return Permission.submitReport;
    }
    if (path.startsWith('/citizen/reports')) {
      return Permission.viewOwnReport;
    }
    return null;
  }

  Permission? _staffPermission(String path) {
    if (path.startsWith('/staff/queues')) {
      return Permission.viewReviewQueue;
    }
    if (path.startsWith('/staff/reports/')) {
      return Permission.reviewReport;
    }
    if (path.startsWith('/staff/planning')) {
      return Permission.manageMunicipalWork;
    }
    if (path.startsWith('/staff/tasks')) {
      return Permission.manageFieldWork;
    }
    if (path.startsWith('/staff/team') || path.startsWith('/staff/users')) {
      return Permission.manageUsers;
    }
    if (path.startsWith('/staff/data-sources')) {
      return Permission.manageSources;
    }
    if (path.startsWith('/staff/audit')) {
      return Permission.viewAudit;
    }
    if (path.startsWith('/staff/privacy-requests')) {
      return Permission.managePrivacyRequests;
    }
    return null;
  }

  bool _isKnownQueue(String path) {
    final value = path.substring('/staff/queues/'.length);
    return StaffQueueType.values.any((type) => type.name == value);
  }

  String _loginUri(String loginPath, Uri returnUri) {
    final safePath = Uri(
      path: returnUri.path,
      queryParameters: returnUri.queryParameters.isEmpty
          ? null
          : returnUri.queryParameters,
    ).toString();
    return Uri(
      path: loginPath,
      queryParameters: {'returnTo': safePath},
    ).toString();
  }
}
