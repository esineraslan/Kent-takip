import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/auth/auth_models.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

void main() {
  const policy = AppRoutePolicy();
  const config = AppConfig(
    environment: AppEnvironment.demo,
    dataMode: DemoDataMode.local,
  );
  late SessionController session;

  setUp(() {
    session = SessionController(
      clock: _FixedClock(DateTime.utc(2026, 8, 17, 9)),
    );
  });

  tearDown(() => session.dispose());

  test('root URL deterministically enters the demo role selector', () {
    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse(AppPaths.root),
    );

    expect(redirect, AppPaths.demoStart);
  });

  test('protected citizen deep link preserves a safe returnTo', () {
    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse('/citizen/report/type'),
    );

    expect(
      redirect,
      '/citizen/login?returnTo=%2Fcitizen%2Freport%2Ftype',
    );
  });

  test('staff URL cannot be opened by a citizen principal', () {
    session.signIn(_principal(UserRole.citizen, const {
      Permission.viewPublicMap,
      Permission.submitReport,
      Permission.viewOwnReport,
    }));

    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse(AppPaths.staffDashboard),
    );

    expect(redirect, AppPaths.citizenMap);
  });

  test('citizen URL cannot be opened by staff principal', () {
    session.signIn(_principal(UserRole.demoSupervisor, Permission.values));

    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse(AppPaths.citizenReports),
    );

    expect(redirect, AppPaths.staffDashboard);
  });

  test('permission guard rejects a staff module outside authorization', () {
    session.signIn(_principal(UserRole.reviewer, const {
      Permission.viewReviewQueue,
    }));

    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse(AppPaths.staffPlanning),
    );

    expect(redirect, AppPaths.staffDashboard);
  });

  test('field task route requires manageFieldWork permission', () {
    session.signIn(_principal(UserRole.reviewer, const {
      Permission.viewReviewQueue,
    }));

    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse(AppPaths.staffTasks),
    );

    expect(redirect, AppPaths.staffDashboard);
  });

  test('field task route opens for authorized staff', () {
    session.signIn(_principal(UserRole.demoSupervisor, Permission.values));

    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse(AppPaths.staffTasks),
    );

    expect(redirect, isNull);
  });

  test('privacy staff queue is a known typed queue', () {
    session.signIn(_principal(UserRole.demoSupervisor, Permission.values));

    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse(AppPaths.staffQueue(StaffQueueType.privacy)),
    );

    expect(redirect, isNull);
  });

  test('unknown staff queue value falls back to the typed canonical queue', () {
    session.signIn(_principal(UserRole.demoSupervisor, Permission.values));

    final redirect = policy.redirect(
      config: config,
      session: session,
      uri: Uri.parse('/staff/queues/not-a-queue'),
    );

    expect(redirect, AppPaths.staffQueue(StaffQueueType.critical));
  });


  test('WP-18 admin routes require their exact permissions', () {
    session.signIn(_principal(UserRole.reviewer, const {
      Permission.viewReviewQueue,
      Permission.reviewReport,
    }));

    expect(
      policy.redirect(config: config, session: session, uri: Uri.parse(AppPaths.staffDataSources)),
      AppPaths.staffDashboard,
    );
    expect(
      policy.redirect(config: config, session: session, uri: Uri.parse(AppPaths.staffUsers)),
      AppPaths.staffDashboard,
    );
    expect(
      policy.redirect(config: config, session: session, uri: Uri.parse(AppPaths.staffAudit)),
      AppPaths.staffDashboard,
    );
    expect(
      policy.redirect(config: config, session: session, uri: Uri.parse(AppPaths.staffPrivacyRequests)),
      AppPaths.staffDashboard,
    );
  });

  test('WP-17/WP-18 supervisor can open source and governance routes', () {
    session.signIn(_principal(UserRole.demoSupervisor, Permission.values));
    for (final path in const [
      AppPaths.staffDataSources,
      AppPaths.staffUsers,
      AppPaths.staffAudit,
      AppPaths.staffPrivacyRequests,
    ]) {
      expect(policy.redirect(config: config, session: session, uri: Uri.parse(path)), isNull);
    }
  });

  test('WP-18 demo reset route requires resetDemo permission', () {
    session.signIn(_principal(UserRole.citizen, const {
      Permission.viewPublicMap,
      Permission.submitReport,
      Permission.viewOwnReport,
    }));
    expect(
      policy.redirect(config: config, session: session, uri: Uri.parse(AppPaths.demoReset)),
      AppPaths.demoStart,
    );
    session.signIn(_principal(UserRole.demoSupervisor, Permission.values));
    expect(
      policy.redirect(config: config, session: session, uri: Uri.parse(AppPaths.demoReset)),
      isNull,
    );
  });

  test('returnTo rejects external and protocol-relative URLs', () {
    expect(policy.safeReturnTo('https://example.invalid'), isNull);
    expect(policy.safeReturnTo('//example.invalid/path'), isNull);
    expect(policy.safeReturnTo('/citizen/reports'), '/citizen/reports');
  });
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

DemoPrincipal _principal(
  UserRole role,
  Iterable<Permission> permissions,
) {
  return DemoPrincipal(
    account: UserAccount(
      id: 'usr_test_001',
      role: role,
      permissions: permissions,
    ),
    displayName: 'Test principal',
    maskedIdentity: '***',
  );
}
