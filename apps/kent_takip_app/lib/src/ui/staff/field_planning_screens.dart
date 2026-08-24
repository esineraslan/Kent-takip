import 'dart:async';

import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/locale_formatter.dart';

import 'package:flutter/material.dart' hide SnapshotController;
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/pins.dart';
import 'package:kent_takip_app/src/ui/design/states.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_app/src/ui/map/map_experience.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

final class FieldTasksScreen extends StatefulWidget {
  FieldTasksScreen({super.key});

  @override
  State<FieldTasksScreen> createState() => _FieldTasksScreenState();
}

final class _FieldTasksScreenState extends State<FieldTasksScreen> {
  FieldTaskFilter _filter = FieldTaskFilter.all;
  String? _selectedId;
  final _reason = TextEditingController();
  final _delay = TextEditingController();
  final _resolution = TextEditingController();
  String? _resolutionMediaId;

  @override
  void initState() {
    super.initState();
    _resolution.addListener(_refreshResolutionAction);
  }

  bool _localizedDefaultsApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultsApplied) return;
    _reason.text = context.strings.text('u0608');
    _delay.text = context.strings.text('u0609');
    _localizedDefaultsApplied = true;
  }

  void _refreshResolutionAction() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _resolution.removeListener(_refreshResolutionAction);
    _reason.dispose();
    _delay.dispose();
    _resolution.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    final account = context.watch<SessionController>().principal?.account;
    if (snapshot == null && controller.error == null) return LoadingView();
    if (snapshot == null || account == null) {
      return RecoverableErrorView(
        message: context.strings.text('u0309'),
        onRetry: () => unawaited(controller.refresh()),
      );
    }
    final tasks = FieldTaskProjection.tasks(
      snapshot,
      viewer: account,
      now: DateTime.now().toUtc(),
      filter: _filter,
    );
    final selected =
        tasks.where((item) => item.incident.id == _selectedId).firstOrNull ??
        (tasks.isEmpty ? null : tasks.first);
    _selectedId ??= selected?.incident.id;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(KtSpacing.x5),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.text('u0160'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 4),
                    Text(context.strings.text('u0161')),
                  ],
                ),
              ),
              if (controller.staffReadOnly)
                Chip(label: Text(context.strings.text('u0162'))),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: KtSpacing.x5),
          child: Row(
            children: [
              for (final filter in FieldTaskFilter.values)
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _filter == filter,
                    label: Text(_filterLabel(context, filter)),
                    onSelected: (_) => setState(() {
                      _filter = filter;
                      _selectedId = null;
                    }),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: KtSpacing.x3),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return selected == null
                    ? Center(child: Text(context.strings.text('u0163')))
                    : ListView(
                        padding: EdgeInsets.all(KtSpacing.x4),
                        children: [
                          _taskList(tasks),
                          SizedBox(height: KtSpacing.x4),
                          _taskDetail(
                            context,
                            selected,
                            controller,
                            account.id,
                            snapshot,
                          ),
                        ],
                      );
              }
              return Row(
                children: [
                  SizedBox(
                    width: 390,
                    child: Padding(
                      padding: EdgeInsets.all(KtSpacing.x4),
                      child: _taskList(tasks, scrollable: true),
                    ),
                  ),
                  VerticalDivider(width: 1),
                  Expanded(
                    child: selected == null
                        ? Center(child: Text(context.strings.text('u0163')))
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(KtSpacing.x5),
                            child: _taskDetail(
                              context,
                              selected,
                              controller,
                              account.id,
                              snapshot,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _taskList(List<FieldTaskEntry> tasks, {bool scrollable = false}) {
    if (tasks.isEmpty) {
      return KtCard(
        child: Padding(
          padding: EdgeInsets.all(KtSpacing.x5),
          child: Text(context.strings.text('u0164')),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: !scrollable,
      physics: scrollable ? null : NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final selected = task.incident.id == _selectedId;
        return Card(
          elevation: selected ? 2 : 0,
          child: ListTile(
            selected: selected,
            title: Text(context.strings.categoryLabel(task.incident.category)),
            subtitle: Text(
              '${task.operationalStatus?.name ?? context.strings.text('u0659')} · ${task.incident.responsibleUnitId}\n${task.sla.label}',
            ),
            isThreeLine: true,
            leading: Icon(
              task.overdue
                  ? Icons.timer_off_outlined
                  : Icons.engineering_outlined,
            ),
            trailing: task.reopenRequested
                ? Tooltip(
                    message: context.strings.text('u0310'),
                    child: Icon(Icons.replay_circle_filled_outlined),
                  )
                : null,
            onTap: () => setState(() => _selectedId = task.incident.id),
          ),
        );
      },
    );
  }

  Widget _taskDetail(
    BuildContext context,
    FieldTaskEntry task,
    SnapshotController controller,
    String actorId,
    AppSnapshotDto snapshot,
  ) {
    final incident = task.incident;
    final status = task.operationalStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.strings.format('u0366', {'incident': incident.id}),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: KtSpacing.x3),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(status?.name ?? 'durum yok')),
            Chip(label: Text(incident.responsibleUnitId ?? 'birim yok')),
            if (task.overdue) Chip(label: Text(context.strings.text('u0165'))),
            if (incident.workOrderRefs.isNotEmpty)
              Chip(
                label: Text(
                  context.strings.format('u0367', {
                    'source': incident.workOrderRefs.last.sourceSystem,
                    'workOrder':
                        incident.workOrderRefs.last.externalWorkOrderId,
                  }),
                ),
              ),
          ],
        ),
        SizedBox(height: KtSpacing.x3),
        KtCard(
          child: Padding(
            padding: EdgeInsets.all(KtSpacing.x4),
            child: Column(
              children: [
                _line(
                  context.strings.text('u0483'),
                  incident.assigneeId ?? context.strings.text('u0488'),
                ),
                _line(
                  context.strings.text('u0484'),
                  incident.fieldTeamId ?? context.strings.text('u0488'),
                ),
                _line(context.strings.text('u0485'), task.sla.label),
                _line(
                  context.strings.text('u0395'),
                  incident.slaTargetAt == null
                      ? context.strings.text('u0486')
                      : context.localeFormat.dateTime(incident.slaTargetAt!),
                ),
                if (incident.slaDelayReason != null)
                  _line(
                    context.strings.text('u0297'),
                    incident.slaDelayReason!,
                  ),
                if (incident.reestimatedMinAt != null &&
                    incident.reestimatedMaxAt != null)
                  _line(
                    context.strings.text('u0487'),
                    '${context.localeFormat.dateTime(incident.reestimatedMinAt!)} – ${context.localeFormat.dateTime(incident.reestimatedMaxAt!)} · ${context.strings.text('u0481')}',
                  ),
              ],
            ),
          ),
        ),
        if (task.reopenRequested) ...[
          SizedBox(height: KtSpacing.x3),
          KtBanner(
            title: context.strings.text('u0306'),
            message: context.strings.text('u0311'),
            tone: KtBannerTone.warning,
          ),
        ],
        SizedBox(height: KtSpacing.x4),
        TextField(
          controller: _reason,
          decoration: InputDecoration(labelText: context.strings.text('u0300')),
        ),
        SizedBox(height: KtSpacing.x3),
        if (status == ReportStatus.assignedUnit)
          FilledButton.icon(
            onPressed: controller.staffReadOnly
                ? null
                : () => _field(
                    controller,
                    actorId,
                    incident.id,
                    FieldOperationAction.assignField,
                    assigneeId: actorId,
                    fieldTeamId: 'field_team_demo_01',
                  ),
            icon: Icon(Icons.person_add_alt_1_outlined),
            label: Text(context.strings.text('u0166')),
          ),
        if (status == ReportStatus.fieldAssigned)
          FilledButton.icon(
            onPressed: controller.staffReadOnly
                ? null
                : () => _field(
                    controller,
                    actorId,
                    incident.id,
                    FieldOperationAction.startProgress,
                  ),
            icon: Icon(Icons.play_arrow_rounded),
            label: Text(context.strings.text('u0167')),
          ),
        if (status == ReportStatus.fieldAssigned ||
            status == ReportStatus.inProgress) ...[
          SizedBox(height: KtSpacing.x3),
          TextField(
            controller: _delay,
            decoration: InputDecoration(
              labelText: context.strings.text('u0301'),
            ),
          ),
          SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.staffReadOnly
                ? null
                : () => _field(
                    controller,
                    actorId,
                    incident.id,
                    FieldOperationAction.recordDelay,
                    delayReason: _delay.text,
                    reestimateMinMinutes: 60,
                    reestimateMaxMinutes: 180,
                  ),
            icon: Icon(Icons.update_rounded),
            label: Text(context.strings.text('u0168')),
          ),
        ],
        if (status == ReportStatus.inProgress) ...[
          SizedBox(height: KtSpacing.x4),
          TextField(
            controller: _resolution,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.strings.text('u0302'),
              helperText: context.strings.text('u0305'),
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _resolutionMediaId,
            decoration: InputDecoration(
              labelText: context.strings.text('u0303'),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(context.strings.text('u0169')),
              ),
              for (final media in snapshot.payload.media)
                if (media.privacyStatus == PrivacyStatus.safe &&
                    media.publicRef != null)
                  DropdownMenuItem<String>(
                    value: media.id,
                    child: Text(
                      context.strings.format('u0368', {'media': media.id}),
                    ),
                  ),
            ],
            onChanged: controller.staffReadOnly
                ? null
                : (value) => setState(() => _resolutionMediaId = value),
          ),
          SizedBox(height: 8),
          FilledButton.icon(
            onPressed:
                controller.staffReadOnly || _resolution.text.trim().isEmpty
                ? null
                : () => _field(
                    controller,
                    actorId,
                    incident.id,
                    FieldOperationAction.resolve,
                    resolutionExplanation: _resolution.text,
                    resolutionMediaId: _resolutionMediaId,
                  ),
            icon: Icon(Icons.task_alt_rounded),
            label: Text(context.strings.text('u0170')),
          ),
        ],
        if (status == ReportStatus.resolved &&
            incident.resolutionExplanation != null) ...[
          SizedBox(height: KtSpacing.x4),
          KtBanner(
            title: context.strings.text('u0227'),
            message: incident.resolutionExplanation!,
            tone: KtBannerTone.success,
          ),
        ],
      ],
    );
  }

  Future<void> _field(
    SnapshotController controller,
    String actorId,
    String incidentId,
    FieldOperationAction action, {
    String? assigneeId,
    String? fieldTeamId,
    String? delayReason,
    int? reestimateMinMinutes,
    int? reestimateMaxMinutes,
    String? resolutionExplanation,
    String? resolutionMediaId,
  }) async {
    await controller.fieldOperation(
      actorId: actorId,
      incidentId: incidentId,
      action: action,
      reason: _reason.text,
      assigneeId: assigneeId,
      fieldTeamId: fieldTeamId,
      delayReason: delayReason,
      reestimateMinMinutes: reestimateMinMinutes,
      reestimateMaxMinutes: reestimateMaxMinutes,
      resolutionExplanation: resolutionExplanation,
      resolutionMediaId: resolutionMediaId,
    );
    if (!mounted) return;
    setState(() {});
  }

  Widget _line(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  String _filterLabel(BuildContext context, FieldTaskFilter filter) =>
      switch (filter) {
        FieldTaskFilter.all => context.strings.text('u0649'),
        FieldTaskFilter.unassigned => context.strings.text('u0610'),
        FieldTaskFilter.mine => context.strings.text('u0611'),
        FieldTaskFilter.fieldAssigned => context.strings.text('u0612'),
        FieldTaskFilter.inProgress => context.strings.text('u0613'),
        FieldTaskFilter.overdue => context.strings.text('u0614'),
      };
}

final class WorkPlanningScreen extends StatefulWidget {
  WorkPlanningScreen({super.key});

  @override
  State<WorkPlanningScreen> createState() => _WorkPlanningScreenState();
}

final class _WorkPlanningScreenState extends State<WorkPlanningScreen>
    with WidgetsBindingObserver {
  final _category = TextEditingController(text: 'road_maintenance');
  final _latitude = TextEditingController(text: '41.0254');
  final _longitude = TextEditingController(text: '29.0152');
  final _radius = TextEditingController(text: '180');
  final _unit = TextEditingController(text: 'unit_road_maintenance');
  final _explanation = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  Timer? _autosave;
  String? _workId;
  bool _saving = false;
  bool _localizedPlanningDefaultApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedPlanningDefaultApplied) return;
    _explanation.text = context.strings.text('u0615');
    _localizedPlanningDefaultApplied = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now().toUtc();
    _start.text = now.add(Duration(hours: 2)).toIso8601String();
    _end.text = now.add(Duration(hours: 6)).toIso8601String();
    for (final controller in [
      _category,
      _latitude,
      _longitude,
      _radius,
      _unit,
      _explanation,
      _start,
      _end,
    ]) {
      controller.addListener(_scheduleAutosave);
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_reconcileClock()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_reconcileClock());
  }

  Future<void> _reconcileClock() async {
    if (!mounted) return;
    final actorId = context.read<SessionController>().principal?.account.id;
    final controller = context.read<SnapshotController>();
    if (actorId == null || controller.staffReadOnly) return;
    await controller.municipalWork(
      actorId: actorId,
      action: MunicipalWorkAction.reconcileClock,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosave?.cancel();
    for (final controller in [
      _category,
      _latitude,
      _longitude,
      _radius,
      _unit,
      _explanation,
      _start,
      _end,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scheduleAutosave() {
    _autosave?.cancel();
    _autosave = Timer(Duration(milliseconds: 700), () async {
      await _saveDraft(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null && controller.error == null) return LoadingView();
    if (snapshot == null) {
      return RecoverableErrorView(
        message: context.strings.text('u0312'),
        onRetry: () => unawaited(controller.refresh()),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final form = _form(context, controller);
        final map = _map(snapshot);
        if (constraints.maxWidth < 980) {
          return ListView(
            padding: EdgeInsets.all(KtSpacing.x5),
            children: [
              form,
              SizedBox(height: KtSpacing.x4),
              SizedBox(height: 360, child: map),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(
              width: constraints.maxWidth * 5 / 12,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(KtSpacing.x5),
                child: form,
              ),
            ),
            VerticalDivider(width: 1),
            Expanded(
              child: Padding(padding: EdgeInsets.all(KtSpacing.x4), child: map),
            ),
          ],
        );
      },
    );
  }

  Widget _form(BuildContext context, SnapshotController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.strings.text('u0171'),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      SizedBox(height: 4),
      Text(
        _workId == null
            ? context.strings.text('u0616')
            : context.strings.format('u0617', {'id': _workId}),
      ),
      SizedBox(height: KtSpacing.x4),
      _text(_category, context.strings.text('u0618')),
      Row(
        children: [
          Expanded(child: _text(_latitude, context.strings.text('u0619'))),
          SizedBox(width: 8),
          Expanded(child: _text(_longitude, context.strings.text('u0620'))),
        ],
      ),
      _text(_radius, context.strings.text('u0621')),
      _text(_start, context.strings.text('u0622')),
      _text(_end, context.strings.text('u0623')),
      _text(_unit, context.strings.text('u0624')),
      _text(_explanation, context.strings.text('u0625'), maxLines: 3),
      SizedBox(height: KtSpacing.x3),
      FilledButton.icon(
        onPressed: _saving || controller.staffReadOnly
            ? null
            : () => _saveDraft(silent: false),
        icon: Icon(Icons.save_outlined),
        label: Text(
          _saving
              ? context.strings.text('u0626')
              : context.strings.text('u0627'),
        ),
      ),
      SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _workId == null || controller.staffReadOnly
            ? null
            : _analyze,
        icon: Icon(Icons.analytics_outlined),
        label: Text(context.strings.text('u0172')),
      ),
      SizedBox(height: KtSpacing.x3),
      KtBanner(
        title: context.strings.text('u0307'),
        message: context.strings.text('u0313'),
        tone: KtBannerTone.info,
      ),
    ],
  );

  Widget _map(AppSnapshotDto snapshot) => ClipRRect(
    borderRadius: BorderRadius.circular(KtRadius.card),
    child: MapExperience(
      snapshot: snapshot,
      viewerId: context.watch<SessionController>().principal?.account.id,
      staff: true,
    ),
  );

  Widget _text(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => Padding(
    padding: EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Future<bool> _saveDraft({required bool silent}) async {
    if (_saving || !mounted) return false;
    final actorId = context.read<SessionController>().principal?.account.id;
    final controller = context.read<SnapshotController>();
    final lat = double.tryParse(_latitude.text);
    final lon = double.tryParse(_longitude.text);
    final radius = int.tryParse(_radius.text);
    final start = DateTime.tryParse(_start.text)?.toUtc();
    final end = DateTime.tryParse(_end.text)?.toUtc();
    if (actorId == null ||
        lat == null ||
        lon == null ||
        radius == null ||
        start == null ||
        end == null ||
        _category.text.trim().isEmpty ||
        _unit.text.trim().isEmpty ||
        _explanation.text.trim().isEmpty ||
        !end.isAfter(start)) {
      return false;
    }
    setState(() => _saving = true);
    final result = await controller.municipalWork(
      actorId: actorId,
      action: MunicipalWorkAction.saveDraft,
      workId: _workId,
      category: _category.text,
      latitude: lat,
      longitude: lon,
      startsAt: start,
      expectedEndsAt: end,
      responsibleUnitId: _unit.text,
      explanation: _explanation.text,
      areaRadiusMeters: radius,
    );
    if (!mounted) return false;
    setState(() {
      _saving = false;
      _workId = result?.resourceId ?? _workId;
    });
    if (!silent && result == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.strings.text('u0173'))));
    }
    return result != null;
  }

  Future<void> _analyze() async {
    final saved = await _saveDraft(silent: true);
    if (!saved || !mounted || _workId == null) return;
    final actorId = context.read<SessionController>().principal!.account.id;
    final result = await context.read<SnapshotController>().municipalWork(
      actorId: actorId,
      action: MunicipalWorkAction.analyzeImpact,
      workId: _workId,
    );
    if (!mounted || result == null) return;
    context.go('/staff/planning/${result.resourceId}/impact');
  }
}

final class WorkImpactScreen extends StatelessWidget {
  WorkImpactScreen({required this.workId, super.key});
  final String workId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null) return LoadingView();
    final work = snapshot.payload.municipalWorks
        .where((item) => item.id == workId)
        .firstOrNull;
    if (work == null) return Center(child: Text(context.strings.text('u0174')));
    final impact = work.impact;
    return ListView(
      padding: EdgeInsets.all(KtSpacing.x5),
      children: [
        Text(
          context.strings.text('u0175'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 4),
        Text(
          context.strings.format('u0369', {'explanation': work.explanation}),
        ),
        SizedBox(height: KtSpacing.x4),
        if (impact == null)
          KtBanner(
            title: context.strings.text('u0308'),
            message: context.strings.text('u0314'),
            tone: KtBannerTone.warning,
          )
        else ...[
          KtBanner(
            title: context.strings.format('u0462', {
              'count': impact.overlaps.length,
            }),
            message: impact.explanation,
            tone: KtBannerTone.info,
          ),
          SizedBox(height: KtSpacing.x4),
          Text(
            context.strings.text('u0176'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KtRadius.card),
              child: MapExperience(
                snapshot: snapshot,
                viewerId: context
                    .watch<SessionController>()
                    .principal
                    ?.account
                    .id,
                staff: true,
                previewPins: [
                  VisibleMapPin(
                    id: 'draft_preview_${work.id}',
                    kind: PinKind.publishedPlanned,
                    category: work.category,
                    latitude: work.latitude,
                    longitude: work.longitude,
                    locationLabel: context.strings.text('u0628'),
                    sourceLabel: context.strings.text('u0629'),
                    verified: false,
                    updatedAt: impact.analyzedAt,
                    responsibleUnitId: work.responsibleUnitId,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: KtSpacing.x4),
          Text(
            context.strings.text('u0177'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ListTile(
            leading: Icon(Icons.play_circle_outline),
            title: Text(context.strings.text('u0178')),
            subtitle: Text(context.localeFormat.dateTime(work.startsAt)),
          ),
          ListTile(
            leading: Icon(Icons.stop_circle_outlined),
            title: Text(context.strings.text('u0179')),
            subtitle: Text(context.localeFormat.dateTime(work.expectedEndsAt)),
          ),
          SizedBox(height: KtSpacing.x3),
          Text(
            context.strings.text('u0180'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...impact.affectedRoadSegments.map(
            (item) => ListTile(
              leading: Icon(Icons.route_outlined),
              title: Text(item),
            ),
          ),
          ...impact.affectedTransitLines.map(
            (item) => ListTile(
              leading: Icon(Icons.directions_transit_outlined),
              title: Text(item),
            ),
          ),
          SizedBox(height: KtSpacing.x3),
          Text(
            context.strings.text('u0181'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final overlap in impact.overlaps)
            ListTile(
              leading: Icon(Icons.compare_arrows_rounded),
              title: Text(
                overlap.body['sourceLabel']?.toString() ?? overlap.id,
              ),
              subtitle: Text(overlap.body['explanation']?.toString() ?? ''),
            ),
          SizedBox(height: KtSpacing.x3),
          Text(
            context.strings.text('u0182'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...impact.suggestions.map(
            (item) => ListTile(
              leading: Icon(Icons.lightbulb_outline),
              title: Text(item),
            ),
          ),
          SizedBox(height: KtSpacing.x3),
          KtCard(
            child: Padding(
              padding: EdgeInsets.all(KtSpacing.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.text('u0183'),
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(impact.citizenInformationDraft),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: KtSpacing.x4),
        FilledButton(
          onPressed:
              impact == null ||
                  work.status != WorkStatus.impactReady ||
                  controller.staffReadOnly
              ? null
              : () async {
                  final actorId = context
                      .read<SessionController>()
                      .principal!
                      .account
                      .id;
                  final result = await controller.municipalWork(
                    actorId: actorId,
                    action: MunicipalWorkAction.markReviewReady,
                    workId: work.id,
                  );
                  if (context.mounted && result != null)
                    context.go('/staff/planning/${work.id}/review');
                },
          child: Text(context.strings.text('u0184')),
        ),
      ],
    );
  }
}

final class WorkReviewScreen extends StatefulWidget {
  WorkReviewScreen({required this.workId, super.key});
  final String workId;

  @override
  State<WorkReviewScreen> createState() => _WorkReviewScreenState();
}

final class _WorkReviewScreenState extends State<WorkReviewScreen> {
  final _publicText = TextEditingController();
  bool _approved = false;
  bool _initializedText = false;

  @override
  void initState() {
    super.initState();
    _publicText.addListener(_refreshPublishAction);
  }

  void _refreshPublishAction() {
    if (mounted && _initializedText) setState(() {});
  }

  @override
  void dispose() {
    _publicText.removeListener(_refreshPublishAction);
    _publicText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null) return LoadingView();
    final work = snapshot.payload.municipalWorks
        .where((item) => item.id == widget.workId)
        .firstOrNull;
    if (work == null) return Center(child: Text(context.strings.text('u0174')));
    if (!_initializedText) {
      _publicText.text =
          work.publicInformationText ??
          work.impact?.citizenInformationDraft ??
          '';
      _initializedText = true;
    }
    return ListView(
      padding: EdgeInsets.all(KtSpacing.x5),
      children: [
        Text(
          context.strings.text('u0185'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 4),
        Text(context.strings.text('u0186')),
        SizedBox(height: KtSpacing.x4),
        KtCard(
          child: Padding(
            padding: EdgeInsets.all(KtSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    KtMapPin(
                      kind: PinKind.publishedPlanned,
                      category: context.strings.categoryLabel(work.category),
                      location:
                          '${context.localeFormat.number(work.latitude, fractionDigits: 5)}, ${context.localeFormat.number(work.longitude, fractionDigits: 5)}',
                      selected: true,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.strings.text('u0187'),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            context.strings.categoryLabel(work.category),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  context.strings.format('u0370', {
                    'start': context.localeFormat.dateTime(work.startsAt),
                    'end': context.localeFormat.dateTime(work.expectedEndsAt),
                  }),
                ),
                SizedBox(height: 8),
                Text(
                  context.strings.format('u0353', {
                    'unit': work.responsibleUnitId,
                  }),
                ),
                SizedBox(height: 8),
                Text(
                  context.strings.format('u0371', {
                    'count': work.impact?.overlaps.length ?? 0,
                  }),
                ),
                Text(
                  context.strings.text('u0188'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _publicText,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: context.strings.text('u0304'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: KtSpacing.x3),
        CheckboxListTile(
          value: _approved,
          onChanged: (value) => setState(() => _approved = value ?? false),
          title: Text(context.strings.text('u0189')),
          subtitle: Text(context.strings.text('u0190')),
        ),
        FilledButton.icon(
          onPressed:
              work.status != WorkStatus.reviewReady ||
                  !_approved ||
                  _publicText.text.trim().isEmpty ||
                  controller.staffReadOnly
              ? null
              : () async {
                  final actorId = context
                      .read<SessionController>()
                      .principal!
                      .account
                      .id;
                  final result = await controller.municipalWork(
                    actorId: actorId,
                    action: MunicipalWorkAction.publish,
                    workId: work.id,
                    publicInformationText: _publicText.text,
                    publicPreviewApproved: true,
                  );
                  if (!context.mounted || result == null) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.strings.text('u0191'))),
                  );
                  context.go('/staff/planning');
                },
          icon: Icon(Icons.publish_rounded),
          label: Text(context.strings.text('u0192')),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
