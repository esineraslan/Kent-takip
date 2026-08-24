import 'dart:async';

import 'package:flutter/material.dart' hide SnapshotController;
import 'package:go_router/go_router.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_app/src/auth/auth_flow_controller.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/locale_controller.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

final class DemoEnvironmentBanner extends StatelessWidget {
  DemoEnvironmentBanner({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final resetAvailable =
        context.read<AppConfig>().dataMode == DemoDataMode.local &&
        session.can(Permission.resetDemo);
    final roleLabel =
        session.principal?.displayName ??
        (session.isGuest ? context.strings.continueAsGuest : '—');
    return Semantics(
      container: true,
      label: context.strings.format('u0455', {
        'demoData': context.strings.demoData,
        'currentRole': context.strings.currentRole,
        'role': roleLabel,
      }),
      child: Material(
        color: AppColors.brandBlue050,
        child: Container(
          constraints: BoxConstraints(minHeight: 36),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.brandBlue100)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 17,
                color: AppColors.brandBlue800,
              ),
              SizedBox(width: 8),
              if (!narrow)
                Flexible(
                  child: Text(
                    '${context.strings.demoData} · $roleLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.brandBlue900,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Text(
                    context.strings.demoData,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.brandBlue900,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              _BannerAction(
                label: context.strings.language,
                onPressed: context.read<LocaleController>().toggle,
              ),
              _BannerAction(
                label: context.strings.scenarios,
                onPressed: () =>
                    unawaited(router.push<void>(AppPaths.demoScenarios)),
                hideOnNarrow: true,
              ),
              _BannerAction(
                label: context.strings.text('u0064'),
                onPressed: () =>
                    unawaited(router.push<void>(AppPaths.demoComponents)),
                hideOnNarrow: true,
              ),
              if (resetAvailable)
                _BannerAction(
                  label: context.strings.resetData,
                  onPressed: () =>
                      unawaited(router.push<void>(_resetLocation())),
                  hideOnNarrow: true,
                ),
              if (!narrow)
                _BannerAction(
                  label: context.strings.switchRole,
                  onPressed: () => _switchRole(context),
                )
              else
                IconButton(
                  tooltip: context.strings.switchRole,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _switchRole(context),
                  icon: Icon(Icons.swap_horiz_rounded, size: 19),
                ),
              if (narrow)
                PopupMenuButton<_DemoBannerMenuAction>(
                  tooltip: context.strings.demoData,
                  onSelected: (action) {
                    switch (action) {
                      case _DemoBannerMenuAction.scenarios:
                        unawaited(router.push<void>(AppPaths.demoScenarios));
                      case _DemoBannerMenuAction.components:
                        unawaited(router.push<void>(AppPaths.demoComponents));
                      case _DemoBannerMenuAction.reset:
                        unawaited(router.push<void>(_resetLocation()));
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _DemoBannerMenuAction.scenarios,
                      child: Text(context.strings.scenarios),
                    ),
                    PopupMenuItem(
                      value: _DemoBannerMenuAction.components,
                      child: Text(context.strings.text('u0064')),
                    ),
                    if (resetAvailable)
                      PopupMenuItem(
                        value: _DemoBannerMenuAction.reset,
                        child: Text(context.strings.resetData),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchRole(BuildContext context) {
    context.read<AuthFlowController>().clear();
    context.read<SessionController>().switchRole();
    router.go(AppPaths.demoStart);
  }

  String _resetLocation() {
    final current = router.routeInformationProvider.value.uri;
    return Uri(
      path: AppPaths.demoReset,
      queryParameters: {
        'returnTo': current.path == AppPaths.demoReset
            ? AppPaths.demoStart
            : current.toString(),
      },
    ).toString();
  }
}

enum _DemoBannerMenuAction { scenarios, components, reset }

final class _BannerAction extends StatelessWidget {
  _BannerAction({
    required this.label,
    required this.onPressed,
    this.hideOnNarrow = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool hideOnNarrow;

  @override
  Widget build(BuildContext context) {
    if (hideOnNarrow && MediaQuery.sizeOf(context).width < 600) {
      return SizedBox.shrink();
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size(44, 32),
        padding: EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }
}

Future<bool> resetDemoData(BuildContext context) async {
  final strings = context.strings;
  final session = context.read<SessionController>();
  if (!session.can(Permission.resetDemo)) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.strings.text('u0065'))));
    return false;
  }
  if (context.read<AppConfig>().dataMode == DemoDataMode.shared) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.strings.text('u0066'))));
    return false;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.resetConfirmTitle),
      content: Text(strings.syntheticNotice),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(strings.reset),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return false;
  }
  final clock = context.read<Clock>();
  if (clock case final DemoClockControl demoClock) demoClock.reset();
  final ai = context.read<KentAiAnalysisService>();
  if (ai is ControllableDemoAiAnalysisService) ai.reset();
  await context.read<DemoResetCoordinator>().reset(
    actorId: session.principal?.account.id ?? 'demo-presenter',
    dynamicMediaIds: [],
  );
  await context.read<SnapshotController>().resetClientState([
    'usr_citizen_demo_001',
    'usr_citizen_demo_002',
    'usr_citizen_demo_003',
  ]);
  if (!context.mounted) {
    return false;
  }
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.strings.resetCompleted)));
  return true;
}
