import 'dart:convert';

import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/src/canonical_json.dart';
import 'package:kent_takip_persistence/src/migration.dart';

final class SnapshotCodec {
  SnapshotCodec({
    required this.migrations,
    this.maximumBytes = 3 * 1024 * 1024,
  });

  final MigrationRegistry migrations;
  final int maximumBytes;

  AppSnapshotDto decode(String source) {
    if (utf8.encode(source).length > maximumBytes) {
      fail(FailureCode.validation, 'Snapshot boyut bütçesini aşıyor.');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      fail(FailureCode.corruption, 'Snapshot JSON parse edilemedi.');
    }
    final migrated = migrations.migrate(expectMap(decoded, 'snapshot'));
    final snapshot = AppSnapshotDto.fromJson(migrated);
    validate(snapshot);
    return snapshot;
  }

  String encode(AppSnapshotDto snapshot) {
    validate(snapshot);
    final encoded = canonicalJson(snapshot.toJson());
    if (utf8.encode(encoded).length > maximumBytes) {
      fail(FailureCode.validation, 'Snapshot boyut bütçesini aşıyor.');
    }
    return encoded;
  }

  AppSnapshotDto seal(AppSnapshotDto snapshot) {
    final checksum = sha256Checksum(snapshot.payload.toJson());
    final sealed = snapshot.copyWith(checksum: checksum);
    validate(sealed);
    return sealed;
  }

  void validate(AppSnapshotDto snapshot) {
    if (snapshot.schemaVersion != migrations.currentVersion) {
      fail(
        FailureCode.unsupportedSchema,
        'Beklenmeyen schema sürümü: ${snapshot.schemaVersion}.',
      );
    }
    final expected = sha256Checksum(snapshot.payload.toJson());
    if (snapshot.checksum != expected) {
      fail(FailureCode.corruption, 'Snapshot checksum uyuşmuyor.');
    }
    _validateUniqueIds(snapshot.payload);
    _validateReferences(snapshot.payload);
    _validateAuxiliaryEntities(snapshot.payload);
    _rejectForbiddenProfileFields(snapshot.payload.toJson(), 'payload');
  }

  void _validateUniqueIds(SnapshotPayloadDto payload) {
    void unique(Iterable<String> ids, String label) {
      final values = ids.toList();
      if (values.toSet().length != values.length) {
        fail(FailureCode.validation, '$label içinde mükerrer ID var.');
      }
    }

    unique(payload.accounts.map((value) => value.id), 'accounts');
    unique(payload.reports.map((value) => value.id), 'reports');
    unique(payload.reports.map((value) => value.clientMutationId), 'clientMutationId');
    unique(payload.reports.map((value) => value.trackingNumber), 'trackingNumber');
    unique(payload.incidents.map((value) => value.id), 'incidents');
    unique(payload.municipalWorks.map((value) => value.id), 'municipalWorks');
    unique(payload.media.map((value) => value.id), 'media');
    unique(payload.analyses.map((value) => value.id), 'analyses');
    unique(payload.sourceAuthorities.map((value) => value.id), 'sourceAuthorities');
    unique(payload.sourceRecords.map((value) => value.id), 'sourceRecords');
    unique(payload.timeline.map((value) => value.id), 'timeline');
    unique(payload.notifications.map((value) => value.id), 'notifications');
    unique(payload.auditEvents.map((value) => value.id), 'auditEvents');
    unique(payload.dataSourceHealth.map((value) => value.id), 'dataSourceHealth');
    unique(payload.corroborations.map((value) => value.id), 'corroborations');
    unique(payload.privacyRequests.map((value) => value.id), 'privacyRequests');
    unique(payload.restrictions.map((value) => value.id), 'restrictions');
    unique(payload.demoScenarios.map((value) => value.id), 'demoScenarios');
  }

  void _validateReferences(SnapshotPayloadDto payload) {
    final accountIds = payload.accounts.map((value) => value.id).toSet();
    final mediaIds = payload.media.map((value) => value.id).toSet();
    final analysisIds = payload.analyses.map((value) => value.id).toSet();
    final reportIds = payload.reports.map((value) => value.id).toSet();
    final incidentIds = payload.incidents.map((value) => value.id).toSet();
    final sourceRecordIds = payload.sourceRecords.map((value) => value.id).toSet();

    for (final report in payload.reports) {
      if (!accountIds.contains(report.ownerId)) {
        fail(FailureCode.validation, 'Report owner bulunamadı: ${report.id}.');
      }
      if (!report.mediaIds.every(mediaIds.contains)) {
        fail(FailureCode.validation, 'Report medya referansı bozuk: ${report.id}.');
      }
      if (report.analysisId != null && !analysisIds.contains(report.analysisId)) {
        fail(FailureCode.validation, 'Report analysis referansı bozuk: ${report.id}.');
      }
      if (report.linkedIncidentId != null &&
          !incidentIds.contains(report.linkedIncidentId)) {
        fail(FailureCode.validation, 'Report incident referansı bozuk: ${report.id}.');
      }
      if (report.status == ReportStatus.merged && report.linkedIncidentId == null) {
        fail(FailureCode.validation, 'Merged report ana incident taşımıyor: ${report.id}.');
      }
      if ({ReportStatus.rejected, ReportStatus.outOfScope}.contains(report.status) &&
          (report.humanDecisionReason == null ||
              report.humanDecisionReason!.trim().isEmpty)) {
        fail(FailureCode.validation, 'İnsan karar gerekçesi eksik: ${report.id}.');
      }
      if (report.status == ReportStatus.resolved &&
          (report.resolutionExplanation == null || report.resolvedAt == null)) {
        fail(FailureCode.validation, 'Çözüm kanıtı eksik: ${report.id}.');
      }
      if (report.resolutionPublicMediaRef != null &&
          !mediaIds.contains(report.resolutionPublicMediaRef)) {
        fail(FailureCode.validation, 'Çözüm medya referansı bozuk: ${report.id}.');
      }
    }
    for (final incident in payload.incidents) {
      if (!incident.reportIds.every(reportIds.contains)) {
        fail(FailureCode.validation, 'Incident report referansı bozuk: ${incident.id}.');
      }
      if (!incident.sourceRecordIds.every(sourceRecordIds.contains)) {
        fail(FailureCode.validation, 'Incident kaynak referansı bozuk: ${incident.id}.');
      }
      if (incident.reportIds.isEmpty && incident.sourceRecordIds.isEmpty) {
        fail(FailureCode.validation, 'Incident kaynak sinyali taşımıyor: ${incident.id}.');
      }
      if (incident.status == IncidentStatus.resolved &&
          (incident.resolutionExplanation == null || incident.resolvedAt == null)) {
        fail(FailureCode.validation, 'Incident çözüm kanıtı eksik: ${incident.id}.');
      }
    }
  }

  void _validateAuxiliaryEntities(SnapshotPayloadDto payload) {
    final accountIds = payload.accounts.map((value) => value.id).toSet();
    final incidentIds = payload.incidents.map((value) => value.id).toSet();
    final resourceIds = <String>{
      ...payload.reports.map((value) => value.id),
      ...incidentIds,
      ...payload.municipalWorks.map((value) => value.id),
    };
    final authorityIds = payload.sourceAuthorities
        .map((value) => value.id)
        .toSet();

    for (final entity in payload.sourceAuthorities) {
      final body = entity.body;
      expectString(body['displayName'], '${entity.id}.displayName');
      expectEnum(
        body['rank'],
        '${entity.id}.rank',
        enumValues(SourceAuthorityRank.values),
      );
      expectBool(
        body['officialAlertAuthority'],
        '${entity.id}.officialAlertAuthority',
      );
    }
    for (final entity in payload.sourceRecords) {
      final body = entity.body;
      expectString(body['sourceId'], '${entity.id}.sourceId');
      expectString(body['externalId'], '${entity.id}.externalId');
      final authorityId = expectString(
        body['authorityId'],
        '${entity.id}.authorityId',
      );
      if (!authorityIds.contains(authorityId)) {
        fail(
          FailureCode.validation,
          'Source authority referansı bozuk: ${entity.id}.',
        );
      }
      expectEnum(
        body['health'],
        '${entity.id}.health',
        enumValues(SourceHealth.values),
      );
      expectUtcDate(body['sourceUpdatedAt'], '${entity.id}.sourceUpdatedAt');
      expectUtcDate(body['ingestedAt'], '${entity.id}.ingestedAt');
      expectString(body['licenseId'], '${entity.id}.licenseId');
      expectString(body['attribution'], '${entity.id}.attribution');
    }
    for (final entity in payload.dataSourceHealth) {
      final body = entity.body;
      expectEnum(
        body['health'],
        '${entity.id}.health',
        enumValues(SourceHealth.values),
      );
      expectUtcDate(body['lastAttemptAt'], '${entity.id}.lastAttemptAt');
      if (body['lastSuccessAt'] != null) {
        expectUtcDate(body['lastSuccessAt'], '${entity.id}.lastSuccessAt');
      }
    }
    for (final entity in payload.corroborations) {
      final body = entity.body;
      final incidentId = expectString(
        body['incidentId'],
        '${entity.id}.incidentId',
      );
      final actorId = expectString(body['actorId'], '${entity.id}.actorId');
      if (!incidentIds.contains(incidentId) || !accountIds.contains(actorId)) {
        fail(
          FailureCode.validation,
          'Corroboration referansı bozuk: ${entity.id}.',
        );
      }
      expectEnum(
        body['kind'],
        '${entity.id}.kind',
        enumValues(CorroborationKind.values),
      );
      expectUtcDate(body['createdAt'], '${entity.id}.createdAt');
    }
    for (final entity in payload.timeline) {
      final body = entity.body;
      final resourceId = expectString(
        body['resourceId'],
        '${entity.id}.resourceId',
      );
      if (!resourceIds.contains(resourceId)) {
        fail(
          FailureCode.validation,
          'Timeline referansı bozuk: ${entity.id}.',
        );
      }
      expectString(body['type'], '${entity.id}.type');
      expectUtcDate(body['at'], '${entity.id}.at');
      expectString(body['publicMessageKey'], '${entity.id}.publicMessageKey');
    }
    for (final entity in payload.notifications) {
      final body = entity.body;
      final recipientId = expectString(
        body['recipientId'],
        '${entity.id}.recipientId',
      );
      if (!accountIds.contains(recipientId)) {
        fail(
          FailureCode.validation,
          'Notification alıcısı bozuk: ${entity.id}.',
        );
      }
      expectString(body['eventId'], '${entity.id}.eventId');
      expectEnum(
        body['type'],
        '${entity.id}.type',
        enumValues(NotificationType.values),
      );
      expectString(body['route'], '${entity.id}.route');
      expectUtcDate(body['createdAt'], '${entity.id}.createdAt');
      if (body['readAt'] != null) {
        expectUtcDate(body['readAt'], '${entity.id}.readAt');
      }
    }
    for (final entity in payload.auditEvents) {
      final body = entity.body;
      expectString(body['actorId'], '${entity.id}.actorId');
      expectString(body['action'], '${entity.id}.action');
      expectString(body['resourceId'], '${entity.id}.resourceId');
      expectUtcDate(body['at'], '${entity.id}.at');
      expectString(body['reason'], '${entity.id}.reason');
      expectMap(body['before'], '${entity.id}.before');
      expectMap(body['after'], '${entity.id}.after');
    }
    for (final entity in payload.privacyRequests) {
      final body = entity.body;
      final ownerId = expectString(body['ownerId'], '${entity.id}.ownerId');
      if (!accountIds.contains(ownerId)) {
        fail(
          FailureCode.validation,
          'Privacy request sahibi bozuk: ${entity.id}.',
        );
      }
      expectString(body['trackingNumber'], '${entity.id}.trackingNumber');
      expectEnum(
        body['type'],
        '${entity.id}.type',
        enumValues(PrivacyRequestType.values),
      );
      expectEnum(
        body['status'],
        '${entity.id}.status',
        enumValues(PrivacyRequestStatus.values),
      );
      expectUtcDate(body['createdAt'], '${entity.id}.createdAt');
    }
    for (final entity in payload.restrictions) {
      final body = entity.body;
      final accountId = expectString(
        body['accountId'],
        '${entity.id}.accountId',
      );
      if (!accountIds.contains(accountId)) {
        fail(
          FailureCode.validation,
          'Restriction hesabı bozuk: ${entity.id}.',
        );
      }
      final level = expectEnum(
        body['level'],
        '${entity.id}.level',
        enumValues(RestrictionLevel.values),
      );
      expectString(body['reason'], '${entity.id}.reason');
      expectUtcDate(body['startsAt'], '${entity.id}.startsAt');
      final decidedBy = expectNullableString(
        body['decidedBy'],
        '${entity.id}.decidedBy',
      );
      if (level == RestrictionLevel.temporaryRestriction && decidedBy == null) {
        fail(
          FailureCode.validation,
          'Geçici restriction insan kararı ister.',
        );
      }
    }
    for (final entity in payload.demoScenarios) {
      final body = entity.body;
      expectString(body['aiMode'], '${entity.id}.aiMode');
      expectString(body['privacyMode'], '${entity.id}.privacyMode');
      expectString(body['connectivity'], '${entity.id}.connectivity');
    }
  }

  void _rejectForbiddenProfileFields(Object? value, String path) {
    if (value is Map<String, Object?>) {
      for (final entry in value.entries) {
        final normalized = entry.key.toLowerCase().replaceAll('_', '');
        if ({'citizentrustscore', 'citizentrustsignal', 'userscore'}.contains(
          normalized,
        )) {
          fail(
            FailureCode.validation,
            'Yasak kişi puanı alanı bulundu: $path.${entry.key}.',
          );
        }
        _rejectForbiddenProfileFields(entry.value, '$path.${entry.key}');
      }
    } else if (value is List<Object?>) {
      for (var index = 0; index < value.length; index++) {
        _rejectForbiddenProfileFields(value[index], '$path[$index]');
      }
    }
  }
}
