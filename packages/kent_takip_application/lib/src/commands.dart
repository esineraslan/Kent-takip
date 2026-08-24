import 'package:kent_takip_application/src/field_sla.dart';
import 'package:kent_takip_application/src/security_hardening.dart';
import 'package:kent_takip_application/src/staff_operations.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';

final class CreateReportCommand {
  CreateReportCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.media = const [],
    this.analysis,
    this.manualReviewRequired = false,
    this.riskLevel = RiskLevel.unknown,
  }) {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    requireText(category, 'category');
    requireText(description, 'description');
    if (category.length > 80 || description.length > 2000) {
      fail(FailureCode.validation, 'Kategori veya açıklama izin verilen sınırı aşıyor.');
    }
    GeoPoint(latitude: latitude, longitude: longitude);
    if (expectedRevision < 0) {
      fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
    }
    final mediaIds = <String>{};
    for (final item in media) {
      if (!mediaIds.add(item.id)) {
        fail(FailureCode.validation, 'Aynı medya iki kez eklenemez.');
      }
      if (item.originalRef != null &&
          !item.originalRef!.startsWith('media://media_${actorId}_')) {
        fail(FailureCode.unauthorized, 'Medya aktör namespace alanında olmalıdır.');
      }
      if (item.publicRef != null &&
          !item.publicRef!.startsWith('media://media_${actorId}_')) {
        fail(FailureCode.unauthorized, 'Kamusal medya aktör namespace alanında olmalıdır.');
      }
    }
  }

  factory CreateReportCommand.fromJson(JsonMap json) => CreateReportCommand(
    actorId: expectString(json['actorId'], 'actorId'),
    clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
    expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
    category: expectString(json['category'], 'category'),
    description: expectString(json['description'], 'description'),
    latitude: _number(json['latitude'], 'latitude'),
    longitude: _number(json['longitude'], 'longitude'),
    media: decodeList(
      json['media'] ?? const <Object?>[],
      'media',
      MediaRefDto.fromObject,
    ),
    analysis: json['analysis'] == null
        ? null
        : AiAnalysisDto.fromObject(json['analysis'], 'analysis'),
    manualReviewRequired: json['manualReviewRequired'] == null
        ? false
        : expectBool(json['manualReviewRequired'], 'manualReviewRequired'),
    riskLevel: json['riskLevel'] == null
        ? RiskLevel.unknown
        : expectEnum(
            json['riskLevel'],
            'riskLevel',
            enumValues(RiskLevel.values),
          ),
  );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final List<MediaRefDto> media;
  final AiAnalysisDto? analysis;
  final bool manualReviewRequired;
  final RiskLevel riskLevel;

  JsonMap toJson() => {
    'actorId': actorId,
    'clientMutationId': clientMutationId,
    'expectedRevision': expectedRevision,
    'category': category,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'media': media.map((item) => item.toJson()).toList(growable: false),
    'analysis': analysis?.toJson(),
    'manualReviewRequired': manualReviewRequired,
    'riskLevel': enumWire(riskLevel),
  };
}

enum CitizenActionKind {
  corroborate,
  additionalInfoResponse,
  resolutionFeedback,
  statusRequest,
  appeal,
  markNotificationRead,
}

final class CitizenActionCommand {
  CitizenActionCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.kind,
    required this.resourceId,
    required JsonMap payload,
  }) : payload = deepFreezeJson(payload, 'payload') as JsonMap {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    requireText(resourceId, 'resourceId');
    if (expectedRevision < 0) {
      fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
    }
    if (payload.length > 12) {
      fail(FailureCode.validation, 'Vatandaş aksiyonu beklenenden büyük.');
    }
  }

  factory CitizenActionCommand.fromJson(JsonMap json) => CitizenActionCommand(
    actorId: expectString(json['actorId'], 'actorId'),
    clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
    expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
    kind: expectEnum(
      json['kind'],
      'kind',
      enumValues(CitizenActionKind.values),
    ),
    resourceId: expectString(json['resourceId'], 'resourceId'),
    payload: expectMap(json['payload'] ?? const <String, Object?>{}, 'payload'),
  );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final CitizenActionKind kind;
  final String resourceId;
  final JsonMap payload;

  JsonMap toJson() => {
    'actorId': actorId,
    'clientMutationId': clientMutationId,
    'expectedRevision': expectedRevision,
    'kind': enumWire(kind),
    'resourceId': resourceId,
    'payload': payload,
  };
}

final class VerifyReportCommand {
  VerifyReportCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.reportId,
    required this.category,
    required this.unitId,
    required this.reason,
    required this.publicPreviewApproved,
    this.aiOverrideReason,
  }) {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    requireText(reportId, 'reportId');
    requireText(category, 'category');
    requireText(unitId, 'unitId');
    requireText(reason, 'reason');
    if (expectedRevision < 0) {
      fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
    }
  }

  factory VerifyReportCommand.fromJson(JsonMap json) => VerifyReportCommand(
    actorId: expectString(json['actorId'], 'actorId'),
    clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
    expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
    reportId: expectString(json['reportId'], 'reportId'),
    category: expectString(json['category'], 'category'),
    unitId: expectString(json['unitId'], 'unitId'),
    reason: expectString(json['reason'], 'reason'),
    publicPreviewApproved: expectBool(
      json['publicPreviewApproved'],
      'publicPreviewApproved',
    ),
    aiOverrideReason: expectNullableString(
      json['aiOverrideReason'],
      'aiOverrideReason',
    ),
  );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final String reportId;
  final String category;
  final String unitId;
  final String reason;
  final bool publicPreviewApproved;
  final String? aiOverrideReason;

  JsonMap toJson() => {
    'actorId': actorId,
    'clientMutationId': clientMutationId,
    'expectedRevision': expectedRevision,
    'reportId': reportId,
    'category': category,
    'unitId': unitId,
    'reason': reason,
    'publicPreviewApproved': publicPreviewApproved,
    'aiOverrideReason': aiOverrideReason,
  };
}

final class MutationResult {
  const MutationResult({
    required this.snapshot,
    required this.resourceId,
    required this.trackingNumber,
    required this.replayed,
  });

  final AppSnapshotDto snapshot;
  final String resourceId;
  final String? trackingNumber;
  final bool replayed;

  JsonMap toJson() => {
    'revision': snapshot.revision,
    'resourceId': resourceId,
    'trackingNumber': trackingNumber,
    'replayed': replayed,
  };
}

final class CommandConflict extends Error {
  CommandConflict({required this.expectedRevision, required this.current});
  final int expectedRevision;
  final AppSnapshotDto current;

  @override
  String toString() =>
      'CommandConflict(expected: $expectedRevision, current: ${current.revision})';
}

final class SnapshotCommandProcessor {
  SnapshotCommandProcessor({
    required this.store,
    required this.codec,
    required this.clock,
  });

  final SnapshotStore store;
  final SnapshotCodec codec;
  final Clock clock;
  final SnapshotTransactionQueue transactionQueue = SnapshotTransactionQueue();

  Future<MutationResult> createReport(CreateReportCommand command) {
    return transactionQueue.run(() async {
      final current = await store.read();
      CitizenReportDto? replay;
      for (final report in current.payload.reports) {
        if (report.clientMutationId == command.clientMutationId) {
          replay = report;
          break;
        }
      }
      if (replay != null) {
        if (replay.ownerId != command.actorId) {
          fail(FailureCode.unauthorized, 'clientMutationId başka aktöre ait.');
        }
        final replayActor = _actor(current, command.actorId);
        AuthorizationPolicy.requirePermission(
          replayActor,
          Permission.submitReport,
        );
        return MutationResult(
          snapshot: current,
          resourceId: replay.id,
          trackingNumber: replay.trackingNumber,
          replayed: true,
        );
      }
      _requireRevision(command.expectedRevision, current);
      final actor = _actor(current, command.actorId);
      AuthorizationPolicy.requirePermission(actor, Permission.submitReport);
      if (actor.deletionRequested) {
        fail(
          FailureCode.privacy,
          'Hesap silme talebi beklerken yeni bildirim gönderilemez.',
        );
      }
      final now = clock.nowUtc();
      final activeRestriction = _activeRestriction(current, actor.id, now);
      if (activeRestriction?.body['level'] == enumWire(RestrictionLevel.temporaryRestriction)) {
        fail(
          FailureCode.unauthorized,
          'Geçici kullanım kısıtı aktif. İtiraz veya sürenin dolması beklenmelidir.',
        );
      }
      final ordinal = current.revision + 1;
      final reportId = _uniqueId(
        prefix: 'rpt_demo_',
        ordinal: ordinal,
        existing: current.payload.reports.map((value) => value.id).toSet(),
      );
      final tracking = _uniqueTracking(current, now.year, ordinal);
      final recentReportCount = current.payload.reports.where((item) {
        if (item.ownerId != command.actorId) return false;
        final age = now.difference(item.createdAt);
        return !age.isNegative && age <= const Duration(minutes: 10);
      }).length;
      final abuseSignals = const CitizenAbuseSignalPolicy().evaluate(
        snapshot: current,
        actorId: command.actorId,
        now: now,
        latitude: command.latitude,
        longitude: command.longitude,
        category: command.category,
        media: command.media,
        recentReportCount: recentReportCount,
      );
      final rateLimited = abuseSignals.codes.contains(SecuritySignalCode.rateBurst);
      final restrictedToManualReview = activeRestriction != null &&
          activeRestriction.body['level'] != enumWire(RestrictionLevel.warning);
      final manualReview = command.manualReviewRequired ||
          restrictedToManualReview ||
          abuseSignals.requiresManualReview ||
          command.analysis == null ||
          command.analysis!.status != AiAnalysisStatus.complete;
      final report = CitizenReportDto(
        id: reportId,
        trackingNumber: tracking,
        ownerId: command.actorId,
        status: ReportStatus.received,
        category: command.category,
        latitude: command.latitude,
        longitude: command.longitude,
        createdAt: now,
        updatedAt: now,
        clientMutationId: command.clientMutationId,
        mediaIds: command.media.map((item) => item.id),
        analysisId: command.analysis?.id,
        manualReviewRequired: manualReview,
        riskLevel: rateLimited ? RiskLevel.high : command.riskLevel,
      );
      final timeline = _timeline(
        id: 'timeline_${reportId}_received',
        resourceId: reportId,
        type: 'report_received',
        at: now,
        publicMessageKey: 'timeline.report_received',
      );
      final audit = _audit(
        id: 'audit_${reportId}_created',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: 'report_created',
        resourceId: reportId,
        at: now,
        reason: 'Citizen submitted minimal local report',
        before: const {},
        after: {
          'status': enumWire(report.status),
          'clientMutationId': command.clientMutationId,
          'description': command.description,
          'mediaCount': command.media.length,
          'analysisId': command.analysis?.id,
          'rateLimitedToManualReview': rateLimited,
          'restrictedToManualReview': restrictedToManualReview,
          'securitySignals': abuseSignals.wireCodes,
          'securitySignalPolicy': 'human_review_only_no_automatic_sanction',
        },
      );
      final notification = _notification(
        id: 'notification_${reportId}_received',
        recipientId: actor.id,
        eventId: timeline.id,
        type: NotificationType.reportReceived,
        route: '/citizen/reports/$reportId',
        createdAt: now,
      );
      final next = _seal(
        current,
        current.payload.copyWith(
          reports: [...current.payload.reports, report],
          media: [...current.payload.media, ...command.media],
          analyses: [
            ...current.payload.analyses,
            if (command.analysis != null) command.analysis!,
          ],
          timeline: [...current.payload.timeline, timeline],
          auditEvents: [...current.payload.auditEvents, audit],
          notifications: [...current.payload.notifications, notification],
        ),
        now,
      );
      final committed = await store.write(next);
      return MutationResult(
        snapshot: committed,
        resourceId: reportId,
        trackingNumber: tracking,
        replayed: false,
      );
    });
  }

  Future<MutationResult> verifyReport(VerifyReportCommand command) {
    return transactionQueue.run(() async {
      final current = await store.read();
      final replay = _findAuditByMutation(current, command.clientMutationId);
      if (replay != null) {
        if (replay.body['actorId'] != command.actorId) {
          fail(FailureCode.unauthorized, 'clientMutationId başka aktöre ait.');
        }
        final replayActor = _actor(current, command.actorId);
        AuthorizationPolicy.requirePermission(
          replayActor,
          Permission.reviewReport,
        );
        final report = _report(current, replay.body['resourceId']! as String);
        return MutationResult(
          snapshot: current,
          resourceId: report.linkedIncidentId ?? report.id,
          trackingNumber: report.trackingNumber,
          replayed: true,
        );
      }
      final actor = _actor(current, command.actorId);
      AuthorizationPolicy.requirePermission(actor, Permission.reviewReport);
      AuthorizationPolicy.requirePermission(actor, Permission.routeReport);
      _requireRevision(command.expectedRevision, current);
      final report = _report(current, command.reportId);
      if (!command.publicPreviewApproved) {
        fail(
          FailureCode.validation,
          'Kamusal olay yayınlanmadan önce insan public preview onayı gerekir.',
          field: 'publicPreviewApproved',
        );
      }
      final now = clock.nowUtc();
      final lease = StaffOperationsProjection.activeLease(
        current,
        report.id,
        now,
      );
      if (lease == null || lease.lockedBy != actor.id) {
        fail(
          FailureCode.conflict,
          'Doğrulama öncesi aktif inceleme lease’i bu personelde olmalıdır.',
          retryable: true,
        );
      }
      AiAnalysisDto? analysis;
      for (final item in current.payload.analyses) {
        if (item.id == report.analysisId) analysis = item;
      }
      final suggestedCategory = _reasonValue(analysis, 'category:');
      final suggestedUnit = _reasonValue(analysis, 'unit:');
      final overridesAi =
          (suggestedCategory != null && suggestedCategory != command.category) ||
          (suggestedUnit != null && suggestedUnit != command.unitId);
      if (overridesAi && (command.aiOverrideReason?.trim().isEmpty ?? true)) {
        fail(
          FailureCode.validation,
          'AI önerisi değiştirildiğinde gerekçe zorunludur.',
          field: 'aiOverrideReason',
        );
      }
      if (report.status != ReportStatus.received &&
          report.status != ReportStatus.aiReview &&
          report.status != ReportStatus.ibbReview &&
          report.status != ReportStatus.manualReview &&
          report.status != ReportStatus.criticalReview) {
        fail(
          FailureCode.invalidTransition,
          'Bu report insan doğrulaması için uygun durumda değil.',
        );
      }
      if (report.status == ReportStatus.received ||
          report.status == ReportStatus.aiReview ||
          report.status == ReportStatus.manualReview ||
          report.status == ReportStatus.criticalReview) {
        ReportTransitionPolicy.requireAllowed(
          report.status,
          ReportStatus.ibbReview,
        );
      }
      ReportTransitionPolicy.requireAllowed(
        ReportStatus.ibbReview,
        ReportStatus.assignedUnit,
      );
      final ordinal = current.revision + 1;
      final sla = FieldSlaPolicy.targetFor(command.category, command.unitId);
      UrbanIncidentDto incident;
      var incidents = current.payload.incidents;
      if (report.linkedIncidentId != null) {
        UrbanIncidentDto? existing;
        for (final item in current.payload.incidents) {
          if (item.id == report.linkedIncidentId) existing = item;
        }
        if (existing == null) {
          fail(FailureCode.corruption, 'Report bağlı incident kaydını bulamıyor.');
        }
        if (existing.status != IncidentStatus.pendingVerification) {
          fail(FailureCode.invalidTransition, 'Bağlı incident yeniden doğrulanamaz.');
        }
        IncidentTransitionPolicy.requireAllowed(
          existing.status,
          IncidentStatus.verifiedActive,
        );
        incident = UrbanIncidentDto(
          id: existing.id,
          status: IncidentStatus.verifiedActive,
          category: command.category,
          latitude: existing.latitude,
          longitude: existing.longitude,
          reportIds: {...existing.reportIds, report.id}.toList(),
          sourceRecordIds: existing.sourceRecordIds,
          workOrderRefs: existing.workOrderRefs,
          createdAt: existing.createdAt,
          updatedAt: now,
          responsibleUnitId: command.unitId,
          slaStartedAt: now,
          slaTargetAt: now.add(sla.max),
          slaEstimateMinMinutes: sla.min.inMinutes,
          slaEstimateMaxMinutes: sla.max.inMinutes,
          resolutionExplanation: existing.resolutionExplanation,
          resolvedAt: existing.resolvedAt,
        );
        incidents = [
          for (final item in incidents)
            if (item.id == incident.id) incident else item,
        ];
      } else {
        final incidentId = _uniqueId(
          prefix: 'inc_demo_',
          ordinal: ordinal,
          existing: current.payload.incidents.map((value) => value.id).toSet(),
        );
        incident = UrbanIncidentDto(
          id: incidentId,
          status: IncidentStatus.verifiedActive,
          category: command.category,
          latitude: report.latitude,
          longitude: report.longitude,
          reportIds: [report.id],
          sourceRecordIds: const [],
          createdAt: now,
          updatedAt: now,
          responsibleUnitId: command.unitId,
          slaStartedAt: now,
          slaTargetAt: now.add(sla.max),
          slaEstimateMinMinutes: sla.min.inMinutes,
          slaEstimateMaxMinutes: sla.max.inMinutes,
        );
        incidents = [...incidents, incident];
      }
      final incidentId = incident.id;
      final updatedReport = CitizenReportDto(
        id: report.id,
        trackingNumber: report.trackingNumber,
        ownerId: report.ownerId,
        status: ReportStatus.assignedUnit,
        category: command.category,
        latitude: report.latitude,
        longitude: report.longitude,
        createdAt: report.createdAt,
        updatedAt: now,
        clientMutationId: report.clientMutationId,
        mediaIds: report.mediaIds,
        analysisId: report.analysisId,
        linkedIncidentId: incidentId,
        manualReviewRequired: report.manualReviewRequired,
        riskLevel: report.riskLevel,
        humanDecisionReason: command.reason,
        resolutionExplanation: report.resolutionExplanation,
        resolvedAt: report.resolvedAt,
        resolutionPublicMediaRef: report.resolutionPublicMediaRef,
      );
      final reportTimeline = _timeline(
        id: 'timeline_${report.id}_verified_$ordinal',
        resourceId: report.id,
        type: 'report_verified',
        at: now,
        publicMessageKey: 'timeline.report_verified_and_routed',
      );
      final incidentTimeline = _timeline(
        id: 'timeline_${incidentId}_published',
        resourceId: incidentId,
        type: 'incident_published',
        at: now,
        publicMessageKey: 'timeline.incident_published',
      );
      final audit = _audit(
        id: 'audit_${report.id}_verified_$ordinal',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: 'report_verified',
        resourceId: report.id,
        at: now,
        reason: command.reason,
        before: {'status': enumWire(report.status)},
        after: {
          'status': enumWire(updatedReport.status),
          'incidentId': incidentId,
          'unitId': command.unitId,
          'category': command.category,
          'aiOverridden': overridesAi,
          'aiOverrideReason': command.aiOverrideReason,
          'publicPreviewApproved': command.publicPreviewApproved,
          'slaTargetAt': incident.slaTargetAt?.toIso8601String(),
          'slaLabel': sla.label,
          'clientMutationId': command.clientMutationId,
        },
      );
      final firstReviewMetric = _audit(
        id: 'audit_metric_first_review_${report.id}_$ordinal',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: 'operational_metric',
        resourceId: report.id,
        at: now,
        reason: 'WP-15 first-review duration marker',
        before: const {},
        after: {
          'metricKey': 'first_review',
          'startedAt': report.createdAt.toIso8601String(),
          'occurredAt': now.toIso8601String(),
          'durationSeconds': now.difference(report.createdAt).inSeconds,
        },
      );
      final routingMetric = _audit(
        id: 'audit_metric_routing_${report.id}_$ordinal',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: 'operational_metric',
        resourceId: incidentId,
        at: now,
        reason: 'WP-15 initial-routing duration marker',
        before: const {},
        after: {
          'metricKey': 'routing',
          'startedAt': report.createdAt.toIso8601String(),
          'occurredAt': now.toIso8601String(),
          'durationSeconds': now.difference(report.createdAt).inSeconds,
        },
      );
      final staffOverrideMetric = overridesAi
          ? _audit(
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
            )
          : null;
      final notification = _notification(
        id: 'notification_${report.id}_verified_$ordinal',
        recipientId: report.ownerId,
        eventId: reportTimeline.id,
        type: NotificationType.statusChanged,
        route: '/citizen/reports/${report.id}',
        createdAt: now,
      );
      final reports = [
        for (final item in current.payload.reports)
          if (item.id == report.id) updatedReport else item,
      ];
      final next = _seal(
        current,
        current.payload.copyWith(
          reports: reports,
          incidents: incidents,
          timeline: [
            ...current.payload.timeline,
            reportTimeline,
            incidentTimeline,
          ],
          auditEvents: [...current.payload.auditEvents, audit, firstReviewMetric, routingMetric, if (staffOverrideMetric != null) staffOverrideMetric],
          notifications: [...current.payload.notifications, notification],
        ),
        now,
      );
      final committed = await store.write(next);
      return MutationResult(
        snapshot: committed,
        resourceId: incidentId,
        trackingNumber: report.trackingNumber,
        replayed: false,
      );
    });
  }

  Future<MutationResult> citizenAction(CitizenActionCommand command) {
    return transactionQueue.run(() async {
      final current = await store.read();
      for (final event in current.payload.auditEvents) {
        final after = event.body['after'];
        if (after is Map<String, Object?> &&
            after['clientMutationId'] == command.clientMutationId &&
            after['kind'] == enumWire(command.kind)) {
          if (event.body['actorId'] != command.actorId) {
            fail(FailureCode.unauthorized, 'clientMutationId başka aktöre ait.');
          }
          CitizenReportDto? replayReport;
          for (final item in current.payload.reports) {
            if (item.id == command.resourceId) replayReport = item;
          }
          return MutationResult(
            snapshot: current,
            resourceId: command.resourceId,
            trackingNumber: replayReport?.trackingNumber,
            replayed: true,
          );
        }
      }
      _requireRevision(command.expectedRevision, current);
      final actor = _actor(current, command.actorId);
      final now = clock.nowUtc();
      final ordinal = current.revision + 1;
      var reports = current.payload.reports;
      var notifications = current.payload.notifications;
      final timeline = [...current.payload.timeline];
      final corroborations = [...current.payload.corroborations];
      CitizenReportDto? affectedReport;
      String action;
      String reason;

      switch (command.kind) {
        case CitizenActionKind.corroborate:
          AuthorizationPolicy.requirePermission(actor, Permission.submitReport);
          UrbanIncidentDto? incident;
          for (final item in current.payload.incidents) {
            if (item.id == command.resourceId) incident = item;
          }
          if (incident == null ||
              incident.status != IncidentStatus.verifiedActive) {
            fail(FailureCode.notFound, 'Doğrulanabilir aktif olay bulunamadı.');
          }
          final kind = expectEnum(
            command.payload['kind'],
            'payload.kind',
            enumValues(CorroborationKind.values),
          );
          final corroborationId = 'corroboration_${ordinal}_${actor.id}';
          corroborations.add(
            OpaqueEntityDto(
              id: corroborationId,
              body: {
                'id': corroborationId,
                'actorId': actor.id,
                'incidentId': incident.id,
                'kind': enumWire(kind),
                'createdAt': now.toIso8601String(),
              },
            ),
          );
          action = 'incident_corroborated';
          reason = 'Citizen supplied a non-authoritative corroboration signal';
          break;
        case CitizenActionKind.additionalInfoResponse:
          AuthorizationPolicy.requirePermission(actor, Permission.viewOwnReport);
          final infoReport = _ownedReport(current, command.resourceId, actor.id);
          ReportTransitionPolicy.requireAllowed(
            infoReport.status,
            ReportStatus.ibbReview,
          );
          final response = _boundedText(
            command.payload['response'],
            'payload.response',
          );
          affectedReport = _copyReport(
            infoReport,
            status: ReportStatus.ibbReview,
            updatedAt: now,
          );
          reports = [
            for (final item in reports)
              if (item.id == infoReport.id) affectedReport! else item,
          ];
          timeline.add(
            _timeline(
              id: 'timeline_${infoReport.id}_additional_info_$ordinal',
              resourceId: infoReport.id,
              type: 'additional_info_received',
              at: now,
              publicMessageKey: 'timeline.additional_info_received',
              detail: response,
            ),
          );
          action = 'additional_info_responded';
          reason = 'Citizen responded to an active additional information request';
          break;
        case CitizenActionKind.resolutionFeedback:
          AuthorizationPolicy.requirePermission(actor, Permission.viewOwnReport);
          final feedbackReport = _ownedReport(current, command.resourceId, actor.id);
          if (feedbackReport.status != ReportStatus.resolved) {
            fail(FailureCode.invalidTransition, 'Çözüm geri bildirimi yalnız çözülmüş kayıt içindir.');
          }
          if (feedbackReport.linkedIncidentId == null) {
            fail(FailureCode.validation, 'Çözülmüş kayıt olay bağlantısı taşımıyor.');
          }
          final feedback = expectEnum(
            command.payload['feedback'],
            'payload.feedback',
            enumValues(CorroborationKind.values),
          );
          if (feedback == CorroborationKind.differentLocation) {
            fail(FailureCode.validation, 'Çözüm geri bildirimi türü desteklenmiyor.');
          }
          affectedReport = feedbackReport;
          final feedbackId = 'resolution_feedback_${ordinal}_${actor.id}';
          corroborations.add(
            OpaqueEntityDto(
              id: feedbackId,
              body: {
                'id': feedbackId,
                'actorId': actor.id,
                'incidentId': feedbackReport.linkedIncidentId,
                'reportId': feedbackReport.id,
                'kind': enumWire(feedback),
                'reopenReviewRequested': feedback == CorroborationKind.stillPresent,
                'createdAt': now.toIso8601String(),
              },
            ),
          );
          timeline.add(
            _timeline(
              id: 'timeline_${feedbackReport.id}_resolution_feedback_$ordinal',
              resourceId: feedbackReport.id,
              type: 'resolution_feedback_received',
              at: now,
              publicMessageKey: 'timeline.resolution_feedback_received',
            ),
          );
          action = 'resolution_feedback_submitted';
          reason = 'Citizen supplied post-resolution feedback; no automatic reopen';
          break;
        case CitizenActionKind.statusRequest:
          AuthorizationPolicy.requirePermission(actor, Permission.viewOwnReport);
          final statusReport = _ownedReport(current, command.resourceId, actor.id);
          if ({ReportStatus.rejected, ReportStatus.outOfScope, ReportStatus.merged}.contains(statusReport.status)) {
            fail(FailureCode.invalidTransition, 'Bu kayıt için tekrar durum isteği açılamaz.');
          }
          affectedReport = statusReport;
          timeline.add(
            _timeline(
              id: 'timeline_${statusReport.id}_status_request_$ordinal',
              resourceId: statusReport.id,
              type: 'status_request_received',
              at: now,
              publicMessageKey: 'timeline.status_request_received',
            ),
          );
          action = 'status_request_submitted';
          reason = 'Citizen requested a repeat status update; metric only, no automatic priority change';
          break;
        case CitizenActionKind.appeal:
          AuthorizationPolicy.requirePermission(actor, Permission.viewOwnReport);
          final appealReport = _ownedReport(current, command.resourceId, actor.id);
          if (appealReport.status != ReportStatus.rejected &&
              appealReport.status != ReportStatus.outOfScope) {
            fail(FailureCode.invalidTransition, 'İtiraz yalnız reddedilen veya kapsam dışı kayıt içindir.');
          }
          final appeal = _boundedText(command.payload['appeal'], 'payload.appeal');
          affectedReport = appealReport;
          timeline.add(
            _timeline(
              id: 'timeline_${appealReport.id}_appeal_$ordinal',
              resourceId: appealReport.id,
              type: 'appeal_received',
              at: now,
              publicMessageKey: 'timeline.appeal_received',
              detail: appeal,
            ),
          );
          action = 'appeal_submitted';
          reason = 'Citizen submitted a human-review appeal';
          break;
        case CitizenActionKind.markNotificationRead:
          AuthorizationPolicy.requirePermission(actor, Permission.viewOwnReport);
          var found = false;
          notifications = [
            for (final item in notifications)
              if (item.id == command.resourceId &&
                  item.body['recipientId'] == actor.id)
                (() {
                  found = true;
                  return OpaqueEntityDto(
                    id: item.id,
                    body: {...item.body, 'readAt': now.toIso8601String()},
                  );
                })()
              else
                item,
          ];
          if (!found) {
            fail(FailureCode.notFound, 'Bildirim bulunamadı.');
          }
          action = 'notification_read';
          reason = 'Citizen marked own notification as read';
          break;
      }

      final audit = _audit(
        id: 'audit_${command.kind.name}_$ordinal',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: action,
        resourceId: command.resourceId,
        at: now,
        reason: reason,
        before: const {},
        after: {
          'clientMutationId': command.clientMutationId,
          'kind': enumWire(command.kind),
        },
      );
      final metricEvents = <OpaqueEntityDto>[];
      if (command.kind == CitizenActionKind.statusRequest) {
        metricEvents.add(_audit(
          id: 'audit_metric_status_request_${command.resourceId}_$ordinal',
          actorId: actor.id,
          activeRoleContext: actor.role.name,
          action: 'operational_metric',
          resourceId: command.resourceId,
          at: now,
          reason: 'WP-23 privacy-safe repeat status request metric',
          before: const {},
          after: {
            'metricKey': 'repeat_status_request',
            'occurredAt': now.toIso8601String(),
          },
        ));
      }
      if (command.kind == CitizenActionKind.resolutionFeedback) {
        metricEvents.add(_audit(
          id: 'audit_metric_resolution_feedback_${command.resourceId}_$ordinal',
          actorId: actor.id,
          activeRoleContext: actor.role.name,
          action: 'operational_metric',
          resourceId: command.resourceId,
          at: now,
          reason: 'WP-23 privacy-safe citizen resolution feedback metric',
          before: const {},
          after: {
            'metricKey': 'citizen_resolution_feedback',
            'feedback': command.payload['feedback']?.toString() ?? 'unknown',
            'occurredAt': now.toIso8601String(),
          },
        ));
      }
      final next = _seal(
        current,
        current.payload.copyWith(
          reports: reports,
          timeline: timeline,
          notifications: notifications,
          corroborations: corroborations,
          auditEvents: [...current.payload.auditEvents, audit, ...metricEvents],
        ),
        now,
      );
      final committed = await store.write(next);
      return MutationResult(
        snapshot: committed,
        resourceId: command.resourceId,
        trackingNumber: affectedReport?.trackingNumber,
        replayed: false,
      );
    });
  }

  Future<AppSnapshotDto> recordDenied({
    required String actorId,
    required String action,
    required String resourceId,
    required String reason,
  }) {
    return transactionQueue.run(() async {
      final current = await store.read();
      final now = clock.nowUtc();
      final ordinal = current.revision + 1;
      final effectiveActorId = actorId.isEmpty ? 'anonymous' : actorId;
      var activeRoleContext = 'anonymous';
      for (final account in current.payload.accounts) {
        if (account.id == actorId) {
          activeRoleContext = account.role.name;
          break;
        }
      }
      final audit = _audit(
        id: 'audit_denied_${ordinal}_${now.microsecondsSinceEpoch}',
        actorId: effectiveActorId,
        activeRoleContext: activeRoleContext,
        action: 'denied_$action',
        resourceId: resourceId.isEmpty ? 'unknown' : resourceId,
        at: now,
        reason: reason,
        before: const {},
        after: const {'authorized': false},
      );
      final next = _seal(
        current,
        current.payload.copyWith(
          auditEvents: [...current.payload.auditEvents, audit],
        ),
        now,
      );
      return store.write(next);
    });
  }

  Future<AppSnapshotDto> recordOriginalMediaAccess({
    required String actorId,
    required String mediaId,
    required String reason,
  }) {
    return transactionQueue.run(() async {
      requireText(reason, 'reason');
      final current = await store.read();
      final actor = _actor(current, actorId);
      AuthorizationPolicy.requirePermission(actor, Permission.viewOriginalMedia);
      final knownOriginal = current.payload.media.any(
        (item) => item.originalRef == 'media://$mediaId',
      );
      if (!knownOriginal) {
        fail(FailureCode.notFound, 'Orijinal medya referansı bulunamadı.');
      }
      final now = clock.nowUtc();
      final audit = _audit(
        id: 'audit_media_access_${current.revision + 1}_${now.microsecondsSinceEpoch}',
        actorId: actor.id,
        activeRoleContext: actor.role.name,
        action: 'original_media_accessed',
        resourceId: mediaId,
        at: now,
        reason: reason,
        before: const {},
        after: const {'authorized': true},
      );
      return store.write(
        _seal(
          current,
          current.payload.copyWith(
            auditEvents: [...current.payload.auditEvents, audit],
          ),
          now,
        ),
      );
    });
  }

  AppSnapshotDto _seal(
    AppSnapshotDto current,
    SnapshotPayloadDto payload,
    DateTime now,
  ) {
    return codec.seal(
      current.copyWith(
        revision: current.revision + 1,
        updatedAt: now,
        checksum: 'sha256:unsealed',
        payload: payload,
      ),
    );
  }

  void _requireRevision(int expected, AppSnapshotDto current) {
    if (expected != current.revision) {
      throw CommandConflict(expectedRevision: expected, current: current);
    }
  }

  OpaqueEntityDto? _activeRestriction(
  AppSnapshotDto snapshot,
  String accountId,
  DateTime now,
) {
  for (final item in snapshot.payload.restrictions.reversed) {
    if (item.body['accountId'] != accountId) continue;
    final startsAt = DateTime.tryParse(item.body['startsAt']?.toString() ?? '');
    final expiresAt = DateTime.tryParse(item.body['expiresAt']?.toString() ?? '');
    if (startsAt != null && now.isBefore(startsAt)) continue;
    if (expiresAt != null && !now.isBefore(expiresAt)) continue;
    return item;
  }
  return null;
}

UserAccount _actor(AppSnapshotDto snapshot, String id) {
    AccountDto? dto;
    for (final item in snapshot.payload.accounts) {
      if (item.id == id) {
        dto = item;
        break;
      }
    }
    if (dto == null) {
      fail(FailureCode.unauthorized, 'Demo hesabı bulunamadı.');
    }
    return UserAccount(
      id: dto.id,
      role: dto.role,
      permissions: dto.permissions,
      unitId: dto.unitId,
      deletionRequested: dto.deletionRequested,
    );
  }

  CitizenReportDto _report(AppSnapshotDto snapshot, String id) {
    CitizenReportDto? report;
    for (final item in snapshot.payload.reports) {
      if (item.id == id) {
        report = item;
        break;
      }
    }
    if (report == null) {
      fail(FailureCode.notFound, 'Report bulunamadı.');
    }
    return report;
  }

  CitizenReportDto _ownedReport(
    AppSnapshotDto snapshot,
    String id,
    String actorId,
  ) {
    final report = _report(snapshot, id);
    if (report.ownerId != actorId) {
      fail(FailureCode.unauthorized, 'Yalnız kendi bildirimin güncellenebilir.');
    }
    return report;
  }

  OpaqueEntityDto? _findAuditByMutation(
    AppSnapshotDto snapshot,
    String clientMutationId,
  ) {
    for (final event in snapshot.payload.auditEvents) {
      if (event.body['action'] != 'report_verified') continue;
      final after = event.body['after'];
      if (after is Map<String, Object?> &&
          after['clientMutationId'] == clientMutationId) {
        return event;
      }
    }
    return null;
  }
}

OpaqueEntityDto _timeline({
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

CitizenReportDto _copyReport(
  CitizenReportDto report, {
  ReportStatus? status,
  DateTime? updatedAt,
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
    linkedIncidentId: report.linkedIncidentId,
    manualReviewRequired: report.manualReviewRequired,
    riskLevel: report.riskLevel,
    humanDecisionReason: report.humanDecisionReason,
    resolutionExplanation: report.resolutionExplanation,
    resolvedAt: report.resolvedAt,
    resolutionPublicMediaRef: report.resolutionPublicMediaRef,
  );
}

OpaqueEntityDto _audit({
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
      'activeRoleContext': activeRoleContext,
      'action': action,
      'resourceId': resourceId,
      'at': at.toIso8601String(),
      'reason': reason,
      'before': before,
      'after': after,
    },
  );
}

OpaqueEntityDto _notification({
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

String _uniqueId({
  required String prefix,
  required int ordinal,
  required Set<String> existing,
}) {
  var candidateOrdinal = ordinal;
  while (true) {
    final candidate = '$prefix${candidateOrdinal.toString().padLeft(6, '0')}';
    if (!existing.contains(candidate)) return candidate;
    candidateOrdinal += 1;
  }
}

String _uniqueTracking(AppSnapshotDto snapshot, int year, int ordinal) {
  final existing = snapshot.payload.reports
      .map((value) => value.trackingNumber)
      .toSet();
  var candidateOrdinal = ordinal;
  while (true) {
    final value = 'KT-$year-${candidateOrdinal.toString().padLeft(6, '0')}';
    if (!existing.contains(value)) return value;
    candidateOrdinal += 1;
  }
}

double _number(Object? value, String field) {
  if (value is! num) {
    fail(FailureCode.validation, '$field sayı olmalıdır.', field: field);
  }
  return value.toDouble();
}

String? _reasonValue(AiAnalysisDto? analysis, String prefix) {
  if (analysis == null) return null;
  for (final code in analysis.reasonCodes) {
    if (code.startsWith(prefix) && code.length > prefix.length) {
      return code.substring(prefix.length);
    }
  }
  return null;
}

String _boundedText(Object? value, String field, {int maxLength = 1200}) {
  final text = expectString(value, field).trim();
  if (text.length > maxLength) {
    fail(FailureCode.validation, '$field $maxLength karakteri aşamaz.', field: field);
  }
  return text;
}
