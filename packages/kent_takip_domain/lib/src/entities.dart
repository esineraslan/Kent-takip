import 'package:kent_takip_domain/src/enums.dart';
import 'package:kent_takip_domain/src/failure.dart';
import 'package:kent_takip_domain/src/value_objects.dart';

final class UserAccount {
  UserAccount({
    required String id,
    required this.role,
    required Iterable<Permission> permissions,
    this.unitId,
    this.deletionRequested = false,
  }) : id = requireText(id, 'id'),
       permissions = Set<Permission>.unmodifiable(permissions);

  final String id;
  final UserRole role;
  final Set<Permission> permissions;
  final String? unitId;
  final bool deletionRequested;
}

final class Session {
  Session({
    required String id,
    required String userId,
    required this.role,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) : id = requireText(id, 'id'),
       userId = requireText(userId, 'userId'),
       createdAt = requireUtc(createdAt, 'createdAt'),
       expiresAt = requireUtc(expiresAt, 'expiresAt') {
    if (!expiresAt.isAfter(createdAt)) {
      fail(FailureCode.validation, 'Oturum bitişi başlangıçtan sonra olmalıdır.');
    }
  }

  final String id;
  final String userId;
  final UserRole role;
  final DateTime createdAt;
  final DateTime expiresAt;
}

final class MediaRef {
  MediaRef({
    required String id,
    required this.privacyStatus,
    this.originalRef,
    this.publicRef,
    required String mimeType,
  }) : id = requireText(id, 'id'),
       mimeType = requireText(mimeType, 'mimeType') {
    if (publicRef != null && privacyStatus != PrivacyStatus.safe) {
      fail(
        FailureCode.privacy,
        'Güvenli olmayan medya publicRef taşıyamaz.',
        field: 'publicRef',
      );
    }
  }

  final String id;
  final PrivacyStatus privacyStatus;
  final String? originalRef;
  final String? publicRef;
  final String mimeType;
}

final class AiAnalysis {
  AiAnalysis({
    required String id,
    required this.status,
    required this.categoryConfidence,
    required this.duplicateConfidence,
    required Iterable<String> reasonCodes,
    required String modelVersion,
    required String configVersion,
    required DateTime createdAt,
    this.suggestedCategory,
    this.suggestedUnitId,
  }) : id = requireText(id, 'id'),
       reasonCodes = List<String>.unmodifiable(reasonCodes),
       modelVersion = requireText(modelVersion, 'modelVersion'),
       configVersion = requireText(configVersion, 'configVersion'),
       createdAt = requireUtc(createdAt, 'createdAt') {
    if (categoryConfidence != null) {
      requireScore(categoryConfidence!, 'categoryConfidence');
    }
    if (duplicateConfidence != null) {
      requireScore(duplicateConfidence!, 'duplicateConfidence');
    }
  }

  final String id;
  final AiAnalysisStatus status;
  final int? categoryConfidence;
  final int? duplicateConfidence;
  final List<String> reasonCodes;
  final String modelVersion;
  final String configVersion;
  final DateTime createdAt;
  final String? suggestedCategory;
  final String? suggestedUnitId;
}

final class CitizenReport {
  CitizenReport({
    required String id,
    required String trackingNumber,
    required String ownerId,
    required this.status,
    required String category,
    required this.location,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String clientMutationId,
    required Iterable<String> mediaIds,
    this.analysisId,
    this.linkedIncidentId,
    this.manualReviewRequired = false,
    this.riskLevel = RiskLevel.unknown,
    this.humanDecisionReason,
    this.resolutionEvidence,
    this.externalApplicationRef,
  }) : id = requireText(id, 'id'),
       trackingNumber = requireTrackingNumber(trackingNumber, 'trackingNumber'),
       ownerId = requireText(ownerId, 'ownerId'),
       category = requireText(category, 'category'),
       createdAt = requireUtc(createdAt, 'createdAt'),
       updatedAt = requireUtc(updatedAt, 'updatedAt'),
       clientMutationId = requireText(clientMutationId, 'clientMutationId'),
       mediaIds = List<String>.unmodifiable(mediaIds) {
    if (updatedAt.isBefore(createdAt)) {
      fail(FailureCode.validation, 'updatedAt createdAt öncesi olamaz.');
    }
    if (status == ReportStatus.resolved && resolutionEvidence == null) {
      fail(FailureCode.validation, 'Çözülmüş report çözüm kanıtı taşımalıdır.');
    }
    if ({ReportStatus.rejected, ReportStatus.outOfScope}.contains(status) &&
        (humanDecisionReason == null || humanDecisionReason!.trim().isEmpty)) {
      fail(FailureCode.validation, 'Ret/kapsam dışı karar gerekçe taşımalıdır.');
    }
    if (status == ReportStatus.merged && linkedIncidentId == null) {
      fail(FailureCode.validation, 'Birleştirilmiş report ana incident taşır.');
    }
  }

  final String id;
  final String trackingNumber;
  final String ownerId;
  final ReportStatus status;
  final String category;
  final GeoPoint location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String clientMutationId;
  final List<String> mediaIds;
  final String? analysisId;
  final String? linkedIncidentId;
  final bool manualReviewRequired;
  final RiskLevel riskLevel;
  final String? humanDecisionReason;
  final ResolutionEvidence? resolutionEvidence;
  final ExternalApplicationRef? externalApplicationRef;

  CitizenReport copyWith({
    ReportStatus? status,
    String? linkedIncidentId,
    String? humanDecisionReason,
    ResolutionEvidence? resolutionEvidence,
    DateTime? updatedAt,
  }) {
    return CitizenReport(
      id: id,
      trackingNumber: trackingNumber,
      ownerId: ownerId,
      status: status ?? this.status,
      category: category,
      location: location,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientMutationId: clientMutationId,
      mediaIds: mediaIds,
      analysisId: analysisId,
      linkedIncidentId: linkedIncidentId ?? this.linkedIncidentId,
      manualReviewRequired: manualReviewRequired,
      riskLevel: riskLevel,
      humanDecisionReason: humanDecisionReason ?? this.humanDecisionReason,
      resolutionEvidence: resolutionEvidence ?? this.resolutionEvidence,
      externalApplicationRef: externalApplicationRef,
    );
  }
}

final class SourceAuthority {
  SourceAuthority({
    required String id,
    required String displayName,
    required this.rank,
    required this.officialAlertAuthority,
  }) : id = requireText(id, 'id'),
       displayName = requireText(displayName, 'displayName');

  final String id;
  final String displayName;
  final SourceAuthorityRank rank;
  final bool officialAlertAuthority;
}

final class SourceRecord {
  SourceRecord({
    required String id,
    required String sourceId,
    required String externalId,
    required String authorityId,
    required this.health,
    required DateTime sourceUpdatedAt,
    required DateTime ingestedAt,
    required String licenseId,
    required String attribution,
  }) : id = requireText(id, 'id'),
       sourceId = requireText(sourceId, 'sourceId'),
       externalId = requireText(externalId, 'externalId'),
       authorityId = requireText(authorityId, 'authorityId'),
       sourceUpdatedAt = requireUtc(sourceUpdatedAt, 'sourceUpdatedAt'),
       ingestedAt = requireUtc(ingestedAt, 'ingestedAt'),
       licenseId = requireText(licenseId, 'licenseId'),
       attribution = requireText(attribution, 'attribution');

  final String id;
  final String sourceId;
  final String externalId;
  final String authorityId;
  final SourceHealth health;
  final DateTime sourceUpdatedAt;
  final DateTime ingestedAt;
  final String licenseId;
  final String attribution;
}

final class DataSourceHealth {
  DataSourceHealth({
    required String sourceId,
    required this.health,
    required DateTime lastAttemptAt,
    this.lastSuccessAt,
    this.lastErrorCode,
    this.acceptedCount = 0,
    this.quarantinedCount = 0,
  }) : sourceId = requireText(sourceId, 'sourceId'),
       lastAttemptAt = requireUtc(lastAttemptAt, 'lastAttemptAt') {
    if (lastSuccessAt != null) {
      requireUtc(lastSuccessAt!, 'lastSuccessAt');
    }
    if (acceptedCount < 0 || quarantinedCount < 0) {
      fail(FailureCode.validation, 'Kaynak sayaçları negatif olamaz.');
    }
  }

  final String sourceId;
  final SourceHealth health;
  final DateTime lastAttemptAt;
  final DateTime? lastSuccessAt;
  final String? lastErrorCode;
  final int acceptedCount;
  final int quarantinedCount;
}

final class CorroborationSignal {
  CorroborationSignal({
    required String id,
    required String incidentId,
    required String actorId,
    required this.kind,
    required DateTime createdAt,
  }) : id = requireText(id, 'id'),
       incidentId = requireText(incidentId, 'incidentId'),
       actorId = requireText(actorId, 'actorId'),
       createdAt = requireUtc(createdAt, 'createdAt');

  final String id;
  final String incidentId;
  final String actorId;
  final CorroborationKind kind;
  final DateTime createdAt;
}

final class UrbanIncident {
  UrbanIncident({
    required String id,
    required this.status,
    required String category,
    required this.location,
    required Iterable<String> reportIds,
    required Iterable<String> sourceRecordIds,
    required Iterable<String> corroborationSignalIds,
    required Iterable<ExternalWorkOrderRef> workOrderRefs,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.responsibleUnitId,
    this.slaClock,
    this.resolutionEvidence,
  }) : id = requireText(id, 'id'),
       category = requireText(category, 'category'),
       reportIds = List<String>.unmodifiable(reportIds),
       sourceRecordIds = List<String>.unmodifiable(sourceRecordIds),
       corroborationSignalIds = List<String>.unmodifiable(
         corroborationSignalIds,
       ),
       workOrderRefs = List<ExternalWorkOrderRef>.unmodifiable(workOrderRefs),
       createdAt = requireUtc(createdAt, 'createdAt'),
       updatedAt = requireUtc(updatedAt, 'updatedAt') {
    if (status == IncidentStatus.resolved && resolutionEvidence == null) {
      fail(FailureCode.validation, 'Çözülmüş incident çözüm kanıtı ister.');
    }
    if (reportIds.isEmpty && sourceRecordIds.isEmpty) {
      fail(FailureCode.validation, 'Incident en az bir kaynak sinyali taşımalıdır.');
    }
  }

  final String id;
  final IncidentStatus status;
  final String category;
  final GeoPoint location;
  final List<String> reportIds;
  final List<String> sourceRecordIds;
  final List<String> corroborationSignalIds;
  final List<ExternalWorkOrderRef> workOrderRefs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? responsibleUnitId;
  final SlaClock? slaClock;
  final ResolutionEvidence? resolutionEvidence;
}

final class MunicipalWork {
  MunicipalWork({
    required String id,
    required this.status,
    required String category,
    required this.location,
    required DateTime startsAt,
    required DateTime expectedEndsAt,
    required String responsibleUnitId,
    required String explanation,
    this.externalWorkOrderRef,
  }) : id = requireText(id, 'id'),
       category = requireText(category, 'category'),
       startsAt = requireUtc(startsAt, 'startsAt'),
       expectedEndsAt = requireUtc(expectedEndsAt, 'expectedEndsAt'),
       responsibleUnitId = requireText(responsibleUnitId, 'responsibleUnitId'),
       explanation = requireText(explanation, 'explanation') {
    if (!expectedEndsAt.isAfter(startsAt)) {
      fail(FailureCode.validation, 'Çalışma bitişi başlangıçtan sonra olmalıdır.');
    }
  }

  final String id;
  final WorkStatus status;
  final String category;
  final GeoPoint location;
  final DateTime startsAt;
  final DateTime expectedEndsAt;
  final String responsibleUnitId;
  final String explanation;
  final ExternalWorkOrderRef? externalWorkOrderRef;
}

final class TimelineEvent {
  TimelineEvent({
    required String id,
    required String resourceId,
    required String type,
    required DateTime at,
    required String publicMessageKey,
    this.internalMessage,
  }) : id = requireText(id, 'id'),
       resourceId = requireText(resourceId, 'resourceId'),
       type = requireText(type, 'type'),
       at = requireUtc(at, 'at'),
       publicMessageKey = requireText(publicMessageKey, 'publicMessageKey');

  final String id;
  final String resourceId;
  final String type;
  final DateTime at;
  final String publicMessageKey;
  final String? internalMessage;
}

final class AppNotification {
  AppNotification({
    required String id,
    required String recipientId,
    required String eventId,
    required this.type,
    required String route,
    required DateTime createdAt,
    this.readAt,
  }) : id = requireText(id, 'id'),
       recipientId = requireText(recipientId, 'recipientId'),
       eventId = requireText(eventId, 'eventId'),
       route = requireText(route, 'route'),
       createdAt = requireUtc(createdAt, 'createdAt') {
    if (readAt != null) {
      requireUtc(readAt!, 'readAt');
    }
  }

  final String id;
  final String recipientId;
  final String eventId;
  final NotificationType type;
  final String route;
  final DateTime createdAt;
  final DateTime? readAt;
}

final class AuditEvent {
  AuditEvent({
    required String id,
    required String actorId,
    required String action,
    required String resourceId,
    required DateTime at,
    required String reason,
    required Map<String, Object?> before,
    required Map<String, Object?> after,
  }) : id = requireText(id, 'id'),
       actorId = requireText(actorId, 'actorId'),
       action = requireText(action, 'action'),
       resourceId = requireText(resourceId, 'resourceId'),
       at = requireUtc(at, 'at'),
       reason = requireText(reason, 'reason'),
       before = Map<String, Object?>.unmodifiable(before),
       after = Map<String, Object?>.unmodifiable(after);

  final String id;
  final String actorId;
  final String action;
  final String resourceId;
  final DateTime at;
  final String reason;
  final Map<String, Object?> before;
  final Map<String, Object?> after;
}

final class PrivacyRequest {
  PrivacyRequest({
    required String id,
    required String ownerId,
    required String trackingNumber,
    required this.type,
    required this.status,
    required DateTime createdAt,
  }) : id = requireText(id, 'id'),
       ownerId = requireText(ownerId, 'ownerId'),
       trackingNumber = requireText(trackingNumber, 'trackingNumber'),
       createdAt = requireUtc(createdAt, 'createdAt');

  final String id;
  final String ownerId;
  final String trackingNumber;
  final PrivacyRequestType type;
  final PrivacyRequestStatus status;
  final DateTime createdAt;
}

final class AccountRestriction {
  AccountRestriction({
    required String id,
    required String accountId,
    required this.level,
    required String reason,
    required DateTime startsAt,
    this.expiresAt,
    this.decidedBy,
  }) : id = requireText(id, 'id'),
       accountId = requireText(accountId, 'accountId'),
       reason = requireText(reason, 'reason'),
       startsAt = requireUtc(startsAt, 'startsAt') {
    if (level == RestrictionLevel.temporaryRestriction && decidedBy == null) {
      fail(FailureCode.validation, 'Geçici kısıtlama insan kararı ister.');
    }
    if (decidedBy != null) {
      requireText(decidedBy!, 'decidedBy');
    }
    if (expiresAt != null) {
      requireUtc(expiresAt!, 'expiresAt');
    }
  }

  final String id;
  final String accountId;
  final RestrictionLevel level;
  final String reason;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final String? decidedBy;
}

final class DemoScenario {
  DemoScenario({
    required String id,
    required String aiMode,
    required String privacyMode,
    required String connectivity,
  }) : id = requireText(id, 'id'),
       aiMode = requireText(aiMode, 'aiMode'),
       privacyMode = requireText(privacyMode, 'privacyMode'),
       connectivity = requireText(connectivity, 'connectivity');

  final String id;
  final String aiMode;
  final String privacyMode;
  final String connectivity;
}
