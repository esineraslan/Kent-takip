import 'dart:io';

import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:test/test.dart';

void main() {
  late SnapshotCodec codec;
  late AppSnapshotDto seed;
  late _FixedClock clock;
  late InMemorySnapshotStore store;
  late SnapshotCommandProcessor processor;

  setUp(() async {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.decode(
      await File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json')
          .readAsString(),
    );
    clock = _FixedClock(DateTime.utc(2026, 8, 17, 12));
    store = InMemorySnapshotStore(initial: seed, codec: codec);
    processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
  });

  test('create report kalıcı snapshot, tracking, audit ve timeline üretir', () async {
    final command = _create(seed.revision);
    final result = await processor.createReport(command);

    expect(result.snapshot.revision, seed.revision + 1);
    expect(result.trackingNumber, matches(RegExp(r'^KT-2026-[0-9]{6}$')));
    expect(
      result.snapshot.payload.timeline
          .where((item) => item.body['resourceId'] == result.resourceId),
      hasLength(1),
    );
    expect(
      result.snapshot.payload.auditEvents
          .where((item) => item.body['resourceId'] == result.resourceId),
      hasLength(1),
    );
  });

  test('aynı clientMutationId iki report üretmez', () async {
    final first = await processor.createReport(_create(seed.revision));
    final replay = await processor.createReport(_create(seed.revision));

    expect(replay.replayed, isTrue);
    expect(replay.resourceId, first.resourceId);
    expect(replay.snapshot.payload.reports, hasLength(seed.payload.reports.length + 1));
  });

  test('pending pin yalnız sahibi ve staff tarafından görünür', () async {
    final result = await processor.createReport(_create(seed.revision));

    final ownerPins = DemoProjections.visiblePins(
      result.snapshot,
      viewerId: 'usr_citizen_demo_001',
    );
    final otherPins = DemoProjections.visiblePins(
      result.snapshot,
      viewerId: 'usr_citizen_demo_002',
    );
    expect(ownerPins.any((pin) => pin.id == result.resourceId), isTrue);
    expect(otherPins.any((pin) => pin.id == result.resourceId), isFalse);
  });

  test('insan doğrulaması incident üretir ve tracking numarasını korur', () async {
    final created = await processor.createReport(_create(seed.revision));
    final leased = await processor.reviewLease(
      ReviewLeaseCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'mutation_lease_verify_001',
        expectedRevision: created.snapshot.revision,
        reportId: created.resourceId,
        action: ReviewLeaseAction.acquire,
      ),
    );
    final verified = await processor.verifyReport(
      VerifyReportCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'mutation_verify_001',
        expectedRevision: leased.snapshot.revision,
        reportId: created.resourceId,
        category: 'road_surface_damage',
        unitId: 'unit_road_maintenance',
        reason: 'Fotoğrafsız bildirim konum ve açıklama ile insan tarafından doğrulandı.',
        publicPreviewApproved: true,
      ),
    );

    final report = verified.snapshot.payload.reports
        .singleWhere((item) => item.id == created.resourceId);
    expect(report.trackingNumber, created.trackingNumber);
    expect(report.linkedIncidentId, verified.resourceId);
    expect(report.status, ReportStatus.assignedUnit);
    expect(
      DemoProjections.visiblePins(verified.snapshot)
          .singleWhere((pin) => pin.id == verified.resourceId)
          .kind,
      PinKind.verifiedActive,
    );
    final ownerPins = DemoProjections.visiblePins(
      verified.snapshot,
      viewerId: 'usr_citizen_demo_001',
    );
    expect(ownerPins.any((pin) => pin.id == created.resourceId), isFalse);
    expect(ownerPins.where((pin) => pin.id == verified.resourceId), hasLength(1));
  });

  test('stale staff kararı sessiz overwrite edilmez', () async {
    final created = await processor.createReport(_create(seed.revision));
    final stale = VerifyReportCommand(
      actorId: 'usr_supervisor_demo_001',
      clientMutationId: 'mutation_verify_stale',
      expectedRevision: seed.revision,
      reportId: created.resourceId,
      category: 'road_surface_damage',
      unitId: 'unit_road_maintenance',
      reason: 'Yetkili insan değerlendirmesi.',
      publicPreviewApproved: true,
    );

    await expectLater(
      processor.verifyReport(stale),
      throwsA(
        isA<CommandConflict>().having(
          (error) => error.current.revision,
          'current revision',
          created.snapshot.revision,
        ),
      ),
    );
  });

  test('staff kategorisi, birimi ve gerekçesi zorunludur', () {
    expect(
      () => VerifyReportCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'mutation_invalid',
        expectedRevision: 1,
        reportId: 'rpt_demo_0001',
        category: 'road_surface_damage',
        unitId: 'unit_road_maintenance',
        reason: ' ',
        publicPreviewApproved: true,
      ),
      throwsA(isA<DomainFailure>()),
    );
  });
}

CreateReportCommand _create(int revision) => CreateReportCommand(
  actorId: 'usr_citizen_demo_001',
  clientMutationId: 'mutation_create_001',
  expectedRevision: revision,
  category: 'road_surface_damage',
  description: 'Meşrutiyet Caddesi üzerinde büyük çukur var.',
  latitude: 41.0302,
  longitude: 28.9748,
);

final class _FixedClock implements Clock {
  _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime nowUtc() => value;
}
