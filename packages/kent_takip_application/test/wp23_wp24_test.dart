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

  test('WP-23 KPI projection privacy-safe audit olaylarından gerçek formülle türetilir', () {
    final reportId = seed.payload.reports.single.id;
    final incidentJson = seed.payload.incidents.single.toJson();
    incidentJson['reportIds'] = [reportId, 'rpt_duplicate_demo'];
    final incident = UrbanIncidentDto.fromObject(incidentJson, 'incident');
    final audit = <OpaqueEntityDto>[
      _event('m1', 'operational_metric', reportId, {
        'metricKey': 'first_review',
        'durationSeconds': 600,
      }),
      _event('m2', 'operational_metric', 'rpt_duplicate_demo', {
        'metricKey': 'first_review',
        'durationSeconds': 1800,
      }),
      _event('v1', 'report_verified', reportId, {
        'aiOverridden': true,
      }),
      _event('o1', 'operational_metric', reportId, {
        'metricKey': 'staff_override',
      }),
      _event('s1', 'operational_metric', reportId, {
        'metricKey': 'repeat_status_request',
      }),
      _event('f1', 'operational_metric', reportId, {
        'metricKey': 'citizen_resolution_feedback',
        'feedback': 'noLongerVisible',
      }),
    ];
    final snapshot = seed.copyWith(
      payload: seed.payload.copyWith(
        incidents: [incident],
        auditEvents: [...seed.payload.auditEvents, ...audit],
      ),
    );

    final kpi = PilotAnalyticsProjection.calculate(snapshot);
    expect(kpi.firstHumanReviewMedian, const Duration(minutes: 20));
    expect(kpi.firstPassRoutingRate, 1);
    expect(kpi.staffAiOverrideRate, 1);
    expect(kpi.northStarRate, 1);
    expect(kpi.duplicateReportsPerIncident, 1);
    expect(kpi.feedbackCount, 1);
    expect(kpi.statusRequestCount, 1);
    expect(kpi.repeatStatusRequestRate, 1);
  });

  test('WP-23 ROI hesaplayıcı girdi tabanlıdır ve sabit tasarruf uydurmaz', () {
    final result = RoiCalculator.calculate(
      const RoiInputs(
        baselineTriageMinutes: 10,
        pilotTriageMinutes: 7,
        monthlyReportCount: 1000,
        staffCostPerMinute: 2,
        baselineWrongRoutingCount: 100,
        pilotWrongRoutingCount: 70,
        reworkCost: 20,
        baselineDuplicateCount: 200,
        pilotDuplicateCount: 150,
        processingCostPerRecord: 10,
        baselineStatusRequestCount: 300,
        pilotStatusRequestCount: 200,
        statusRequestCost: 5,
        infrastructureCost: 1000,
        aiCost: 500,
        mapCost: 200,
        smsCost: 100,
        supportCost: 300,
        operationsCost: 400,
      ),
    );
    expect(result.grossBenefit, 7600);
    expect(result.operatingCost, 2500);
    expect(result.netMonthlyBenefit, 5100);
  });

  test('WP-23 tekrar durum isteği state değiştirmez ve privacy-safe metric üretir', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final report = seed.payload.reports.single;
    final result = await processor.citizenAction(
      CitizenActionCommand(
        actorId: report.ownerId,
        clientMutationId: 'wp23_status_request_001',
        expectedRevision: seed.revision,
        kind: CitizenActionKind.statusRequest,
        resourceId: report.id,
        payload: const {},
      ),
    );
    final after = result.snapshot.payload.reports.singleWhere((item) => item.id == report.id);
    expect(after.status, report.status);
    final metric = result.snapshot.payload.auditEvents.singleWhere(
      (event) => event.body['action'] == 'operational_metric' &&
          (event.body['after'] as Map<String, Object?>)['metricKey'] == 'repeat_status_request',
    );
    final metricAfter = metric.body['after'] as Map<String, Object?>;
    expect(metricAfter.keys, isNot(contains('description')));
    expect(metricAfter.keys, isNot(contains('media')));
    expect(metricAfter.keys, isNot(contains('location')));
  });

  test('WP-23 kontrollü source outage son geçerli cache kaydını korur', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final sources = SourceGovernanceProcessor(processor: core);
    final refreshed = await sources.execute(
      SourceOperationCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'wp23_source_refresh',
        expectedRevision: seed.revision,
        action: SourceOperationAction.refreshFixture,
        payload: const {'sourceId': 'water_events_fixture'},
      ),
    );
    final cached = refreshed.snapshot.payload.sourceRecords
        .where((item) => item.body['sourceId'] == 'water_events_fixture')
        .map((item) => item.id)
        .toSet();
    final outage = await sources.execute(
      SourceOperationCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'wp23_source_outage',
        expectedRevision: refreshed.snapshot.revision,
        action: SourceOperationAction.simulateOutage,
        payload: const {'sourceId': 'water_events_fixture'},
      ),
    );
    final health = outage.snapshot.payload.dataSourceHealth.singleWhere(
      (item) => item.body['sourceId'] == 'water_events_fixture',
    );
    expect(health.body['health'], 'unavailable');
    expect(health.body['staleCacheRetained'], isTrue);
    expect(
      outage.snapshot.payload.sourceRecords
          .where((item) => item.body['sourceId'] == 'water_events_fixture')
          .map((item) => item.id)
          .toSet(),
      cached,
    );
  });

  test('WP-24 go/no-go policy eksik kanıtı GO saymaz', () {
    expect(
      PilotGoNoGoPolicy.evaluate(
        privacyLeakDetected: false,
        criticalRecallMeasured: false,
        criticalRecallMet: false,
        routingMeasured: true,
        routingImproved: true,
        staffTimeMeasured: true,
        staffTimeImproved: true,
        timelineMeasured: true,
        timelineUnderstood: true,
      ),
      PilotGoNoGo.insufficientEvidence,
    );
    expect(
      PilotGoNoGoPolicy.evaluate(
        privacyLeakDetected: true,
        criticalRecallMeasured: true,
        criticalRecallMet: true,
        routingMeasured: true,
        routingImproved: true,
        staffTimeMeasured: true,
        staffTimeImproved: true,
        timelineMeasured: true,
        timelineUnderstood: true,
      ),
      PilotGoNoGo.noGo,
    );
  });
}

OpaqueEntityDto _event(String id, String action, String resourceId, Map<String, Object?> after) {
  return OpaqueEntityDto(
    id: id,
    body: {
      'id': id,
      'actorId': 'usr_supervisor_demo_001',
      'activeRoleContext': 'demoSupervisor',
      'action': action,
      'resourceId': resourceId,
      'at': '2026-08-17T16:00:00.000Z',
      'reason': 'WP-23 test metric',
      'before': const <String, Object?>{},
      'after': after,
    },
  );
}

final class _FixedClock implements Clock {
  const _FixedClock();
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 17, 16);
}
