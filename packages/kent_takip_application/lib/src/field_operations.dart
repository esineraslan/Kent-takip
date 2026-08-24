import 'package:kent_takip_application/src/commands.dart';
import 'package:kent_takip_application/src/field_sla.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

enum FieldTaskFilter { all, unassigned, mine, fieldAssigned, inProgress, overdue }

enum FieldOperationAction { assignField, startProgress, recordDelay, resolve }

final class FieldTaskEntry {
  const FieldTaskEntry({
    required this.incident,
    required this.reports,
    required this.sla,
    required this.overdue,
    required this.reopenRequested,
  });

  final UrbanIncidentDto incident;
  final List<CitizenReportDto> reports;
  final SlaTargetRange sla;
  final bool overdue;
  final bool reopenRequested;

  ReportStatus? get operationalStatus {
    final active = reports
        .where((item) => !{
              ReportStatus.merged,
              ReportStatus.rejected,
              ReportStatus.outOfScope,
            }.contains(item.status))
        .toList(growable: false);
    if (active.any((item) => item.status == ReportStatus.inProgress)) {
      return ReportStatus.inProgress;
    }
    if (active.any((item) => item.status == ReportStatus.fieldAssigned)) {
      return ReportStatus.fieldAssigned;
    }
    if (active.any((item) => item.status == ReportStatus.assignedUnit)) {
      return ReportStatus.assignedUnit;
    }
    if (active.isNotEmpty && active.every((item) => item.status == ReportStatus.resolved)) {
      return ReportStatus.resolved;
    }
    return active.isEmpty ? null : active.first.status;
  }
}

abstract final class FieldTaskProjection {
  static List<FieldTaskEntry> tasks(
    AppSnapshotDto snapshot, {
    required UserAccount viewer,
    required DateTime now,
    FieldTaskFilter filter = FieldTaskFilter.all,
  }) {
    AuthorizationPolicy.requirePermission(viewer, Permission.manageFieldWork);
    final reportsByIncident = <String, List<CitizenReportDto>>{};
    for (final report in snapshot.payload.reports) {
      final incidentId = report.linkedIncidentId;
      if (incidentId == null) continue;
      reportsByIncident.putIfAbsent(incidentId, () => []).add(report);
    }
    final reopenIncidentIds = <String>{};
    for (final signal in snapshot.payload.corroborations) {
      if (signal.body['reopenReviewRequested'] == true) {
        final incidentId = signal.body['incidentId'];
        if (incidentId is String) reopenIncidentIds.add(incidentId);
      }
    }
    final result = <FieldTaskEntry>[];
    for (final incident in snapshot.payload.incidents) {
      if (incident.responsibleUnitId == null) continue;
      if (viewer.role == UserRole.unitOfficer && viewer.unitId != incident.responsibleUnitId) {
        continue;
      }
      final reports = reportsByIncident[incident.id] ?? const <CitizenReportDto>[];
      if (reports.isEmpty) continue;
      final operational = reports.any((item) => {
            ReportStatus.assignedUnit,
            ReportStatus.fieldAssigned,
            ReportStatus.inProgress,
            ReportStatus.resolved,
          }.contains(item.status));
      if (!operational) continue;
      final range = FieldSlaPolicy.targetFor(incident.category, incident.responsibleUnitId!);
      final overdue = incident.status != IncidentStatus.resolved &&
          incident.slaTargetAt != null &&
          !incident.slaTargetAt!.isAfter(now);
      final entry = FieldTaskEntry(
        incident: incident,
        reports: List.unmodifiable(reports),
        sla: range,
        overdue: overdue,
        reopenRequested: reopenIncidentIds.contains(incident.id),
      );
      if (!_matches(entry, viewer, filter)) continue;
      result.add(entry);
    }
    result.sort((a, b) {
      if (a.overdue != b.overdue) return a.overdue ? -1 : 1;
      final aTarget = a.incident.slaTargetAt ?? DateTime(9999).toUtc();
      final bTarget = b.incident.slaTargetAt ?? DateTime(9999).toUtc();
      return aTarget.compareTo(bTarget);
    });
    return List.unmodifiable(result);
  }

  static bool _matches(FieldTaskEntry entry, UserAccount viewer, FieldTaskFilter filter) {
    final status = entry.operationalStatus;
    return switch (filter) {
      FieldTaskFilter.all => true,
      FieldTaskFilter.unassigned => entry.incident.assigneeId == null && entry.incident.fieldTeamId == null,
      FieldTaskFilter.mine => entry.incident.assigneeId == viewer.id,
      FieldTaskFilter.fieldAssigned => status == ReportStatus.fieldAssigned,
      FieldTaskFilter.inProgress => status == ReportStatus.inProgress,
      FieldTaskFilter.overdue => entry.overdue,
    };
  }
}

final class FieldOperationCommand {
  FieldOperationCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.incidentId,
    required this.action,
    required this.reason,
    this.assigneeId,
    this.fieldTeamId,
    this.externalWorkOrder,
    this.delayReason,
    this.reestimateMinMinutes,
    this.reestimateMaxMinutes,
    this.resolutionExplanation,
    this.resolutionMediaId,
  }) {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    requireText(incidentId, 'incidentId');
    requireText(reason, 'reason');
    if (expectedRevision < 0) {
      fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
    }
    switch (action) {
      case FieldOperationAction.assignField:
        if ((assigneeId?.trim().isEmpty ?? true) && (fieldTeamId?.trim().isEmpty ?? true)) {
          fail(FailureCode.validation, 'Saha atamasında personel veya ekip zorunludur.');
        }
        break;
      case FieldOperationAction.recordDelay:
        requireText(delayReason ?? '', 'delayReason');
        final min = reestimateMinMinutes ?? 0;
        final max = reestimateMaxMinutes ?? 0;
        if (min < 15 || max <= min || max > 60 * 24 * 30) {
          fail(FailureCode.validation, 'Yeni tahmin aralığı geçersiz.');
        }
        break;
      case FieldOperationAction.resolve:
        requireText(resolutionExplanation ?? '', 'resolutionExplanation');
        break;
      case FieldOperationAction.startProgress:
        break;
    }
  }

  factory FieldOperationCommand.fromJson(JsonMap json) => FieldOperationCommand(
        actorId: expectString(json['actorId'], 'actorId'),
        clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
        expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
        incidentId: expectString(json['incidentId'], 'incidentId'),
        action: expectEnum(json['action'], 'action', enumValues(FieldOperationAction.values)),
        reason: expectString(json['reason'], 'reason'),
        assigneeId: expectNullableString(json['assigneeId'], 'assigneeId'),
        fieldTeamId: expectNullableString(json['fieldTeamId'], 'fieldTeamId'),
        externalWorkOrder: json['externalWorkOrder'] == null
            ? null
            : ExternalWorkOrderRefDto.fromObject(json['externalWorkOrder'], 'externalWorkOrder'),
        delayReason: expectNullableString(json['delayReason'], 'delayReason'),
        reestimateMinMinutes: json['reestimateMinMinutes'] == null
            ? null
            : expectInt(json['reestimateMinMinutes'], 'reestimateMinMinutes'),
        reestimateMaxMinutes: json['reestimateMaxMinutes'] == null
            ? null
            : expectInt(json['reestimateMaxMinutes'], 'reestimateMaxMinutes'),
        resolutionExplanation: expectNullableString(
          json['resolutionExplanation'],
          'resolutionExplanation',
        ),
        resolutionMediaId: expectNullableString(json['resolutionMediaId'], 'resolutionMediaId'),
      );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final String incidentId;
  final FieldOperationAction action;
  final String reason;
  final String? assigneeId;
  final String? fieldTeamId;
  final ExternalWorkOrderRefDto? externalWorkOrder;
  final String? delayReason;
  final int? reestimateMinMinutes;
  final int? reestimateMaxMinutes;
  final String? resolutionExplanation;
  final String? resolutionMediaId;

  JsonMap toJson() => {
        'actorId': actorId,
        'clientMutationId': clientMutationId,
        'expectedRevision': expectedRevision,
        'incidentId': incidentId,
        'action': enumWire(action),
        'reason': reason,
        'assigneeId': assigneeId,
        'fieldTeamId': fieldTeamId,
        'externalWorkOrder': externalWorkOrder?.toJson(),
        'delayReason': delayReason,
        'reestimateMinMinutes': reestimateMinMinutes,
        'reestimateMaxMinutes': reestimateMaxMinutes,
        'resolutionExplanation': resolutionExplanation,
        'resolutionMediaId': resolutionMediaId,
      };
}

extension FieldCommandOperations on SnapshotCommandProcessor {
  Future<MutationResult> fieldOperation(FieldOperationCommand command) {
    return transactionQueue.run(() async {
      final current = await store.read();
      final replay = _fieldMutationAudit(current, command.clientMutationId);
      if (replay != null) {
        if (replay.body['actorId'] != command.actorId) {
          fail(FailureCode.unauthorized, 'clientMutationId başka aktöre ait.');
        }
        return MutationResult(
          snapshot: current,
          resourceId: command.incidentId,
          trackingNumber: null,
          replayed: true,
        );
      }
      if (command.expectedRevision != current.revision) {
        throw CommandConflict(expectedRevision: command.expectedRevision, current: current);
      }
      final actor = _fieldActor(current, command.actorId);
      AuthorizationPolicy.requirePermission(actor, Permission.manageFieldWork);
      final incident = _fieldIncident(current, command.incidentId);
      if (actor.role == UserRole.unitOfficer && actor.unitId != incident.responsibleUnitId) {
        fail(FailureCode.unauthorized, 'Bu olay aktörün birimine ait değil.');
      }
      if (incident.responsibleUnitId == null) {
        fail(FailureCode.invalidTransition, 'Saha işleminden önce olay birime yönlendirilmelidir.');
      }
      final linked = current.payload.reports
          .where((item) => incident.reportIds.contains(item.id))
          .toList(growable: false);
      final operational = linked
          .where((item) => !{
                ReportStatus.merged,
                ReportStatus.rejected,
                ReportStatus.outOfScope,
              }.contains(item.status))
          .toList(growable: false);
      if (operational.isEmpty) {
        fail(FailureCode.validation, 'Saha işlemi için aktif bağlı vatandaş bildirimi bulunamadı.');
      }
      final now = clock.nowUtc();
      var reports = current.payload.reports;
      var updatedIncident = incident;
      final timelines = [...current.payload.timeline];
      final notifications = [...current.payload.notifications];
      final audits = [...current.payload.auditEvents];
      final range = FieldSlaPolicy.targetFor(incident.category, incident.responsibleUnitId!);
      final ordinal = current.revision + 1;
      String auditAction;
      String publicMessageKey;
      String? resolutionPublicRef;

      switch (command.action) {
        case FieldOperationAction.assignField:
          _requireAllStatuses(operational, {ReportStatus.assignedUnit}, ReportStatus.fieldAssigned);
          reports = _replaceLinkedReports(
            reports,
            operational,
            (report) => _fieldCopyReport(
              report,
              status: ReportStatus.fieldAssigned,
              updatedAt: now,
            ),
          );
          final workOrderRefs = command.externalWorkOrder != null
              ? [...incident.workOrderRefs, command.externalWorkOrder!]
              : incident.workOrderRefs.isEmpty
                  ? [
                      ExternalWorkOrderRefDto(
                        sourceSystem: 'DEMO_SIMULATED_WORK_ORDER',
                        externalWorkOrderId: 'DEMO-WO-${ordinal.toString().padLeft(6, '0')}',
                        sourceUpdatedAt: now,
                        syncStatus: 'simulated',
                      ),
                    ]
                  : incident.workOrderRefs;
          updatedIncident = _fieldCopyIncident(
            incident,
            assigneeId: command.assigneeId,
            fieldTeamId: command.fieldTeamId,
            workOrderRefs: workOrderRefs,
            slaStartedAt: incident.slaStartedAt ?? now,
            slaTargetAt: incident.slaTargetAt ?? now.add(range.max),
            slaEstimateMinMinutes: range.min.inMinutes,
            slaEstimateMaxMinutes: range.max.inMinutes,
            updatedAt: now,
          );
          auditAction = 'field_assigned';
          publicMessageKey = 'timeline.field_assigned';
          break;
        case FieldOperationAction.startProgress:
          _requireAllStatuses(operational, {ReportStatus.fieldAssigned}, ReportStatus.inProgress);
          reports = _replaceLinkedReports(
            reports,
            operational,
            (report) => _fieldCopyReport(
              report,
              status: ReportStatus.inProgress,
              updatedAt: now,
            ),
          );
          updatedIncident = _fieldCopyIncident(
            incident,
            slaStartedAt: incident.slaStartedAt ?? now,
            slaTargetAt: incident.slaTargetAt ?? now.add(range.max),
            slaEstimateMinMinutes: incident.slaEstimateMinMinutes ?? range.min.inMinutes,
            slaEstimateMaxMinutes: incident.slaEstimateMaxMinutes ?? range.max.inMinutes,
            updatedAt: now,
          );
          auditAction = 'field_work_started';
          publicMessageKey = 'timeline.field_work_started';
          break;
        case FieldOperationAction.recordDelay:
          if (!operational.any((item) => item.status == ReportStatus.fieldAssigned || item.status == ReportStatus.inProgress)) {
            fail(FailureCode.invalidTransition, 'Gecikme yalnız saha aşamasında kaydedilebilir.');
          }
          updatedIncident = _fieldCopyIncident(
            incident,
            slaDelayReason: command.delayReason,
            reestimatedMinAt: now.add(Duration(minutes: command.reestimateMinMinutes!)),
            reestimatedMaxAt: now.add(Duration(minutes: command.reestimateMaxMinutes!)),
            updatedAt: now,
          );
          auditAction = 'field_delay_recorded';
          publicMessageKey = 'timeline.field_delay_recorded';
          break;
        case FieldOperationAction.resolve:
          _requireAllStatuses(operational, {ReportStatus.inProgress}, ReportStatus.resolved);
          resolutionPublicRef = _safeResolutionMediaRef(current, command.resolutionMediaId);
          final explanation = command.resolutionExplanation!.trim();
          reports = _replaceLinkedReports(
            reports,
            operational,
            (report) => _fieldCopyReport(
              report,
              status: ReportStatus.resolved,
              updatedAt: now,
              resolutionExplanation: explanation,
              resolvedAt: now,
              resolutionPublicMediaRef: resolutionPublicRef,
            ),
          );
          if (incident.status == IncidentStatus.verifiedActive) {
            IncidentTransitionPolicy.requireAllowed(incident.status, IncidentStatus.resolved);
          } else if (incident.status != IncidentStatus.resolved) {
            fail(FailureCode.invalidTransition, 'Yalnız aktif incident çözülebilir.');
          }
          updatedIncident = _fieldCopyIncident(
            incident,
            status: IncidentStatus.resolved,
            slaPausedAt: now,
            resolutionExplanation: explanation,
            resolvedAt: now,
            resolutionPublicMediaRef: resolutionPublicRef,
            updatedAt: now,
          );
          auditAction = 'incident_resolved';
          publicMessageKey = 'timeline.resolution_published';
          break;
      }

      for (final report in linked) {
        final timelineId = 'timeline_${report.id}_${command.action.name}_$ordinal';
        timelines.add(_fieldTimeline(
          id: timelineId,
          resourceId: report.id,
          type: command.action.name,
          at: now,
          publicMessageKey: publicMessageKey,
          detail: command.action == FieldOperationAction.recordDelay
              ? '${command.delayReason}; yeni tahmin ${command.reestimateMinMinutes}–${command.reestimateMaxMinutes} dk, garanti değildir.'
              : command.action == FieldOperationAction.resolve
                  ? command.resolutionExplanation
                  : null,
        ));
        notifications.add(_fieldNotification(
          id: 'notification_${report.id}_${command.action.name}_$ordinal',
          recipientId: report.ownerId,
          eventId: timelineId,
          type: command.action == FieldOperationAction.resolve
              ? NotificationType.resolutionPublished
              : NotificationType.statusChanged,
          route: '/citizen/reports/${report.id}',
          createdAt: now,
        ));
      }
      audits.add(_fieldAudit(
        id: 'audit_${auditAction}_${ordinal}_${incident.id}',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: auditAction,
        resourceId: incident.id,
        at: now,
        reason: command.reason,
        before: {
          'status': enumWire(incident.status),
          'assigneeId': incident.assigneeId,
          'fieldTeamId': incident.fieldTeamId,
          'slaTargetAt': incident.slaTargetAt?.toIso8601String(),
        },
        after: {
          'clientMutationId': command.clientMutationId,
          'status': enumWire(updatedIncident.status),
          'assigneeId': updatedIncident.assigneeId,
          'fieldTeamId': updatedIncident.fieldTeamId,
          'slaTargetAt': updatedIncident.slaTargetAt?.toIso8601String(),
          'slaDelayReason': updatedIncident.slaDelayReason,
          'resolutionPublicMediaRef': resolutionPublicRef,
        },
      ));
      if (command.action == FieldOperationAction.startProgress ||
          command.action == FieldOperationAction.resolve) {
        audits.add(_fieldAudit(
          id: 'audit_metric_${command.action.name}_${ordinal}_${incident.id}',
          actorId: actor.id,
          activeRoleContext: actor.role.name,
          action: 'operational_metric',
          resourceId: incident.id,
          at: now,
          reason: 'WP-15 operational duration marker',
          before: const {},
          after: {
            'metricKey': command.action == FieldOperationAction.startProgress
                ? 'field_start'
                : 'resolution',
            'startedAt': (updatedIncident.slaStartedAt ?? incident.createdAt).toIso8601String(),
            'occurredAt': now.toIso8601String(),
            'durationSeconds': now.difference(updatedIncident.slaStartedAt ?? incident.createdAt).inSeconds,
          },
        ));
      }
      final incidents = [
        for (final item in current.payload.incidents)
          if (item.id == incident.id) updatedIncident else item,
      ];
      _assertFieldInvariants(reports, incidents);
      final next = codec.seal(
        current.copyWith(
          revision: current.revision + 1,
          updatedAt: now,
          checksum: 'sha256:unsealed',
          payload: current.payload.copyWith(
            reports: reports,
            incidents: incidents,
            timeline: timelines,
            notifications: notifications,
            auditEvents: audits,
          ),
        ),
      );
      final committed = await store.write(next);
      return MutationResult(
        snapshot: committed,
        resourceId: incident.id,
        trackingNumber: operational.first.trackingNumber,
        replayed: false,
      );
    });
  }
}

void _requireAllStatuses(
  Iterable<CitizenReportDto> reports,
  Set<ReportStatus> allowedFrom,
  ReportStatus target,
) {
  for (final report in reports) {
    if (!allowedFrom.contains(report.status)) {
      fail(
        FailureCode.invalidTransition,
        '${report.trackingNumber}: ${report.status.name} → ${target.name} geçişi uygun değil.',
      );
    }
    ReportTransitionPolicy.requireAllowed(report.status, target);
  }
}

List<CitizenReportDto> _replaceLinkedReports(
  List<CitizenReportDto> all,
  List<CitizenReportDto> linked,
  CitizenReportDto Function(CitizenReportDto report) map,
) {
  final updates = {for (final report in linked) report.id: map(report)};
  return [for (final report in all) updates[report.id] ?? report];
}

String? _safeResolutionMediaRef(AppSnapshotDto snapshot, String? mediaId) {
  if (mediaId == null) return null;
  for (final media in snapshot.payload.media) {
    if (media.id != mediaId) continue;
    if (media.privacyStatus != PrivacyStatus.safe || media.publicRef == null) {
      fail(FailureCode.privacy, 'Sonuç fotoğrafı kamusal gösterim için güvenli değil.');
    }
    return media.publicRef;
  }
  fail(FailureCode.notFound, 'Sonuç medyası bulunamadı.');
}

UserAccount _fieldActor(AppSnapshotDto snapshot, String actorId) {
  for (final dto in snapshot.payload.accounts) {
    if (dto.id == actorId) {
      return UserAccount(
        id: dto.id,
        role: dto.role,
        permissions: dto.permissions,
        unitId: dto.unitId,
        deletionRequested: dto.deletionRequested,
      );
    }
  }
  fail(FailureCode.unauthorized, 'Demo hesabı bulunamadı.');
}

UrbanIncidentDto _fieldIncident(AppSnapshotDto snapshot, String incidentId) {
  for (final item in snapshot.payload.incidents) {
    if (item.id == incidentId) return item;
  }
  fail(FailureCode.notFound, 'Incident bulunamadı.');
}

OpaqueEntityDto? _fieldMutationAudit(AppSnapshotDto snapshot, String mutationId) {
  for (final event in snapshot.payload.auditEvents) {
    final after = event.body['after'];
    if (after is Map<String, Object?> && after['clientMutationId'] == mutationId) {
      return event;
    }
  }
  return null;
}

CitizenReportDto _fieldCopyReport(
  CitizenReportDto report, {
  required ReportStatus status,
  required DateTime updatedAt,
  String? resolutionExplanation,
  DateTime? resolvedAt,
  String? resolutionPublicMediaRef,
}) {
  return CitizenReportDto(
    id: report.id,
    trackingNumber: report.trackingNumber,
    ownerId: report.ownerId,
    status: status,
    category: report.category,
    latitude: report.latitude,
    longitude: report.longitude,
    createdAt: report.createdAt,
    updatedAt: updatedAt,
    clientMutationId: report.clientMutationId,
    mediaIds: report.mediaIds,
    analysisId: report.analysisId,
    linkedIncidentId: report.linkedIncidentId,
    manualReviewRequired: report.manualReviewRequired,
    riskLevel: report.riskLevel,
    humanDecisionReason: report.humanDecisionReason,
    resolutionExplanation: resolutionExplanation ?? report.resolutionExplanation,
    resolvedAt: resolvedAt ?? report.resolvedAt,
    resolutionPublicMediaRef:
        resolutionPublicMediaRef ?? report.resolutionPublicMediaRef,
  );
}

UrbanIncidentDto _fieldCopyIncident(
  UrbanIncidentDto incident, {
  IncidentStatus? status,
  String? assigneeId,
  String? fieldTeamId,
  List<ExternalWorkOrderRefDto>? workOrderRefs,
  DateTime? slaStartedAt,
  DateTime? slaTargetAt,
  DateTime? slaPausedAt,
  String? slaDelayReason,
  int? slaEstimateMinMinutes,
  int? slaEstimateMaxMinutes,
  DateTime? reestimatedMinAt,
  DateTime? reestimatedMaxAt,
  String? resolutionExplanation,
  DateTime? resolvedAt,
  String? resolutionPublicMediaRef,
  DateTime? updatedAt,
}) {
  return UrbanIncidentDto(
    id: incident.id,
    status: status ?? incident.status,
    category: incident.category,
    latitude: incident.latitude,
    longitude: incident.longitude,
    reportIds: incident.reportIds,
    sourceRecordIds: incident.sourceRecordIds,
    workOrderRefs: workOrderRefs ?? incident.workOrderRefs,
    createdAt: incident.createdAt,
    updatedAt: updatedAt ?? incident.updatedAt,
    responsibleUnitId: incident.responsibleUnitId,
    assigneeId: assigneeId ?? incident.assigneeId,
    fieldTeamId: fieldTeamId ?? incident.fieldTeamId,
    slaStartedAt: slaStartedAt ?? incident.slaStartedAt,
    slaTargetAt: slaTargetAt ?? incident.slaTargetAt,
    slaPausedAt: slaPausedAt ?? incident.slaPausedAt,
    slaDelayReason: slaDelayReason ?? incident.slaDelayReason,
    slaEstimateMinMinutes: slaEstimateMinMinutes ?? incident.slaEstimateMinMinutes,
    slaEstimateMaxMinutes: slaEstimateMaxMinutes ?? incident.slaEstimateMaxMinutes,
    reestimatedMinAt: reestimatedMinAt ?? incident.reestimatedMinAt,
    reestimatedMaxAt: reestimatedMaxAt ?? incident.reestimatedMaxAt,
    resolutionExplanation: resolutionExplanation ?? incident.resolutionExplanation,
    resolvedAt: resolvedAt ?? incident.resolvedAt,
    resolutionPublicMediaRef:
        resolutionPublicMediaRef ?? incident.resolutionPublicMediaRef,
    citizenResolutionConfirmed: incident.citizenResolutionConfirmed,
  );
}

void _assertFieldInvariants(
  Iterable<CitizenReportDto> reports,
  Iterable<UrbanIncidentDto> incidents,
) {
  final reportById = {for (final item in reports) item.id: item};
  for (final incident in incidents) {
    for (final id in incident.reportIds) {
      if (!reportById.containsKey(id)) {
        fail(FailureCode.corruption, 'Incident report referansı bulunamadı.');
      }
    }
    if (incident.status == IncidentStatus.resolved &&
        (incident.resolutionExplanation?.trim().isEmpty ?? true)) {
      fail(FailureCode.corruption, 'Çözülmüş incident açıklama taşımalıdır.');
    }
  }
  for (final report in reports) {
    if (report.status == ReportStatus.resolved &&
        (report.resolutionExplanation?.trim().isEmpty ?? true)) {
      fail(FailureCode.corruption, 'Çözülmüş report açıklama taşımalıdır.');
    }
  }
}

OpaqueEntityDto _fieldTimeline({
  required String id,
  required String resourceId,
  required String type,
  required DateTime at,
  required String publicMessageKey,
  String? detail,
}) =>
    OpaqueEntityDto(
      id: id,
      body: {
        'id': id,
        'resourceId': resourceId,
        'type': type,
        'at': at.toIso8601String(),
        'publicMessageKey': publicMessageKey,
        if (detail != null) 'detail': detail,
      },
    );

OpaqueEntityDto _fieldAudit({
  required String id,
  required String actorId,
  required String activeRoleContext,
  required String action,
  required String resourceId,
  required DateTime at,
  required String reason,
  required JsonMap before,
  required JsonMap after,
}) =>
    OpaqueEntityDto(
      id: id,
      body: {
        'id': id,
        'actorId': actorId,
        'activeRoleContext': activeRoleContext,
        'action': action,
        'resourceId': resourceId,
        'at': at.toIso8601String(),
        'reason': reason,
        'before': before,
        'after': after,
      },
    );

OpaqueEntityDto _fieldNotification({
  required String id,
  required String recipientId,
  required String eventId,
  required NotificationType type,
  required String route,
  required DateTime createdAt,
}) =>
    OpaqueEntityDto(
      id: id,
      body: {
        'id': id,
        'recipientId': recipientId,
        'eventId': eventId,
        'type': enumWire(type),
        'route': route,
        'createdAt': createdAt.toIso8601String(),
      },
    );
