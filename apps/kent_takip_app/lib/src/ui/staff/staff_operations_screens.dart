import 'dart:async';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/locale_formatter.dart';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart' hide SnapshotController;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/states.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_app/src/ui/map/map_experience.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

String _humanize(String value) => value
  .replaceAll('_', ' ')
  .replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (match) => ' ${match.group(1)}')
  .trim()
  .split(' ')
  .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
  .join(' ');

final class StaffOperationsDashboardScreen extends StatelessWidget {
  StaffOperationsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null && controller.error == null) return LoadingView();
    if (snapshot == null) {
      return RecoverableErrorView(
        message: context.strings.text('u0431'),
        onRetry: () => unawaited(controller.refresh()),
      );
    }
    final now = DateTime.now().toUtc();
    final projection = StaffOperationsProjectionIndex(snapshot);
    final metrics = projection.dashboard(now);
    final review = <StaffQueueEntry>[];
    for (final type in [
      ReviewQueueType.critical,
      ReviewQueueType.high,
      ReviewQueueType.normal,
    ]) {
      review.addAll(
        projection.queue(
          type,
          now: now,
          filters: StaffQueueFilters(pageSize: 10),
        ).items,
      );
    }
    final seen = <String>{};
    final uniqueReview = review.where((entry) => seen.add(entry.report.id)).take(8).toList();

    return ListView(
      padding: EdgeInsets.all(KtSpacing.x6),
      children: [
        Text(context.strings.text('u0067'), style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(height: KtSpacing.x1),
        Text(context.strings.text('u0068'),
        ),
        SizedBox(height: KtSpacing.x4),
        _OperationalBanners(controller: controller),
        SizedBox(height: KtSpacing.x4),
        Wrap(
          spacing: KtSpacing.x3,
          runSpacing: KtSpacing.x3,
          children: [
            _MetricTile(label: context.strings.text('u0415'), value: metrics.activeIncidentCount, icon: Icons.location_on_outlined),
            _MetricTile(label: context.strings.text('u0187'), value: metrics.plannedWorkCount, icon: Icons.construction_outlined),
            _MetricTile(label: context.strings.text('u0437'), value: metrics.staleSourceCount, icon: Icons.schedule_outlined),
            _MetricTile(label: context.strings.text('u0438'), value: metrics.unavailableSourceCount, icon: Icons.cloud_off_outlined),
            _MetricTile(label: context.strings.text('u0439'), valueText: _duration(context, metrics.oldestReviewAge), icon: Icons.hourglass_bottom_rounded),
            _MetricTile(label: context.strings.text('u0440'), valueText: metrics.firstReviewMedian == null ? '—' : _duration(context, metrics.firstReviewMedian!), icon: Icons.fact_check_outlined),
            _MetricTile(label: context.strings.text('u0441'), valueText: metrics.routingMedian == null ? '—' : _duration(context, metrics.routingMedian!), icon: Icons.alt_route_rounded),
            _MetricTile(label: context.strings.text('u0442'), valueText: metrics.resolutionMedian == null ? '—' : _duration(context, metrics.resolutionMedian!), icon: Icons.task_alt_rounded),
          ],
        ),
        SizedBox(height: KtSpacing.x6),
        Text(context.strings.text('u0059'), style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: KtSpacing.x3),
        Wrap(
          spacing: KtSpacing.x3,
          runSpacing: KtSpacing.x3,
          children: [
            for (final type in ReviewQueueType.values)
              _QueueCard(
                type: type,
                count: metrics.count(type),
                onTap: () => context.go('/staff/queues/${type.name}'),
              ),
          ],
        ),
        SizedBox(height: KtSpacing.x6),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(KtSpacing.x4),
                child: Text(context.strings.text('u0069'), style: Theme.of(context).textTheme.titleLarge),
              ),
              Divider(height: 1),
              if (uniqueReview.isEmpty)
                Padding(
                  padding: EdgeInsets.all(KtSpacing.x6),
                  child: Text(context.strings.text('u0070')),
                )
              else
                for (final entry in uniqueReview)
                  KtQueueRow(
                    title: _humanize(entry.report.category),
                    subtitle: '${entry.report.trackingNumber} · ${_duration(context, entry.age)}',
                    status: _queueLabel(context, entry.queues.first),
                    statusIcon: _queueIcon(entry.queues.first),
                    onTap: () => context.go('/staff/queues/${entry.queues.first.name}?selected=${entry.report.id}'),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}


final class StaffReportWorkspaceScreen extends StatelessWidget {
  StaffReportWorkspaceScreen({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return StaffOperationsQueueScreen(
      queueType: ReviewQueueType.normal,
      initialQuery: {'selected': reportId},
    );
  }
}

final class StaffOperationsQueueScreen extends StatefulWidget {
  StaffOperationsQueueScreen({
    required this.queueType,
    required this.initialQuery,
    super.key,
  });

  final ReviewQueueType queueType;
  final Map<String, String> initialQuery;

  @override
  State<StaffOperationsQueueScreen> createState() => _StaffOperationsQueueScreenState();
}

final class _StaffOperationsQueueScreenState extends State<StaffOperationsQueueScreen> {
  final _search = TextEditingController();
  final _reason = TextEditingController();
  final _additionalInfo = TextEditingController();
  final _decisionFocus = FocusNode();

  String? _selectedReportId;
  String? _category;
  String _unit = 'unit_road_maintenance';
  String _district = 'district_municipality_demo';
  String? _mergeTarget;
  String _decisionReasonCode = StaffDecisionReasonCodes.insufficientEvidence;
  String? _filterCategory;
  String? _filterUnit;
  int? _minDuplicateConfidence;
  RiskLevel? _risk;
  ReportStatus? _status;
  StaffQueueSort _sort = StaffQueueSort.priorityOldest;
  int _page = 1;
  bool _publicPreviewApproved = false;

  @override
  void initState() {
    super.initState();
    final query = widget.initialQuery;
    _search.text = query['q'] ?? '';
    _selectedReportId = query['selected'];
    _filterCategory = query['category'];
    _filterUnit = query['unit'];
    _minDuplicateConfidence = int.tryParse(query['duplicateMin'] ?? '');
    _risk = _enumByName(RiskLevel.values, query['risk']);
    _status = _enumByName(ReportStatus.values, query['status']);
    _sort = _enumByName(StaffQueueSort.values, query['sort']) ?? StaffQueueSort.priorityOldest;
    _page = int.tryParse(query['page'] ?? '') ?? 1;
  }

  @override
  void didUpdateWidget(covariant StaffOperationsQueueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queueType != widget.queueType) {
      _selectedReportId = null;
      _page = 1;
      _publicPreviewApproved = false;
      _reason.clear();
      _additionalInfo.clear();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _reason.dispose();
    _additionalInfo.dispose();
    _decisionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null && controller.error == null) return LoadingView();
    if (snapshot == null) {
      return RecoverableErrorView(
        message: context.strings.text('u0432'),
        onRetry: () => unawaited(controller.refresh()),
      );
    }
    final now = DateTime.now().toUtc();
    final projection = StaffOperationsProjectionIndex(snapshot);
    final page = projection.queue(
      widget.queueType,
      now: now,
      filters: StaffQueueFilters(
        search: _search.text,
        category: _filterCategory,
        riskLevel: _risk,
        status: _status,
        unitId: _filterUnit,
        minDuplicateConfidence: _minDuplicateConfidence,
        sort: _sort,
        page: _page,
        pageSize: 50,
      ),
    );
    final selected = _selectedReportId == null
        ? null
        : projection.entryByReportId(_selectedReportId!, now: now);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.keyJ): () => _moveSelection(page, 1),
        SingleActivator(LogicalKeyboardKey.arrowDown): () => _moveSelection(page, 1),
        SingleActivator(LogicalKeyboardKey.keyK): () => _moveSelection(page, -1),
        SingleActivator(LogicalKeyboardKey.arrowUp): () => _moveSelection(page, -1),
        SingleActivator(LogicalKeyboardKey.enter): _decisionFocus.requestFocus,
        SingleActivator(LogicalKeyboardKey.escape): _clearSelection,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            _OperationalBanners(controller: controller),
            _QueueSwitcher(selected: widget.queueType),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= KtBreakpoints.expandedSidebar) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 260, child: _filterPanel()),
                        VerticalDivider(width: 1),
                        SizedBox(width: 440, child: _queuePanel(page)),
                        VerticalDivider(width: 1),
                        Expanded(child: _detailPanel(selected, controller, snapshot, page)),
                      ],
                    );
                  }
                  if (constraints.maxWidth >= KtBreakpoints.twoPanel) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 380, child: _queuePanel(page, includeFilters: true)),
                        VerticalDivider(width: 1),
                        Expanded(child: _detailPanel(selected, controller, snapshot, page)),
                      ],
                    );
                  }
                  return _mobilePanel(page, selected, controller, snapshot);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobilePanel(
    StaffQueuePage page,
    StaffQueueEntry? selected,
    SnapshotController controller,
    AppSnapshotDto snapshot,
  ) {
    if (selected != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _clearSelection,
              icon: Icon(Icons.arrow_back_rounded),
              label: Text(context.strings.text('u0071')),
            ),
          ),
          Expanded(child: _detailPanel(selected, controller, snapshot, page)),
        ],
      );
    }
    return _queuePanel(page, includeFilters: true);
  }

  Widget _filterPanel() {
    return ListView(
      padding: EdgeInsets.all(KtSpacing.x4),
      children: [
        Text(context.strings.text('u0072'), style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: KtSpacing.x3),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: context.strings.text('u0266'),
            hintText: context.strings.text('u0264'),
            prefixIcon: Icon(Icons.search_rounded),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _filtersChanged(),
        ),
        SizedBox(height: KtSpacing.x3),
        DropdownButtonFormField<String?>(
          key: ValueKey('filter-category-$_filterCategory'),
          initialValue: _filterCategory,
          decoration: InputDecoration(labelText: context.strings.text('u0267')),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(context.strings.text('u0026'))),
            DropdownMenuItem<String?>(value: 'road_surface_damage', child: Text(context.strings.text('u0073'))),
            DropdownMenuItem<String?>(value: 'traffic_signal', child: Text(context.strings.text('u0074'))),
            DropdownMenuItem<String?>(value: 'water_infrastructure', child: Text(context.strings.text('u0075'))),
            DropdownMenuItem<String?>(value: 'lighting', child: Text(context.strings.text('u0054'))),
          ],
          onChanged: (value) {
            _filterCategory = value;
            _filtersChanged();
          },
        ),
        SizedBox(height: KtSpacing.x3),
        DropdownButtonFormField<RiskLevel?>(
          initialValue: _risk,
          decoration: InputDecoration(labelText: context.strings.text('u0268')),
          items: [
            DropdownMenuItem<RiskLevel?>(value: null, child: Text(context.strings.text('u0026'))),
            ...RiskLevel.values.map((v) => DropdownMenuItem<RiskLevel?>(value: v, child: Text(_humanize(v.name)))),
          ],
          onChanged: (value) {
            _risk = value;
            _filtersChanged();
          },
        ),
        SizedBox(height: KtSpacing.x3),
        DropdownButtonFormField<ReportStatus?>(
          initialValue: _status,
          decoration: InputDecoration(labelText: context.strings.text('u0127')),
          items: [
            DropdownMenuItem<ReportStatus?>(value: null, child: Text(context.strings.text('u0026'))),
            ...ReportStatus.values.map((v) => DropdownMenuItem<ReportStatus?>(value: v, child: Text(_humanize(v.name)))),
          ],
          onChanged: (value) {
            _status = value;
            _filtersChanged();
          },
        ),
        SizedBox(height: KtSpacing.x3),
        DropdownButtonFormField<String?>(
          key: ValueKey('filter-unit-$_filterUnit'),
          initialValue: _filterUnit,
          decoration: InputDecoration(labelText: context.strings.text('u0269')),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(context.strings.text('u0026'))),
            DropdownMenuItem<String?>(value: 'unit_road_maintenance', child: Text(context.strings.text('u0055'))),
            DropdownMenuItem<String?>(value: 'unit_traffic', child: Text(context.strings.text('u0056'))),
            DropdownMenuItem<String?>(value: 'unit_water_operations', child: Text(context.strings.text('u0057'))),
            DropdownMenuItem<String?>(value: 'district_beyoglu', child: Text(context.strings.text('u0076'))),
            DropdownMenuItem<String?>(value: 'district_uskudar', child: Text(context.strings.text('u0077'))),
          ],
          onChanged: (value) {
            _filterUnit = value;
            _filtersChanged();
          },
        ),
        SizedBox(height: KtSpacing.x3),
        DropdownButtonFormField<int?>(
          key: ValueKey('filter-duplicate-$_minDuplicateConfidence'),
          initialValue: _minDuplicateConfidence,
          decoration: InputDecoration(labelText: context.strings.text('u0270')),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(context.strings.text('u0026'))),
            DropdownMenuItem<int?>(value: 25, child: Text(context.strings.text('u0078'))),
            DropdownMenuItem<int?>(value: 50, child: Text(context.strings.text('u0079'))),
            DropdownMenuItem<int?>(value: 75, child: Text(context.strings.text('u0080'))),
          ],
          onChanged: (value) {
            _minDuplicateConfidence = value;
            _filtersChanged();
          },
        ),
        SizedBox(height: KtSpacing.x3),
        DropdownButtonFormField<StaffQueueSort>(
          initialValue: _sort,
          decoration: InputDecoration(labelText: context.strings.text('u0271')),
          items: StaffQueueSort.values
              .map((v) => DropdownMenuItem(value: v, child: Text(_sortLabel(context, v))))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            _sort = value;
            _filtersChanged();
          },
        ),
        SizedBox(height: KtSpacing.x3),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _search.clear();
              _filterCategory = null;
              _filterUnit = null;
              _minDuplicateConfidence = null;
              _risk = null;
              _status = null;
              _sort = StaffQueueSort.priorityOldest;
              _page = 1;
            });
            _syncUrl();
          },
          icon: Icon(Icons.filter_alt_off_outlined),
          label: Text(context.strings.text('u0081')),
        ),
      ],
    );
  }

  Widget _queuePanel(StaffQueuePage page, {bool includeFilters = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeFilters)
          ExpansionTile(
            title: Text(context.strings.text('u0082')),
            leading: Icon(Icons.tune_rounded),
            children: [SizedBox(height: 420, child: _filterPanel())],
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(KtSpacing.x4, KtSpacing.x3, KtSpacing.x4, KtSpacing.x2),
          child: Row(
            children: [
              Expanded(child: Text('${_queueLabel(context, widget.queueType)} · ${page.total}', style: Theme.of(context).textTheme.titleMedium)),
              Text(context.strings.format('u0335', {'page': page.page, 'pages': page.totalPages})),
            ],
          ),
        ),
        Divider(height: 1),
        Expanded(
          child: page.items.isEmpty
              ? EmptyView(
                  title: context.strings.text('u0284'),
                  description: context.strings.text('u0449'),
                )
              : ListView.builder(
                  key: PageStorageKey('queue-${widget.queueType.name}'),
                  itemCount: page.items.length,
                  itemExtent: 84,
                  itemBuilder: (context, index) {
                    final entry = page.items[index];
                    final locked = entry.lease != null;
                    return KtQueueRow(
                      title: _humanize(entry.report.category),
                      subtitle: '${entry.report.trackingNumber} · ${_duration(context, entry.age)}${locked ? ' · ${context.strings.text('u0592')}' : ''}',
                      status: _humanize(entry.report.status.name),
                      statusIcon: locked ? Icons.lock_outline_rounded : _queueIcon(widget.queueType),
                      selected: _selectedReportId == entry.report.id,
                      onTap: () => _select(entry),
                    );
                  },
                ),
        ),
        Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(KtSpacing.x2),
          child: Row(
            children: [
              IconButton(
                tooltip: context.strings.text('u0280'),
                onPressed: page.page > 1 ? () => _setPage(page.page - 1) : null,
                icon: Icon(Icons.chevron_left_rounded),
              ),
              Spacer(),
              Text(context.strings.format('u0336', {'count': page.total})),
              Spacer(),
              IconButton(
                tooltip: context.strings.text('u0281'),
                onPressed: page.page < page.totalPages ? () => _setPage(page.page + 1) : null,
                icon: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reportMap(AppSnapshotDto snapshot, StaffQueueEntry entry) {
    final session = context.watch<SessionController>();
    final visible = DemoProjections.visiblePins(
      snapshot,
      viewerId: session.principal?.account.id,
      staff: true,
      nowUtc: DateTime.now().toUtc(),
    );
    final ids = <String>{
      entry.report.id,
      if (entry.report.linkedIncidentId != null) entry.report.linkedIncidentId!,
    };
    final pins = visible.where((pin) => ids.contains(pin.id)).toList(growable: false);
    return SizedBox(
      height: 240,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KtRadius.control),
        child: MapSurface(
          pins: pins,
          alerts: [],
          showTraffic: false,
          onSelected: (_) {},
          viewCommand: 0,
          onViewportSettled: (_, __) {},
        ),
      ),
    );
  }

  Widget _detailPanel(
    StaffQueueEntry? entry,
    SnapshotController controller,
    AppSnapshotDto snapshot,
    StaffQueuePage page,
  ) {
    if (entry == null) {
      return EmptyView(
        title: context.strings.text('u0285'),
        description: context.strings.text('u0450'),
      );
    }
    final session = context.watch<SessionController>();
    final actorId = session.principal?.account.id;
    final lease = entry.lease;
    final hasLease = lease != null && lease.lockedBy == actorId && lease.activeAt(DateTime.now().toUtc());
    final lockedByOther = lease != null && lease.lockedBy != actorId && lease.activeAt(DateTime.now().toUtc());
    final canOriginal = session.can(Permission.viewOriginalMedia);
    final report = entry.report;
    final categories = <String>{
      report.category,
      'road_surface_damage',
      'traffic_signal',
      'water_infrastructure',
      'lighting',
    }.toList();
    _category ??= report.category;
    if (!categories.contains(_category)) _category = report.category;

    return ListView(
      padding: EdgeInsets.all(KtSpacing.x5),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_humanize(report.category), style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: KtSpacing.x1),
                  SelectableText(
                    context.strings.format('u0357', {'tracking': report.trackingNumber, 'queue': _queueLabel(context, widget.queueType), 'status': _humanize(report.status.name), 'age': _duration(context, entry.age), 'revision': snapshot.revision}),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.strings.text('u0282'),
              onPressed: page.items.isEmpty ? null : () => _moveSelection(page, -1),
              icon: Icon(Icons.keyboard_arrow_up_rounded),
            ),
            IconButton(
              tooltip: context.strings.text('u0283'),
              onPressed: page.items.isEmpty ? null : () => _moveSelection(page, 1),
              icon: Icon(Icons.keyboard_arrow_down_rounded),
            ),
            KtStatusChip(
              label: _humanize(report.riskLevel.name),
              icon: report.riskLevel == RiskLevel.criticalSignal ? Icons.crisis_alert_rounded : Icons.flag_outlined,
              tone: report.riskLevel == RiskLevel.criticalSignal ? KtStatusTone.danger : KtStatusTone.warning,
            ),
          ],
        ),
        SizedBox(height: KtSpacing.x4),
        if (lockedByOther)
          KtBanner(
            title: context.strings.text('u0286'),
            message: context.strings.format('u0456', {'actor': lease.lockedBy, 'time': context.localeFormat.dateTime(lease.expiresAt)}),
            tone: KtBannerTone.warning,
            action: session.role == UserRole.demoSupervisor || session.role == UserRole.systemAdmin
                ? KtButton(
                    label: context.strings.text('u0443'),
                    kind: KtButtonKind.text,
                    onPressed: () => unawaited(_takeOver(report.id)),
                  )
                : null,
          )
        else if (!hasLease)
          KtBanner(
            title: context.strings.text('u0287'),
            message: context.strings.text('u0433'),
            tone: KtBannerTone.info,
            action: KtButton(
              label: context.strings.text('u0444'),
              kind: KtButtonKind.text,
              onPressed: controller.staffReadOnly ? null : () => unawaited(_acquireLease(report.id)),
            ),
          )
        else
          KtBanner(
            title: context.strings.text('u0288'),
            message: context.strings.format('u0457', {'time': context.localeFormat.dateTime(lease.expiresAt)}),
            tone: KtBannerTone.success,
            action: KtButton(
              label: context.strings.text('u0445'),
              kind: KtButtonKind.text,
              onPressed: () => unawaited(_releaseLease(report.id)),
            ),
          ),
        SizedBox(height: KtSpacing.x4),
        _SectionCard(
          title: context.strings.text('u0289'),
          icon: Icons.description_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_descriptionFromAudit(snapshot, report) ?? context.strings.text('u0565')),
              SizedBox(height: KtSpacing.x3),
              SelectableText(context.strings.format('u0358', {'lat': context.localeFormat.number(report.latitude, fractionDigits: 5), 'lon': context.localeFormat.number(report.longitude, fractionDigits: 5)})),
              SizedBox(height: KtSpacing.x3),
              _reportMap(snapshot, entry),
            ],
          ),
        ),
        SizedBox(height: KtSpacing.x3),
        _MediaCard(entry: entry, canOriginal: canOriginal),
        SizedBox(height: KtSpacing.x3),
        _AiCard(analysis: entry.analysis),
        SizedBox(height: KtSpacing.x3),
        _SourceCard(entry: entry, snapshot: snapshot),
        SizedBox(height: KtSpacing.x3),
        _SimilarReportsCard(report: report, snapshot: snapshot),
        SizedBox(height: KtSpacing.x3),
        _HistoryCard(report: report, snapshot: snapshot, canAudit: session.can(Permission.viewAudit)),
        SizedBox(height: KtSpacing.x3),
        _IncidentCard(entry: entry, snapshot: snapshot),
        SizedBox(height: KtSpacing.x3),
        _PublicPreviewCard(entry: entry),
        SizedBox(height: KtSpacing.x4),
        Focus(
          focusNode: _decisionFocus,
          child: _decisionPanel(
            entry: entry,
            snapshot: snapshot,
            enabled: hasLease && !controller.staffReadOnly && !controller.busy,
            categories: categories,
          ),
        ),
      ],
    );
  }

  Widget _decisionPanel({
    required StaffQueueEntry entry,
    required AppSnapshotDto snapshot,
    required bool enabled,
    required List<String> categories,
  }) {
    final report = entry.report;
    final preDecision = report.status != ReportStatus.assignedUnit;
    final mergeCandidates = snapshot.payload.reports
        .where((item) => item.id != report.id && !{ReportStatus.rejected, ReportStatus.outOfScope}.contains(item.status))
        .toList();
    if (_mergeTarget != null && !mergeCandidates.any((item) => item.id == _mergeTarget)) {
      _mergeTarget = null;
    }
    CitizenReportDto? selectedMergeCandidate;
    if (_mergeTarget != null) {
      for (final candidate in mergeCandidates) {
        if (candidate.id == _mergeTarget) selectedMergeCandidate = candidate;
      }
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.all(KtSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.strings.text('u0083'), style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: KtSpacing.x2),
            Text(context.strings.text('u0084')),
            SizedBox(height: KtSpacing.x4),
            DropdownButtonFormField<String>(
              key: ValueKey('category-${report.id}-$_category'),
              initialValue: _category,
              decoration: InputDecoration(labelText: context.strings.text('u0235')),
              items: categories.map((value) => DropdownMenuItem(value: value, child: Text(_humanize(value)))).toList(),
              onChanged: enabled ? (value) => setState(() => _category = value) : null,
            ),
            SizedBox(height: KtSpacing.x3),
            DropdownButtonFormField<String>(
              key: ValueKey('unit-${report.id}-$_unit'),
              initialValue: _unit,
              decoration: InputDecoration(labelText: context.strings.text('u0272')),
              items: [
                DropdownMenuItem(value: 'unit_road_maintenance', child: Text(context.strings.text('u0055'))),
                DropdownMenuItem(value: 'unit_traffic', child: Text(context.strings.text('u0056'))),
                DropdownMenuItem(value: 'unit_water_operations', child: Text(context.strings.text('u0057'))),
              ],
              onChanged: enabled ? (value) => setState(() => _unit = value ?? _unit) : null,
            ),
            SizedBox(height: KtSpacing.x3),
            TextField(
              controller: _reason,
              enabled: enabled,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.strings.text('u0273'),
                hintText: context.strings.text('u0265'),
              ),
            ),
            if (preDecision) ...[
              SizedBox(height: KtSpacing.x3),
              DropdownButtonFormField<String>(
                key: ValueKey('reason-code-${report.id}-$_decisionReasonCode'),
                initialValue: _decisionReasonCode,
                decoration: InputDecoration(labelText: context.strings.text('u0274')),
                items: [
                  DropdownMenuItem(value: StaffDecisionReasonCodes.insufficientEvidence, child: Text(context.strings.text('u0085'))),
                  DropdownMenuItem(value: StaffDecisionReasonCodes.notMunicipalScope, child: Text(context.strings.text('u0086'))),
                  DropdownMenuItem(value: StaffDecisionReasonCodes.privateProperty, child: Text(context.strings.text('u0087'))),
                  DropdownMenuItem(value: StaffDecisionReasonCodes.outsideServiceBoundary, child: Text(context.strings.text('u0088'))),
                  DropdownMenuItem(value: StaffDecisionReasonCodes.invalidOrAbusive, child: Text(context.strings.text('u0089'))),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _decisionReasonCode = value ?? _decisionReasonCode)
                    : null,
              ),
            ],
            if (preDecision) ...[
              SizedBox(height: KtSpacing.x3),
              CheckboxListTile(
                value: _publicPreviewApproved,
                contentPadding: EdgeInsets.zero,
                onChanged: enabled ? (value) => setState(() => _publicPreviewApproved = value ?? false) : null,
                title: Text(context.strings.text('u0090')),
                subtitle: Text(context.strings.text('u0091')),
              ),
            ],
            SizedBox(height: KtSpacing.x2),
            Wrap(
              spacing: KtSpacing.x2,
              runSpacing: KtSpacing.x2,
              children: [
                if (preDecision)
                  FilledButton.icon(
                    onPressed: enabled ? () => unawaited(_verify(entry)) : null,
                    icon: Icon(Icons.verified_rounded),
                    label: Text(context.strings.text('u0092')),
                  ),
                if (preDecision)
                  OutlinedButton.icon(
                    onPressed: enabled ? () => unawaited(_decision(entry, StaffDecisionAction.reject)) : null,
                    icon: Icon(Icons.cancel_outlined),
                    label: Text(context.strings.text('u0093')),
                  ),
                if (preDecision)
                  OutlinedButton.icon(
                    onPressed: enabled ? () => unawaited(_decision(entry, StaffDecisionAction.outOfScope)) : null,
                    icon: Icon(Icons.not_listed_location_outlined),
                    label: Text(context.strings.text('u0094')),
                  ),
                if (!preDecision)
                  OutlinedButton.icon(
                    onPressed: enabled ? () => unawaited(_decision(entry, StaffDecisionAction.routeToUnit, targetId: _unit)) : null,
                    icon: Icon(Icons.alt_route_rounded),
                    label: Text(context.strings.text('u0095')),
                  ),
                if (!preDecision)
                  OutlinedButton.icon(
                    onPressed: enabled ? () => unawaited(_decision(entry, StaffDecisionAction.transferBack)) : null,
                    icon: Icon(Icons.undo_rounded),
                    label: Text(context.strings.text('u0096')),
                  ),
              ],
            ),
            if (preDecision) ...[
              Divider(height: KtSpacing.x8),
              TextField(
                controller: _additionalInfo,
                enabled: enabled,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(labelText: context.strings.text('u0275')),
              ),
              SizedBox(height: KtSpacing.x2),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: enabled
                      ? () => unawaited(_decision(
                            entry,
                            StaffDecisionAction.requestAdditionalInfo,
                            message: _additionalInfo.text,
                          ))
                      : null,
                  icon: Icon(Icons.question_answer_outlined),
                  label: Text(context.strings.text('u0097')),
                ),
              ),
              Divider(height: KtSpacing.x8),
              DropdownButtonFormField<String?>(
                key: ValueKey('merge-${report.id}-$_mergeTarget'),
                initialValue: _mergeTarget,
                decoration: InputDecoration(labelText: context.strings.text('u0276')),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(context.strings.text('u0098'))),
                  ...mergeCandidates.map(
                    (candidate) => DropdownMenuItem<String?>(
                      value: candidate.id,
                      child: Text(context.strings.format('u0337', {'tracking': candidate.trackingNumber, 'category': _humanize(candidate.category)})),
                    ),
                  ),
                ],
                onChanged: enabled ? (value) => setState(() => _mergeTarget = value) : null,
              ),
              SizedBox(height: KtSpacing.x2),
              if (selectedMergeCandidate != null) ...[
                _MergeComparison(source: report, target: selectedMergeCandidate),
                SizedBox(height: KtSpacing.x2),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: enabled && _mergeTarget != null
                      ? () => unawaited(_decision(entry, StaffDecisionAction.merge, targetReportId: _mergeTarget))
                      : null,
                  icon: Icon(Icons.merge_rounded),
                  label: Text(context.strings.text('u0099')),
                ),
              ),
            ],
            Divider(height: KtSpacing.x8),
            DropdownButtonFormField<String>(
              key: ValueKey('district-${report.id}-$_district'),
              initialValue: _district,
              decoration: InputDecoration(labelText: context.strings.text('u0277')),
              items: [
                DropdownMenuItem(value: 'district_municipality_demo', child: Text(context.strings.text('u0100'))),
                DropdownMenuItem(value: 'district_beyoglu', child: Text(context.strings.text('u0076'))),
                DropdownMenuItem(value: 'district_uskudar', child: Text(context.strings.text('u0077'))),
              ],
              onChanged: enabled ? (value) => setState(() => _district = value ?? _district) : null,
            ),
            SizedBox(height: KtSpacing.x2),
            if (!preDecision)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: enabled
                      ? () => unawaited(_decision(entry, StaffDecisionAction.routeToDistrict, targetId: _district))
                      : null,
                  icon: Icon(Icons.account_balance_outlined),
                  label: Text(context.strings.text('u0101')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(StaffQueueEntry entry) async {
    setState(() {
      _selectedReportId = entry.report.id;
      _category = entry.report.category;
      _reason.clear();
      _additionalInfo.clear();
      _publicPreviewApproved = false;
    });
    _syncUrl();
    final session = context.read<SessionController>();
    if (entry.lease == null && !context.read<SnapshotController>().staffReadOnly && session.principal != null) {
      await _acquireLease(entry.report.id);
    }
  }

  Future<void> _acquireLease(String reportId) async {
    final principal = context.read<SessionController>().principal;
    if (principal == null) return;
    await context.read<SnapshotController>().reviewLease(
          actorId: principal.account.id,
          reportId: reportId,
          action: ReviewLeaseAction.acquire,
        );
  }

  Future<void> _releaseLease(String reportId) async {
    final principal = context.read<SessionController>().principal;
    if (principal == null) return;
    await context.read<SnapshotController>().reviewLease(
          actorId: principal.account.id,
          reportId: reportId,
          action: ReviewLeaseAction.release,
          reason: context.strings.text('u0566'),
        );
  }

  Future<void> _takeOver(String reportId) async {
    final reason = await _askText(
      title: context.strings.text('u0290'),
      hint: context.strings.text('u0567'),
    );
    if (reason == null || !mounted) return;
    final principal = context.read<SessionController>().principal;
    if (principal == null) return;
    await context.read<SnapshotController>().reviewLease(
          actorId: principal.account.id,
          reportId: reportId,
          action: ReviewLeaseAction.takeOver,
          reason: reason,
        );
  }

  Future<void> _verify(StaffQueueEntry entry) async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) return _showError(context.strings.text('u0544'));
    if (!_publicPreviewApproved) return _showError(context.strings.text('u0568'));
    final principal = context.read<SessionController>().principal;
    if (principal == null) return;
    final result = await context.read<SnapshotController>().verifyReport(
          actorId: principal.account.id,
          clientMutationId: 'verify_${principal.account.id}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
          reportId: entry.report.id,
          category: _category ?? entry.report.category,
          unitId: _unit,
          reason: reason,
          aiOverrideReason: reason,
          publicPreviewApproved: true,
        );
    if (!mounted || result == null) return;
    setState(() {
      _selectedReportId = entry.report.id;
      _publicPreviewApproved = false;
      _reason.clear();
    });
    _syncUrl();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.format('u0338', {'tracking': entry.report.trackingNumber}))),
    );
  }

  Future<void> _decision(
    StaffQueueEntry entry,
    StaffDecisionAction action, {
    String? targetId,
    String? targetReportId,
    String? message,
  }) async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) return _showError(context.strings.text('u0544'));
    if (action == StaffDecisionAction.requestAdditionalInfo && (message?.trim().isEmpty ?? true)) {
      return _showError(context.strings.text('u0569'));
    }
    var confirmCritical = false;
    if (entry.report.riskLevel == RiskLevel.criticalSignal &&
        (action == StaffDecisionAction.reject || action == StaffDecisionAction.outOfScope)) {
      confirmCritical = await _confirm(
        context.strings.text('u0570'),
        context.strings.format('u0571', {'action': action == StaffDecisionAction.reject ? context.strings.text('u0635') : context.strings.text('u0636')}),
      );
      if (!confirmCritical || !mounted) return;
    }
    final principal = context.read<SessionController>().principal;
    if (principal == null) return;
    final result = await context.read<SnapshotController>().staffDecision(
          actorId: principal.account.id,
          reportId: entry.report.id,
          action: action,
          reason: reason,
          reasonCode: action == StaffDecisionAction.reject || action == StaffDecisionAction.outOfScope
              ? _decisionReasonCode
              : null,
          targetId: targetId,
          targetReportId: targetReportId,
          message: message?.trim(),
          aiOverrideReason: reason,
          confirmCritical: confirmCritical,
        );
    if (!mounted || result == null) return;
    _afterDecision(context.strings.format('u0644', {'tracking': entry.report.trackingNumber, 'decision': _decisionLabel(context, action)}));
  }

  void _afterDecision(String message) {
    setState(() {
      _selectedReportId = null;
      _reason.clear();
      _additionalInfo.clear();
      _mergeTarget = null;
      _publicPreviewApproved = false;
    });
    _syncUrl();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _askText({required String title, required String hint}) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: hint), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.strings.text('u0043'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: Text(context.strings.text('u0102'))),
        ],
      ),
    );
    controller.dispose();
    return value?.trim().isEmpty == true ? null : value;
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.strings.text('u0043'))),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.strings.text('u0103'))),
            ],
          ),
        ) ??
        false;
  }

  void _moveSelection(StaffQueuePage page, int delta) {
    if (page.items.isEmpty) return;
    final index = page.items.indexWhere((entry) => entry.report.id == _selectedReportId);
    final next = index < 0 ? 0 : (index + delta).clamp(0, page.items.length - 1).toInt();
    unawaited(_select(page.items[next]));
  }

  void _clearSelection() {
    setState(() => _selectedReportId = null);
    _syncUrl();
  }

  void _filtersChanged() {
    setState(() => _page = 1);
    _syncUrl();
  }

  void _setPage(int value) {
    setState(() {
      _page = value;
      _selectedReportId = null;
    });
    _syncUrl();
  }

  void _syncUrl() {
    if (!mounted) return;
    final params = <String, String>{};
    if (_search.text.trim().isNotEmpty) params['q'] = _search.text.trim();
    if (_filterCategory != null) params['category'] = _filterCategory!;
    if (_filterUnit != null) params['unit'] = _filterUnit!;
    if (_minDuplicateConfidence != null) params['duplicateMin'] = '$_minDuplicateConfidence';
    if (_risk != null) params['risk'] = _risk!.name;
    if (_status != null) params['status'] = _status!.name;
    if (_sort != StaffQueueSort.priorityOldest) params['sort'] = _sort.name;
    if (_page != 1) params['page'] = '$_page';
    if (_selectedReportId != null) params['selected'] = _selectedReportId!;
    final uri = Uri(path: '/staff/queues/${widget.queueType.name}', queryParameters: params.isEmpty ? null : params);
    context.replace(uri.toString());
  }
}

final class _OperationalBanners extends StatelessWidget {
  _OperationalBanners({required this.controller});
  final SnapshotController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    final session = context.watch<SessionController>();
    final alerts = snapshot == null
        ? <GovernanceAlert>[]
        : AdministrationProjection.alerts(snapshot, DateTime.now().toUtc());
    final sourceAlerts = alerts.where((item) => item.kind == GovernanceAlertKind.sourceHealth).length;
    final deniedAlerts = alerts.where((item) => item.kind == GovernanceAlertKind.securityDenied).length;
    final automationAlerts = alerts.where((item) => item.kind == GovernanceAlertKind.automationFailure).length;
    final privacyAlerts = alerts.where((item) =>
        item.kind == GovernanceAlertKind.privacyBacklog ||
        item.kind == GovernanceAlertKind.restrictionAppeal).length;
    return Column(
      children: [
        if (session.can(Permission.manageSources) && sourceAlerts > 0)
          KtBanner(
            title: context.strings.text('u0291'),
            message: context.strings.format('u0458', {'count': sourceAlerts}),
            tone: KtBannerTone.warning,
            action: KtButton(label: context.strings.text('u0446'), kind: KtButtonKind.text, onPressed: () => context.go(AppPaths.staffDataSources)),
          ),
        if (session.can(Permission.viewAudit) && deniedAlerts > 0)
          KtBanner(
            title: context.strings.text('u0419'),
            message: context.strings.format('u0459', {'count': deniedAlerts}),
            tone: KtBannerTone.danger,
            action: KtButton(label: context.strings.text('u0447'), kind: KtButtonKind.text, onPressed: () => context.go(AppPaths.staffAudit)),
          ),
        if (session.can(Permission.viewAudit) && automationAlerts > 0)
          KtBanner(
            title: context.strings.text('u0420'),
            message: context.strings.format('u0460', {'count': automationAlerts}),
            tone: KtBannerTone.warning,
            action: KtButton(label: context.strings.text('u0447'), kind: KtButtonKind.text, onPressed: () => context.go(AppPaths.staffAudit)),
          ),
        if (session.can(Permission.managePrivacyRequests) && privacyAlerts > 0)
          KtBanner(
            title: context.strings.text('u0421'),
            message: context.strings.format('u0461', {'count': privacyAlerts}),
            tone: KtBannerTone.info,
            action: KtButton(label: context.strings.text('u0448'), kind: KtButtonKind.text, onPressed: () => context.go(AppPaths.staffPrivacyRequests)),
          ),
        if (controller.staffReadOnly)
          KtBanner(
            title: context.strings.text('u0241'),
            message: context.strings.text('u0434'),
            tone: KtBannerTone.warning,
            action: KtButton(label: context.strings.text('u0663'), kind: KtButtonKind.text, onPressed: () => unawaited(controller.refresh())),
          ),
        if (controller.revisionError != null && controller.online)
          KtBanner(
            title: context.strings.text('u0422'),
            message: context.strings.text('u0435'),
            tone: KtBannerTone.warning,
            action: KtButton(label: context.strings.text('u0663'), kind: KtButtonKind.text, onPressed: () => unawaited(controller.refresh())),
          ),
        if (controller.conflict != null)
          KtBanner(
            title: context.strings.text('u0423'),
            message: context.strings.text('u0436'),
            tone: KtBannerTone.danger,
            action: KtButton(label: context.strings.text('u0062'), kind: KtButtonKind.text, onPressed: controller.clearConflict),
          ),
        if (controller.error is DomainFailure)
          KtBanner(
            title: context.strings.text('u0424'),
            message: context.strings.format('u0671', {'code': enumWire((controller.error! as DomainFailure).code)}),
            tone: KtBannerTone.danger,
          ),
      ],
    );
  }
}

final class _QueueSwitcher extends StatelessWidget {
  _QueueSwitcher({required this.selected});
  final ReviewQueueType selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KtColors.white,
      child: SizedBox(
        height: 54,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: KtSpacing.x3, vertical: KtSpacing.x2),
          scrollDirection: Axis.horizontal,
          itemCount: ReviewQueueType.values.length,
          separatorBuilder: (_, __) => SizedBox(width: KtSpacing.x2),
          itemBuilder: (context, index) {
            final type = ReviewQueueType.values[index];
            return ChoiceChip(
              selected: type == selected,
              avatar: Icon(_queueIcon(type), size: 18),
              label: Text(_queueLabel(context, type)),
              onSelected: (_) => context.go('/staff/queues/${type.name}'),
            );
          },
        ),
      ),
    );
  }
}

final class _MetricTile extends StatelessWidget {
  _MetricTile({required this.label, this.value, this.valueText, required this.icon});
  final String label;
  final int? value;
  final String? valueText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(KtSpacing.x4),
          child: Row(
            children: [
              Icon(icon, color: KtColors.brandBlue800),
              SizedBox(width: KtSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(valueText ?? '${value ?? 0}', style: Theme.of(context).textTheme.headlineSmall),
                    Text(label, style: TextStyle(color: KtColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _QueueCard extends StatelessWidget {
  _QueueCard({required this.type, required this.count, required this.onTap});
  final ReviewQueueType type;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(KtRadius.card),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(KtSpacing.x4),
            child: Row(
              children: [
                Icon(_queueIcon(type), color: type == ReviewQueueType.critical ? KtColors.active : KtColors.brandBlue800),
                SizedBox(width: KtSpacing.x3),
                Expanded(child: Text(_queueLabel(context, type))),
                Text('$count', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _SectionCard extends StatelessWidget {
  _SectionCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(KtSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [Icon(icon), SizedBox(width: KtSpacing.x2), Text(title, style: Theme.of(context).textTheme.titleMedium)]),
            SizedBox(height: KtSpacing.x3),
            child,
          ],
        ),
      ),
    );
  }
}

final class _AiCard extends StatelessWidget {
  _AiCard({required this.analysis});
  final AiAnalysisDto? analysis;

  @override
  Widget build(BuildContext context) {
    final value = analysis;
    return _SectionCard(
      title: context.strings.text('u0425'),
      icon: Icons.auto_awesome_outlined,
      child: value == null
          ? Text(context.strings.text('u0104'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.strings.format('u0339', {'status': _humanize(value.status.name)})),
                Text(context.strings.format('u0340', {'value': '${value.categoryConfidence?.toString() ?? '—'} / 100'})),
                Text(context.strings.format('u0341', {'value': '${value.duplicateConfidence?.toString() ?? '—'} / 100'})),
                SizedBox(height: KtSpacing.x2),
                Text(context.strings.format('u0342', {'value': value.reasonCodes.isEmpty ? '—' : value.reasonCodes.join(', ')})),
                SizedBox(height: KtSpacing.x2),
                Text(context.strings.format('u0343', {'model': value.modelVersion, 'config': value.configVersion}), style: TextStyle(color: KtColors.textMuted)),
              ],
            ),
    );
  }
}

final class _SourceCard extends StatelessWidget {
  _SourceCard({required this.entry, required this.snapshot});
  final StaffQueueEntry entry;
  final AppSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.strings.text('u0426'),
      icon: Icons.hub_outlined,
      child: entry.sourceRecords.isEmpty
          ? Text(context.strings.text('u0105'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.sourceConflict)
                  Padding(
                    padding: EdgeInsets.only(bottom: KtSpacing.x2),
                    child: Text(context.strings.text('u0106'), style: TextStyle(color: KtColors.critical)),
                  ),
                for (final record in entry.sourceRecords) ...[
                  Text(record.body['attribution']?.toString() ?? record.id, style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    context.strings.format('u0344', {'health': '${record.body['health'] ?? 'unknown'} · ${context.strings.text('u0662')}: ${_authority(snapshot, record.body['authorityId']?.toString())}'}),
                  ),
                  Text(
                    context.strings.format('u0345', {'date': '${record.body['sourceUpdatedAt'] ?? '—'} · ${context.strings.text('u0653')}: ${record.body['ingestedAt'] ?? '—'}'}),
                    style: TextStyle(color: KtColors.textMuted),
                  ),
                  SizedBox(height: KtSpacing.x2),
                ],
              ],
            ),
    );
  }
}

final class _MediaCard extends StatefulWidget {
  _MediaCard({required this.entry, required this.canOriginal});
  final StaffQueueEntry entry;
  final bool canOriginal;

  @override
  State<_MediaCard> createState() => _MediaCardState();
}

final class _MediaCardState extends State<_MediaCard> {
  final Map<String, Uint8List> _loaded = {};
  String? _loadingRef;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.strings.text('u0427'),
      icon: Icons.photo_library_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.strings.format('u0346', {'count': widget.entry.publicMediaRefs.length})),
          for (final ref in widget.entry.publicMediaRefs)
            SelectableText(ref, style: TextStyle(color: KtColors.textMuted)),
          SizedBox(height: KtSpacing.x2),
          if (widget.canOriginal) ...[
            Text(context.strings.format('u0347', {'count': widget.entry.originalMediaRefs.length})),
            Text(context.strings.text('u0107'),
              style: TextStyle(color: KtColors.textMuted),
            ),
            SizedBox(height: KtSpacing.x2),
            for (final ref in widget.entry.originalMediaRefs) ...[
              Row(
                children: [
                  Expanded(child: SelectableText(ref, style: TextStyle(color: KtColors.textMuted))),
                  TextButton.icon(
                    onPressed: _loadingRef == ref ? null : () => unawaited(_openOriginal(context, ref)),
                    icon: _loadingRef == ref
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.visibility_outlined),
                    label: Text(context.strings.text('u0108')),
                  ),
                ],
              ),
              if (_loaded[ref] case final bytes?)
                Padding(
                  padding: EdgeInsets.only(top: KtSpacing.x2, bottom: KtSpacing.x3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(bytes, height: 220, fit: BoxFit.contain),
                  ),
                ),
            ],
          ] else
            Text(context.strings.text('u0109'), style: TextStyle(color: KtColors.critical)),
        ],
      ),
    );
  }

  Future<void> _openOriginal(BuildContext context, String ref) async {
    final principal = context.read<SessionController>().principal;
    if (principal == null) return;
    final reasonController = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.strings.text('u0110')),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: context.strings.text('u0278'),
            helperText: context.strings.text('u0279'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.strings.text('u0043'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.strings.text('u0111'))),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (approved != true || reason.length < 8 || !mounted) return;
    setState(() => _loadingRef = ref);
    try {
      final bytes = await context.read<SnapshotController>().viewOriginalMedia(
            actorId: principal.account.id,
            mediaRef: ref,
            reason: reason,
          );
      if (!mounted || bytes == null) return;
      setState(() => _loaded[ref] = bytes);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.strings.format('u0348', {'error': error}))));
    } finally {
      if (mounted) setState(() => _loadingRef = null);
    }
  }
}

final class _SimilarReportsCard extends StatelessWidget {
  _SimilarReportsCard({required this.report, required this.snapshot});

  final CitizenReportDto report;
  final AppSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final candidates = snapshot.payload.reports
        .where((item) => item.id != report.id)
        .map((item) => (report: item, score: _similarityScore(report, item)))
        .where((item) => item.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return _SectionCard(
      title: context.strings.text('u0428'),
      icon: Icons.content_copy_outlined,
      child: candidates.isEmpty
          ? Text(context.strings.text('u0112'))
          : Column(
              children: [
                for (final candidate in candidates.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.compare_arrows_rounded),
                    title: Text(candidate.report.trackingNumber),
                    subtitle: Text(
                      '${_humanize(candidate.report.category)} · ${_humanize(candidate.report.status.name)} · ${_distanceLabel(context, report, candidate.report)}',
                    ),
                    trailing: Text('${candidate.score}/100'),
                  ),
              ],
            ),
    );
  }
}

final class _HistoryCard extends StatelessWidget {
  _HistoryCard({required this.report, required this.snapshot, required this.canAudit});

  final CitizenReportDto report;
  final AppSnapshotDto snapshot;
  final bool canAudit;

  @override
  Widget build(BuildContext context) {
    final timeline = snapshot.payload.timeline
        .where((event) => event.body['resourceId'] == report.id)
        .toList()
      ..sort((a, b) => _opaqueAt(b).compareTo(_opaqueAt(a)));
    final audits = canAudit
        ? (snapshot.payload.auditEvents.where((event) => event.body['resourceId'] == report.id).toList()
          ..sort((a, b) => _opaqueAt(b).compareTo(_opaqueAt(a))))
        : <OpaqueEntityDto>[];
    return _SectionCard(
      title: context.strings.text('u0027'),
      icon: Icons.history_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (timeline.isEmpty) Text(context.strings.text('u0113')),
          for (final event in timeline.take(6))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.timeline_rounded),
              title: Text(_humanize(event.body['type']?.toString() ?? 'event')),
              subtitle: Text('${event.body['publicMessageKey'] ?? '—'} · ${event.body['at'] ?? '—'}'),
            ),
          if (canAudit) ...[
            Divider(),
            Text(context.strings.text('u0114'), style: Theme.of(context).textTheme.titleSmall),
            for (final event in audits.take(6))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.policy_outlined),
                title: Text(_humanize(event.body['action']?.toString() ?? 'audit')),
                subtitle: Text(
                  '${event.body['actorId'] ?? 'system'} · ${event.body['reason'] ?? '—'} · ${event.body['at'] ?? '—'}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

final class _IncidentCard extends StatelessWidget {
  _IncidentCard({required this.entry, required this.snapshot});
  final StaffQueueEntry entry;
  final AppSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final incident = entry.incident;
    final corroborations = incident == null
        ? <OpaqueEntityDto>[]
        : snapshot.payload.corroborations.where((item) => item.body['incidentId'] == incident.id).toList();
    return _SectionCard(
      title: context.strings.text('u0429'),
      icon: Icons.workspaces_outline,
      child: incident == null
          ? Text(context.strings.text('u0115'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(context.strings.format('u0359', {'incident': incident.id, 'status': _humanize(incident.status.name)})),
                Text(context.strings.format('u0349', {'value': incident.reportIds.join(', ')})),
                Text(context.strings.format('u0350', {'value': incident.sourceRecordIds.isEmpty ? '—' : incident.sourceRecordIds.join(', ')})),
                Text(context.strings.format('u0351', {'count': corroborations.length})),
                Text(
                  context.strings.format('u0352', {
                    'value': incident.workOrderRefs.isEmpty
                        ? '—'
                        : incident.workOrderRefs
                            .map((ref) => '${ref.sourceSystem}:${ref.externalWorkOrderId} · ${ref.syncStatus}')
                            .join(', '),
                  }),
                ),
                Text(context.strings.format('u0353', {'unit': incident.responsibleUnitId ?? context.strings.text('u0488')})),
              ],
            ),
    );
  }
}

final class _MergeComparison extends StatelessWidget {
  _MergeComparison({required this.source, required this.target});

  final CitizenReportDto source;
  final CitizenReportDto target;

  @override
  Widget build(BuildContext context) {
    Widget column(String title, CitizenReportDto report) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(KtSpacing.x3),
          decoration: BoxDecoration(
            border: Border.all(color: KtColors.border),
            borderRadius: BorderRadius.circular(KtRadius.control),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: KtSpacing.x1),
              Text(report.trackingNumber),
              Text('${_humanize(report.category)} · ${_humanize(report.status.name)}'),
              Text(context.strings.format('u0354', {'risk': _humanize(report.riskLevel.name)})),
              Text('${context.localeFormat.number(report.latitude, fractionDigits: 4)}, ${context.localeFormat.number(report.longitude, fractionDigits: 4)}'),
              Text(context.strings.format('u0355', {'incident': report.linkedIncidentId ?? '—'})),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.strings.text('u0116'), style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: KtSpacing.x2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            column(context.strings.text('u0572'), source),
            SizedBox(width: KtSpacing.x2),
            column(context.strings.text('u0573'), target),
          ],
        ),
      ],
    );
  }
}

final class _PublicPreviewCard extends StatelessWidget {
  _PublicPreviewCard({required this.entry});
  final StaffQueueEntry entry;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.strings.text('u0430'),
      icon: Icons.public_rounded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_rounded, color: KtColors.active, size: 36),
          SizedBox(width: KtSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_humanize(entry.report.category), style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${context.localeFormat.number(entry.report.latitude, fractionDigits: 4)}, ${context.localeFormat.number(entry.report.longitude, fractionDigits: 4)}'),
                Text(context.strings.format('u0356', {'count': entry.publicMediaRefs.length})),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _similarityScore(CitizenReportDto source, CitizenReportDto other) {
  var score = 0;
  if (source.category == other.category) score += 55;
  final lat = (source.latitude - other.latitude).abs();
  final lon = (source.longitude - other.longitude).abs();
  if (lat <= .005 && lon <= .005) {
    score += 35;
  } else if (lat <= .015 && lon <= .015) {
    score += 20;
  }
  if (source.riskLevel == other.riskLevel) score += 10;
  return score.clamp(0, 100).toInt();
}

String _distanceLabel(BuildContext context, CitizenReportDto source, CitizenReportDto other) {
  final latMeters = (source.latitude - other.latitude).abs() * 111000;
  final lonMeters = (source.longitude - other.longitude).abs() * 85000;
  final squaredMeters = latMeters * latMeters + lonMeters * lonMeters;
  final distance = math.sqrt(squaredMeters);
  return distance < 1000
      ? context.strings.format('u0643', {'distance': distance.round()})
      : context.strings.format('u0642', {'distance': context.localeFormat.number(distance / 1000, fractionDigits: 1)});
}

DateTime _opaqueAt(OpaqueEntityDto event) {
  return DateTime.tryParse(event.body['at'] as String? ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

T? _enumByName<T extends Enum>(Iterable<T> values, String? raw) {
  if (raw == null) return null;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return null;
}

String _authority(AppSnapshotDto snapshot, String? authorityId) {
  if (authorityId == null) return '—';
  for (final authority in snapshot.payload.sourceAuthorities) {
    if (authority.id == authorityId) {
      return '${authority.body['displayName'] ?? authority.id} (${authority.body['rank'] ?? 'unknown'})';
    }
  }
  return authorityId;
}

String? _descriptionFromAudit(AppSnapshotDto snapshot, CitizenReportDto report) {
  for (final event in snapshot.payload.auditEvents.reversed) {
    if (event.body['resourceId'] != report.id) continue;
    final after = event.body['after'];
    if (after is Map<String, Object?>) {
      final value = after['description'];
      if (value is String && value.trim().isNotEmpty) return value;
    }
  }
  return null;
}

String _duration(BuildContext context, Duration value) {
  if (value.inDays > 0) {
    return context.strings.format('u0639', {
      'days': value.inDays,
      'hours': value.inHours.remainder(24),
    });
  }
  if (value.inHours > 0) {
    return context.strings.format('u0640', {
      'hours': value.inHours,
      'minutes': value.inMinutes.remainder(60),
    });
  }
  return context.strings.format('u0641', {'minutes': value.inMinutes.clamp(0, 59)});
}

String _queueLabel(BuildContext context, ReviewQueueType type) => switch (type) {
  ReviewQueueType.critical => context.strings.text('u0574'),
  ReviewQueueType.high => context.strings.text('u0575'),
  ReviewQueueType.normal => context.strings.text('u0576'),
  ReviewQueueType.lowConfidence => context.strings.text('u0577'),
  ReviewQueueType.privacy => context.strings.text('u0578'),
  ReviewQueueType.abuse => context.strings.text('u0579'),
  ReviewQueueType.manualAiError => context.strings.text('u0580'),
};

IconData _queueIcon(ReviewQueueType type) {
  switch (type) {
    case ReviewQueueType.critical:
      return Icons.crisis_alert_rounded;
    case ReviewQueueType.high:
      return Icons.priority_high_rounded;
    case ReviewQueueType.normal:
      return Icons.inbox_outlined;
    case ReviewQueueType.lowConfidence:
      return Icons.help_outline_rounded;
    case ReviewQueueType.privacy:
      return Icons.privacy_tip_outlined;
    case ReviewQueueType.abuse:
      return Icons.gpp_bad_outlined;
    case ReviewQueueType.manualAiError:
      return Icons.person_search_rounded;
  }
}

String _sortLabel(BuildContext context, StaffQueueSort sort) => switch (sort) {
  StaffQueueSort.priorityOldest => context.strings.text('u0581'),
  StaffQueueSort.oldest => context.strings.text('u0582'),
  StaffQueueSort.newest => context.strings.text('u0583'),
  StaffQueueSort.duplicateProbability => context.strings.text('u0584'),
};

String _decisionLabel(BuildContext context, StaffDecisionAction action) => switch (action) {
  StaffDecisionAction.reject => context.strings.text('u0585'),
  StaffDecisionAction.outOfScope => context.strings.text('u0586'),
  StaffDecisionAction.requestAdditionalInfo => context.strings.text('u0587'),
  StaffDecisionAction.merge => context.strings.text('u0588'),
  StaffDecisionAction.routeToUnit => context.strings.text('u0589'),
  StaffDecisionAction.routeToDistrict => context.strings.text('u0590'),
  StaffDecisionAction.transferBack => context.strings.text('u0591'),
};
