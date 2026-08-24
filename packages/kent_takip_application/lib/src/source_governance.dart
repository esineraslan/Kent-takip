import 'dart:convert';

import 'package:kent_takip_application/src/commands.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

/// WP-17 canonical adapter lifecycle: fetch -> decode -> validate -> normalize
/// -> freshness/provenance. Adapters never mutate snapshot directly.
abstract interface class SourceAdapter<T> {
  String get sourceId;
  String get sourceType;
  String get authorityId;
  String get licenseId;
  String get attribution;
  Duration get staleAfter;

  Future<T> fetch();
  List<JsonMap> decode(T raw);
  List<SourceValidationResult> validate(List<JsonMap> decoded);
  NormalizedSourceItem normalize(JsonMap valid, DateTime ingestedAt);
}

final class SourceValidationResult {
  const SourceValidationResult.valid(this.value)
      : errorCode = null,
        valid = true;
  const SourceValidationResult.invalid(this.value, this.errorCode)
      : valid = false;

  final JsonMap value;
  final String? errorCode;
  final bool valid;
}

final class NormalizedSourceItem {
  NormalizedSourceItem({
    required this.externalId,
    required this.sourceUpdatedAt,
    required this.ingestedAt,
    required JsonMap provenance,
    required JsonMap normalized,
  })  : provenance = deepFreezeJson(provenance, 'provenance') as JsonMap,
        normalized = deepFreezeJson(normalized, 'normalized') as JsonMap {
    requireText(externalId, 'externalId');
    requireUtc(sourceUpdatedAt, 'sourceUpdatedAt');
    requireUtc(ingestedAt, 'ingestedAt');
  }

  final String externalId;
  final DateTime sourceUpdatedAt;
  final DateTime ingestedAt;
  final JsonMap provenance;
  final JsonMap normalized;
}

/// Real-schema proof adapter. IETT publishes GTFS; this maps the standard
/// stops.txt schema (stop_id, stop_name, stop_lat, stop_lon) without making
/// runtime internet access a demo dependency.
final class IettGtfsStopsSchemaAdapter implements SourceAdapter<String> {
  IettGtfsStopsSchemaAdapter({required this.fixtureCsv});

  final String fixtureCsv;

  @override
  String get sourceId => 'transit_gtfs_schema';
  @override
  String get sourceType => 'csv_real_schema_fixture';
  @override
  String get authorityId => 'authority_ibb_open_data';
  @override
  String get licenseId => 'ibb-open-data-license';
  @override
  String get attribution => 'İBB / İETT GTFS şemasına dayalı demo fixture';
  @override
  Duration get staleAfter => const Duration(days: 30);

  @override
  Future<String> fetch() async => fixtureCsv;

  @override
  List<JsonMap> decode(String raw) {
    final lines = const LineSplitter().convert(raw).where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const [];
    final headers = _parseCsvLine(lines.first);
    return [
      for (final line in lines.skip(1))
        () {
          final values = _parseCsvLine(line);
          final row = <String, Object?>{};
          for (var index = 0; index < headers.length; index++) {
            row[headers[index]] = index < values.length ? values[index] : '';
          }
          return row;
        }(),
    ];
  }

  @override
  List<SourceValidationResult> validate(List<JsonMap> decoded) {
    return decoded.map((row) {
      final id = row['stop_id']?.toString().trim() ?? '';
      final name = row['stop_name']?.toString().trim() ?? '';
      final lat = double.tryParse(row['stop_lat']?.toString() ?? '');
      final lon = double.tryParse(row['stop_lon']?.toString() ?? '');
      if (id.isEmpty || name.isEmpty) {
        return SourceValidationResult.invalid(row, 'gtfs_missing_identity');
      }
      if (lat == null || lon == null || lat < 40.7 || lat > 41.6 || lon < 27.8 || lon > 30.0) {
        return SourceValidationResult.invalid(row, 'gtfs_invalid_coordinate');
      }
      return SourceValidationResult.valid(row);
    }).toList(growable: false);
  }

  @override
  NormalizedSourceItem normalize(JsonMap valid, DateTime ingestedAt) {
    final sourceTimestamp = DateTime.utc(2026, 8, 17, 8);
    return NormalizedSourceItem(
      externalId: valid['stop_id']! as String,
      sourceUpdatedAt: sourceTimestamp,
      ingestedAt: ingestedAt,
      provenance: {
        'schema': 'GTFS stops.txt',
        'mappingVersion': 1,
        'rawCoordinateSystem': 'EPSG:4326',
        'sourceDataset': 'IETT GTFS',
      },
      normalized: {
        'entityKind': 'transit_stop',
        'name': valid['stop_name'],
        'latitude': double.parse(valid['stop_lat']! as String),
        'longitude': double.parse(valid['stop_lon']! as String),
      },
    );
  }
}

final class FixtureSourceAdapter implements SourceAdapter<List<JsonMap>> {
  FixtureSourceAdapter({
    required this.sourceId,
    required this.sourceType,
    required this.authorityId,
    required this.licenseId,
    required this.attribution,
    required this.records,
    this.staleAfter = const Duration(hours: 2),
    this.failuresBeforeSuccess = 0,
  });

  @override
  final String sourceId;
  @override
  final String sourceType;
  @override
  final String authorityId;
  @override
  final String licenseId;
  @override
  final String attribution;
  final List<JsonMap> records;
  @override
  final Duration staleAfter;
  final int failuresBeforeSuccess;
  int _fetchAttempts = 0;

  @override
  Future<List<JsonMap>> fetch() async {
    _fetchAttempts += 1;
    if (_fetchAttempts <= failuresBeforeSuccess) {
      throw StateError('Deterministic demo source fetch failure $_fetchAttempts');
    }
    return records;
  }

  @override
  List<JsonMap> decode(List<JsonMap> raw) => raw;

  @override
  List<SourceValidationResult> validate(List<JsonMap> decoded) => decoded.map((row) {
        final externalId = row['externalId']?.toString().trim() ?? '';
        final updated = DateTime.tryParse(row['sourceUpdatedAt']?.toString() ?? '');
        final category = row['category']?.toString().trim() ?? '';
        if (externalId.isEmpty || updated == null || !updated.isUtc || category.isEmpty) {
          return SourceValidationResult.invalid(row, 'fixture_schema_invalid');
        }
        return SourceValidationResult.valid(row);
      }).toList(growable: false);

  @override
  NormalizedSourceItem normalize(JsonMap valid, DateTime ingestedAt) => NormalizedSourceItem(
        externalId: valid['externalId']! as String,
        sourceUpdatedAt: DateTime.parse(valid['sourceUpdatedAt']! as String),
        ingestedAt: ingestedAt,
        provenance: {
          'schema': 'kent_takip_fixture_v1',
          'mappingVersion': 1,
          'sourceType': sourceType,
        },
        normalized: Map<String, Object?>.from(valid)..remove('sourceUpdatedAt')..remove('externalId'),
      );
}

abstract final class SourceAuthorityPolicy {
  static int priority(SourceAuthorityRank rank) => switch (rank) {
        SourceAuthorityRank.owningAuthority => 600,
        SourceAuthorityRank.ibbApproved => 500,
        SourceAuthorityRank.licensedOpenData => 400,
        SourceAuthorityRank.thirdPartyUnverified => 300,
        SourceAuthorityRank.citizenSignal => 200,
        SourceAuthorityRank.aiSuggestion => 100,
      };

  static bool shouldReplace({
    required SourceAuthorityRank existingRank,
    required DateTime existingUpdatedAt,
    required SourceAuthorityRank incomingRank,
    required DateTime incomingUpdatedAt,
  }) {
    final authority = priority(incomingRank).compareTo(priority(existingRank));
    if (authority != 0) return authority > 0;
    return incomingUpdatedAt.isAfter(existingUpdatedAt);
  }
}

abstract final class SourceFixtureExport {
  static String toJson(Iterable<OpaqueEntityDto> records) =>
      const JsonEncoder.withIndent('  ').convert(records.map((item) => item.toJson()).toList(growable: false));

  static String toCsv(Iterable<OpaqueEntityDto> records) {
    final buffer = StringBuffer('id,sourceId,externalId,health,sourceUpdatedAt,ingestedAt,licenseId,attribution\n');
    for (final item in records) {
      final body = item.body;
      buffer.writeln([
        item.id,
        body['sourceId'],
        body['externalId'],
        body['health'],
        body['sourceUpdatedAt'],
        body['ingestedAt'],
        body['licenseId'],
        body['attribution'],
      ].map(_csvField).join(','));
    }
    return buffer.toString();
  }
}

enum SourceOperationAction {
  refreshGtfsSchema,
  refreshFixture,
  manualActiveIncident,
  manualPlannedWork,
  sync153Mock,
  importFixture,
  simulateOutage,
}

final class SourceOperationCommand {
  SourceOperationCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.action,
    required JsonMap payload,
  }) : payload = deepFreezeJson(payload, 'payload') as JsonMap {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    if (expectedRevision < 0) fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
  }

  factory SourceOperationCommand.fromJson(JsonMap json) => SourceOperationCommand(
        actorId: expectString(json['actorId'], 'actorId'),
        clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
        expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
        action: expectEnum(json['action'], 'action', enumValues(SourceOperationAction.values)),
        payload: expectMap(json['payload'] ?? const <String, Object?>{}, 'payload'),
      );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final SourceOperationAction action;
  final JsonMap payload;

  JsonMap toJson() => {
        'actorId': actorId,
        'clientMutationId': clientMutationId,
        'expectedRevision': expectedRevision,
        'action': enumWire(action),
        'payload': payload,
      };
}

final class SourceCatalogEntry {
  const SourceCatalogEntry({
    required this.id,
    required this.label,
    required this.kind,
    required this.integrationLabel,
    required this.enabled,
  });
  final String id;
  final String label;
  final String kind;
  final String integrationLabel;
  final bool enabled;
}

abstract final class SourceCatalog {
  static const entries = <SourceCatalogEntry>[
    SourceCatalogEntry(id: 'water_events_fixture', label: 'Su olayları', kind: 'Fixture', integrationLabel: 'Deterministik demo fixture', enabled: true),
    SourceCatalogEntry(id: 'traffic_events_fixture', label: 'Trafik olayları', kind: 'Fixture', integrationLabel: 'Deterministik demo fixture', enabled: true),
    SourceCatalogEntry(id: 'transit_events_fixture', label: 'Toplu ulaşım', kind: 'Fixture', integrationLabel: 'Deterministik demo fixture', enabled: true),
    SourceCatalogEntry(id: 'planned_works_fixture', label: 'Planlı çalışmalar', kind: 'Fixture', integrationLabel: 'Deterministik demo fixture', enabled: true),
    SourceCatalogEntry(id: 'disaster_alerts_fixture', label: 'Resmî uyarı örneği', kind: 'Fixture', integrationLabel: 'Yetkili kaynak simülasyonu · salt okunur', enabled: true),
    SourceCatalogEntry(id: 'transit_gtfs_schema', label: 'İETT GTFS şema kanıtı', kind: 'CSV', integrationLabel: 'Gerçek şemaya dayalı fixture · canlı entegrasyon değil', enabled: true),
    SourceCatalogEntry(id: 'external_153_mock', label: '153 / İstanbul Senin', kind: 'Contract mock', integrationLabel: 'Simüle sözleşme · gerçek 153 yazımı yok', enabled: true),
    SourceCatalogEntry(id: 'electricity_events', label: 'Elektrik kesintileri', kind: 'Disabled', integrationLabel: 'Yetkili kaynak bulunana kadar MVP filtresi kapalı', enabled: false),
  ];
}

final class SourceGovernanceProcessor {
  SourceGovernanceProcessor({required this.processor});
  final SnapshotCommandProcessor processor;

  Future<MutationResult> execute(SourceOperationCommand command) {
    return processor.transactionQueue.run(() async {
      final current = await processor.store.read();
      _requireRevision(command.expectedRevision, current);
      final actor = _actor(current, command.actorId);
      AuthorizationPolicy.requirePermission(actor, Permission.manageSources);
      final now = processor.clock.nowUtc();
      return switch (command.action) {
        SourceOperationAction.refreshGtfsSchema => _refreshGtfs(current, command, now),
        SourceOperationAction.refreshFixture => _refreshFixture(current, command, now),
        SourceOperationAction.manualActiveIncident => _manualIncident(current, command, now),
        SourceOperationAction.manualPlannedWork => _manualWork(current, command, now),
        SourceOperationAction.sync153Mock => _sync153(current, command, now),
        SourceOperationAction.importFixture => _importFixture(current, command, now),
        SourceOperationAction.simulateOutage => _simulateOutage(current, command, now),
      };
    });
  }

  Future<MutationResult> _simulateOutage(AppSnapshotDto current, SourceOperationCommand command, DateTime now) async {
    final sourceId = expectString(command.payload['sourceId'], 'payload.sourceId');
    final known = SourceCatalog.entries.any((entry) => entry.id == sourceId && entry.enabled);
    if (!known) fail(FailureCode.notFound, 'Demo kesintisi için bilinmeyen veya kapalı kaynak.');
    final payload = _withHealth(
      current,
      sourceId,
      SourceHealth.unavailable,
      now,
      lastSuccessAt: _lastSuccess(current, sourceId),
      lastErrorCode: 'demo_forced_outage',
      received: 0,
      accepted: 0,
      quarantined: 0,
      durationMs: 0,
      attempts: 0,
    );
    return _commit(
      current,
      payload,
      command,
      now,
      sourceId,
      'source_demo_outage_enabled',
      'Jüri provası için kontrollü kaynak kesintisi; son geçerli cache korunur.',
      extraAfter: const {'staleCacheRetained': true, 'demoOnly': true},
    );
  }

  Future<MutationResult> _refreshGtfs(AppSnapshotDto current, SourceOperationCommand command, DateTime now) async {
    final csv = command.payload['csv']?.toString() ?? _defaultGtfsFixture;
    final adapter = IettGtfsStopsSchemaAdapter(fixtureCsv: csv);
    return _runAdapter(current, command, adapter, now);
  }

  Future<MutationResult> _refreshFixture(AppSnapshotDto current, SourceOperationCommand command, DateTime now) async {
    final sourceId = expectString(command.payload['sourceId'], 'payload.sourceId');
    final failuresBeforeSuccess = command.payload['simulateTransientFailures'] == null
        ? 0
        : expectInt(command.payload['simulateTransientFailures'], 'payload.simulateTransientFailures');
    if (failuresBeforeSuccess < 0 || failuresBeforeSuccess > 3) {
      fail(FailureCode.validation, 'simulateTransientFailures 0–3 aralığında olmalıdır.');
    }
    final adapter = _fixtureAdapter(sourceId, now, failuresBeforeSuccess: failuresBeforeSuccess);
    if (adapter == null) fail(FailureCode.notFound, 'Bilinmeyen fixture kaynağı.');
    return _runAdapter(current, command, adapter, now);
  }

  Future<MutationResult> _runAdapter<T>(
    AppSnapshotDto current,
    SourceOperationCommand command,
    SourceAdapter<T> adapter,
    DateTime now,
  ) async {
    final started = DateTime.now().microsecondsSinceEpoch;
    if (_circuitBlocked(current, adapter.sourceId, now)) {
      return _commit(
        current,
        current.payload,
        command,
        now,
        adapter.sourceId,
        'source_circuit_open_skipped',
        'Circuit breaker açık; son geçerli cache korunuyor.',
        extraAfter: {'circuitState': 'open', 'staleCacheRetained': true},
      );
    }
    T? raw;
    Object? lastError;
    var attempts = 0;
    for (var index = 0; index < 3; index++) {
      attempts += 1;
      try {
        raw = await adapter.fetch();
        lastError = null;
        break;
      } on Object catch (error) {
        lastError = error;
        if (index < 2) {
          await Future<void>.delayed(_retryDelay(adapter.sourceId, index + 1));
        }
      }
    }
    if (raw == null) {
      final durationMs = ((DateTime.now().microsecondsSinceEpoch - started) / 1000).round();
      final next = _withHealth(
        current,
        adapter.sourceId,
        SourceHealth.unavailable,
        now,
        lastSuccessAt: _lastSuccess(current, adapter.sourceId),
        lastErrorCode: 'source_fetch_failed',
        received: 0,
        accepted: 0,
        quarantined: 0,
        durationMs: durationMs,
        attempts: attempts,
      );
      return _commit(current, next, command, now, adapter.sourceId, 'source_refresh_failed', 'Kaynak yenileme başarısız; son geçerli cache korunuyor.', extraAfter: {'error': lastError.runtimeType.toString()});
    }
    final decoded = adapter.decode(raw as T);
    final validations = adapter.validate(decoded);
    final accepted = <NormalizedSourceItem>[];
    final quarantined = <OpaqueEntityDto>[];
    for (final validation in validations) {
      if (!validation.valid) {
        final id = 'src_quarantine_${adapter.sourceId}_${quarantined.length + 1}_${current.revision + 1}';
        quarantined.add(OpaqueEntityDto(id: id, body: {
          'id': id,
          'sourceId': adapter.sourceId,
          'externalId': 'quarantine_${quarantined.length + 1}',
          'authorityId': adapter.authorityId,
          'health': enumWire(SourceHealth.quarantined),
          'sourceUpdatedAt': now.toIso8601String(),
          'ingestedAt': now.toIso8601String(),
          'licenseId': adapter.licenseId,
          'attribution': adapter.attribution,
          'quarantineReason': validation.errorCode,
          'rawFieldNames': validation.value.keys.toList(growable: false),
        }));
      } else {
        accepted.add(adapter.normalize(validation.value, now));
      }
    }
    final authority = _authorityFor(adapter, current);
    final incoming = accepted.map((item) {
      final id = 'src_${adapter.sourceId}_${_safeId(item.externalId)}';
      return OpaqueEntityDto(id: id, body: {
        'id': id,
        'sourceId': adapter.sourceId,
        'sourceType': adapter.sourceType,
        'externalId': item.externalId,
        'authorityId': adapter.authorityId,
        'health': enumWire(SourceHealth.fresh),
        'sourceUpdatedAt': item.sourceUpdatedAt.toIso8601String(),
        'ingestedAt': item.ingestedAt.toIso8601String(),
        'licenseId': adapter.licenseId,
        'attribution': adapter.attribution,
        'provenance': item.provenance,
        'normalized': item.normalized,
        ...item.normalized,
      });
    }).toList(growable: false);
    final byExternalKey = <String, OpaqueEntityDto>{};
    for (final item in current.payload.sourceRecords) {
      final key = '${item.body['sourceId']}|${item.body['externalId']}';
      byExternalKey[key] = item;
    }
    for (final item in incoming) {
      final key = '${item.body['sourceId']}|${item.body['externalId']}';
      final existing = byExternalKey[key];
      if (existing == null || _sourceAt(item).isAfter(_sourceAt(existing))) {
        byExternalKey[key] = item;
      }
    }
    for (final item in quarantined) {
      byExternalKey['${item.body['sourceId']}|${item.body['externalId']}'] = item;
    }
    final durationMs = ((DateTime.now().microsecondsSinceEpoch - started) / 1000).round();
    var payload = current.payload.copyWith(
      sourceAuthorities: authority == null ? current.payload.sourceAuthorities : [...current.payload.sourceAuthorities, authority],
      sourceRecords: byExternalKey.values,
    );
    final newestSourceTimestamp = accepted.isEmpty
        ? null
        : accepted.map((e) => e.sourceUpdatedAt).reduce((a, b) => a.isAfter(b) ? a : b);
    final resolvedHealth = accepted.isEmpty && quarantined.isNotEmpty
        ? SourceHealth.quarantined
        : newestSourceTimestamp != null && now.difference(newestSourceTimestamp) > adapter.staleAfter
            ? SourceHealth.stale
            : SourceHealth.fresh;
    payload = _withHealth(
      current.copyWith(payload: payload),
      adapter.sourceId,
      resolvedHealth,
      now,
      lastSuccessAt: now,
      sourceTimestamp: newestSourceTimestamp,
      received: decoded.length,
      accepted: accepted.length,
      quarantined: quarantined.length,
      durationMs: durationMs,
      attempts: attempts,
    );
    return _commit(current, payload, command, now, adapter.sourceId, 'source_refreshed', 'Kaynak adaptörü doğrulandı ve normalize edildi.', extraAfter: {
      'received': decoded.length,
      'accepted': accepted.length,
      'quarantined': quarantined.length,
      'sourceType': adapter.sourceType,
      'health': enumWire(resolvedHealth),
    });
  }

  Future<MutationResult> _manualIncident(AppSnapshotDto current, SourceOperationCommand command, DateTime now) async {
    final category = expectString(command.payload['category'], 'payload.category');
    final unitId = expectString(command.payload['unitId'], 'payload.unitId');
    final reason = expectString(command.payload['reason'], 'payload.reason');
    final lat = _number(command.payload['latitude'], 'payload.latitude');
    final lon = _number(command.payload['longitude'], 'payload.longitude');
    GeoPoint(latitude: lat, longitude: lon);
    final authority = _manualAuthority(current);
    final ordinal = current.revision + 1;
    final sourceId = 'src_manual_${ordinal.toString().padLeft(6, '0')}';
    final record = OpaqueEntityDto(id: sourceId, body: {
      'id': sourceId,
      'sourceId': 'municipal_authorized_entry',
      'sourceType': 'manual_authorized',
      'externalId': sourceId,
      'authorityId': 'authority_municipal_authorized',
      'health': enumWire(SourceHealth.fresh),
      'sourceUpdatedAt': now.toIso8601String(),
      'ingestedAt': now.toIso8601String(),
      'licenseId': 'internal-authorized-entry',
      'attribution': 'Yetkili belediye personeli manuel girişi',
      'provenance': {'actorId': command.actorId, 'reason': reason},
    });
    final incidentId = 'inc_manual_${ordinal.toString().padLeft(6, '0')}';
    final incident = UrbanIncidentDto(
      id: incidentId,
      status: IncidentStatus.verifiedActive,
      category: category,
      latitude: lat,
      longitude: lon,
      reportIds: const [],
      sourceRecordIds: [sourceId],
      workOrderRefs: const [],
      createdAt: now,
      updatedAt: now,
      responsibleUnitId: unitId,
    );
    final payload = current.payload.copyWith(
      sourceAuthorities: authority == null ? current.payload.sourceAuthorities : [...current.payload.sourceAuthorities, authority],
      sourceRecords: [...current.payload.sourceRecords, record],
      incidents: [...current.payload.incidents, incident],
    );
    return _commit(current, payload, command, now, incidentId, 'manual_incident_created', reason, extraAfter: {'provenance': 'municipal_authorized_entry'});
  }

  Future<MutationResult> _manualWork(AppSnapshotDto current, SourceOperationCommand command, DateTime now) async {
    final category = expectString(command.payload['category'], 'payload.category');
    final unitId = expectString(command.payload['unitId'], 'payload.unitId');
    final explanation = expectString(command.payload['explanation'], 'payload.explanation');
    final reason = expectString(command.payload['reason'], 'payload.reason');
    final startsAt = expectUtcDate(command.payload['startsAt'], 'payload.startsAt');
    final expectedEndsAt = expectUtcDate(command.payload['expectedEndsAt'], 'payload.expectedEndsAt');
    final lat = _number(command.payload['latitude'], 'payload.latitude');
    final lon = _number(command.payload['longitude'], 'payload.longitude');
    GeoPoint(latitude: lat, longitude: lon);
    if (!expectedEndsAt.isAfter(startsAt)) {
      fail(FailureCode.validation, 'Planlı çalışma bitişi başlangıçtan sonra olmalıdır.');
    }
    final ordinal = current.revision + 1;
    final workId = 'work_manual_${ordinal.toString().padLeft(6, '0')}';
    final work = MunicipalWorkDto(
      id: workId,
      status: WorkStatus.publishedPlanned,
      category: category,
      latitude: lat,
      longitude: lon,
      startsAt: startsAt,
      expectedEndsAt: expectedEndsAt,
      responsibleUnitId: unitId,
      explanation: explanation,
      areaRadiusMeters: 120,
      publicInformationText: explanation,
      publicPreviewApproved: true,
      createdBy: command.actorId,
      createdAt: now,
      updatedAt: now,
      publishedAt: now,
    );
    final auditSource = OpaqueEntityDto(id: 'src_$workId', body: {
      'id': 'src_$workId',
      'sourceId': 'municipal_authorized_entry',
      'sourceType': 'manual_authorized',
      'externalId': workId,
      'authorityId': 'authority_municipal_authorized',
      'health': enumWire(SourceHealth.fresh),
      'sourceUpdatedAt': now.toIso8601String(),
      'ingestedAt': now.toIso8601String(),
      'licenseId': 'internal-authorized-entry',
      'attribution': 'Yetkili belediye personeli manuel girişi',
      'provenance': {'actorId': command.actorId, 'reason': reason},
    });
    final authority = _manualAuthority(current);
    final payload = current.payload.copyWith(
      sourceAuthorities: authority == null ? current.payload.sourceAuthorities : [...current.payload.sourceAuthorities, authority],
      sourceRecords: [...current.payload.sourceRecords, auditSource],
      municipalWorks: [...current.payload.municipalWorks, work],
    );
    return _commit(current, payload, command, now, workId, 'manual_work_created', reason, extraAfter: {'provenance': 'municipal_authorized_entry'});
  }

  Future<MutationResult> _sync153(AppSnapshotDto current, SourceOperationCommand command, DateTime now) async {
    final externalApplicationId = expectString(command.payload['externalApplicationId'], 'payload.externalApplicationId');
    final statusSync = expectString(command.payload['statusSync'], 'payload.statusSync');
    final linkedReportId = expectNullableString(command.payload['linkedReportId'], 'payload.linkedReportId');
    final linkedIncidentId = expectNullableString(command.payload['linkedIncidentId'], 'payload.linkedIncidentId');
    if (linkedReportId == null && linkedIncidentId == null) {
      fail(FailureCode.validation, '153 mock en az bir Kent Takip kaydına bağlanmalıdır.');
    }
    if (linkedReportId != null && !current.payload.reports.any((e) => e.id == linkedReportId)) {
      fail(FailureCode.notFound, '153 mock report bağlantısı bulunamadı.');
    }
    if (linkedIncidentId != null && !current.payload.incidents.any((e) => e.id == linkedIncidentId)) {
      fail(FailureCode.notFound, '153 mock incident bağlantısı bulunamadı.');
    }
    final authority = _external153Authority(current);
    final id = 'src_153_${_safeId(externalApplicationId)}';
    final record = OpaqueEntityDto(id: id, body: {
      'id': id,
      'sourceId': 'external_153_mock',
      'sourceType': 'contract_mock',
      'externalId': externalApplicationId,
      'authorityId': 'authority_153_contract_mock',
      'health': enumWire(SourceHealth.fresh),
      'sourceUpdatedAt': now.toIso8601String(),
      'ingestedAt': now.toIso8601String(),
      'licenseId': 'internal-contract-mock',
      'attribution': '153 / İstanbul Senin simüle sözleşme',
      'integrationMode': 'simulated_contract',
      'externalApplicationId': externalApplicationId,
      'statusSync': statusSync,
      'sourceTimestamp': now.toIso8601String(),
      'linkedReportId': linkedReportId,
      'linkedIncidentId': linkedIncidentId,
      'syncError': command.payload['syncError'],
    });
    final records = [for (final item in current.payload.sourceRecords) if (item.id != id) item, record];
    final payload = current.payload.copyWith(
      sourceAuthorities: authority == null ? current.payload.sourceAuthorities : [...current.payload.sourceAuthorities, authority],
      sourceRecords: records,
    );
    return _commit(current, payload, command, now, id, 'external_153_mock_synced', '153/İstanbul Senin gerçek erişim gerektirmeyen sözleşme simülasyonu.', extraAfter: {'integrationMode': 'simulated_contract', 'statusSync': statusSync});
  }

  Future<MutationResult> _importFixture(AppSnapshotDto current, SourceOperationCommand command, DateTime now) async {
    final format = expectString(command.payload['format'], 'payload.format').toLowerCase();
    final content = expectString(command.payload['content'], 'payload.content');
    List<JsonMap> rows;
    if (format == 'json') {
      final decoded = jsonDecode(content);
      final list = decoded is List ? decoded : null;
      if (list == null) fail(FailureCode.validation, 'JSON fixture dizi olmalıdır.');
      rows = [for (final item in list) expectMap(item, 'fixture.item')];
    } else if (format == 'csv') {
      final lines = const LineSplitter().convert(content).where((e) => e.trim().isNotEmpty).toList();
      if (lines.length < 2) fail(FailureCode.validation, 'CSV fixture başlık ve kayıt içermelidir.');
      final headers = _parseCsvLine(lines.first);
      rows = [
        for (final line in lines.skip(1))
          () {
            final values = _parseCsvLine(line);
            return <String, Object?>{for (var i = 0; i < headers.length; i++) headers[i]: i < values.length ? values[i] : ''};
          }(),
      ];
    } else {
      fail(FailureCode.validation, 'Yalnız JSON/CSV fixture import edilir.');
    }
    const reserved = <String>{
      'role', 'roles', 'permissions', 'permission', 'audit', 'auditevents',
      'accounts', 'accountid', 'actorid', 'ownerid', 'session', 'token',
      'password', 'otp', 'mfa', 'originalref', 'deletionrequested',
      'restrictions', 'privacyrequests', 'schemaversion', 'revision', 'checksum',
    };
    for (var index = 0; index < rows.length; index++) {
      final forbidden = _reservedFixtureKeys(rows[index], reserved);
      if (forbidden.isNotEmpty) {
        fail(
          FailureCode.unauthorized,
          'Fixture importu ayrılmış yönetim/yetki alanlarını içeremez: ${forbidden.join(', ')}',
          field: 'fixture[$index]',
        );
      }
    }
    final adapter = FixtureSourceAdapter(
      sourceId: 'staff_import_fixture',
      sourceType: format,
      authorityId: 'authority_demo_ibb',
      licenseId: 'internal-synthetic',
      attribution: 'Yetkili personel doğrulanmış sentetik fixture importu',
      records: rows,
    );
    return _runAdapter(current, command, adapter, now);
  }

  List<String> _reservedFixtureKeys(
    Object? value,
    Set<String> reserved, [
    String path = r'$'
  ]) {
    final hits = <String>[];
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final nextPath = '$path.$key';
        if (reserved.contains(key.toLowerCase())) hits.add(nextPath);
        hits.addAll(_reservedFixtureKeys(entry.value, reserved, nextPath));
      }
    } else if (value is Iterable) {
      var index = 0;
      for (final item in value) {
        hits.addAll(_reservedFixtureKeys(item, reserved, '$path[$index]'));
        index += 1;
      }
    }
    return hits.toSet().toList(growable: false)..sort();
  }

  SnapshotPayloadDto _withHealth(
    AppSnapshotDto snapshot,
    String sourceId,
    SourceHealth health,
    DateTime now, {
    DateTime? lastSuccessAt,
    DateTime? sourceTimestamp,
    String? lastErrorCode,
    int received = 0,
    int accepted = 0,
    int quarantined = 0,
    int durationMs = 0,
    int attempts = 1,
  }) {
    final id = 'health_$sourceId';
    final entry = OpaqueEntityDto(id: id, body: {
      'id': id,
      'sourceId': sourceId,
      'health': enumWire(health),
      'lastAttemptAt': now.toIso8601String(),
      'lastSuccessAt': lastSuccessAt?.toIso8601String(),
      'sourceTimestamp': sourceTimestamp?.toIso8601String(),
      'durationMs': durationMs,
      'receivedCount': received,
      'acceptedCount': accepted,
      'quarantinedCount': quarantined,
      'lastErrorCode': lastErrorCode,
      'attemptCount': attempts,
      'retryPolicy': 'max3_exponential_backoff_with_jitter_contract',
      'circuitState': health == SourceHealth.unavailable ? 'open' : 'closed',
      'circuitOpenedAt': health == SourceHealth.unavailable ? now.toIso8601String() : null,
      'nextRetryAt': health == SourceHealth.unavailable ? now.add(const Duration(minutes: 2)).toIso8601String() : null,
      'staleCacheRetained': health != SourceHealth.fresh,
    });
    return snapshot.payload.copyWith(
      dataSourceHealth: [for (final item in snapshot.payload.dataSourceHealth) if (item.id != id && item.body['sourceId'] != sourceId) item, entry],
    );
  }

  DateTime? _lastSuccess(AppSnapshotDto snapshot, String sourceId) {
    for (final item in snapshot.payload.dataSourceHealth.reversed) {
      if (item.body['sourceId'] == sourceId && item.body['lastSuccessAt'] is String) {
        return DateTime.tryParse(item.body['lastSuccessAt']! as String);
      }
    }
    return null;
  }

  Future<MutationResult> _commit(
    AppSnapshotDto current,
    SnapshotPayloadDto payload,
    SourceOperationCommand command,
    DateTime now,
    String resourceId,
    String action,
    String reason, {
    JsonMap extraAfter = const {},
  }) async {
    final auditId = 'audit_${action}_${current.revision + 1}_${now.microsecondsSinceEpoch}';
    final audit = OpaqueEntityDto(id: auditId, body: {
      'id': auditId,
      'actorId': command.actorId,
      'action': action,
      'resourceId': resourceId,
      'at': now.toIso8601String(),
      'reason': reason,
      'before': const <String, Object?>{},
      'after': {'clientMutationId': command.clientMutationId, 'activeRoleContext': _actor(current, command.actorId).role.name, ...extraAfter},
    });
    final next = processor.codec.seal(current.copyWith(
      revision: current.revision + 1,
      updatedAt: now,
      checksum: 'sha256:unsealed',
      payload: payload.copyWith(auditEvents: [...payload.auditEvents, audit]),
    ));
    final committed = await processor.store.write(next);
    return MutationResult(snapshot: committed, resourceId: resourceId, trackingNumber: null, replayed: false);
  }

  OpaqueEntityDto? _authorityFor<T>(SourceAdapter<T> adapter, AppSnapshotDto current) {
    if (current.payload.sourceAuthorities.any((e) => e.id == adapter.authorityId)) return null;
    return OpaqueEntityDto(id: adapter.authorityId, body: {
      'id': adapter.authorityId,
      'displayName': adapter.authorityId == 'authority_ibb_open_data' ? 'İBB / İETT Açık Veri' : 'Kent Takip kaynak otoritesi',
      'rank': enumWire(SourceAuthorityRank.ibbApproved),
      'officialAlertAuthority': false,
    });
  }

  OpaqueEntityDto? _manualAuthority(AppSnapshotDto current) {
    if (current.payload.sourceAuthorities.any((e) => e.id == 'authority_municipal_authorized')) return null;
    return OpaqueEntityDto(id: 'authority_municipal_authorized', body: {
      'id': 'authority_municipal_authorized',
      'displayName': 'Yetkili belediye manuel girişi',
      'rank': enumWire(SourceAuthorityRank.owningAuthority),
      'officialAlertAuthority': false,
    });
  }

  OpaqueEntityDto? _external153Authority(AppSnapshotDto current) {
    if (current.payload.sourceAuthorities.any((e) => e.id == 'authority_153_contract_mock')) return null;
    return OpaqueEntityDto(id: 'authority_153_contract_mock', body: {
      'id': 'authority_153_contract_mock',
      'displayName': '153 / İstanbul Senin sözleşme simülasyonu',
      'rank': enumWire(SourceAuthorityRank.thirdPartyUnverified),
      'officialAlertAuthority': false,
    });
  }
}

FixtureSourceAdapter? _fixtureAdapter(String sourceId, DateTime now, {int failuresBeforeSuccess = 0}) {
  final timestamp = now.subtract(const Duration(minutes: 6)).toIso8601String();
  final records = switch (sourceId) {
    'water_events_fixture' => [<String, Object?>{'externalId': 'water-demo-refresh', 'sourceUpdatedAt': timestamp, 'category': 'water_infrastructure', 'label': 'İSKİ su olayı demo fixture'}],
    'traffic_events_fixture' => [<String, Object?>{'externalId': 'traffic-demo-refresh', 'sourceUpdatedAt': timestamp, 'category': 'traffic', 'label': 'Trafik olayı demo fixture'}],
    'transit_events_fixture' => [<String, Object?>{'externalId': 'transit-demo-refresh', 'sourceUpdatedAt': timestamp, 'category': 'transit', 'label': 'Toplu ulaşım demo fixture'}],
    'planned_works_fixture' => [<String, Object?>{'externalId': 'planned-demo-refresh', 'sourceUpdatedAt': timestamp, 'category': 'planned_work', 'label': 'Planlı çalışma demo fixture'}],
    'disaster_alerts_fixture' => [<String, Object?>{'externalId': 'alert-demo-refresh', 'sourceUpdatedAt': timestamp, 'category': 'official_alert', 'label': 'Salt okunur yetkili uyarı demo fixture'}],
    _ => null,
  };
  if (records == null) return null;
  return FixtureSourceAdapter(
    sourceId: sourceId,
    sourceType: 'deterministic_fixture',
    authorityId: 'authority_demo_ibb',
    licenseId: 'internal-synthetic',
    attribution: 'Sentetik Kent Takip demo fixture',
    records: records,
    failuresBeforeSuccess: failuresBeforeSuccess,
  );
}

UserAccount _actor(AppSnapshotDto snapshot, String id) {
  for (final dto in snapshot.payload.accounts) {
    if (dto.id == id) {
      return UserAccount(id: dto.id, role: dto.role, permissions: dto.permissions, unitId: dto.unitId, deletionRequested: dto.deletionRequested);
    }
  }
  fail(FailureCode.unauthorized, 'Demo hesabı bulunamadı.');
}

void _requireRevision(int expected, AppSnapshotDto current) {
  if (expected != current.revision) throw CommandConflict(expectedRevision: expected, current: current);
}

bool _circuitBlocked(AppSnapshotDto snapshot, String sourceId, DateTime now) {
  for (final item in snapshot.payload.dataSourceHealth.reversed) {
    if (item.body['sourceId'] != sourceId) continue;
    if (item.body['circuitState'] != 'open') return false;
    final nextRetry = DateTime.tryParse(item.body['nextRetryAt']?.toString() ?? '');
    return nextRetry != null && now.isBefore(nextRetry);
  }
  return false;
}

Duration _retryDelay(String sourceId, int attempt) {
  final baseMs = 120 * (1 << (attempt - 1));
  final jitter = sourceId.codeUnits.fold<int>(0, (sum, value) => sum + value) % 73;
  return Duration(milliseconds: baseMs + jitter);
}

double _number(Object? value, String field) {
  if (value is! num) fail(FailureCode.validation, '$field sayı olmalıdır.', field: field);
  return value.toDouble();
}

DateTime _sourceAt(OpaqueEntityDto item) => DateTime.tryParse(item.body['sourceUpdatedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
String _safeId(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

List<String> _parseCsvLine(String line) {
  final values = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    if (char == '"') {
      if (quoted && index + 1 < line.length && line[index + 1] == '"') {
        buffer.write('"');
        index += 1;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      values.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  values.add(buffer.toString().trim());
  return values;
}

String _csvField(Object? value) {
  final text = value?.toString() ?? '';
  return '"' + text.replaceAll('"', '""') + '"';
}

const _defaultGtfsFixture = '''stop_id,stop_name,stop_lat,stop_lon
IETT_DEMO_001,"Kadıköy Demo Durağı",40.9902,29.0231
IETT_DEMO_002,"Üsküdar Demo Durağı",41.0262,29.0150
BROKEN_STOP,"Karantina örneği",999,999
''';
