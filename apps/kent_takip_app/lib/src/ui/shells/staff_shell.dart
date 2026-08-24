import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/auth_flow_controller.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_app/src/ui/widgets/brand_header.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

final class StaffShell extends StatelessWidget {
  const StaffShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = _items(context).where((item) {
      return item.permission == null ||
          context.read<SessionController>().can(item.permission!);
    }).toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          return _MobileStaffShell(
            items: items,
            location: location,
            child: child,
          );
        }
        final expanded = constraints.maxWidth >= 1280;
        return Scaffold(
          body: Row(
            children: [
              _StaffSidebar(
                items: items,
                location: location,
                expanded: expanded,
              ),
              Expanded(
                child: Column(
                  children: [
                    const _StaffTopBar(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_StaffDestination> _items(BuildContext context) => [
    _StaffDestination(
      label: context.strings.overview,
      icon: Icons.home_outlined,
      path: AppPaths.staffDashboard,
    ),
    _StaffDestination(
      label: context.strings.reviewQueues,
      icon: Icons.format_list_bulleted_rounded,
      path: AppPaths.staffQueues,
      permission: Permission.viewReviewQueue,
    ),
    _StaffDestination(
      label: context.strings.map,
      icon: Icons.map_outlined,
      path: AppPaths.staffMap,
    ),
    _StaffDestination(
      label: context.strings.plannedWorks,
      icon: Icons.calendar_month_outlined,
      path: AppPaths.staffPlanning,
      permission: Permission.manageMunicipalWork,
    ),
    _StaffDestination(
      label: context.strings.text('u0378'),
      icon: Icons.engineering_outlined,
      path: AppPaths.staffTasks,
      permission: Permission.manageFieldWork,
    ),
    _StaffDestination(
      label: context.strings.reports,
      icon: Icons.bar_chart_rounded,
      path: AppPaths.staffReports,
    ),
    _StaffDestination(
      label: context.strings.teamManagement,
      icon: Icons.groups_outlined,
      path: AppPaths.staffTeam,
      permission: Permission.manageUsers,
    ),
    _StaffDestination(
      label: context.strings.text('u0117'),
      icon: Icons.hub_outlined,
      path: AppPaths.staffDataSources,
      permission: Permission.manageSources,
    ),
    _StaffDestination(
      label: context.strings.text('u0379'),
      icon: Icons.admin_panel_settings_outlined,
      path: AppPaths.staffUsers,
      permission: Permission.manageUsers,
    ),
    _StaffDestination(
      label: context.strings.text('u0380'),
      icon: Icons.history_rounded,
      path: AppPaths.staffAudit,
      permission: Permission.viewAudit,
    ),
    _StaffDestination(
      label: context.strings.text('u0381'),
      icon: Icons.privacy_tip_outlined,
      path: AppPaths.staffPrivacyRequests,
      permission: Permission.managePrivacyRequests,
    ),
    _StaffDestination(
      label: context.strings.settings,
      icon: Icons.settings_outlined,
      path: AppPaths.staffSettings,
    ),
  ];
}

final class _StaffSidebar extends StatelessWidget {
  const _StaffSidebar({
    required this.items,
    required this.location,
    required this.expanded,
  });

  final List<_StaffDestination> items;
  final String location;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 232 : 80,
      color: AppColors.brandBlue900,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 20 : 14,
                vertical: 16,
              ),
              child: expanded
                  ? const BrandMark(onDark: true, compact: true)
                  : const Icon(
                      Icons.location_city_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
            const Divider(color: KtColors.onDarkDivider, height: 1),
            Expanded(
              child: Scrollbar(
                child: ListView(
                  key: const ValueKey('staff-navigation-scroll'),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: [
                    for (final item in items)
                      _StaffNavigationItem(
                        item: item,
                        selected: _matchesDestination(location, item.path),
                        expanded: expanded,
                      ),
                  ],
                ),
              ),
            ),
            const Divider(color: KtColors.onDarkDivider, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        context.strings.systemHealthy,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StaffNavigationItem extends StatelessWidget {
  const _StaffNavigationItem({
    required this.item,
    required this.selected,
    required this.expanded,
  });

  final _StaffDestination item;
  final bool selected;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: () => context.go(item.path),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppColors.brandBlue700 : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.magenta600 : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0),
          child: Row(
            mainAxisAlignment: expanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: Colors.white, size: 22),
              if (expanded) ...[
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 2,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _StaffTopBar extends StatelessWidget {
  const _StaffTopBar();

  @override
  Widget build(BuildContext context) {
    final principal = context.watch<SessionController>().principal;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            context.strings.appName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          const Icon(Icons.notifications_none_rounded),
          const SizedBox(width: 20),
          const VerticalDivider(indent: 14, endIndent: 14),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.brandBlue100,
            child: Text(
              principal?.displayName.substring(0, 1).toUpperCase() ?? 'D',
              style: const TextStyle(
                color: AppColors.brandBlue900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                principal?.displayName ?? context.strings.municipalOfficer,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                context.strings.format('u0323', {'role': principal?.account.role.name ?? 'staff'}),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          PopupMenuButton<_StaffMenuAction>(
            onSelected: (action) => _handleMenu(context, action),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _StaffMenuAction.switchRole,
                child: Text(context.strings.switchRole),
              ),
              PopupMenuItem(
                value: _StaffMenuAction.signOut,
                child: Text(context.strings.signOut),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenu(BuildContext context, _StaffMenuAction action) {
    final router = GoRouter.of(context);
    final authFlow = context.read<AuthFlowController>();
    final session = context.read<SessionController>();
    authFlow.clear();
    session.signOut();
    router.go(
      action == _StaffMenuAction.signOut
          ? AppPaths.staffLogin
          : AppPaths.demoStart,
    );
  }
}

enum _StaffMenuAction { switchRole, signOut }

final class _MobileStaffShell extends StatelessWidget {
  const _MobileStaffShell({
    required this.items,
    required this.location,
    required this.child,
  });

  final List<_StaffDestination> items;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandMark(compact: true),
        backgroundColor: Colors.white,
      ),
      drawer: Drawer(
        backgroundColor: AppColors.brandBlue900,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: BrandMark(onDark: true, compact: true),
              ),
              for (final item in items)
                ListTile(
                  selected: _matchesDestination(location, item.path),
                  selectedTileColor: AppColors.brandBlue700,
                  leading: Icon(item.icon, color: Colors.white),
                  title: Text(item.label, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.go(item.path);
                  },
                ),
              const Divider(color: KtColors.onDarkDivider),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                title: Text(
                  context.strings.switchRole,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  final router = GoRouter.of(context);
                  final authFlow = context.read<AuthFlowController>();
                  final session = context.read<SessionController>();
                  Navigator.of(context).pop();
                  authFlow.clear();
                  session.switchRole();
                  router.go(AppPaths.demoStart);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.white),
                title: Text(
                  context.strings.signOut,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  final router = GoRouter.of(context);
                  final authFlow = context.read<AuthFlowController>();
                  final session = context.read<SessionController>();
                  Navigator.of(context).pop();
                  authFlow.clear();
                  session.signOut();
                  router.go(AppPaths.staffLogin);
                },
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}

final class _StaffDestination {
  const _StaffDestination({
    required this.label,
    required this.icon,
    required this.path,
    this.permission,
  });

  final String label;
  final IconData icon;
  final String path;
  final Permission? permission;
}

bool _matchesDestination(String location, String destination) {
  if (destination.startsWith('/staff/queues/')) {
    return location.startsWith('/staff/queues/');
  }
  return location == destination || location.startsWith('$destination/');
}
