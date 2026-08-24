import 'dart:io';

import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:test/test.dart';

void main() {
  late SnapshotCodec codec;
  late AppSnapshotDto seed;
  const clock = _FixedClock();

  setUp(() async {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.decode(
      await File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json').readAsString(),
    );
  });

  test('WP-21 map projection aynı revision/work-clock için memoized kalır', () {
    final service = MemoizedMapProjectionService();
    final first = service.project(
      seed,
      staff: true,
      nowUtc: DateTime.utc(2026, 8, 17, 16),
    );
    final second = service.project(
      seed,
      staff: true,
      nowUtc: DateTime.utc(2026, 8, 17, 16, 1),
    );
    expect(identical(first, second), isTrue);
    final afterWorkStart = service.project(
      seed,
      staff: true,
      nowUtc: DateTime.utc(2026, 8, 18, 7),
    );
    expect(identical(first, afterWorkStart), isFalse);
  });

  test('E2E-23 UrbanIncident çoklu report ve source sinyalini tek public olaya projekte eder', () {
    final first = seed.payload.reports.single;
    final second = CitizenReportDto(
      id: 'rpt_e2e_23_02',
      trackingNumber: 'KT-2026-230002',
      ownerId: 'usr_citizen_demo_002',
      status: ReportStatus.assignedUnit,
      category: 'road_surface_damage',
      latitude: first.latitude,
      longitude: first.longitude,
      createdAt: DateTime.utc(2026, 8, 17, 8),
      updatedAt: DateTime.utc(2026, 8, 17, 8, 5),
      clientMutationId: 'e2e23_report_02',
      mediaIds: const [],
      linkedIncidentId: 'inc_e2e_23',
      manualReviewRequired: false,
      riskLevel: RiskLevel.medium,
    );
    final linkedFirst = CitizenReportDto.fromObject(
      {...first.toJson(), 'status': 'assigned_unit', 'linkedIncidentId': 'inc_e2e_23'},
      'report',
    );
    final sourceA = OpaqueEntityDto(
      id: 'src_e2e_23_a',
      body: {
        'id': 'src_e2e_23_a',
        'sourceId': 'water_events_fixture',
        'externalId': 'e2e-23-a',
        'authorityId': 'authority_demo_ibb',
        'health': 'fresh',
        'sourceUpdatedAt': '2026-08-17T08:00:00.000Z',
        'ingestedAt': '2026-08-17T08:01:00.000Z',
        'licenseId': 'internal-synthetic',
        'attribution': 'Yetkili kaynak A',
      },
    );
    final sourceB = OpaqueEntityDto(
      id: 'src_e2e_23_b',
      body: {
        'id': 'src_e2e_23_b',
        'sourceId': 'traffic_events_fixture',
        'externalId': 'e2e-23-b',
        'authorityId': 'authority_demo_ibb',
        'health': 'stale',
        'sourceUpdatedAt': '2026-08-17T07:00:00.000Z',
        'ingestedAt': '2026-08-17T07:01:00.000Z',
        'licenseId': 'internal-synthetic',
        'attribution': 'Yetkili kaynak B',
      },
    );
    final incident = UrbanIncidentDto(
      id: 'inc_e2e_23',
      status: IncidentStatus.verifiedActive,
      category: 'road_surface_damage',
      latitude: first.latitude,
      longitude: first.longitude,
      reportIds: [linkedFirst.id, second.id],
      sourceRecordIds: [sourceA.id, sourceB.id],
      createdAt: DateTime.utc(2026, 8, 17, 8),
      updatedAt: DateTime.utc(2026, 8, 17, 8, 5),
      responsibleUnitId: 'unit_road_maintenance',
    );
    final snapshot = seed.copyWith(
      revision: seed.revision + 1,
      payload: seed.payload.copyWith(
        reports: [linkedFirst, second],
        incidents: [incident],
        sourceRecords: [sourceA, sourceB],
      ),
    );

    final pins = DemoProjections.visiblePins(snapshot, staff: false);
    expect(pins.where((pin) => pin.id == incident.id), hasLength(1));
    expect(pins.where((pin) => pin.id == linkedFirst.id || pin.id == second.id), isEmpty);
    final pin = pins.singleWhere((item) => item.id == incident.id);
    expect(pin.sourceLabel, 'Yetkili kaynak A');
    expect(pin.freshness, SourceHealth.stale);
  });

  test('E2E-24 153 mock sync external referansı provenance ile ve simüle olarak tutar', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SourceGovernanceProcessor(
      processor: SnapshotCommandProcessor(store: store, codec: codec, clock: clock),
    );
    final result = await processor.execute(
      SourceOperationCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'e2e24_sync_153',
        expectedRevision: seed.revision,
        action: SourceOperationAction.sync153Mock,
        payload: const {
          'externalApplicationId': '153-E2E-24',
          'statusSync': 'received_simulated',
          'linkedReportId': 'rpt_demo_0001',
        },
      ),
    );
    final record = result.snapshot.payload.sourceRecords.lastWhere(
      (item) => item.body['sourceId'] == 'external_153_mock',
    );
    expect(record.body['integrationMode'], 'simulated_contract');
    expect(record.body['externalApplicationId'], '153-E2E-24');
    expect(record.body['linkedReportId'], 'rpt_demo_0001');
  });

  test('E2E-25 structured corroboration değişmez olay stateine ayrı sinyal ekler', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final result = await processor.citizenAction(
      CitizenActionCommand(
        actorId: 'usr_citizen_demo_001',
        clientMutationId: 'e2e25_corroboration',
        expectedRevision: seed.revision,
        kind: CitizenActionKind.corroborate,
        resourceId: 'inc_demo_0001',
        payload: const {'kind': 'still_present'},
      ),
    );
    final signal = result.snapshot.payload.corroborations.last;
    expect(signal.body['kind'], 'still_present');
    expect(signal.body['incidentId'], 'inc_demo_0001');
    expect(result.snapshot.payload.incidents.single.status, IncidentStatus.verifiedActive);
  });

  test('E2E-27 çözüm geri bildirimi incidenti otomatik reopen etmez, insan kuyruğuna taşır', () async {
    final baseReport = seed.payload.reports.single;
    final resolvedReport = CitizenReportDto.fromObject(
      {
        ...baseReport.toJson(),
        'status': 'resolved',
        'linkedIncidentId': 'inc_e2e_27',
        'resolutionExplanation': 'Sentetik saha çözümü tamamlandı.',
        'resolvedAt': '2026-08-17T09:00:00.000Z',
        'updatedAt': '2026-08-17T09:00:00.000Z',
      },
      'report',
    );
    final resolvedIncident = UrbanIncidentDto(
      id: 'inc_e2e_27',
      status: IncidentStatus.resolved,
      category: resolvedReport.category,
      latitude: resolvedReport.latitude,
      longitude: resolvedReport.longitude,
      reportIds: [resolvedReport.id],
      sourceRecordIds: const [],
      createdAt: DateTime.utc(2026, 8, 17, 8),
      updatedAt: DateTime.utc(2026, 8, 17, 9),
      responsibleUnitId: 'unit_road_maintenance',
      resolutionExplanation: 'Sentetik saha çözümü tamamlandı.',
      resolvedAt: DateTime.utc(2026, 8, 17, 9),
    );
    final initial = seed.copyWith(
      revision: seed.revision + 1,
      updatedAt: DateTime.utc(2026, 8, 17, 9),
      payload: seed.payload.copyWith(
        reports: [resolvedReport],
        incidents: [resolvedIncident],
      ),
    );
    final store = InMemorySnapshotStore(initial: initial, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final feedback = await processor.citizenAction(
      CitizenActionCommand(
        actorId: resolvedReport.ownerId,
        clientMutationId: 'e2e27_still_present',
        expectedRevision: initial.revision,
        kind: CitizenActionKind.resolutionFeedback,
        resourceId: resolvedReport.id,
        payload: const {'feedback': 'still_present'},
      ),
    );
    expect(
      feedback.snapshot.payload.incidents.single.status,
      IncidentStatus.resolved,
    );
    final high = StaffOperationsProjection.queue(
      feedback.snapshot,
      ReviewQueueType.high,
      now: clock.nowUtc(),
    );
    expect(high.items.map((item) => item.report.id), contains(resolvedReport.id));
  });

  test('E2E-28 resmî uyarı salt okunur source projection olarak görünür', () {
    final authority = OpaqueEntityDto(
      id: 'authority_e2e_28',
      body: {
        'id': 'authority_e2e_28',
        'displayName': 'Yetkili afet kaynağı',
        'rank': 'owning_authority',
        'officialAlertAuthority': true,
      },
    );
    final alert = OpaqueEntityDto(
      id: 'source_alert_e2e_28',
      body: {
        'id': 'source_alert_e2e_28',
        'sourceId': 'disaster_alerts_fixture',
        'externalId': 'alert-e2e-28',
        'authorityId': authority.id,
        'officialAlert': true,
        'title': 'Sentetik resmî uyarı',
        'latitude': 41.01,
        'longitude': 28.98,
        'sourceUpdatedAt': '2026-08-17T08:00:00.000Z',
      },
    );
    final snapshot = seed.copyWith(
      payload: seed.payload.copyWith(
        sourceAuthorities: [...seed.payload.sourceAuthorities, authority],
        sourceRecords: [...seed.payload.sourceRecords, alert],
      ),
    );
    final projected = DemoProjections.officialAlerts(snapshot);
    final item = projected.singleWhere((value) => value.id == alert.id);
    expect(item.authority, 'Yetkili afet kaynağı');
    expect(item.title, 'Sentetik resmî uyarı');
  });

  test('E2E-29 citizen AI projection operasyonel reason/model ayrıntısını taşımaz', () async {
    final result = await const DemoAiAnalysisService().analyze(
      AiAnalysisInput(
        description: 'Yolda çukur var',
        categoryHint: 'road_surface_damage',
        latitude: 41.03,
        longitude: 28.98,
        capturedAt: DateTime.utc(2026, 8, 17, 8),
      ),
    );
    final citizen = CitizenAiProjection.from(result);
    final staff = StaffAiProjection(result);
    expect(citizen.suggestedCategories, isNotEmpty);
    expect(citizen.hasPossibleDuplicate, isTrue);
    expect(staff.result.reasonCodes, isNotEmpty);
    expect(staff.result.modelVersion, isNotEmpty);
  });

  test('E2E-30 GTFS gerçek şeması normalize edilir, hatalı koordinat karantinaya hazır kalır', () async {
    final adapter = IettGtfsStopsSchemaAdapter(
      fixtureCsv: 'stop_id,stop_name,stop_lat,stop_lon\nA,Durak A,41.01,28.98\nB,Bozuk,0,0\n',
    );
    final decoded = adapter.decode(await adapter.fetch());
    final validations = adapter.validate(decoded);
    expect(validations.where((item) => item.valid), hasLength(1));
    expect(validations.where((item) => !item.valid).single.errorCode, 'gtfs_invalid_coordinate');
    final normalized = adapter.normalize(
      validations.firstWhere((item) => item.valid).value,
      DateTime.utc(2026, 8, 17, 8, 5),
    );
    expect(normalized.provenance['schema'], 'GTFS stops.txt');
    expect(normalized.normalized['entityKind'], 'transit_stop');
  });
}

final class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 17, 16);
}
