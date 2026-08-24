import 'dart:async';

import 'package:flutter/material.dart' hide SnapshotController;
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/map/map_experience.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/states.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

final class CitizenMapScreen extends StatelessWidget {
  CitizenMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final data = controller.snapshot;
    if (data == null && controller.error == null) return LoadingView();
    if (data == null) {
      return RecoverableErrorView(
        message: context.strings.text('u0244'),
        onRetry: () => unawaited(controller.refresh()),
      );
    }
    final session = context.watch<SessionController>();
    return Column(
      children: [
        if (controller.revisionError != null)
          KtBanner(
            title: context.strings.text('u0238'),
            message: context.strings.text('u0245'),
            tone: KtBannerTone.warning,
            action: KtButton(
              label: context.strings.text('u0663'),
              kind: KtButtonKind.text,
              onPressed: () => unawaited(controller.refresh()),
            ),
          ),
        Expanded(
          child: MapExperience(
            snapshot: data,
            viewerId: session.principal?.account.id,
            staff: session.isStaff,
          ),
        ),
      ],
    );
  }
}

final class CitizenSettingsScreen extends StatefulWidget {
  CitizenSettingsScreen({super.key});

  @override
  State<CitizenSettingsScreen> createState() => _CitizenSettingsScreenState();
}

final class _CitizenSettingsScreenState extends State<CitizenSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final controller = context.watch<SnapshotController>();
    final principal = session.principal;
    final snapshot = controller.snapshot;
    if (principal == null) return SizedBox.shrink();
    final ownRequests =
        snapshot?.payload.privacyRequests
            .where((item) => item.body['ownerId'] == principal.account.id)
            .toList(growable: false) ??
        <OpaqueEntityDto>[];
    final ownRestrictions =
        snapshot?.payload.restrictions
            .where((item) => item.body['accountId'] == principal.account.id)
            .toList(growable: false) ??
        <OpaqueEntityDto>[];
    final deletionRequested = snapshot == null
        ? principal.account.deletionRequested
        : snapshot.payload.accounts.any(
            (item) => item.id == principal.account.id && item.deletionRequested,
          );
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          context.strings.settings,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person_outline),
                title: Text(principal.displayName),
                subtitle: Text(principal.maskedIdentity),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout_rounded),
                title: Text(context.strings.signOut),
                onTap: () {
                  final router = GoRouter.of(context);
                  session.signOut();
                  router.go(AppPaths.citizenMap);
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Text(
          context.strings.text('u0034'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(context.strings.text('u0035')),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in [
              (PrivacyRequestType.access, 'u0537'),
              (PrivacyRequestType.correction, 'u0538'),
              (PrivacyRequestType.deletion, 'u0539'),
              (PrivacyRequestType.automatedAssessmentObjection, 'u0540'),
            ])
              OutlinedButton(
                onPressed: controller.busy
                    ? null
                    : () => unawaited(
                        _createPrivacy(
                          context,
                          controller,
                          principal.account.id,
                          entry.$1,
                          context.strings.text(entry.$2),
                        ),
                      ),
                child: Text(context.strings.text(entry.$2)),
              ),
          ],
        ),
        if (ownRequests.isNotEmpty) ...[
          SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (final request in ownRequests)
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text(
                      '${request.body['trackingNumber'] ?? '—'} · ${request.body['type'] ?? '—'}',
                    ),
                    subtitle: Text(
                      '${request.body['status'] ?? '—'} · ${request.body['note'] ?? ''}',
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (ownRestrictions.isNotEmpty) ...[
          SizedBox(height: 20),
          Text(
            context.strings.text('u0036'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          for (final restriction in ownRestrictions)
            Card(
              child: ListTile(
                leading: Icon(Icons.gpp_maybe_outlined),
                title: Text('${restriction.body['level'] ?? 'restriction'}'),
                subtitle: Text(
                  '${restriction.body['reason'] ?? ''}\n${context.strings.text('u0634')}: ${restriction.body['appealStatus'] ?? 'not_submitted'}',
                ),
                isThreeLine: true,
                trailing:
                    restriction.body['appealStatus'] == 'human_review_required'
                    ? Text(context.strings.text('u0037'))
                    : TextButton(
                        onPressed: () => unawaited(
                          _appeal(
                            context,
                            controller,
                            principal.account.id,
                            restriction.id,
                          ),
                        ),
                        child: Text(context.strings.text('u0038')),
                      ),
              ),
            ),
        ],
        SizedBox(height: 20),
        Text(
          context.strings.text('u0039'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        if (deletionRequested)
          KtBanner(
            title: context.strings.text('u0239'),
            message: context.strings.text('u0404'),
            tone: KtBannerTone.warning,
          )
        else
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text(context.strings.text('u0040')),
              subtitle: Text(context.strings.text('u0041')),
              trailing: FilledButton(
                onPressed: controller.busy
                    ? null
                    : () => unawaited(
                        _deleteAccount(
                          context,
                          controller,
                          principal.account.id,
                        ),
                      ),
                child: Text(context.strings.text('u0042')),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _createPrivacy(
    BuildContext context,
    SnapshotController controller,
    String actorId,
    PrivacyRequestType type,
    String label,
  ) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: InputDecoration(labelText: context.strings.text('u0232')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.strings.text('u0043')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.strings.text('u0044')),
          ),
        ],
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (confirmed != true || text.isEmpty) return;
    final result = await controller.administration(
      actorId: actorId,
      action: AdministrationAction.createPrivacyRequest,
      payload: {'type': enumWire(type), 'note': text},
    );
    if (!context.mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.strings.format('u0331', {
            'tracking': result.trackingNumber ?? result.resourceId,
          }),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
    SnapshotController controller,
    String actorId,
  ) async {
    final code = TextEditingController();
    final reauth = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.strings.text('u0045')),
        content: TextField(
          controller: code,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.strings.text('u0233'),
            helperText: context.strings.text('u0237'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.strings.text('u0043')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, code.text.trim() == '123456'),
            child: Text(context.strings.text('u0046')),
          ),
        ],
      ),
    );
    code.dispose();
    if (reauth != true || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.strings.text('u0047')),
        content: Text(context.strings.text('u0048')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.strings.text('u0043')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.strings.text('u0049')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.administration(
      actorId: actorId,
      action: AdministrationAction.requestAccountDeletion,
      payload: {'reauthVerified': true, 'confirmed': true},
    );
  }

  Future<void> _appeal(
    BuildContext context,
    SnapshotController controller,
    String actorId,
    String restrictionId,
  ) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.strings.text('u0050')),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: InputDecoration(labelText: context.strings.text('u0234')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.strings.text('u0043')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.strings.text('u0038')),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (confirmed != true || text.isEmpty) return;
    await controller.administration(
      actorId: actorId,
      action: AdministrationAction.appealRestriction,
      payload: {'restrictionId': restrictionId, 'reason': text},
    );
  }
}

final class StaffDashboardScreen extends StatelessWidget {
  StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final data = controller.snapshot;
    if (data == null) return LoadingView();
    final queue = DemoProjections.reviewQueue(data);
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        Text(
          context.strings.overview,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 6),
        Text(context.strings.text('u0541')),
        SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: context.strings.text('u0520'),
              value: queue.length,
              icon: Icons.fact_check_outlined,
              color: AppColors.critical,
            ),
            _MetricCard(
              label: context.strings.text('u0633'),
              value: data.payload.incidents.length,
              icon: Icons.warning_amber_rounded,
              color: AppColors.active,
            ),
            _MetricCard(
              label: context.strings.text('u0554'),
              value: data.payload.municipalWorks.length,
              icon: Icons.calendar_month_outlined,
              color: AppColors.plannedInk,
            ),
            _MetricCard(
              label: context.strings.text('u0572'),
              value: data.payload.sourceRecords.length,
              icon: Icons.hub_outlined,
              color: AppColors.brandBlue800,
            ),
          ],
        ),
        SizedBox(height: 24),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  context.strings.reviewQueues,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Divider(height: 1),
              for (final report in queue)
                KtQueueRow(
                  title: context.strings.categoryLabel(report.category),
                  subtitle: '${report.trackingNumber} · ${report.status.name}',
                  status: context.strings.text('u0542'),
                  statusIcon: Icons.priority_high_rounded,
                  onTap: () => context.go(AppPaths.staffQueues),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

final class StaffReviewQueueScreen extends StatefulWidget {
  StaffReviewQueueScreen({super.key});

  @override
  State<StaffReviewQueueScreen> createState() => _StaffReviewQueueScreenState();
}

final class _StaffReviewQueueScreenState extends State<StaffReviewQueueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _selectedReportId;
  var _category = 'road_surface_damage';
  var _unit = 'unit_road_maintenance';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null) return LoadingView();
    final queue = DemoProjections.reviewQueue(snapshot);
    if (_selectedReportId == null && queue.isNotEmpty) {
      _selectedReportId = queue.first.id;
      _category = queue.first.category;
    }
    final selected = _reportById(queue, _selectedReportId);
    final list = _ReviewList(
      reports: queue,
      selectedId: _selectedReportId,
      onSelected: (report) {
        setState(() {
          _selectedReportId = report.id;
          _category = report.category;
          _reason.clear();
        });
      },
    );
    final detail = selected == null
        ? EmptyView(
            title: context.strings.text('u0240'),
            description: context.strings.text('u0408'),
          )
        : _buildReview(context, selected, controller);
    return Column(
      children: [
        if (controller.staffReadOnly)
          KtBanner(
            title: context.strings.text('u0241'),
            message: context.strings.text('u0246'),
            tone: KtBannerTone.warning,
            action: KtButton(
              label: context.strings.text('u0663'),
              kind: KtButtonKind.text,
              onPressed: () => unawaited(controller.refresh()),
            ),
          ),
        if (controller.revisionError != null && controller.online)
          KtBanner(
            title: context.strings.text('u0238'),
            message: context.strings.text('u0247'),
            tone: KtBannerTone.warning,
            action: KtButton(
              label: context.strings.text('u0663'),
              kind: KtButtonKind.text,
              onPressed: () => unawaited(controller.refresh()),
            ),
          ),
        if (controller.conflict != null)
          KtBanner(
            title: context.strings.text('u0242'),
            message: context.strings.format('u0454', {
              'revision': controller.conflict!.current.revision,
            }),
            tone: KtBannerTone.danger,
            action: KtButton(
              label: context.strings.text('u0405'),
              kind: KtButtonKind.text,
              onPressed: controller.clearConflict,
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return ListView(
                  padding: EdgeInsets.all(KtSpacing.x4),
                  children: [
                    list,
                    SizedBox(height: KtSpacing.x4),
                    detail,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 380, child: list),
                  VerticalDivider(width: 1),
                  Expanded(child: SingleChildScrollView(child: detail)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReview(
    BuildContext context,
    CitizenReportDto report,
    SnapshotController controller,
  ) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(KtSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KtStatusChip(
              label: context.strings.text('u0406'),
              icon: Icons.person_search_rounded,
              tone: KtStatusTone.warning,
            ),
            SizedBox(height: KtSpacing.x4),
            Text(
              context.strings.categoryLabel(report.category),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              context.strings.format('u0332', {
                'tracking': report.trackingNumber,
                'revision': controller.snapshot!.revision,
              }),
            ),
            if (report.analysisId != null) ...[
              SizedBox(height: KtSpacing.x4),
              KtBanner(
                title: context.strings.text('u0243'),
                message: context.strings.text('u0248'),
                tone: KtBannerTone.info,
              ),
            ],
            SizedBox(height: KtSpacing.x6),
            DropdownButtonFormField<String>(
              key: ValueKey('category-${report.id}'),
              initialValue: _category,
              decoration: InputDecoration(
                labelText: context.strings.text('u0235'),
              ),
              items: [
                DropdownMenuItem(
                  value: 'road_surface_damage',
                  child: Text(context.strings.text('u0051')),
                ),
                DropdownMenuItem(
                  value: 'traffic_signal',
                  child: Text(context.strings.text('u0052')),
                ),
                DropdownMenuItem(
                  value: 'water_infrastructure',
                  child: Text(context.strings.text('u0053')),
                ),
                DropdownMenuItem(
                  value: 'lighting',
                  child: Text(context.strings.text('u0054')),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
            ),
            SizedBox(height: KtSpacing.x4),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: InputDecoration(
                labelText: context.strings.text('u0236'),
              ),
              items: [
                DropdownMenuItem(
                  value: 'unit_road_maintenance',
                  child: Text(context.strings.text('u0055')),
                ),
                DropdownMenuItem(
                  value: 'unit_traffic',
                  child: Text(context.strings.text('u0056')),
                ),
                DropdownMenuItem(
                  value: 'unit_water_operations',
                  child: Text(context.strings.text('u0057')),
                ),
              ],
              onChanged: (value) => setState(() => _unit = value ?? _unit),
            ),
            SizedBox(height: KtSpacing.x4),
            KtTextField(
              key: ValueKey('review-reason'),
              controller: _reason,
              label: context.strings.text('u0295'),
              hint: context.strings.text('u0543'),
              maxLines: 4,
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.strings.text('u0544')
                  : null,
            ),
            SizedBox(height: KtSpacing.x6),
            KtButton(
              key: ValueKey('walking-skeleton-verify-report'),
              label: context.strings.text('u0407'),
              icon: Icons.verified_rounded,
              expand: true,
              busy: controller.busy,
              onPressed: controller.staffReadOnly
                  ? null
                  : () => unawaited(_verify(context, report)),
            ),
            SizedBox(height: KtSpacing.x2),
            Text(
              context.strings.text('u0058'),
              style: TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify(BuildContext context, CitizenReportDto report) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final actor = context.read<SessionController>().principal;
    if (actor == null) return;
    final result = await context.read<SnapshotController>().verifyReport(
      actorId: actor.account.id,
      clientMutationId:
          'staff_${actor.account.id}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      reportId: report.id,
      category: _category,
      unitId: _unit,
      reason: _reason.text,
      aiOverrideReason: report.analysisId == null ? null : _reason.text,
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedReportId = null;
      _reason.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.strings.format('u0333', {'tracking': report.trackingNumber}),
        ),
      ),
    );
  }
}

final class _ReviewList extends StatelessWidget {
  _ReviewList({
    required this.reports,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CitizenReportDto> reports;
  final String? selectedId;
  final ValueChanged<CitizenReportDto> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KtColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(KtSpacing.x4),
            child: Text(
              context.strings.text('u0059'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final report in reports)
            KtQueueRow(
              title: context.strings.categoryLabel(report.category),
              subtitle: '${report.trackingNumber} · ${report.status.name}',
              status: context.strings.text('u0520'),
              statusIcon: Icons.fact_check_outlined,
              selected: selectedId == report.id,
              onTap: () => onSelected(report),
            ),
        ],
      ),
    );
  }
}

CitizenReportDto? _reportById(List<CitizenReportDto> reports, String? id) {
  for (final report in reports) {
    if (report.id == id) return report;
  }
  return null;
}

final class StaffModuleScreen extends StatelessWidget {
  StaffModuleScreen({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _ModuleBoundaryScreen(
      icon: icon,
      title: title,
      description: description,
      highlights: [
        context.strings.text('u0545'),
        context.strings.text('u0546'),
        context.strings.text('u0547'),
        context.strings.text('u0548'),
      ],
    );
  }
}

final class _ModuleBoundaryScreen extends StatelessWidget {
  _ModuleBoundaryScreen({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlights,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.brandBlue800, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description),
                  SizedBox(height: 20),
                  for (final item in highlights)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _MetricCard extends StatelessWidget {
  _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(label, style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StatusLabel extends StatelessWidget {
  _StatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brandBlue050,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: AppColors.brandBlue900,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
