import 'dart:async';

import 'package:flutter/material.dart' hide SnapshotController;
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_app/src/ui/widgets/brand_header.dart';
import 'package:kent_takip_app/src/ui/widgets/demo_environment_banner.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:provider/provider.dart';

final class DemoStartScreen extends StatelessWidget {
  const DemoStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 48 : 20,
                vertical: wide ? 48 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: wide
                      ? IntrinsicHeight(
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 5,
                                child: _IntroPanel(wide: true),
                              ),
                              const SizedBox(width: 48),
                              const Expanded(
                                flex: 6,
                                child: _RolePanel(wide: true),
                              ),
                            ],
                          ),
                        )
                      : const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _IntroPanel(wide: false),
                            SizedBox(height: 28),
                            _RolePanel(wide: false),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandBlue900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(wide ? 40 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const BrandMark(onDark: true),
            Padding(
              padding: EdgeInsets.symmetric(vertical: wide ? 64 : 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.tagline,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.strings.chooseRoleHint,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: KtColors.onDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TrustChip(
                  icon: Icons.verified_outlined,
                  label: context.strings.text('u0549'),
                ),
                _TrustChip(
                  icon: Icons.shield_outlined,
                  label: context.strings.text('u0550'),
                ),
                _TrustChip(
                  icon: Icons.science_outlined,
                  label: context.strings.text('u0657'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _RolePanel extends StatelessWidget {
  const _RolePanel({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: wide ? 28 : 0),
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.strings.chooseRole,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(context.strings.chooseRoleHint),
            const SizedBox(height: 28),
            _RoleCard(
              icon: Icons.person_outline_rounded,
              title: context.strings.citizen,
              description: context.strings.publicMapDescription,
              onTap: () => context.go(AppPaths.citizenWelcome),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.account_balance_outlined,
              title: context.strings.municipalOfficer,
              description: context.strings.reviewQueues,
              onTap: () => context.go(AppPaths.staffLogin),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue050,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.brandBlue800, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.brandBlue800),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: KtColors.translucentWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

final class CitizenWelcomeScreen extends StatelessWidget {
  const CitizenWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppPaths.demoStart)),
        title: const BrandMark(compact: true),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      color: AppColors.brandBlue800,
                      size: 48,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.strings.citizen,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.strings.publicMapDescription,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: () => context.go(AppPaths.citizenLogin),
                      icon: const Icon(Icons.login_rounded),
                      label: Text(context.strings.signInDemo),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        final router = GoRouter.of(context);
                        context.read<SessionController>().continueAsGuest();
                        router.go(AppPaths.citizenMap);
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(context.strings.continueAsGuest),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class DemoScenariosScreen extends StatefulWidget {
  const DemoScenariosScreen({super.key});

  @override
  State<DemoScenariosScreen> createState() => _DemoScenariosScreenState();
}

final class _DemoScenariosScreenState extends State<DemoScenariosScreen> {
  Future<AppSnapshotDto>? _snapshot;
  bool _busy = false;
  String? _message;

  static const _stepTextKeys = <String, (String, String)>{
    'problem_boundary': ('u0737', 'u0738'),
    'common_city_view': ('u0739', 'u0740'),
    'citizen_report': ('u0741', 'u0742'),
    'ai_boundary': ('u0743', 'u0744'),
    'staff_workspace': ('u0745', 'u0746'),
    'closed_loop': ('u0747', 'u0748'),
    'outage_and_trust': ('u0749', 'u0750'),
    'pilot_and_ask': ('u0751', 'u0752'),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _snapshot ??= context.read<SnapshotStore>().read();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final clock = context.read<Clock>();
    final ai = context.read<KentAiAnalysisService>();
    final localMode = context.read<AppConfig>().dataMode == DemoDataMode.local;
    final canControlSources = session.can(Permission.manageSources);
    final canReset = session.can(Permission.resetDemo);
    final DemoClockControl? demoClock = clock is DemoClockControl ? clock as DemoClockControl : null;
    final offset = demoClock?.offset ?? Duration.zero;
    final aiMode = ai is ControllableDemoAiAnalysisService ? ai.scenario.name : DemoAiScenario.success.name;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _closeUtilityRoute(context)),
        title: Text(context.strings.scenarios),
      ),
      body: FutureBuilder<AppSnapshotDto>(
        future: _snapshot,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text(context.strings.bootstrapFailure));
          }
          final scenarios = snapshot.data!.payload.demoScenarios;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(context.strings.text('u0708'), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              for (var index = 0; index < JuryDemoScenario.steps.length; index++) ...[
                Builder(builder: (context) {
                  final step = JuryDemoScenario.steps[index];
                  final keys = _stepTextKeys[step.id]!;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(context.strings.text(keys.$1)),
                      subtitle: Text(
                        '${context.strings.format('u0726', {'index': index + 1, 'start': step.startSecond, 'end': step.endSecond})}\n'
                        '${context.strings.text(keys.$2)}\n${step.route}',
                      ),
                      isThreeLine: true,
                      onTap: () => context.go(step.route),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              Text(context.strings.text('u0709'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(context.strings.format('u0728', {'minutes': offset.inMinutes})),
              Text(context.strings.format('u0729', {'mode': aiMode})),
              if (!localMode) ...[
                const SizedBox(height: 8),
                Text(context.strings.text('u0736')),
              ],
              if (!canControlSources) ...[
                const SizedBox(height: 8),
                Text(context.strings.text('u0716')),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: localMode && !_busy ? () => _advance(const Duration(minutes: 15)) : null,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(context.strings.text('u0710')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: localMode && !_busy ? () => _advance(const Duration(hours: 1)) : null,
                    icon: const Icon(Icons.more_time_rounded),
                    label: Text(context.strings.text('u0711')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: canControlSources && !_busy ? _sourceOutage : null,
                    icon: const Icon(Icons.cloud_off_outlined),
                    label: Text(context.strings.text('u0712')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: canControlSources && !_busy ? _sourceRecover : null,
                    icon: const Icon(Icons.cloud_done_outlined),
                    label: Text(context.strings.text('u0713')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: !_busy ? () => _setAi(DemoAiScenario.unavailable) : null,
                    icon: const Icon(Icons.psychology_alt_outlined),
                    label: Text(context.strings.text('u0714')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: !_busy ? () => _setAi(DemoAiScenario.success) : null,
                    icon: const Icon(Icons.psychology_outlined),
                    label: Text(context.strings.text('u0715')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: canReset && !_busy ? () => context.go(AppPaths.demoReset) : null,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(context.strings.text('u0753')),
                  ),
                ],
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!),
              ],
              const SizedBox(height: 24),
              Text(context.strings.scenarios, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final scenario in scenarios)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: Text(scenario.id),
                    subtitle: Text(
                      context.strings.format('u0658', {
                        'ai': scenario.body['aiMode'],
                        'privacy': scenario.body['privacyMode'],
                        'connectivity': scenario.body['connectivity'],
                      }),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _advance(Duration duration) {
    final clock = context.read<Clock>();
    if (clock is! DemoClockControl) return;
    (clock as DemoClockControl).advance(duration);
    setState(() => _message = context.strings.text('u0717'));
  }

  void _setAi(DemoAiScenario scenario) {
    final ai = context.read<KentAiAnalysisService>();
    if (ai is! ControllableDemoAiAnalysisService) return;
    ai.setScenario(scenario);
    setState(() => _message = context.strings.text('u0717'));
  }

  Future<void> _sourceOutage() async {
    await _sourceAction(
      SourceOperationAction.simulateOutage,
      const {'sourceId': 'water_events_fixture'},
    );
  }

  Future<void> _sourceRecover() async {
    await _sourceAction(
      SourceOperationAction.refreshFixture,
      const {'sourceId': 'water_events_fixture'},
    );
  }

  Future<void> _sourceAction(SourceOperationAction action, JsonMap payload) async {
    final actorId = context.read<SessionController>().principal?.account.id;
    if (actorId == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await context.read<SnapshotController>().sourceOperation(
        actorId: actorId,
        action: action,
        payload: payload,
      );
      if (mounted && result != null) {
        setState(() {
          _snapshot = Future.value(result.snapshot);
          _message = context.strings.text('u0717');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class DemoResetScreen extends StatefulWidget {
  const DemoResetScreen({super.key});

  @override
  State<DemoResetScreen> createState() => _DemoResetScreenState();
}

final class _DemoResetScreenState extends State<DemoResetScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _closeUtilityRoute(context)),
        title: Text(context.strings.resetData),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restart_alt_rounded, size: 48, color: AppColors.brandBlue800),
                    const SizedBox(height: 16),
                    Text(
                      context.strings.resetConfirmTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(context.strings.syntheticNotice, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_reset(context)),
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restart_alt_rounded),
                      label: Text(context.strings.resetData),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context) async {
    if (_busy) {
      return;
    }
    final returnTo = const AppRoutePolicy().safeReturnTo(
      GoRouterState.of(context).uri.queryParameters['returnTo'],
    );
    setState(() => _busy = true);
    try {
      final reset = await resetDemoData(context);
      if (reset && context.mounted) {
        context.go(returnTo ?? AppPaths.demoStart);
      }
    } on Object catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      context.read<StructuredLogger>().error(
        'demo.reset_failed',
        error: error,
        stackTrace: stackTrace,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.strings.bootstrapFailure)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

final class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, size: 48, color: AppColors.pending),
              const SizedBox(height: 16),
              Text(
                context.strings.text('u0652'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(location, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppPaths.demoStart),
                child: Text(context.strings.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _closeUtilityRoute(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    context.pop();
    return;
  }
  context.go(AppPaths.demoStart);
}
