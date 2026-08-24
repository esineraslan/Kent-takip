import 'package:kent_takip_application/src/commands.dart';
import 'package:kent_takip_application/src/field_sla.dart';
import 'package:kent_takip_application/src/staff_operations.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

enum ReviewLeaseAction { acquire, release, takeOver }

enum StaffDecisionAction {
  reject,
  outOfScope,
  requestAdditionalInfo,
  merge,
  routeToUnit,
  routeToDistrict,
  transferBack,
}

abstract final class StaffDecisionReasonCodes {
  static const insufficientEvidence = 'insufficient_evidence';
  static const notMunicipalScope = 'not_municipal_scope';
  static const privateProperty = 'private_property';
  static const outsideServiceBoundary = 'outside_service_boundary';
  static const invalidOrAbusive = 'invalid_or_abusive';

  static const allowed = <String>{
    insufficientEvidence,
    notMunicipalScope,
    privateProperty,
    outsideServiceBoundary,
    invalidOrAbusive,
  };
}

final class ReviewLeaseCommand {
  ReviewLeaseCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.reportId,
    required this.action,
    this.reason,
    this.leaseDuration = const Duration(minutes: 5),
  }) {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    requireText(reportId, 'reportId');
    if (expectedRevision < 0) {
      fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
    }
    if (leaseDuration < const Duration(minutes: 1) ||
        leaseDuration > const Duration(minutes: 15)) {
      fail(FailureCode.validation, 'İnceleme lease süresi 1–15 dakika arasında olmalıdır.');
    }
    if (action == ReviewLeaseAction.takeOver && (reason?.trim().isEmpty ?? true)) {
      fail(FailureCode.validation, 'Lease devralma gerekçesi zorunludur.', field: 'reason');
    }
  }

  factory ReviewLeaseCommand.fromJson(JsonMap json) => ReviewLeaseCommand(
        actorId: expectString(json['actorId'], 'actorId'),
        clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
        expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
        reportId: expectString(json['reportId'], 'reportId'),
        action: expectEnum(
          json['action'],
          'action',
          enumValues(ReviewLeaseAction.values),
        ),
        reason: expectNullableString(json['reason'], 'reason'),
        leaseDuration: Duration(
          seconds: json['leaseSeconds'] == null
              ? 300
              : expectInt(json['leaseSeconds'], 'leaseSeconds'),
        ),
      );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final String reportId;
  final ReviewLeaseAction action;
  final String? reason;
  final Duration leaseDuration;

  JsonMap toJson() => {
        'actorId': actorId,
        'clientMutationId': clientMutationId,
        'expectedRevision': expectedRevision,
        'reportId': reportId,
        'action': enumWire(action),
        'reason': reason,
        'leaseSeconds': leaseDuration.inSeconds,
      };
}

final class StaffDecisionCommand {
  StaffDecisionCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.reportId,
    required this.action,
    required this.reason,
    this.reasonCode,
    this.targetId,
    this.targetReportId,
    this.message,
    this.aiOverrideReason,
    this.confirmCritical = false,
  }) {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    requireText(reportId, 'reportId');
    requireText(reason, 'reason');
    if (expectedRevision < 0) {
      fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
    }
    switch (action) {
      case StaffDecisionAction.routeToUnit:
      case StaffDecisionAction.routeToDistrict:
        requireText(targetId ?? '', 'targetId');
        break;
      case StaffDecisionAction.merge:
        requireText(targetReportId ?? '', 'targetReportId');
        break;
      case StaffDecisionAction.requestAdditionalInfo:
        requireText(message ?? '', 'message');
        break;
      case StaffDecisionAction.reject:
      case StaffDecisionAction.outOfScope:
        requireText(reasonCode ?? '', 'reasonCode');
        if (!StaffDecisionReasonCodes.allowed.contains(reasonCode)) {
          fail(
            FailureCode.validation,
            'Ret / kapsam dışı neden kodu desteklenmiyor.',
            field: 'reasonCode',
          );
        }
        break;
      case StaffDecisionAction.transferBack:
        break;
    }
  }

  factory StaffDecisionCommand.fromJson(JsonMap json) => StaffDecisionCommand(
        actorId: expectString(json['actorId'], 'actorId'),
        clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
        expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
        reportId: expectString(json['reportId'], 'reportId'),
        action: expectEnum(
          json['action'],
          'action',
          enumValues(StaffDecisionAction.values),
        ),
        reason: expectString(json['reason'], 'reason'),
        reasonCode: expectNullableString(json['reasonCode'], 'reasonCode'),
        targetId: expectNullableString(json['targetId'], 'targetId'),
        targetReportId: expectNullableString(json['targetReportId'], 'targetReportId'),
        message: expectNullableString(json['message'], 'message'),
        aiOverrideReason: expectNullableString(json['aiOverrideReason'], 'aiOverrideReason'),
        confirmCritical: json['confirmCritical'] == null
            ? false
            : expectBool(json['confirmCritical'], 'confirmCritical'),
      );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final String reportId;
  final StaffDecisionAction action;
  final String reason;
  final String? reasonCode;
  final String? targetId;
  final String? targetReportId;
  final String? message;
  final String? aiOverrideReason;
  final bool confirmCritical;

  JsonMap toJson() => {
        'actorId': actorId,
        'clientMutationId': clientMutationId,
        'expectedRevision': expectedRevision,
        'reportId': reportId,
        'action': enumWire(action),
        'reason': reason,
        'reasonCode': reasonCode,
        'targetId': targetId,
        'targetReportId': targetReportId,
        'message': message,
        'aiOverrideReason': aiOverrideReason,
        'confirmCritical': confirmCritical,
      };
}

extension StaffCommandOperations on SnapshotCommandProcessor {
  Future<MutationResult> reviewLease(ReviewLeaseCommand command) {
    return transactionQueue.run(() async {
      final current = await store.read();
      final replay = _mutationAudit(current, command.clientMutationId);
      if (replay != null) {
        _requireReplayActor(replay, command.actorId);
        return MutationResult(
          snapshot: current,
          resourceId: command.reportId,
          trackingNumber: _findReport(current, command.reportId).trackingNumber,
          replayed: true,
        );
      }
      final actor = _findActor(current, command.actorId);
      AuthorizationPolicy.requirePermission(actor, Permission.viewReviewQueue);
      AuthorizationPolicy.requirePermission(actor, Permission.reviewReport);
      _requireRevision(command.expectedRevision, current);
      final report = _findReport(current, command.reportId);
      _requireReviewable(current, report);
      final now = clock.nowUtc();
      final active = StaffOperationsProjection.activeLease(current, report.id, now);
      final afterRevision = current.revision + 1;
      late String action;
      late JsonMap after;
      late String reason;

      switch (command.action) {
        case ReviewLeaseAction.acquire:
          if (active != null && active.lockedBy != actor.id) {
            fail(
              FailureCode.conflict,
              'Kayıt ${active.lockedBy} tarafından inceleniyor.',
              retryable: true,
            );
          }
          action = 'review_lease_acquired';
          reason = 'Staff opened report review workspace';
          after = {
            'lockedBy': actor.id,
            'lockedAt': now.toIso8601String(),
            'expiresAt': now.add(command.leaseDuration).toIso8601String(),
            'revision': afterRevision,
            'clientMutationId': command.clientMutationId,
          };
          break;
        case ReviewLeaseAction.release:
          if (active != null && active.lockedBy != actor.id) {
            fail(FailureCode.unauthorized, 'Başka personelin lease kaydı bırakılamaz.');
          }
          action = 'review_lease_released';
          reason = command.reason?.trim().isNotEmpty == true
              ? command.reason!.trim()
              : 'Staff left report review workspace';
          after = {
            'lockedBy': actor.id,
            'releasedAt': now.toIso8601String(),
            'revision': afterRevision,
            'clientMutationId': command.clientMutationId,
          };
          break;
        case ReviewLeaseAction.takeOver:
          if (actor.role != UserRole.demoSupervisor && actor.role != UserRole.systemAdmin) {
            fail(FailureCode.unauthorized, 'Lease devralma supervisor yetkisi ister.');
          }
          if (active == null || active.lockedBy == actor.id) {
            fail(FailureCode.validation, 'Devralınacak başka bir aktif lease bulunamadı.');
          }
          action = 'review_lease_taken_over';
          reason = command.reason!.trim();
          after = {
            'lockedBy': actor.id,
            'previousLockedBy': active.lockedBy,
            'lockedAt': now.toIso8601String(),
            'expiresAt': now.add(command.leaseDuration).toIso8601String(),
            'revision': afterRevision,
            'clientMutationId': command.clientMutationId,
          };
          break;
      }

      final audit = _staffAudit(
        id: 'audit_${action}_${afterRevision}_${report.id}',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: action,
        resourceId: report.id,
        at: now,
        reason: reason,
        before: active == null
            ? const {}
            : {
                'lockedBy': active.lockedBy,
                'expiresAt': active.expiresAt.toIso8601String(),
                'revision': active.revision,
              },
        after: after,
      );
      final next = _sealStaff(
        this,
        current,
        current.payload.copyWith(
          auditEvents: [...current.payload.auditEvents, audit],
        ),
        now,
      );
      final committed = await store.write(next);
      return MutationResult(
        snapshot: committed,
        resourceId: report.id,
        trackingNumber: report.trackingNumber,
        replayed: false,
      );
    });
  }

  Future<MutationResult> staffDecision(StaffDecisionCommand command) {
    return transactionQueue.run(() async {
      final current = await store.read();
      final replay = _mutationAudit(current, command.clientMutationId);
      if (replay != null) {
        _requireReplayActor(replay, command.actorId);
        final report = _findReport(current, command.reportId);
        return MutationResult(
          snapshot: current,
          resourceId: report.linkedIncidentId ?? report.id,
          trackingNumber: report.trackingNumber,
          replayed: true,
        );
      }

      // Common pipeline: authorize -> validate -> stale check -> mutate ->
      // invariant -> persist -> audit -> event.
      final actor = _findActor(current, command.actorId);
      AuthorizationPolicy.requirePermission(actor, Permission.reviewReport);
      _requireRevision(command.expectedRevision, current);
      final report = _findReport(current, command.reportId);
      final now = clock.nowUtc();
      _requireActorLease(current, report.id, actor.id, now);
      _requireReviewOrTransferState(report, command.action);

      var reports = current.payload.reports;
      var incidents = current.payload.incidents;
      final timeline = [...current.payload.timeline];
      final notifications = [...current.payload.notifications];
      final audits = [...current.payload.auditEvents];
      final ordinal = current.revision + 1;
      String resultResourceId = report.linkedIncidentId ?? report.id;
      CitizenReportDto updatedReport = report;
      String publicMessageKey;
      String auditAction;
      final before = <String, Object?>{
        'status': enumWire(report.status),
        'linkedIncidentId': report.linkedIncidentId,
      };
      final after = <String, Object?>{
        'clientMutationId': command.clientMutationId,
      };

      switch (command.action) {
        case StaffDecisionAction.reject:
        case StaffDecisionAction.outOfScope:
          if (report.riskLevel == RiskLevel.criticalSignal) {
            if (!command.confirmCritical ||
                (actor.role != UserRole.demoSupervisor && actor.role != UserRole.systemAdmin)) {
              fail(
                FailureCode.unauthorized,
                'Kritik kayıt reddi supervisor ikinci onayı ister.',
              );
            }
          }
          final target = command.action == StaffDecisionAction.reject
              ? ReportStatus.rejected
              : ReportStatus.outOfScope;
          _requireDecisionTransition(report.status, target);
          updatedReport = _copyStaffReport(
            report,
            status: target,
            updatedAt: now,
            humanDecisionReason: command.reason,
          );
          auditAction = command.action == StaffDecisionAction.reject
              ? 'report_rejected'
              : 'report_out_of_scope';
          publicMessageKey = command.action == StaffDecisionAction.reject
              ? 'timeline.report_rejected'
              : 'timeline.report_out_of_scope';
          after['status'] = enumWire(target);
          after['reasonCode'] = command.reasonCode;
          after['criticalSecondApproval'] = command.confirmCritical;
          break;

        case StaffDecisionAction.requestAdditionalInfo:
          _requireDecisionTransition(report.status, ReportStatus.additionalInfoRequired);
          updatedReport = _copyStaffReport(
            report,
            status: ReportStatus.additionalInfoRequired,
            updatedAt: now,
            humanDecisionReason: command.reason,
          );
          auditAction = 'additional_info_requested';
          publicMessageKey = 'timeline.additional_info_requested';
          after['status'] = enumWire(ReportStatus.additionalInfoRequired);
          after['request'] = command.message;
          break;

        case StaffDecisionAction.merge:
          AuthorizationPolicy.requirePermission(actor, Permission.mergeReport);
          final targetReport = _findReport(current, command.targetReportId!);
          if (targetReport.id == report.id) {
            fail(FailureCode.validation, 'Report kendisiyle birleştirilemez.');
          }
          if ({ReportStatus.merged, ReportStatus.rejected, ReportStatus.outOfScope}
              .contains(targetReport.status)) {
            fail(FailureCode.invalidTransition, 'Hedef report merge için uygun değil.');
          }
          if (report.status == ReportStatus.merged) {
            fail(FailureCode.invalidTransition, 'Birleştirilmiş report tekrar merge edilemez.');
          }
          UrbanIncidentDto incident;
          if (targetReport.linkedIncidentId != null) {
            incident = _findIncident(current, targetReport.linkedIncidentId!);
            if (incident.reportIds.contains(report.id)) {
              fail(FailureCode.conflict, 'Report zaten bu incident altında birleştirilmiş.');
            }
            incident = _copyIncident(
              incident,
              reportIds: {...incident.reportIds, report.id}.toList(),
              updatedAt: now,
            );
            incidents = [
              for (final item in incidents)
                if (item.id == incident.id) incident else item,
            ];
          } else {
            final incidentId = _uniqueStaffId(
              'inc_merge_',
              ordinal,
              incidents.map((item) => item.id).toSet(),
            );
            incident = UrbanIncidentDto(
              id: incidentId,
              status: IncidentStatus.pendingVerification,
              category: targetReport.category,
              latitude: targetReport.latitude,
              longitude: targetReport.longitude,
              reportIds: [targetReport.id, report.id],
              sourceRecordIds: const [],
              createdAt: now,
              updatedAt: now,
            );
            incidents = [...incidents, incident];
            final linkedTarget = _copyStaffReport(
              targetReport,
              linkedIncidentId: incidentId,
              updatedAt: now,
            );
            reports = [
              for (final item in reports)
                if (item.id == targetReport.id) linkedTarget else item,
            ];
          }
          _requireDecisionTransition(report.status, ReportStatus.merged);
          updatedReport = _copyStaffReport(
            report,
            status: ReportStatus.merged,
            linkedIncidentId: incident.id,
            updatedAt: now,
            humanDecisionReason: command.reason,
          );
          resultResourceId = incident.id;
          auditAction = 'report_merged';
          publicMessageKey = 'timeline.report_merged';
          after['status'] = enumWire(ReportStatus.merged);
          after['incidentId'] = incident.id;
          after['targetReportId'] = targetReport.id;
          break;

        case StaffDecisionAction.routeToUnit:
        case StaffDecisionAction.routeToDistrict:
          AuthorizationPolicy.requirePermission(actor, Permission.routeReport);
          final targetId = command.targetId!;
          _requireAiOverrideIfNeeded(current, report, targetId, command.aiOverrideReason);
          if (report.status != ReportStatus.assignedUnit || report.linkedIncidentId == null) {
            fail(
              FailureCode.invalidTransition,
              'Yönlendirme yalnız insan doğrulamasıyla incident oluşturulmuş atanmış kayıtta yapılır.',
            );
          }
          final incident = _findIncident(current, report.linkedIncidentId!);
          if (incident.status != IncidentStatus.verifiedActive) {
            fail(FailureCode.invalidTransition, 'Yönlendirme için incident doğrulanmış ve aktif olmalıdır.');
          }
          before['responsibleUnitId'] = incident.responsibleUnitId;
          final sla = FieldSlaPolicy.targetFor(incident.category, targetId);
          final changed = _copyIncident(
            incident,
            responsibleUnitId: targetId,
            slaStartedAt: now,
            slaTargetAt: now.add(sla.max),
            slaEstimateMinMinutes: sla.min.inMinutes,
            slaEstimateMaxMinutes: sla.max.inMinutes,
            updatedAt: now,
          );
          incidents = [
            for (final item in incidents)
              if (item.id == changed.id) changed else item,
          ];
          resultResourceId = changed.id;
          updatedReport = _copyStaffReport(
            report,
            updatedAt: now,
            humanDecisionReason: command.reason,
          );
          auditAction = command.action == StaffDecisionAction.routeToUnit
              ? 'report_routed_to_unit'
              : 'report_routed_to_district';
          publicMessageKey = command.action == StaffDecisionAction.routeToUnit
              ? 'timeline.report_routed_to_unit'
              : 'timeline.report_routed_to_district';
          after['status'] = enumWire(updatedReport.status);
          after['targetId'] = targetId;
          after['routingKind'] = command.action == StaffDecisionAction.routeToUnit
              ? 'ibb_unit'
              : 'district_municipality';
          after['aiOverrideReason'] = command.aiOverrideReason;
          after['slaTargetAt'] = changed.slaTargetAt?.toIso8601String();
          after['slaLabel'] = sla.label;
          break;

        case StaffDecisionAction.transferBack:
          AuthorizationPolicy.requirePermission(actor, Permission.routeReport);
          if (report.status != ReportStatus.assignedUnit) {
            fail(FailureCode.invalidTransition, 'Geri aktarım yalnız atanmış kayıtta yapılır.');
          }
          ReportTransitionPolicy.requireAllowed(report.status, ReportStatus.ibbReview);
          updatedReport = _copyStaffReport(
            report,
            status: ReportStatus.ibbReview,
            updatedAt: now,
            humanDecisionReason: command.reason,
          );
          if (report.linkedIncidentId != null) {
            final incident = _findIncident(current, report.linkedIncidentId!);
            before['responsibleUnitId'] = incident.responsibleUnitId;
            final changed = _copyIncident(
              incident,
              clearResponsibleUnit: true,
              clearOperationalOwnership: true,
              updatedAt: now,
            );
            incidents = [
              for (final item in incidents)
                if (item.id == changed.id) changed else item,
            ];
            resultResourceId = changed.id;
            after['previousResponsibleUnitId'] = incident.responsibleUnitId;
            after['responsibleUnitId'] = null;
          }
          auditAction = 'report_transferred_back';
          publicMessageKey = 'timeline.report_transferred_back';
          after['status'] = enumWire(ReportStatus.ibbReview);
          break;
      }

      reports = [
        for (final item in reports)
          if (item.id == report.id) updatedReport else item,
      ];

      _assertStaffInvariants(reports, incidents);
      final timelineEvent = _staffTimeline(
        id: 'timeline_${report.id}_${auditAction}_$ordinal',
        resourceId: report.id,
        type: auditAction,
        at: now,
        publicMessageKey: publicMessageKey,
        detail: command.action == StaffDecisionAction.requestAdditionalInfo
            ? command.message
            : command.reason,
      );
      timeline.add(timelineEvent);
      final audit = _staffAudit(
        id: 'audit_${report.id}_${auditAction}_$ordinal',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: auditAction,
        resourceId: report.id,
        at: now,
        reason: command.reason,
        before: before,
        after: after,
      );
      audits.add(audit);
      if (command.action == StaffDecisionAction.merge) {
        audits.add(_staffAudit(
          id: 'audit_metric_duplicate_cluster_${report.id}_$ordinal',
          actorId: actor.id,
          activeRoleContext: actor.role.name,
          action: 'operational_metric',
          resourceId: resultResourceId,
          at: now,
          reason: 'WP-23 privacy-safe duplicate cluster metric',
          before: const {},
          after: {
            'metricKey': 'duplicate_cluster',
            'occurredAt': now.toIso8601String(),
          },
        ));
      }
      if ((command.action == StaffDecisionAction.routeToUnit ||
              command.action == StaffDecisionAction.routeToDistrict) &&
          (command.aiOverrideReason?.trim().isNotEmpty ?? false)) {
        audits.add(_staffAudit(
          id: 'audit_metric_staff_override_${report.id}_$ordinal',
          actorId: actor.id,
          activeRoleContext: actor.role.name,
          action: 'operational_metric',
          resourceId: report.id,
          at: now,
          reason: 'WP-23 privacy-safe staff AI override metric',
          before: const {},
          after: {
            'metricKey': 'staff_override',
            'occurredAt': now.toIso8601String(),
          },
        ));
      }
      if (command.action == StaffDecisionAction.routeToUnit ||
          command.action == StaffDecisionAction.routeToDistrict) {
        audits.add(_staffAudit(
          id: 'audit_metric_routing_${report.id}_$ordinal',
          actorId: actor.id,
          activeRoleContext: actor.role.name,
          action: 'operational_metric',
          resourceId: resultResourceId,
          at: now,
          reason: 'WP-15 routing duration marker',
          before: const {},
          after: {
            'metricKey': 'routing',
            'startedAt': report.updatedAt.toIso8601String(),
            'occurredAt': now.toIso8601String(),
            'durationSeconds': now.difference(report.updatedAt).inSeconds,
          },
        ));
      }
      notifications.add(
        _staffNotification(
          id: 'notification_${report.id}_${auditAction}_$ordinal',
          recipientId: report.ownerId,
          eventId: timelineEvent.id,
          type: command.action == StaffDecisionAction.requestAdditionalInfo
              ? NotificationType.additionalInfoRequested
              : NotificationType.statusChanged,
          route: '/citizen/reports/${report.id}',
          createdAt: now,
        ),
      );

      final next = _sealStaff(
        this,
        current,
        current.payload.copyWith(
          reports: reports,
          incidents: incidents,
          timeline: timeline,
          notifications: notifications,
          auditEvents: audits,
        ),
        now,
      );
      final committed = await store.write(next);
      return MutationResult(
        snapshot: committed,
        resourceId: resultResourceId,
        trackingNumber: updatedReport.trackingNumber,
        replayed: false,
      );
    });
  }
}

void _requireRevision(int expected, AppSnapshotDto current) {
  if (expected != current.revision) {
    throw CommandConflict(expectedRevision: expected, current: current);
  }
}

void _requireActorLease(
  AppSnapshotDto snapshot,
  String reportId,
  String actorId,
  DateTime now,
) {
  final lease = StaffOperationsProjection.activeLease(snapshot, reportId, now);
  if (lease == null) {
    fail(FailureCode.conflict, 'Karar öncesi aktif inceleme lease’i alınmalıdır.', retryable: true);
  }
  if (lease.lockedBy != actorId) {
    fail(FailureCode.conflict, 'Kayıt başka personel tarafından inceleniyor.', retryable: true);
  }
}

void _requireReviewable(AppSnapshotDto snapshot, CitizenReportDto report) {
  if ({
    ReportStatus.received,
    ReportStatus.aiReview,
    ReportStatus.ibbReview,
    ReportStatus.manualReview,
    ReportStatus.criticalReview,
    ReportStatus.assignedUnit,
  }.contains(report.status)) {
    return;
  }
  if (report.status == ReportStatus.resolved && _hasReopenReview(snapshot, report)) {
    return;
  }
  fail(FailureCode.invalidTransition, 'Kayıt personel incelemesine açık değil.');
}

bool _hasReopenReview(AppSnapshotDto snapshot, CitizenReportDto report) {
  final incidentId = report.linkedIncidentId;
  if (incidentId == null) return false;
  for (final signal in snapshot.payload.corroborations) {
    if (signal.body['incidentId'] == incidentId &&
        signal.body['reopenReviewRequested'] == true) {
      return true;
    }
  }
  return false;
}

void _requireReviewOrTransferState(CitizenReportDto report, StaffDecisionAction action) {
  switch (action) {
    case StaffDecisionAction.routeToUnit:
    case StaffDecisionAction.routeToDistrict:
    case StaffDecisionAction.transferBack:
      if (report.status != ReportStatus.assignedUnit) {
        fail(
          FailureCode.invalidTransition,
          'Yönlendirme/geri aktarım için report insan doğrulaması sonrası atanmış olmalıdır.',
        );
      }
      return;
    case StaffDecisionAction.reject:
    case StaffDecisionAction.outOfScope:
    case StaffDecisionAction.requestAdditionalInfo:
    case StaffDecisionAction.merge:
      if (!{
        ReportStatus.received,
        ReportStatus.aiReview,
        ReportStatus.ibbReview,
        ReportStatus.manualReview,
        ReportStatus.criticalReview,
      }.contains(report.status)) {
        fail(
          FailureCode.invalidTransition,
          'Bu karar yalnız doğrulama öncesi belediye inceleme durumunda verilebilir.',
        );
      }
      return;
  }
}

void _requireDecisionTransition(ReportStatus from, ReportStatus to) {
  if (from == ReportStatus.received ||
      from == ReportStatus.aiReview ||
      from == ReportStatus.manualReview ||
      from == ReportStatus.criticalReview) {
    if (from != ReportStatus.ibbReview) {
      if (from == ReportStatus.criticalReview || from == ReportStatus.manualReview) {
        ReportTransitionPolicy.requireAllowed(from, ReportStatus.ibbReview);
      } else if (from == ReportStatus.received || from == ReportStatus.aiReview) {
        ReportTransitionPolicy.requireAllowed(from, ReportStatus.ibbReview);
      }
    }
    ReportTransitionPolicy.requireAllowed(ReportStatus.ibbReview, to);
    return;
  }
  ReportTransitionPolicy.requireAllowed(from, to);
}

void _requireAiOverrideIfNeeded(
  AppSnapshotDto snapshot,
  CitizenReportDto report,
  String targetId,
  String? overrideReason,
) {
  AiAnalysisDto? analysis;
  for (final item in snapshot.payload.analyses) {
    if (item.id == report.analysisId) analysis = item;
  }
  if (analysis == null) return;
  String? suggested;
  for (final code in analysis.reasonCodes) {
    if (code.startsWith('unit:') && code.length > 5) suggested = code.substring(5);
  }
  if (suggested != null && suggested != targetId && (overrideReason?.trim().isEmpty ?? true)) {
    fail(
      FailureCode.validation,
      'AI birim önerisi değiştirildiğinde override gerekçesi zorunludur.',
      field: 'aiOverrideReason',
    );
  }
}

UserAccount _findActor(AppSnapshotDto snapshot, String actorId) {
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

CitizenReportDto _findReport(AppSnapshotDto snapshot, String reportId) {
  for (final report in snapshot.payload.reports) {
    if (report.id == reportId) return report;
  }
  fail(FailureCode.notFound, 'Report bulunamadı.');
}

UrbanIncidentDto _findIncident(AppSnapshotDto snapshot, String incidentId) {
  for (final incident in snapshot.payload.incidents) {
    if (incident.id == incidentId) return incident;
  }
  fail(FailureCode.notFound, 'Incident bulunamadı.');
}

OpaqueEntityDto? _mutationAudit(AppSnapshotDto snapshot, String mutationId) {
  for (final event in snapshot.payload.auditEvents) {
    final after = event.body['after'];
    if (after is Map<String, Object?> && after['clientMutationId'] == mutationId) {
      return event;
    }
  }
  return null;
}

void _requireReplayActor(OpaqueEntityDto event, String actorId) {
  if (event.body['actorId'] != actorId) {
    fail(FailureCode.unauthorized, 'clientMutationId başka aktöre ait.');
  }
}

CitizenReportDto _copyStaffReport(
  CitizenReportDto report, {
  ReportStatus? status,
  String? linkedIncidentId,
  bool preserveLinkedIncident = true,
  DateTime? updatedAt,
  String? humanDecisionReason,
}) {
  return CitizenReportDto(
    id: report.id,
    trackingNumber: report.trackingNumber,
    ownerId: report.ownerId,
    status: status ?? report.status,
    category: report.category,
    latitude: report.latitude,
    longitude: report.longitude,
    createdAt: report.createdAt,
    updatedAt: updatedAt ?? report.updatedAt,
    clientMutationId: report.clientMutationId,
    mediaIds: report.mediaIds,
    analysisId: report.analysisId,
    linkedIncidentId: preserveLinkedIncident
        ? linkedIncidentId ?? report.linkedIncidentId
        : linkedIncidentId,
    manualReviewRequired: report.manualReviewRequired,
    riskLevel: report.riskLevel,
    humanDecisionReason: humanDecisionReason ?? report.humanDecisionReason,
    resolutionExplanation: report.resolutionExplanation,
    resolvedAt: report.resolvedAt,
    resolutionPublicMediaRef: report.resolutionPublicMediaRef,
  );
}

UrbanIncidentDto _copyIncident(
  UrbanIncidentDto incident, {
  IncidentStatus? status,
  List<String>? reportIds,
  String? responsibleUnitId,
  bool clearResponsibleUnit = false,
  bool clearOperationalOwnership = false,
  DateTime? slaStartedAt,
  DateTime? slaTargetAt,
  int? slaEstimateMinMinutes,
  int? slaEstimateMaxMinutes,
  DateTime? updatedAt,
}) {
  return UrbanIncidentDto(
    id: incident.id,
    status: status ?? incident.status,
    category: incident.category,
    latitude: incident.latitude,
    longitude: incident.longitude,
    reportIds: reportIds ?? incident.reportIds,
    sourceRecordIds: incident.sourceRecordIds,
    workOrderRefs: incident.workOrderRefs,
    createdAt: incident.createdAt,
    updatedAt: updatedAt ?? incident.updatedAt,
    responsibleUnitId:
        clearResponsibleUnit ? null : responsibleUnitId ?? incident.responsibleUnitId,
    assigneeId: clearOperationalOwnership ? null : incident.assigneeId,
    fieldTeamId: clearOperationalOwnership ? null : incident.fieldTeamId,
    slaStartedAt: clearOperationalOwnership ? null : slaStartedAt ?? incident.slaStartedAt,
    slaTargetAt: clearOperationalOwnership ? null : slaTargetAt ?? incident.slaTargetAt,
    slaPausedAt: clearOperationalOwnership ? null : incident.slaPausedAt,
    slaDelayReason: clearOperationalOwnership ? null : incident.slaDelayReason,
    slaEstimateMinMinutes:
        clearOperationalOwnership ? null : slaEstimateMinMinutes ?? incident.slaEstimateMinMinutes,
    slaEstimateMaxMinutes:
        clearOperationalOwnership ? null : slaEstimateMaxMinutes ?? incident.slaEstimateMaxMinutes,
    reestimatedMinAt: clearOperationalOwnership ? null : incident.reestimatedMinAt,
    reestimatedMaxAt: clearOperationalOwnership ? null : incident.reestimatedMaxAt,
    resolutionExplanation: incident.resolutionExplanation,
    resolvedAt: incident.resolvedAt,
    resolutionPublicMediaRef: incident.resolutionPublicMediaRef,
    citizenResolutionConfirmed: incident.citizenResolutionConfirmed,
  );
}

void _assertStaffInvariants(
  Iterable<CitizenReportDto> reports,
  Iterable<UrbanIncidentDto> incidents,
) {
  final incidentById = {for (final item in incidents) item.id: item};
  final tracking = <String>{};
  for (final report in reports) {
    if (!tracking.add(report.trackingNumber)) {
      fail(FailureCode.corruption, 'Tracking numarası tekil olmalıdır.');
    }
    if (report.status == ReportStatus.merged) {
      final incident = report.linkedIncidentId == null
          ? null
          : incidentById[report.linkedIncidentId!];
      if (incident == null || !incident.reportIds.contains(report.id)) {
        fail(FailureCode.corruption, 'Merged report kanonik incident bağlantısını kaybetti.');
      }
    }
  }
  for (final incident in incidents) {
    if (incident.reportIds.toSet().length != incident.reportIds.length) {
      fail(FailureCode.corruption, 'Incident report referansı tekrarlı olamaz.');
    }
  }
}

AppSnapshotDto _sealStaff(
  SnapshotCommandProcessor processor,
  AppSnapshotDto current,
  SnapshotPayloadDto payload,
  DateTime now,
) {
  return processor.codec.seal(
    current.copyWith(
      revision: current.revision + 1,
      updatedAt: now,
      checksum: 'sha256:unsealed',
      payload: payload,
    ),
  );
}

OpaqueEntityDto _staffTimeline({
  required String id,
  required String resourceId,
  required String type,
  required DateTime at,
  required String publicMessageKey,
  String? detail,
}) {
  return OpaqueEntityDto(
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
}

OpaqueEntityDto _staffAudit({
  required String id,
  required String actorId,
  required String activeRoleContext,
  required String action,
  required String resourceId,
  required DateTime at,
  required String reason,
  required JsonMap before,
  required JsonMap after,
}) {
  return OpaqueEntityDto(
    id: id,
    body: {
      'id': id,
      'actorId': actorId,
      'action': action,
      'resourceId': resourceId,
      'at': at.toIso8601String(),
      'reason': reason,
      'before': before,
      'after': after,
    },
  );
}

OpaqueEntityDto _staffNotification({
  required String id,
  required String recipientId,
  required String eventId,
  required NotificationType type,
  required String route,
  required DateTime createdAt,
}) {
  return OpaqueEntityDto(
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
}

String _uniqueStaffId(String prefix, int ordinal, Set<String> existing) {
  var value = ordinal;
  while (true) {
    final candidate = '$prefix${value.toString().padLeft(6, '0')}';
    if (!existing.contains(candidate)) return candidate;
    value += 1;
  }
}
