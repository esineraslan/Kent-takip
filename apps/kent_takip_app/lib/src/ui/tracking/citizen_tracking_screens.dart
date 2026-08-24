import 'dart:async';

import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/locale_formatter.dart';

import 'package:flutter/material.dart' hide SnapshotController;
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/states.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

enum ReportListFilter { active, completed, all }

final class CitizenReportsHubScreen extends StatefulWidget {
  CitizenReportsHubScreen({super.key});

  @override
  State<CitizenReportsHubScreen> createState() =>
      _CitizenReportsHubScreenState();
}

final class _CitizenReportsHubScreenState
    extends State<CitizenReportsHubScreen> {
  var _filter = ReportListFilter.active;

  @override
  Widget build(BuildContext context) {
    final ownerId = context.watch<SessionController>().principal?.account.id;
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null || ownerId == null) return LoadingView();
    final all = DemoProjections.ownedReports(snapshot, ownerId);
    final reports = all
        .where(
          (report) => switch (_filter) {
            ReportListFilter.active => !_terminal.contains(report.status),
            ReportListFilter.completed => _terminal.contains(report.status),
            ReportListFilter.all => true,
          },
        )
        .toList(growable: false);
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.strings.text('u0023'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: context.strings.text('u0032'),
              onPressed: () => context.go(AppPaths.citizenNotifications),
              icon: Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (!controller.online)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: KtBanner(
              title: context.strings.text('u0223'),
              message: context.strings.text('u0224'),
              tone: KtBannerTone.warning,
            ),
          ),
        SegmentedButton<ReportListFilter>(
          segments: [
            ButtonSegment(
              value: ReportListFilter.active,
              label: Text(context.strings.text('u0024')),
            ),
            ButtonSegment(
              value: ReportListFilter.completed,
              label: Text(context.strings.text('u0025')),
            ),
            ButtonSegment(
              value: ReportListFilter.all,
              label: Text(context.strings.text('u0026')),
            ),
          ],
          selected: {_filter},
          onSelectionChanged: (value) => setState(() => _filter = value.first),
        ),
        SizedBox(height: 16),
        if (reports.isEmpty)
          EmptyView(
            title: context.strings.text('u0225'),
            description: context.strings.text('u0402'),
            action: KtButton(
              label: context.strings.text('u0022'),
              onPressed: () => context.go(AppPaths.citizenReport),
            ),
          )
        else
          for (final report in reports)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      context.go(AppPaths.citizenReportDetail(report.id)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _statusColor(report.status)
                              .withValues(alpha: .12),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: _statusColor(report.status),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.strings.categoryLabel(report.category),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                context.strings.format('u0328', {
                                  'tracking': report.trackingNumber,
                                  'status': _status(context, report.status),
                                }),
                              ),
                              Text(
                                context.strings.format('u0329', {
                                  'date': context.localeFormat.dateTime(
                                    report.updatedAt,
                                  ),
                                }),
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

final class CitizenReportDetailScreen extends StatefulWidget {
  CitizenReportDetailScreen({required this.reportId, super.key});
  final String reportId;

  @override
  State<CitizenReportDetailScreen> createState() =>
      _CitizenReportDetailScreenState();
}

final class _CitizenReportDetailScreenState
    extends State<CitizenReportDetailScreen> {
  final _response = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = context.watch<SessionController>().principal?.account.id;
    final snapshot = context.watch<SnapshotController>().snapshot;
    if (snapshot == null || ownerId == null) return LoadingView();
    final detail = DemoProjections.ownedReportDetail(
      snapshot,
      ownerId,
      widget.reportId,
    );
    if (detail == null) {
      return RecoverableErrorView(
        message: context.strings.text('u0230'),
        onRetry: () => context.go(AppPaths.citizenReports),
      );
    }
    final report = detail.report;
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          _status(context, report.status).toUpperCase(),
          style: TextStyle(
            color: _statusColor(report.status),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          context.strings.categoryLabel(report.category),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 6),
        SelectableText(
          context.strings.format('u0330', {'tracking': report.trackingNumber}),
        ),
        SizedBox(height: 16),
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: Color(0xffedf2ec),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 100,
                color: AppColors.brandBlue100,
              ),
              Icon(
                Icons.location_pin,
                size: 48,
                color: _statusColor(report.status),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Text(
                  '${context.localeFormat.number(report.latitude, fractionDigits: 4)}, ${context.localeFormat.number(report.longitude, fractionDigits: 4)}',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        KtCard(
          child: Column(
            children: [
              _DetailRow(
                label: context.strings.text('u0125'),
                value: detail.provenance,
              ),
              _DetailRow(
                label: context.strings.text('u0236'),
                value:
                    detail.responsibleUnitId?.replaceAll('_', ' ') ??
                    context.strings.text('u0478'),
              ),
              _DetailRow(
                label: context.strings.text('u0394'),
                value: context.strings.format('u0511', {
                  'label': detail.sla.label,
                }),
              ),
              if (detail.slaTargetAt != null)
                _DetailRow(
                  label: context.strings.text('u0395'),
                  value:
                      '${context.localeFormat.dateTime(detail.slaTargetAt!)} (${context.strings.text('u0480')})',
                ),
              if (detail.reestimatedMinAt != null &&
                  detail.reestimatedMaxAt != null)
                _DetailRow(
                  label: context.strings.text('u0396'),
                  value:
                      '${context.localeFormat.dateTime(detail.reestimatedMinAt!)} – ${context.localeFormat.dateTime(detail.reestimatedMaxAt!)} (${context.strings.text('u0481')})',
                ),
              _DetailRow(
                label: context.strings.text('u0397'),
                value: detail.sourceHealth.name,
              ),
            ],
          ),
        ),
        if (detail.sourceHealth != SourceHealth.fresh) ...[
          SizedBox(height: 12),
          KtBanner(
            title: context.strings.text('u0226'),
            message: context.strings.text('u0231'),
            tone: KtBannerTone.warning,
          ),
        ],
        if (detail.resolutionExplanation != null) ...[
          SizedBox(height: 12),
          KtBanner(
            title: context.strings.text('u0227'),
            message: detail.resolutionPublicMediaRef == null
                ? detail.resolutionExplanation!
                : '${detail.resolutionExplanation!}\n${context.strings.text('u0482')}',
            tone: KtBannerTone.success,
          ),
        ],
        if (report.humanDecisionReason != null) ...[
          SizedBox(height: 12),
          KtBanner(
            title: report.status == ReportStatus.merged
                ? context.strings.text('u0512')
                : context.strings.text('u0513'),
            message: report.humanDecisionReason!,
            tone: KtBannerTone.info,
          ),
        ],
        SizedBox(height: 20),
        Text(
          context.strings.text('u0027'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 10),
        KtTimeline(
          items: [
            for (final event in detail.timeline)
              KtTimelineItem(
                title: _timelineTitle(
                  context,
                  event.body['publicMessageKey'] as String? ?? '',
                ),
                description:
                    event.body['detail'] as String? ??
                    context.strings.text('u0514'),
                at: _timelineAt(context, event.body['at']),
                icon: Icons.check_circle_outline_rounded,
              ),
          ],
        ),
        if (report.mediaIds.isNotEmpty) ...[
          SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.photo_outlined),
            title: Text(context.strings.text('u0028')),
            subtitle: Text(context.strings.text('u0029')),
          ),
        ],
        if (report.status == ReportStatus.additionalInfoRequired) ...[
          SizedBox(height: 16),
          TextField(
            controller: _response,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.strings.text('u0221'),
            ),
          ),
          SizedBox(height: 10),
          KtButton(
            label: context.strings.text('u0398'),
            expand: true,
            onPressed: () => unawaited(_additionalInfo(ownerId)),
          ),
        ],
        if ({
          ReportStatus.received,
          ReportStatus.aiReview,
          ReportStatus.ibbReview,
          ReportStatus.criticalReview,
          ReportStatus.manualReview,
          ReportStatus.additionalInfoRequired,
          ReportStatus.assignedUnit,
          ReportStatus.fieldAssigned,
          ReportStatus.inProgress,
        }.contains(report.status)) ...[
          SizedBox(height: 16),
          KtButton(
            label: context.strings.text('u0718'),
            kind: KtButtonKind.secondary,
            expand: true,
            onPressed: () => unawaited(_statusRequest(ownerId)),
          ),
        ],
        if (report.status == ReportStatus.resolved) ...[
          SizedBox(height: 16),
          Text(
            context.strings.text('u0030'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: KtButton(
                  label: context.strings.text('u0399'),
                  kind: KtButtonKind.secondary,
                  onPressed: () => unawaited(
                    _feedback(ownerId, CorroborationKind.noLongerVisible),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: KtButton(
                  label: context.strings.text('u0400'),
                  onPressed: () => unawaited(
                    _feedback(ownerId, CorroborationKind.stillPresent),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            context.strings.text('u0031'),
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        if (report.status == ReportStatus.rejected ||
            report.status == ReportStatus.outOfScope) ...[
          SizedBox(height: 16),
          TextField(
            controller: _response,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.strings.text('u0222'),
            ),
          ),
          SizedBox(height: 10),
          KtButton(
            label: context.strings.text('u0401'),
            expand: true,
            onPressed: () => unawaited(_appeal(ownerId)),
          ),
        ],
        if (_message != null) ...[
          SizedBox(height: 12),
          KtBanner(
            title: context.strings.text('u0228'),
            message: _message!,
            tone: KtBannerTone.success,
          ),
        ],
      ],
    );
  }

  Future<void> _additionalInfo(String actorId) async {
    if (_response.text.trim().length < 3) return;
    final result = await context.read<SnapshotController>().citizenAction(
      actorId: actorId,
      kind: CitizenActionKind.additionalInfoResponse,
      resourceId: widget.reportId,
      payload: {'response': _response.text.trim()},
    );
    if (mounted && result != null)
      setState(() => _message = context.strings.text('u0515'));
  }

  Future<void> _statusRequest(String actorId) async {
    final result = await context.read<SnapshotController>().citizenAction(
      actorId: actorId,
      kind: CitizenActionKind.statusRequest,
      resourceId: widget.reportId,
    );
    if (mounted && result != null) {
      setState(() => _message = context.strings.text('u0719'));
    }
  }

  Future<void> _feedback(String actorId, CorroborationKind kind) async {
    final result = await context.read<SnapshotController>().citizenAction(
      actorId: actorId,
      kind: CitizenActionKind.resolutionFeedback,
      resourceId: widget.reportId,
      payload: {'feedback': enumWire(kind)},
    );
    if (mounted && result != null)
      setState(() => _message = context.strings.text('u0516'));
  }

  Future<void> _appeal(String actorId) async {
    if (_response.text.trim().length < 10) return;
    final result = await context.read<SnapshotController>().citizenAction(
      actorId: actorId,
      kind: CitizenActionKind.appeal,
      resourceId: widget.reportId,
      payload: {'appeal': _response.text.trim()},
    );
    if (mounted && result != null)
      setState(() => _message = context.strings.text('u0517'));
  }
}

final class CitizenNotificationCenterScreen extends StatefulWidget {
  CitizenNotificationCenterScreen({super.key});

  @override
  State<CitizenNotificationCenterScreen> createState() =>
      _CitizenNotificationCenterScreenState();
}

final class _CitizenNotificationCenterScreenState
    extends State<CitizenNotificationCenterScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final actorId = context.watch<SessionController>().principal?.account.id;
    final snapshot = context.watch<SnapshotController>().snapshot;
    if (actorId == null || snapshot == null) return LoadingView();
    final notifications = DemoProjections.ownedNotifications(
      snapshot,
      actorId,
      unreadOnly: _unreadOnly,
    );
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.strings.text('u0032'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            FilterChip(
              label: Text(context.strings.text('u0033')),
              selected: _unreadOnly,
              onSelected: (value) => setState(() => _unreadOnly = value),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (notifications.isEmpty)
          EmptyView(
            title: context.strings.text('u0229'),
            description: context.strings.text('u0403'),
          )
        else
          for (final notification in notifications)
            Card(
              child: ListTile(
                leading: Icon(
                  notification.body['readAt'] == null
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: AppColors.brandBlue800,
                ),
                title: Text(
                  _notificationTitle(
                    context,
                    notification.body['type'] as String? ?? '',
                  ),
                ),
                subtitle: Text(notification.body['createdAt'] as String? ?? ''),
                trailing: Icon(Icons.chevron_right),
                onTap: () => unawaited(_open(context, actorId, notification)),
              ),
            ),
      ],
    );
  }

  Future<void> _open(
    BuildContext context,
    String actorId,
    OpaqueEntityDto notification,
  ) async {
    await context.read<SnapshotController>().citizenAction(
      actorId: actorId,
      kind: CitizenActionKind.markNotificationRead,
      resourceId: notification.id,
    );
    if (!context.mounted) return;
    final route = notification.body['route'];
    if (route is String && route.startsWith('/citizen/reports/'))
      context.go(route);
  }
}

const Set<ReportStatus> _terminal = {
  ReportStatus.resolved,
  ReportStatus.merged,
  ReportStatus.rejected,
  ReportStatus.outOfScope,
};

String _status(BuildContext context, ReportStatus status) => switch (status) {
  ReportStatus.received => context.strings.text('u0518'),
  ReportStatus.aiReview => context.strings.text('u0519'),
  ReportStatus.ibbReview ||
  ReportStatus.manualReview ||
  ReportStatus.criticalReview => context.strings.text('u0520'),
  ReportStatus.additionalInfoRequired => context.strings.text('u0521'),
  ReportStatus.assignedUnit ||
  ReportStatus.fieldAssigned => context.strings.text('u0522'),
  ReportStatus.inProgress => context.strings.text('u0523'),
  ReportStatus.resolved => context.strings.text('u0524'),
  ReportStatus.merged => context.strings.text('u0525'),
  ReportStatus.outOfScope => context.strings.text('u0526'),
  ReportStatus.rejected => context.strings.text('u0527'),
  _ => status.name,
};

Color _statusColor(ReportStatus status) => switch (status) {
  ReportStatus.resolved => AppColors.success,
  ReportStatus.rejected || ReportStatus.outOfScope => AppColors.critical,
  ReportStatus.additionalInfoRequired => AppColors.plannedInk,
  _ => AppColors.brandBlue800,
};

String _timelineTitle(BuildContext context, String key) => switch (key) {
  'timeline.report_received' => context.strings.text('u0518'),
  'timeline.report_verified_and_routed' => context.strings.text('u0528'),
  'timeline.additional_info_received' => context.strings.text('u0529'),
  'timeline.resolution_feedback_received' => context.strings.text('u0530'),
  'timeline.status_request_received' => context.strings.text('u0718'),
  'timeline.appeal_received' => context.strings.text('u0531'),
  _ => context.strings.text('u0532'),
};

String _notificationTitle(BuildContext context, String type) => switch (type) {
  'report_received' => context.strings.text('u0005'),
  'status_changed' => context.strings.text('u0533'),
  'additional_info_requested' => context.strings.text('u0534'),
  'resolution_published' => context.strings.text('u0535'),
  _ => context.strings.text('u0536'),
};

String _timelineAt(BuildContext context, Object? raw) {
  final parsed = DateTime.tryParse(raw?.toString() ?? '');
  return parsed == null
      ? raw?.toString() ?? ''
      : context.localeFormat.dateTime(parsed);
}

final class _DetailRow extends StatelessWidget {
  _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
