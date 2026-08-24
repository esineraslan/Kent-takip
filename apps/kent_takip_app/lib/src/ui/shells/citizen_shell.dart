import 'package:flutter/material.dart' hide SnapshotController;
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/auth_flow_controller.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/locale_controller.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/widgets/brand_header.dart';
import 'package:provider/provider.dart';
import 'package:kent_takip_application/kent_takip_application.dart';

final class CitizenShell extends StatelessWidget {
  const CitizenShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = location.startsWith('/citizen/report/')
        ? 1
        : location.startsWith('/citizen/reports') ||
              location.startsWith('/citizen/notifications')
        ? 2
        : 0;
    final actorId = context.watch<SessionController>().principal?.account.id;
    final snapshot = context.watch<SnapshotController>().snapshot;
    final unread = actorId == null || snapshot == null
        ? 0
        : DemoProjections.ownedNotifications(
            snapshot,
            actorId,
            unreadOnly: true,
          ).length;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const BrandMark(compact: true),
        actions: [
          IconButton(
            tooltip: unread == 0 ? context.strings.text('u0032') : context.strings.format('u0324', {'count': unread}),
            onPressed: actorId == null
                ? null
                : () => context.go(AppPaths.citizenNotifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          PopupMenuButton<_CitizenMenuAction>(
            tooltip: context.strings.settings,
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onSelected: (action) => _handleMenu(context, action),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _CitizenMenuAction.settings,
                child: ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(context.strings.settings),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _CitizenMenuAction.locale,
                child: ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(context.strings.language),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _CitizenMenuAction.switchRole,
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: Text(context.strings.switchRole),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: child,
      bottomNavigationBar: _CitizenBottomNavigation(
        selectedIndex: selectedIndex,
      ),
    );
  }

  void _handleMenu(BuildContext context, _CitizenMenuAction action) {
    switch (action) {
      case _CitizenMenuAction.settings:
        context.go(AppPaths.citizenSettings);
      case _CitizenMenuAction.locale:
        context.read<LocaleController>().toggle();
      case _CitizenMenuAction.switchRole:
        final router = GoRouter.of(context);
        final authFlow = context.read<AuthFlowController>();
        final session = context.read<SessionController>();
        authFlow.clear();
        session.switchRole();
        router.go(AppPaths.demoStart);
    }
  }
}

enum _CitizenMenuAction { settings, locale, switchRole }

final class _CitizenBottomNavigation extends StatelessWidget {
  const _CitizenBottomNavigation({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final items = [
      _CitizenDestination(
        label: context.strings.map,
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
        path: AppPaths.citizenMap,
      ),
      _CitizenDestination(
        label: context.strings.report,
        icon: Icons.note_add_outlined,
        selectedIcon: Icons.note_add_rounded,
        path: AppPaths.citizenReport,
      ),
      _CitizenDestination(
        label: context.strings.myReports,
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications_rounded,
        path: AppPaths.citizenReports,
      ),
    ];
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _CitizenNavigationItem(
                    item: items[index],
                    selected: selectedIndex == index,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _CitizenNavigationItem extends StatelessWidget {
  const _CitizenNavigationItem({required this.item, required this.selected});

  final _CitizenDestination item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brandBlue800 : AppColors.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: () => context.go(item.path),
        child: Column(
          children: [
            Container(
              height: 3,
              color: selected ? AppColors.brandBlue800 : Colors.transparent,
            ),
            const Spacer(),
            Icon(selected ? item.selectedIcon : item.icon, color: color, size: 25),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

final class _CitizenDestination {
  const _CitizenDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
