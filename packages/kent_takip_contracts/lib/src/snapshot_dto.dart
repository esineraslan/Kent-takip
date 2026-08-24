import 'package:kent_takip_contracts/src/strict_json.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

final class AppSnapshotDto {
  AppSnapshotDto({
    required this.schemaVersion,
    required this.seedVersion,
    required this.revision,
    required DateTime updatedAt,
    required this.checksum,
    required this.payload,
  }) : updatedAt = requireUtc(updatedAt, 'updatedAt') {
    if (schemaVersion < 1 || revision < 0) {
      fail(FailureCode.validation, 'Schema ve revision geçersiz.');
    }
  }

  factory AppSnapshotDto.fromJson(JsonMap json) {
    return AppSnapshotDto(
      schemaVersion: expectInt(json['schemaVersion'], 'schemaVersion'),
      seedVersion: expectString(json['seedVersion'], 'seedVersion'),
      revision: expectInt(json['revision'], 'revision'),
      updatedAt: expectUtcDate(json['updatedAt'], 'updatedAt'),
      checksum: expectString(json['checksum'], 'checksum'),
      payload: SnapshotPayloadDto.fromJson(
        expectMap(json['payload'], 'payload'),
      ),
    );
  }

  final int schemaVersion;
  final String seedVersion;
  final int revision;
  final DateTime updatedAt;
  final String checksum;
  final SnapshotPayloadDto payload;

  JsonMap toJson() => {
    'schemaVersion': schemaVersion,
    'seedVersion': seedVersion,
    'revision': revision,
    'updatedAt': updatedAt.toIso8601String(),
    'checksum': checksum,
    'payload': payload.toJson(),
  };

  AppSnapshotDto copyWith({
    int? schemaVersion,
    String? seedVersion,
    int? revision,
    DateTime? updatedAt,
    String? checksum,
    SnapshotPayloadDto? payload,
  }) {
    return AppSnapshotDto(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      seedVersion: seedVersion ?? this.seedVersion,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
      checksum: checksum ?? this.checksum,
      payload: payload ?? this.payload,
    );
  }
}

final class SnapshotPayloadDto {
  SnapshotPayloadDto({
    required Iterable<AccountDto> accounts,
    required Iterable<CitizenReportDto> reports,
    required Iterable<UrbanIncidentDto> incidents,
    required Iterable<MunicipalWorkDto> municipalWorks,
    required Iterable<MediaRefDto> media,
    required Iterable<AiAnalysisDto> analyses,
    required Iterable<OpaqueEntityDto> sourceAuthorities,
    required Iterable<OpaqueEntityDto> sourceRecords,
    required Iterable<OpaqueEntityDto> dataSourceHealth,
    required Iterable<OpaqueEntityDto> corroborations,
    required Iterable<OpaqueEntityDto> timeline,
    required Iterable<OpaqueEntityDto> notifications,
    required Iterable<OpaqueEntityDto> auditEvents,
    required Iterable<OpaqueEntityDto> privacyRequests,
    required Iterable<OpaqueEntityDto> restrictions,
    required Iterable<OpaqueEntityDto> demoScenarios,
  }) : accounts = List<AccountDto>.unmodifiable(accounts),
       reports = List<CitizenReportDto>.unmodifiable(reports),
       incidents = List<UrbanIncidentDto>.unmodifiable(incidents),
       municipalWorks = List<MunicipalWorkDto>.unmodifiable(municipalWorks),
       media = List<MediaRefDto>.unmodifiable(media),
       analyses = List<AiAnalysisDto>.unmodifiable(analyses),
       sourceAuthorities = List<OpaqueEntityDto>.unmodifiable(sourceAuthorities),
       sourceRecords = List<OpaqueEntityDto>.unmodifiable(sourceRecords),
       dataSourceHealth = List<OpaqueEntityDto>.unmodifiable(dataSourceHealth),
       corroborations = List<OpaqueEntityDto>.unmodifiable(corroborations),
       timeline = List<OpaqueEntityDto>.unmodifiable(timeline),
       notifications = List<OpaqueEntityDto>.unmodifiable(notifications),
       auditEvents = List<OpaqueEntityDto>.unmodifiable(auditEvents),
       privacyRequests = List<OpaqueEntityDto>.unmodifiable(privacyRequests),
       restrictions = List<OpaqueEntityDto>.unmodifiable(restrictions),
       demoScenarios = List<OpaqueEntityDto>.unmodifiable(demoScenarios);

  factory SnapshotPayloadDto.fromJson(JsonMap json) {
    List<OpaqueEntityDto> opaque(String key) => decodeList(
      json[key] ?? <Object?>[],
      'payload.$key',
      OpaqueEntityDto.fromObject,
    );

    return SnapshotPayloadDto(
      accounts: decodeList(
        json['accounts'],
        'payload.accounts',
        AccountDto.fromObject,
      ),
      reports: decodeList(
        json['reports'],
        'payload.reports',
        CitizenReportDto.fromObject,
      ),
      incidents: decodeList(
        json['incidents'],
        'payload.incidents',
        UrbanIncidentDto.fromObject,
      ),
      municipalWorks: decodeList(
        json['municipalWorks'],
        'payload.municipalWorks',
        MunicipalWorkDto.fromObject,
      ),
      media: decodeList(json['media'], 'payload.media', MediaRefDto.fromObject),
      analyses: decodeList(
        json['analyses'],
        'payload.analyses',
        AiAnalysisDto.fromObject,
      ),
      sourceAuthorities: opaque('sourceAuthorities'),
      sourceRecords: opaque('sourceRecords'),
      dataSourceHealth: opaque('dataSourceHealth'),
      corroborations: opaque('corroborations'),
      timeline: opaque('timeline'),
      notifications: opaque('notifications'),
      auditEvents: opaque('auditEvents'),
      privacyRequests: opaque('privacyRequests'),
      restrictions: opaque('restrictions'),
      demoScenarios: opaque('demoScenarios'),
    );
  }

  factory SnapshotPayloadDto.empty() => SnapshotPayloadDto(
    accounts: const [],
    reports: const [],
    incidents: const [],
    municipalWorks: const [],
    media: const [],
    analyses: const [],
    sourceAuthorities: const [],
    sourceRecords: const [],
    dataSourceHealth: const [],
    corroborations: const [],
    timeline: const [],
    notifications: const [],
    auditEvents: const [],
    privacyRequests: const [],
    restrictions: const [],
    demoScenarios: const [],
  );

  final List<AccountDto> accounts;
  final List<CitizenReportDto> reports;
  final List<UrbanIncidentDto> incidents;
  final List<MunicipalWorkDto> municipalWorks;
  final List<MediaRefDto> media;
  final List<AiAnalysisDto> analyses;
  final List<OpaqueEntityDto> sourceAuthorities;
  final List<OpaqueEntityDto> sourceRecords;
  final List<OpaqueEntityDto> dataSourceHealth;
  final List<OpaqueEntityDto> corroborations;
  final List<OpaqueEntityDto> timeline;
  final List<OpaqueEntityDto> notifications;
  final List<OpaqueEntityDto> auditEvents;
  final List<OpaqueEntityDto> privacyRequests;
  final List<OpaqueEntityDto> restrictions;
  final List<OpaqueEntityDto> demoScenarios;

  SnapshotPayloadDto copyWith({
    Iterable<AccountDto>? accounts,
    Iterable<CitizenReportDto>? reports,
    Iterable<UrbanIncidentDto>? incidents,
    Iterable<MunicipalWorkDto>? municipalWorks,
    Iterable<MediaRefDto>? media,
    Iterable<AiAnalysisDto>? analyses,
    Iterable<OpaqueEntityDto>? sourceAuthorities,
    Iterable<OpaqueEntityDto>? sourceRecords,
    Iterable<OpaqueEntityDto>? dataSourceHealth,
    Iterable<OpaqueEntityDto>? corroborations,
    Iterable<OpaqueEntityDto>? timeline,
    Iterable<OpaqueEntityDto>? notifications,
    Iterable<OpaqueEntityDto>? auditEvents,
    Iterable<OpaqueEntityDto>? privacyRequests,
    Iterable<OpaqueEntityDto>? restrictions,
    Iterable<OpaqueEntityDto>? demoScenarios,
  }) {
    return SnapshotPayloadDto(
      accounts: accounts ?? this.accounts,
      reports: reports ?? this.reports,
      incidents: incidents ?? this.incidents,
      municipalWorks: municipalWorks ?? this.municipalWorks,
      media: media ?? this.media,
      analyses: analyses ?? this.analyses,
      sourceAuthorities: sourceAuthorities ?? this.sourceAuthorities,
      sourceRecords: sourceRecords ?? this.sourceRecords,
      dataSourceHealth: dataSourceHealth ?? this.dataSourceHealth,
      corroborations: corroborations ?? this.corroborations,
      timeline: timeline ?? this.timeline,
      notifications: notifications ?? this.notifications,
      auditEvents: auditEvents ?? this.auditEvents,
      privacyRequests: privacyRequests ?? this.privacyRequests,
      restrictions: restrictions ?? this.restrictions,
      demoScenarios: demoScenarios ?? this.demoScenarios,
    );
  }

  JsonMap toJson() => {
    'accounts': accounts.map((value) => value.toJson()).toList(),
    'reports': reports.map((value) => value.toJson()).toList(),
    'incidents': incidents.map((value) => value.toJson()).toList(),
    'municipalWorks': municipalWorks.map((value) => value.toJson()).toList(),
    'media': media.map((value) => value.toJson()).toList(),
    'analyses': analyses.map((value) => value.toJson()).toList(),
    'sourceAuthorities': sourceAuthorities.map((value) => value.toJson()).toList(),
    'sourceRecords': sourceRecords.map((value) => value.toJson()).toList(),
    'dataSourceHealth': dataSourceHealth.map((value) => value.toJson()).toList(),
    'corroborations': corroborations.map((value) => value.toJson()).toList(),
    'timeline': timeline.map((value) => value.toJson()).toList(),
    'notifications': notifications.map((value) => value.toJson()).toList(),
    'auditEvents': auditEvents.map((value) => value.toJson()).toList(),
    'privacyRequests': privacyRequests.map((value) => value.toJson()).toList(),
    'restrictions': restrictions.map((value) => value.toJson()).toList(),
    'demoScenarios': demoScenarios.map((value) => value.toJson()).toList(),
  };
}

final class AccountDto {
  AccountDto({
    required this.id,
    required this.role,
    required Iterable<Permission> permissions,
    this.unitId,
    required this.deletionRequested,
  }) : permissions = List<Permission>.unmodifiable(permissions) {
    UserAccount(
      id: id,
      role: role,
      permissions: permissions,
      unitId: unitId,
      deletionRequested: deletionRequested,
    );
  }

  factory AccountDto.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    return AccountDto(
      id: expectString(json['id'], '$path.id'),
      role: expectEnum(json['role'], '$path.role', enumValues(UserRole.values)),
      permissions: decodeList(
        json['permissions'],
        '$path.permissions',
        (item, itemPath) => expectEnum(
          item,
          itemPath,
          enumValues(Permission.values),
        ),
      ),
      unitId: expectNullableString(json['unitId'], '$path.unitId'),
      deletionRequested: expectBool(
        json['deletionRequested'],
        '$path.deletionRequested',
      ),
    );
  }

  final String id;
  final UserRole role;
  final List<Permission> permissions;
  final String? unitId;
  final bool deletionRequested;

  JsonMap toJson() => {
    'id': id,
    'role': enumWire(role),
    'permissions': permissions.map(enumWire).toList(),
    'unitId': unitId,
    'deletionRequested': deletionRequested,
  };
}

final class CitizenReportDto {
  CitizenReportDto({
    required this.id,
    required this.trackingNumber,
    required this.ownerId,
    required this.status,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.clientMutationId,
    required Iterable<String> mediaIds,
    this.analysisId,
    this.linkedIncidentId,
    required this.manualReviewRequired,
    required this.riskLevel,
    this.humanDecisionReason,
    this.resolutionExplanation,
    this.resolvedAt,
    this.resolutionPublicMediaRef,
  }) : mediaIds = List<String>.unmodifiable(mediaIds) {
    requireText(id, 'id');
    requireTrackingNumber(trackingNumber, 'trackingNumber');
    requireText(ownerId, 'ownerId');
    requireText(category, 'category');
    requireText(clientMutationId, 'clientMutationId');
    GeoPoint(latitude: latitude, longitude: longitude);
    requireUtc(createdAt, 'createdAt');
    requireUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      fail(FailureCode.validation, 'updatedAt createdAt öncesi olamaz.');
    }
    if (status == ReportStatus.resolved &&
        (resolutionExplanation?.trim().isEmpty ?? true)) {
      fail(FailureCode.validation, 'Çözülmüş report çözüm açıklaması ister.');
    }
    if (resolvedAt != null) requireUtc(resolvedAt!, 'resolvedAt');
  }

  factory CitizenReportDto.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    final location = expectMap(json['location'], '$path.location');
    if (expectString(
          location['coordinateSystem'],
          '$path.location.coordinateSystem',
        ) !=
        'EPSG:4326') {
      fail(FailureCode.validation, '$path.location yalnız WGS84 olabilir.');
    }
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    if (latitude is! num || longitude is! num) {
      fail(FailureCode.validation, '$path.location koordinatları geçersiz.');
    }
    return CitizenReportDto(
      id: expectString(json['id'], '$path.id'),
      trackingNumber: expectString(json['trackingNumber'], '$path.trackingNumber'),
      ownerId: expectString(json['ownerId'], '$path.ownerId'),
      status: expectEnum(
        json['status'],
        '$path.status',
        enumValues(ReportStatus.values),
      ),
      category: expectString(json['category'], '$path.category'),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      createdAt: expectUtcDate(json['createdAt'], '$path.createdAt'),
      updatedAt: expectUtcDate(json['updatedAt'], '$path.updatedAt'),
      clientMutationId: expectString(
        json['clientMutationId'],
        '$path.clientMutationId',
      ),
      mediaIds: decodeList(
        json['mediaIds'],
        '$path.mediaIds',
        expectString,
      ),
      analysisId: expectNullableString(json['analysisId'], '$path.analysisId'),
      linkedIncidentId: expectNullableString(
        json['linkedIncidentId'],
        '$path.linkedIncidentId',
      ),
      manualReviewRequired: expectBool(
        json['manualReviewRequired'],
        '$path.manualReviewRequired',
      ),
      riskLevel: expectEnum(
        json['riskLevel'],
        '$path.riskLevel',
        enumValues(RiskLevel.values),
      ),
      humanDecisionReason: expectNullableString(
        json['humanDecisionReason'],
        '$path.humanDecisionReason',
      ),
      resolutionExplanation: expectNullableString(
        json['resolutionExplanation'],
        '$path.resolutionExplanation',
      ),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : expectUtcDate(json['resolvedAt'], '$path.resolvedAt'),
      resolutionPublicMediaRef: expectNullableString(
        json['resolutionPublicMediaRef'],
        '$path.resolutionPublicMediaRef',
      ),
    );
  }

  final String id;
  final String trackingNumber;
  final String ownerId;
  final ReportStatus status;
  final String category;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String clientMutationId;
  final List<String> mediaIds;
  final String? analysisId;
  final String? linkedIncidentId;
  final bool manualReviewRequired;
  final RiskLevel riskLevel;
  final String? humanDecisionReason;
  final String? resolutionExplanation;
  final DateTime? resolvedAt;
  final String? resolutionPublicMediaRef;

  JsonMap toJson() => {
    'id': id,
    'trackingNumber': trackingNumber,
    'ownerId': ownerId,
    'status': enumWire(status),
    'category': category,
    'location': {
      'latitude': latitude,
      'longitude': longitude,
      'coordinateSystem': 'EPSG:4326',
    },
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'clientMutationId': clientMutationId,
    'mediaIds': mediaIds,
    'analysisId': analysisId,
    'linkedIncidentId': linkedIncidentId,
    'manualReviewRequired': manualReviewRequired,
    'riskLevel': enumWire(riskLevel),
    'humanDecisionReason': humanDecisionReason,
    'resolutionExplanation': resolutionExplanation,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolutionPublicMediaRef': resolutionPublicMediaRef,
  };
}

final class ExternalWorkOrderRefDto {
  ExternalWorkOrderRefDto({
    required this.sourceSystem,
    required this.externalWorkOrderId,
    required this.sourceUpdatedAt,
    required this.syncStatus,
    this.lastSyncError,
  }) {
    ExternalWorkOrderRef(
      sourceSystem: sourceSystem,
      externalWorkOrderId: externalWorkOrderId,
      sourceUpdatedAt: sourceUpdatedAt,
      syncStatus: syncStatus,
      lastSyncError: lastSyncError,
    );
  }

  factory ExternalWorkOrderRefDto.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    return ExternalWorkOrderRefDto(
      sourceSystem: expectString(json['sourceSystem'], '$path.sourceSystem'),
      externalWorkOrderId: expectString(
        json['externalWorkOrderId'],
        '$path.externalWorkOrderId',
      ),
      sourceUpdatedAt: expectUtcDate(
        json['sourceUpdatedAt'],
        '$path.sourceUpdatedAt',
      ),
      syncStatus: expectString(json['syncStatus'], '$path.syncStatus'),
      lastSyncError: expectNullableString(
        json['lastSyncError'],
        '$path.lastSyncError',
      ),
    );
  }

  final String sourceSystem;
  final String externalWorkOrderId;
  final DateTime sourceUpdatedAt;
  final String syncStatus;
  final String? lastSyncError;

  JsonMap toJson() => {
    'sourceSystem': sourceSystem,
    'externalWorkOrderId': externalWorkOrderId,
    'sourceUpdatedAt': sourceUpdatedAt.toIso8601String(),
    'syncStatus': syncStatus,
    'lastSyncError': lastSyncError,
  };
}

final class UrbanIncidentDto {
  UrbanIncidentDto({
    required this.id,
    required this.status,
    required this.category,
    required this.latitude,
    required this.longitude,
    required Iterable<String> reportIds,
    required Iterable<String> sourceRecordIds,
    Iterable<ExternalWorkOrderRefDto> workOrderRefs = const [],
    required this.createdAt,
    required this.updatedAt,
    this.responsibleUnitId,
    this.assigneeId,
    this.fieldTeamId,
    this.slaStartedAt,
    this.slaTargetAt,
    this.slaPausedAt,
    this.slaDelayReason,
    this.slaEstimateMinMinutes,
    this.slaEstimateMaxMinutes,
    this.reestimatedMinAt,
    this.reestimatedMaxAt,
    this.resolutionExplanation,
    this.resolvedAt,
    this.resolutionPublicMediaRef,
    this.citizenResolutionConfirmed,
  }) : reportIds = List<String>.unmodifiable(reportIds),
       sourceRecordIds = List<String>.unmodifiable(sourceRecordIds),
       workOrderRefs = List<ExternalWorkOrderRefDto>.unmodifiable(workOrderRefs) {
    requireText(id, 'id');
    requireText(category, 'category');
    GeoPoint(latitude: latitude, longitude: longitude);
    requireUtc(createdAt, 'createdAt');
    requireUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      fail(FailureCode.validation, 'updatedAt createdAt öncesi olamaz.');
    }
    if (status == IncidentStatus.resolved &&
        (resolutionExplanation?.trim().isEmpty ?? true)) {
      fail(FailureCode.validation, 'Çözülmüş incident çözüm açıklaması ister.');
    }
    if ((slaStartedAt == null) != (slaTargetAt == null)) {
      fail(FailureCode.validation, 'SLA başlangıç ve hedef zamanı birlikte bulunmalıdır.');
    }
    if (slaStartedAt != null) requireUtc(slaStartedAt!, 'slaStartedAt');
    if (slaTargetAt != null) {
      requireUtc(slaTargetAt!, 'slaTargetAt');
      if (!slaTargetAt!.isAfter(slaStartedAt!)) {
        fail(FailureCode.validation, 'SLA hedefi başlangıçtan sonra olmalıdır.');
      }
    }
    if (slaPausedAt != null) {
      requireUtc(slaPausedAt!, 'slaPausedAt');
      if (slaStartedAt == null || slaPausedAt!.isBefore(slaStartedAt!)) {
        fail(FailureCode.validation, 'SLA durma zamanı başlangıçtan önce olamaz.');
      }
    }
    if ((reestimatedMinAt == null) != (reestimatedMaxAt == null)) {
      fail(FailureCode.validation, 'Yeniden tahmin alt/üst zamanı birlikte bulunmalıdır.');
    }
    if (reestimatedMinAt != null) {
      requireUtc(reestimatedMinAt!, 'reestimatedMinAt');
      requireUtc(reestimatedMaxAt!, 'reestimatedMaxAt');
      if (!reestimatedMaxAt!.isAfter(reestimatedMinAt!)) {
        fail(FailureCode.validation, 'Yeniden tahmin üst zamanı alt zamandan sonra olmalıdır.');
      }
    }
    if (resolvedAt != null) requireUtc(resolvedAt!, 'resolvedAt');
    if (slaEstimateMinMinutes != null && slaEstimateMaxMinutes != null &&
        (slaEstimateMinMinutes! <= 0 || slaEstimateMaxMinutes! <= slaEstimateMinMinutes!)) {
      fail(FailureCode.validation, 'SLA hedef aralığı geçersiz.');
    }
  }

  factory UrbanIncidentDto.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    final location = expectMap(json['location'], '$path.location');
    if (expectString(
          location['coordinateSystem'],
          '$path.location.coordinateSystem',
        ) !=
        'EPSG:4326') {
      fail(FailureCode.validation, '$path.location yalnız WGS84 olabilir.');
    }
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    if (latitude is! num || longitude is! num) {
      fail(FailureCode.validation, '$path.location koordinatları geçersiz.');
    }
    return UrbanIncidentDto(
      id: expectString(json['id'], '$path.id'),
      status: expectEnum(
        json['status'],
        '$path.status',
        enumValues(IncidentStatus.values),
      ),
      category: expectString(json['category'], '$path.category'),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      reportIds: decodeList(json['reportIds'], '$path.reportIds', expectString),
      sourceRecordIds: decodeList(
        json['sourceRecordIds'],
        '$path.sourceRecordIds',
        expectString,
      ),
      workOrderRefs: json['workOrderRefs'] == null
          ? const []
          : decodeList(
              json['workOrderRefs'],
              '$path.workOrderRefs',
              ExternalWorkOrderRefDto.fromObject,
            ),
      createdAt: expectUtcDate(json['createdAt'], '$path.createdAt'),
      updatedAt: expectUtcDate(json['updatedAt'], '$path.updatedAt'),
      responsibleUnitId: expectNullableString(
        json['responsibleUnitId'],
        '$path.responsibleUnitId',
      ),
      assigneeId: expectNullableString(json['assigneeId'], '$path.assigneeId'),
      fieldTeamId: expectNullableString(json['fieldTeamId'], '$path.fieldTeamId'),
      slaStartedAt: json['slaStartedAt'] == null
          ? null
          : expectUtcDate(json['slaStartedAt'], '$path.slaStartedAt'),
      slaTargetAt: json['slaTargetAt'] == null
          ? null
          : expectUtcDate(json['slaTargetAt'], '$path.slaTargetAt'),
      slaPausedAt: json['slaPausedAt'] == null
          ? null
          : expectUtcDate(json['slaPausedAt'], '$path.slaPausedAt'),
      slaDelayReason: expectNullableString(
        json['slaDelayReason'],
        '$path.slaDelayReason',
      ),
      slaEstimateMinMinutes: json['slaEstimateMinMinutes'] == null
          ? null
          : expectInt(json['slaEstimateMinMinutes'], '$path.slaEstimateMinMinutes'),
      slaEstimateMaxMinutes: json['slaEstimateMaxMinutes'] == null
          ? null
          : expectInt(json['slaEstimateMaxMinutes'], '$path.slaEstimateMaxMinutes'),
      reestimatedMinAt: json['reestimatedMinAt'] == null
          ? null
          : expectUtcDate(json['reestimatedMinAt'], '$path.reestimatedMinAt'),
      reestimatedMaxAt: json['reestimatedMaxAt'] == null
          ? null
          : expectUtcDate(json['reestimatedMaxAt'], '$path.reestimatedMaxAt'),
      resolutionExplanation: expectNullableString(
        json['resolutionExplanation'],
        '$path.resolutionExplanation',
      ),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : expectUtcDate(json['resolvedAt'], '$path.resolvedAt'),
      resolutionPublicMediaRef: expectNullableString(
        json['resolutionPublicMediaRef'],
        '$path.resolutionPublicMediaRef',
      ),
      citizenResolutionConfirmed: json['citizenResolutionConfirmed'] == null
          ? null
          : expectBool(
              json['citizenResolutionConfirmed'],
              '$path.citizenResolutionConfirmed',
            ),
    );
  }

  final String id;
  final IncidentStatus status;
  final String category;
  final double latitude;
  final double longitude;
  final List<String> reportIds;
  final List<String> sourceRecordIds;
  final List<ExternalWorkOrderRefDto> workOrderRefs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? responsibleUnitId;
  final String? assigneeId;
  final String? fieldTeamId;
  final DateTime? slaStartedAt;
  final DateTime? slaTargetAt;
  final DateTime? slaPausedAt;
  final String? slaDelayReason;
  final int? slaEstimateMinMinutes;
  final int? slaEstimateMaxMinutes;
  final DateTime? reestimatedMinAt;
  final DateTime? reestimatedMaxAt;
  final String? resolutionExplanation;
  final DateTime? resolvedAt;
  final String? resolutionPublicMediaRef;
  final bool? citizenResolutionConfirmed;

  JsonMap toJson() => {
    'id': id,
    'status': enumWire(status),
    'category': category,
    'location': {
      'latitude': latitude,
      'longitude': longitude,
      'coordinateSystem': 'EPSG:4326',
    },
    'reportIds': reportIds,
    'sourceRecordIds': sourceRecordIds,
    if (workOrderRefs.isNotEmpty)
      'workOrderRefs': workOrderRefs.map((value) => value.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'responsibleUnitId': responsibleUnitId,
    if (assigneeId != null) 'assigneeId': assigneeId,
    if (fieldTeamId != null) 'fieldTeamId': fieldTeamId,
    if (slaStartedAt != null) 'slaStartedAt': slaStartedAt!.toIso8601String(),
    if (slaTargetAt != null) 'slaTargetAt': slaTargetAt!.toIso8601String(),
    if (slaPausedAt != null) 'slaPausedAt': slaPausedAt!.toIso8601String(),
    if (slaDelayReason != null) 'slaDelayReason': slaDelayReason,
    if (slaEstimateMinMinutes != null)
      'slaEstimateMinMinutes': slaEstimateMinMinutes,
    if (slaEstimateMaxMinutes != null)
      'slaEstimateMaxMinutes': slaEstimateMaxMinutes,
    if (reestimatedMinAt != null)
      'reestimatedMinAt': reestimatedMinAt!.toIso8601String(),
    if (reestimatedMaxAt != null)
      'reestimatedMaxAt': reestimatedMaxAt!.toIso8601String(),
    'resolutionExplanation': resolutionExplanation,
    'resolvedAt': resolvedAt?.toIso8601String(),
    if (resolutionPublicMediaRef != null)
      'resolutionPublicMediaRef': resolutionPublicMediaRef,
    if (citizenResolutionConfirmed != null)
      'citizenResolutionConfirmed': citizenResolutionConfirmed,
  };
}

final class MunicipalWorkImpactDto {
  MunicipalWorkImpactDto({
    required this.analyzedAt,
    required Iterable<OpaqueEntityDto> overlaps,
    required Iterable<String> affectedRoadSegments,
    required Iterable<String> affectedTransitLines,
    required Iterable<String> suggestions,
    required this.citizenInformationDraft,
    required this.explanation,
  }) : overlaps = List<OpaqueEntityDto>.unmodifiable(overlaps),
       affectedRoadSegments = List<String>.unmodifiable(affectedRoadSegments),
       affectedTransitLines = List<String>.unmodifiable(affectedTransitLines),
       suggestions = List<String>.unmodifiable(suggestions) {
    requireUtc(analyzedAt, 'analyzedAt');
    requireText(citizenInformationDraft, 'citizenInformationDraft');
    requireText(explanation, 'explanation');
  }

  factory MunicipalWorkImpactDto.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    return MunicipalWorkImpactDto(
      analyzedAt: expectUtcDate(json['analyzedAt'], '$path.analyzedAt'),
      overlaps: decodeList(json['overlaps'], '$path.overlaps', OpaqueEntityDto.fromObject),
      affectedRoadSegments: decodeList(
        json['affectedRoadSegments'],
        '$path.affectedRoadSegments',
        expectString,
      ),
      affectedTransitLines: decodeList(
        json['affectedTransitLines'],
        '$path.affectedTransitLines',
        expectString,
      ),
      suggestions: decodeList(json['suggestions'], '$path.suggestions', expectString),
      citizenInformationDraft: expectString(
        json['citizenInformationDraft'],
        '$path.citizenInformationDraft',
      ),
      explanation: expectString(json['explanation'], '$path.explanation'),
    );
  }

  final DateTime analyzedAt;
  final List<OpaqueEntityDto> overlaps;
  final List<String> affectedRoadSegments;
  final List<String> affectedTransitLines;
  final List<String> suggestions;
  final String citizenInformationDraft;
  final String explanation;

  JsonMap toJson() => {
    'analyzedAt': analyzedAt.toIso8601String(),
    'overlaps': overlaps.map((value) => value.toJson()).toList(),
    'affectedRoadSegments': affectedRoadSegments,
    'affectedTransitLines': affectedTransitLines,
    'suggestions': suggestions,
    'citizenInformationDraft': citizenInformationDraft,
    'explanation': explanation,
  };
}

final class MunicipalWorkDto {
  MunicipalWorkDto({
    required this.id,
    required this.status,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.expectedEndsAt,
    required this.responsibleUnitId,
    required this.explanation,
    this.areaRadiusMeters = 120,
    Iterable<String> affectedRoadSegments = const [],
    Iterable<String> affectedTransitLines = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.impact,
    this.publicInformationText,
    this.publicPreviewApproved = false,
    this.publishedAt,
    this.completedAt,
  }) : affectedRoadSegments = List<String>.unmodifiable(affectedRoadSegments),
       affectedTransitLines = List<String>.unmodifiable(affectedTransitLines) {
    requireText(id, 'id');
    requireText(category, 'category');
    GeoPoint(latitude: latitude, longitude: longitude);
    requireUtc(startsAt, 'startsAt');
    requireUtc(expectedEndsAt, 'expectedEndsAt');
    requireText(responsibleUnitId, 'responsibleUnitId');
    requireText(explanation, 'explanation');
    if (!expectedEndsAt.isAfter(startsAt)) {
      fail(FailureCode.validation, 'Çalışma tarih aralığı geçersiz.');
    }
    if (areaRadiusMeters < 25 || areaRadiusMeters > 5000) {
      fail(FailureCode.validation, 'Etki alanı yarıçapı 25–5000 metre olmalıdır.');
    }
    if (createdAt != null) requireUtc(createdAt!, 'createdAt');
    if (updatedAt != null) requireUtc(updatedAt!, 'updatedAt');
    if (publishedAt != null) requireUtc(publishedAt!, 'publishedAt');
    if (completedAt != null) requireUtc(completedAt!, 'completedAt');
  }

  factory MunicipalWorkDto.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    final location = expectMap(json['location'], '$path.location');
    if (expectString(
          location['coordinateSystem'],
          '$path.location.coordinateSystem',
        ) !=
        'EPSG:4326') {
      fail(FailureCode.validation, '$path.location yalnız WGS84 olabilir.');
    }
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    if (latitude is! num || longitude is! num) {
      fail(FailureCode.validation, '$path.location koordinatları geçersiz.');
    }
    return MunicipalWorkDto(
      id: expectString(json['id'], '$path.id'),
      status: expectEnum(
        json['status'],
        '$path.status',
        enumValues(WorkStatus.values),
      ),
      category: expectString(json['category'], '$path.category'),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      startsAt: expectUtcDate(json['startsAt'], '$path.startsAt'),
      expectedEndsAt: expectUtcDate(
        json['expectedEndsAt'],
        '$path.expectedEndsAt',
      ),
      responsibleUnitId: expectString(
        json['responsibleUnitId'],
        '$path.responsibleUnitId',
      ),
      explanation: expectString(json['explanation'], '$path.explanation'),
      areaRadiusMeters: json['areaRadiusMeters'] == null
          ? 120
          : expectInt(json['areaRadiusMeters'], '$path.areaRadiusMeters'),
      affectedRoadSegments: json['affectedRoadSegments'] == null
          ? const []
          : decodeList(
              json['affectedRoadSegments'],
              '$path.affectedRoadSegments',
              expectString,
            ),
      affectedTransitLines: json['affectedTransitLines'] == null
          ? const []
          : decodeList(
              json['affectedTransitLines'],
              '$path.affectedTransitLines',
              expectString,
            ),
      createdBy: expectNullableString(json['createdBy'], '$path.createdBy'),
      createdAt: json['createdAt'] == null
          ? null
          : expectUtcDate(json['createdAt'], '$path.createdAt'),
      updatedAt: json['updatedAt'] == null
          ? null
          : expectUtcDate(json['updatedAt'], '$path.updatedAt'),
      impact: json['impact'] == null
          ? null
          : MunicipalWorkImpactDto.fromObject(json['impact'], '$path.impact'),
      publicInformationText: expectNullableString(
        json['publicInformationText'],
        '$path.publicInformationText',
      ),
      publicPreviewApproved: json['publicPreviewApproved'] == null
          ? false
          : expectBool(json['publicPreviewApproved'], '$path.publicPreviewApproved'),
      publishedAt: json['publishedAt'] == null
          ? null
          : expectUtcDate(json['publishedAt'], '$path.publishedAt'),
      completedAt: json['completedAt'] == null
          ? null
          : expectUtcDate(json['completedAt'], '$path.completedAt'),
    );
  }

  final String id;
  final WorkStatus status;
  final String category;
  final double latitude;
  final double longitude;
  final DateTime startsAt;
  final DateTime expectedEndsAt;
  final String responsibleUnitId;
  final String explanation;
  final int areaRadiusMeters;
  final List<String> affectedRoadSegments;
  final List<String> affectedTransitLines;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final MunicipalWorkImpactDto? impact;
  final String? publicInformationText;
  final bool publicPreviewApproved;
  final DateTime? publishedAt;
  final DateTime? completedAt;

  JsonMap toJson() => {
    'id': id,
    'status': enumWire(status),
    'category': category,
    'location': {
      'latitude': latitude,
      'longitude': longitude,
      'coordinateSystem': 'EPSG:4326',
    },
    'startsAt': startsAt.toIso8601String(),
    'expectedEndsAt': expectedEndsAt.toIso8601String(),
    'responsibleUnitId': responsibleUnitId,
    'explanation': explanation,
    if (areaRadiusMeters != 120) 'areaRadiusMeters': areaRadiusMeters,
    if (affectedRoadSegments.isNotEmpty)
      'affectedRoadSegments': affectedRoadSegments,
    if (affectedTransitLines.isNotEmpty)
      'affectedTransitLines': affectedTransitLines,
    if (createdBy != null) 'createdBy': createdBy,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (impact != null) 'impact': impact!.toJson(),
    if (publicInformationText != null)
      'publicInformationText': publicInformationText,
    if (publicPreviewApproved) 'publicPreviewApproved': true,
    if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
  };
}

final class MediaRefDto {
  MediaRefDto({
    required this.id,
    required this.privacyStatus,
    this.originalRef,
    this.publicRef,
    required this.mimeType,
  }) {
    MediaRef(
      id: id,
      privacyStatus: privacyStatus,
      originalRef: originalRef,
      publicRef: publicRef,
      mimeType: mimeType,
    );
  }

  factory MediaRefDto.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    return MediaRefDto(
      id: expectString(json['id'], '$path.id'),
      privacyStatus: expectEnum(
        json['privacyStatus'],
        '$path.privacyStatus',
        enumValues(PrivacyStatus.values),
      ),
      originalRef: expectNullableString(json['originalRef'], '$path.originalRef'),
      publicRef: expectNullableString(json['publicRef'], '$path.publicRef'),
      mimeType: expectString(json['mimeType'], '$path.mimeType'),
    );
  }

  final String id;
  final PrivacyStatus privacyStatus;
  final String? originalRef;
  final String? publicRef;
  final String mimeType;

  JsonMap toJson() => {
    'id': id,
    'privacyStatus': enumWire(privacyStatus),
    'originalRef': originalRef,
    'publicRef': publicRef,
    'mimeType': mimeType,
  };
}

final class AiAnalysisDto {
  AiAnalysisDto({
    required this.id,
    required this.status,
    this.categoryConfidence,
    this.duplicateConfidence,
    required Iterable<String> reasonCodes,
    required this.modelVersion,
    required this.configVersion,
    required this.createdAt,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes) {
    if (categoryConfidence != null) {
      requireScore(categoryConfidence!, 'categoryConfidence');
    }
    if (duplicateConfidence != null) {
      requireScore(duplicateConfidence!, 'duplicateConfidence');
    }
  }

  factory AiAnalysisDto.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    return AiAnalysisDto(
      id: expectString(json['id'], '$path.id'),
      status: expectEnum(
        json['status'],
        '$path.status',
        enumValues(AiAnalysisStatus.values),
      ),
      categoryConfidence: json['categoryConfidence'] == null
          ? null
          : expectInt(json['categoryConfidence'], '$path.categoryConfidence'),
      duplicateConfidence: json['duplicateConfidence'] == null
          ? null
          : expectInt(json['duplicateConfidence'], '$path.duplicateConfidence'),
      reasonCodes: decodeList(
        json['reasonCodes'],
        '$path.reasonCodes',
        expectString,
      ),
      modelVersion: expectString(json['modelVersion'], '$path.modelVersion'),
      configVersion: expectString(json['configVersion'], '$path.configVersion'),
      createdAt: expectUtcDate(json['createdAt'], '$path.createdAt'),
    );
  }

  final String id;
  final AiAnalysisStatus status;
  final int? categoryConfidence;
  final int? duplicateConfidence;
  final List<String> reasonCodes;
  final String modelVersion;
  final String configVersion;
  final DateTime createdAt;

  JsonMap toJson() => {
    'id': id,
    'status': enumWire(status),
    'categoryConfidence': categoryConfidence,
    'duplicateConfidence': duplicateConfidence,
    'reasonCodes': reasonCodes,
    'modelVersion': modelVersion,
    'configVersion': configVersion,
    'createdAt': createdAt.toIso8601String(),
  };
}

final class OpaqueEntityDto {
  OpaqueEntityDto({required this.id, required JsonMap body})
    : body = deepFreezeJson(body, id) as JsonMap;

  factory OpaqueEntityDto.fromObject(Object? value, String path) {
    final body = expectMap(value, path);
    final id = expectString(body['id'] ?? body['sourceId'], '$path.id');
    return OpaqueEntityDto(id: id, body: body);
  }

  final String id;
  final JsonMap body;

  JsonMap toJson() => body;
}
