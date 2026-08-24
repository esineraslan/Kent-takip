import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/screens/auth_screens.dart';
import 'package:kent_takip_app/src/ui/screens/component_gallery_screen.dart';
import 'package:kent_takip_app/src/ui/screens/demo_entry_screens.dart';
import 'package:kent_takip_app/src/ui/screens/module_screens.dart';
import 'package:kent_takip_app/src/ui/staff/staff_operations_screens.dart';
import 'package:kent_takip_app/src/ui/staff/field_planning_screens.dart';
import 'package:kent_takip_app/src/ui/staff/administration_screens.dart';
import 'package:kent_takip_app/src/ui/staff/pilot_analytics_screen.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_app/src/ui/report/report_wizard.dart';
import 'package:kent_takip_app/src/ui/tracking/citizen_tracking_screens.dart';
import 'package:kent_takip_app/src/ui/shells/citizen_shell.dart';
import 'package:kent_takip_app/src/ui/shells/staff_shell.dart';

enum AppRouteId {
  root,
  demoStart,
  demoScenarios,
  demoReset,
  demoComponents,
  citizenWelcome,
  citizenMap,
  citizenLogin,
  citizenVerify,
  citizenReport,
  citizenReports,
  citizenReportDetail,
  citizenNotifications,
  citizenSettings,
  staffLogin,
  staffMfa,
  staffDashboard,
  staffQueue,
  staffMap,
  staffPlanning,
  staffPlanningNew,
  staffPlanningImpact,
  staffPlanningReview,
  staffTasks,
  staffReports,
  staffReportDetail,
  staffTeam,
  staffSettings,
  staffDataSources,
  staffUsers,
  staffAudit,
  staffPrivacyRequests,
}

GoRouter createAppRouter({
  required AppConfig config,
  required SessionController session,
  required StructuredLogger logger,
}) {
  const policy = AppRoutePolicy();
  return GoRouter(
    initialLocation: config.isDemo ? AppPaths.demoStart : AppPaths.citizenMap,
    refreshListenable: session,
    redirect: (context, state) {
      final target = policy.redirect(
        config: config,
        session: session,
        uri: state.uri,
      );
      if (target != null && target != state.uri.toString()) {
        logger.info(
          'router.redirected',
          fields: {'fromPath': state.uri.path, 'toPath': Uri.parse(target).path},
        );
      }
      return target;
    },
    routes: [
      GoRoute(
        name: AppRouteId.root.name,
        path: AppPaths.root,
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        name: AppRouteId.demoStart.name,
        path: AppPaths.demoStart,
        builder: (context, state) => const DemoStartScreen(),
      ),
      GoRoute(
        name: AppRouteId.demoScenarios.name,
        path: AppPaths.demoScenarios,
        builder: (context, state) => const DemoScenariosScreen(),
      ),
      GoRoute(
        name: AppRouteId.demoReset.name,
        path: AppPaths.demoReset,
        builder: (context, state) => const DemoResetScreen(),
      ),
      GoRoute(
        name: AppRouteId.demoComponents.name,
        path: AppPaths.demoComponents,
        builder: (context, state) => ComponentGalleryScreen(),
      ),
      GoRoute(
        name: AppRouteId.citizenWelcome.name,
        path: AppPaths.citizenWelcome,
        builder: (context, state) => const CitizenWelcomeScreen(),
      ),
      GoRoute(
        name: AppRouteId.citizenLogin.name,
        path: AppPaths.citizenLogin,
        builder: (context, state) => const CitizenLoginScreen(),
      ),
      GoRoute(
        name: AppRouteId.citizenVerify.name,
        path: AppPaths.citizenVerify,
        builder: (context, state) => const CitizenVerifyScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => CitizenShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            name: AppRouteId.citizenMap.name,
            path: AppPaths.citizenMap,
            builder: (context, state) => CitizenMapScreen(),
          ),
          GoRoute(
            name: AppRouteId.citizenReport.name,
            path: AppPaths.citizenReport,
            builder: (context, state) => CitizenReportWizardScreen(),
          ),
          GoRoute(
            name: AppRouteId.citizenReports.name,
            path: AppPaths.citizenReports,
            builder: (context, state) => CitizenReportsHubScreen(),
          ),
          GoRoute(
            name: AppRouteId.citizenReportDetail.name,
            path: '/citizen/reports/:reportId',
            builder: (context, state) => CitizenReportDetailScreen(
              reportId: state.pathParameters['reportId']!,
            ),
          ),
          GoRoute(
            name: AppRouteId.citizenNotifications.name,
            path: AppPaths.citizenNotifications,
            builder: (context, state) => CitizenNotificationCenterScreen(),
          ),
          GoRoute(
            name: AppRouteId.citizenSettings.name,
            path: AppPaths.citizenSettings,
            builder: (context, state) => CitizenSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        name: AppRouteId.staffLogin.name,
        path: AppPaths.staffLogin,
        builder: (context, state) => const StaffLoginScreen(),
      ),
      GoRoute(
        name: AppRouteId.staffMfa.name,
        path: AppPaths.staffMfa,
        builder: (context, state) => const StaffMfaScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => StaffShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            name: AppRouteId.staffDashboard.name,
            path: AppPaths.staffDashboard,
            builder: (context, state) => StaffOperationsDashboardScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffQueue.name,
            path: '/staff/queues/:queueType',
            builder: (context, state) {
              final raw = state.pathParameters['queueType'];
              final type = ReviewQueueType.values.firstWhere(
                (value) => value.name == raw,
                orElse: () => ReviewQueueType.critical,
              );
              return StaffOperationsQueueScreen(
                queueType: type,
                initialQuery: state.uri.queryParameters,
              );
            },
          ),
          GoRoute(
            name: AppRouteId.staffMap.name,
            path: AppPaths.staffMap,
            builder: (context, state) => CitizenMapScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffPlanning.name,
            path: AppPaths.staffPlanning,
            builder: (context, state) => WorkPlanningScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffPlanningNew.name,
            path: AppPaths.staffPlanningNew,
            builder: (context, state) => WorkPlanningScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffPlanningImpact.name,
            path: '/staff/planning/:workId/impact',
            builder: (context, state) => WorkImpactScreen(workId: state.pathParameters['workId']!),
          ),
          GoRoute(
            name: AppRouteId.staffPlanningReview.name,
            path: '/staff/planning/:workId/review',
            builder: (context, state) => WorkReviewScreen(workId: state.pathParameters['workId']!),
          ),
          GoRoute(
            name: AppRouteId.staffTasks.name,
            path: AppPaths.staffTasks,
            builder: (context, state) => FieldTasksScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffReports.name,
            path: AppPaths.staffReports,
            builder: (context, state) => const PilotAnalyticsScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffReportDetail.name,
            path: '/staff/reports/:reportId',
            builder: (context, state) => StaffReportWorkspaceScreen(
              reportId: state.pathParameters['reportId']!,
            ),
          ),
          GoRoute(
            name: AppRouteId.staffTeam.name,
            path: AppPaths.staffTeam,
            builder: (context, state) => StaffModuleScreen(
              title: context.strings.teamManagement,
              description: context.strings.moduleBoundary,
              icon: Icons.groups_outlined,
            ),
          ),
          GoRoute(
            name: AppRouteId.staffSettings.name,
            path: AppPaths.staffSettings,
            builder: (context, state) => StaffModuleScreen(
              title: context.strings.settings,
              description: context.strings.moduleBoundary,
              icon: Icons.settings_outlined,
            ),
          ),
          GoRoute(
            name: AppRouteId.staffDataSources.name,
            path: AppPaths.staffDataSources,
            builder: (context, state) => DataSourcesScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffUsers.name,
            path: AppPaths.staffUsers,
            builder: (context, state) => StaffUsersScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffAudit.name,
            path: AppPaths.staffAudit,
            builder: (context, state) => AuditExplorerScreen(),
          ),
          GoRoute(
            name: AppRouteId.staffPrivacyRequests.name,
            path: AppPaths.staffPrivacyRequests,
            builder: (context, state) => PrivacyRequestsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => RouteErrorScreen(
      location: state.uri.path,
    ),
  );
}
