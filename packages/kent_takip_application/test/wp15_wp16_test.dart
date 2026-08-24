import 'dart:io';

import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:test/test.dart';

void main() {
  late SnapshotCodec codec;
  late AppSnapshotDto seed;
  late _MutableClock clock;

  setUp(() async {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.decode(
      await File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json').readAsString(),
    );
    clock = _MutableClock(DateTime.utc(2026, 8, 17, 15));
  });

  test('WP-15 saha akışı SLA, simulated work-order ve çözüm kanıtını korur', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final verified = await _verify(processor, seed, suffix: 'field');
    final initiallyRouted = verified.snapshot.payload.incidents.singleWhere((i) => i.id == verified.resourceId);
    expect(initiallyRouted.slaStartedAt, clock.nowUtc());
    expect(initiallyRouted.slaTargetAt, isNotNull);
    expect(
      verified.snapshot.payload.auditEvents
          .where((event) => event.body['action'] == 'operational_metric')
          .map((event) => (event.body['after'] as Map<String, Object?>)['metricKey']),
      containsAll(<String>['first_review', 'routing']),
    );
    final routed = await processor.staffDecision(
      StaffDecisionCommand(
        actorId: _staffId,
        clientMutationId: 'route_field_001',
        expectedRevision: verified.snapshot.revision,
        reportId: _reportId,
        action: StaffDecisionAction.routeToUnit,
        reason: 'Saha operasyonu için yol bakım birimine yönlendirildi.',
        targetId: 'unit_road_maintenance',
      ),
    );
    var incident = routed.snapshot.payload.incidents.singleWhere((i) => i.id == verified.resourceId);
    expect(incident.slaStartedAt, clock.nowUtc());
    expect(incident.slaTargetAt, isNotNull);
    expect(FieldSlaPolicy.targetFor(incident.category, incident.responsibleUnitId!).label, contains('garanti değildir'));

    final assigned = await processor.fieldOperation(
      FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'field_assign_001',
        expectedRevision: routed.snapshot.revision,
        incidentId: incident.id,
        action: FieldOperationAction.assignField,
        reason: 'Demo saha ekibi atandı.',
        fieldTeamId: 'team_demo_road_01',
      ),
    );
    incident = assigned.snapshot.payload.incidents.singleWhere((i) => i.id == incident.id);
    expect(incident.fieldTeamId, 'team_demo_road_01');
    expect(incident.workOrderRefs, hasLength(1));
    expect(incident.workOrderRefs.single.sourceSystem, 'DEMO_SIMULATED_WORK_ORDER');
    expect(incident.workOrderRefs.single.syncStatus, 'simulated');
    expect(_report(assigned.snapshot).status, ReportStatus.fieldAssigned);

    final started = await processor.fieldOperation(
      FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'field_start_001',
        expectedRevision: assigned.snapshot.revision,
        incidentId: incident.id,
        action: FieldOperationAction.startProgress,
        reason: 'Saha müdahalesi başladı.',
      ),
    );
    expect(_report(started.snapshot).status, ReportStatus.inProgress);

    clock.value = clock.value.add(const Duration(hours: 3));
    final delayed = await processor.fieldOperation(
      FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'field_delay_001',
        expectedRevision: started.snapshot.revision,
        incidentId: incident.id,
        action: FieldOperationAction.recordDelay,
        reason: 'Operasyon planı güncellendi.',
        delayReason: 'Saha erişimi geçici olarak kapalı.',
        reestimateMinMinutes: 60,
        reestimateMaxMinutes: 180,
      ),
    );
    incident = delayed.snapshot.payload.incidents.singleWhere((i) => i.id == incident.id);
    expect(incident.slaDelayReason, 'Saha erişimi geçici olarak kapalı.');
    expect(incident.reestimatedMinAt, clock.nowUtc().add(const Duration(minutes: 60)));
    expect(incident.reestimatedMaxAt, clock.nowUtc().add(const Duration(minutes: 180)));

    expect(
      () => FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'field_resolve_invalid',
        expectedRevision: delayed.snapshot.revision,
        incidentId: incident.id,
        action: FieldOperationAction.resolve,
        reason: 'Çözüm kaydı.',
        resolutionExplanation: '   ',
      ),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.validation)),
    );

    final resolved = await processor.fieldOperation(
      FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'field_resolve_001',
        expectedRevision: delayed.snapshot.revision,
        incidentId: incident.id,
        action: FieldOperationAction.resolve,
        reason: 'Saha kontrolü tamamlandı.',
        resolutionExplanation: 'Bozuk asfalt yaması yenilendi ve saha güvenli hale getirildi.',
        resolutionMediaId: 'media_demo_public_0001',
      ),
    );
    expect(_report(resolved.snapshot).status, ReportStatus.resolved);
    incident = resolved.snapshot.payload.incidents.singleWhere((i) => i.id == incident.id);
    expect(incident.status, IncidentStatus.resolved);
    expect(incident.slaPausedAt, clock.nowUtc());
    expect(incident.resolutionExplanation, contains('asfalt'));
    final detail = DemoProjections.ownedReportDetail(resolved.snapshot, _citizenId, _reportId)!;
    expect(detail.resolutionExplanation, contains('asfalt'));
    expect(detail.resolutionPublicMediaRef, 'asset://demo_media/public/road_damage_demo.bin');
    expect(detail.slaTargetAt, isNotNull);
  });

  test('WP-15 sorun devam ediyor sinyali otomatik reopen yapmaz, yüksek inceleme kuyruğuna girer', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final verified = await _verify(processor, seed, suffix: 'reopen');
    final routed = await processor.staffDecision(
      StaffDecisionCommand(
        actorId: _staffId,
        clientMutationId: 'route_reopen_001',
        expectedRevision: verified.snapshot.revision,
        reportId: _reportId,
        action: StaffDecisionAction.routeToUnit,
        reason: 'Saha operasyonuna yönlendirildi.',
        targetId: 'unit_road_maintenance',
      ),
    );
    final incidentId = verified.resourceId;
    final assigned = await processor.fieldOperation(
      FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'assign_reopen_001',
        expectedRevision: routed.snapshot.revision,
        incidentId: incidentId,
        action: FieldOperationAction.assignField,
        reason: 'Ekip atandı.',
        fieldTeamId: 'team_demo_road_01',
      ),
    );
    final started = await processor.fieldOperation(
      FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'start_reopen_001',
        expectedRevision: assigned.snapshot.revision,
        incidentId: incidentId,
        action: FieldOperationAction.startProgress,
        reason: 'Saha başladı.',
      ),
    );
    final resolved = await processor.fieldOperation(
      FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'resolve_reopen_001',
        expectedRevision: started.snapshot.revision,
        incidentId: incidentId,
        action: FieldOperationAction.resolve,
        reason: 'Çözüm kaydı.',
        resolutionExplanation: 'İlk saha müdahalesi tamamlandı.',
      ),
    );
    final feedback = await processor.citizenAction(
      CitizenActionCommand(
        actorId: _citizenId,
        clientMutationId: 'resolution_feedback_001',
        expectedRevision: resolved.snapshot.revision,
        kind: CitizenActionKind.resolutionFeedback,
        resourceId: _reportId,
        payload: const {'feedback': 'still_present'},
      ),
    );
    expect(_report(feedback.snapshot).status, ReportStatus.resolved);
    expect(
      feedback.snapshot.payload.incidents.singleWhere((i) => i.id == incidentId).status,
      IncidentStatus.resolved,
    );
    final high = StaffOperationsProjection.queue(
      feedback.snapshot,
      ReviewQueueType.high,
      now: clock.nowUtc(),
    );
    expect(high.items.map((item) => item.report.id), contains(_reportId));
    final leased = await processor.reviewLease(
      ReviewLeaseCommand(
        actorId: _staffId,
        clientMutationId: 'lease_reopen_001',
        expectedRevision: feedback.snapshot.revision,
        reportId: _reportId,
        action: ReviewLeaseAction.acquire,
      ),
    );
    expect(StaffOperationsProjection.activeLease(leased.snapshot, _reportId, clock.nowUtc())?.lockedBy, _staffId);
  });

  test('WP-15 merged alias saha state geçişini bloke etmez', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final created = await processor.createReport(
      CreateReportCommand(
        actorId: _citizen2Id,
        clientMutationId: 'merge_field_source_create',
        expectedRevision: seed.revision,
        category: 'road_surface_damage',
        description: 'Aynı yol hasarı için ikinci vatandaş sinyali.',
        latitude: 41.0255,
        longitude: 29.0153,
      ),
    );
    final sourceId = created.resourceId;
    final sourceLease = await processor.reviewLease(
      ReviewLeaseCommand(
        actorId: _staffId,
        clientMutationId: 'merge_field_source_lease',
        expectedRevision: created.snapshot.revision,
        reportId: sourceId,
        action: ReviewLeaseAction.acquire,
      ),
    );
    final merged = await processor.staffDecision(
      StaffDecisionCommand(
        actorId: _staffId,
        clientMutationId: 'merge_field_decision',
        expectedRevision: sourceLease.snapshot.revision,
        reportId: sourceId,
        action: StaffDecisionAction.merge,
        reason: 'Aynı fiziksel yol hasarıyla birleştirildi.',
        targetReportId: _reportId,
      ),
    );
    final targetLease = await processor.reviewLease(
      ReviewLeaseCommand(
        actorId: _staffId,
        clientMutationId: 'merge_field_target_lease',
        expectedRevision: merged.snapshot.revision,
        reportId: _reportId,
        action: ReviewLeaseAction.acquire,
      ),
    );
    final verified = await processor.verifyReport(
      VerifyReportCommand(
        actorId: _staffId,
        clientMutationId: 'merge_field_verify',
        expectedRevision: targetLease.snapshot.revision,
        reportId: _reportId,
        category: 'road_surface_damage',
        unitId: 'unit_road_maintenance',
        reason: 'Birleşmiş olay insan tarafından doğrulandı.',
        publicPreviewApproved: true,
      ),
    );
    final assigned = await processor.fieldOperation(
      FieldOperationCommand(
        actorId: _staffId,
        clientMutationId: 'merge_field_assign',
        expectedRevision: verified.snapshot.revision,
        incidentId: verified.resourceId,
        action: FieldOperationAction.assignField,
        reason: 'Birleşmiş olay saha ekibine atandı.',
        fieldTeamId: 'team_demo_road_01',
      ),
    );
    expect(_report(assigned.snapshot).status, ReportStatus.fieldAssigned);
    expect(
      assigned.snapshot.payload.reports.singleWhere((report) => report.id == sourceId).status,
      ReportStatus.merged,
    );
  });

  test('WP-16 geometri + zaman çakışması kaynak ve alternatif zaman gerekçesi üretir', () {
    final work = MunicipalWorkDto(
      id: 'work_geometry_primary',
      status: WorkStatus.draft,
      category: 'road_maintenance',
      latitude: 41.0257,
      longitude: 29.0156,
      startsAt: DateTime.utc(2026, 8, 18, 8),
      expectedEndsAt: DateTime.utc(2026, 8, 18, 12),
      responsibleUnitId: 'unit_road_maintenance',
      explanation: 'Birincil planlı bakım',
      areaRadiusMeters: 250,
      createdBy: _staffId,
      createdAt: clock.nowUtc(),
      updatedAt: clock.nowUtc(),
    );
    final other = MunicipalWorkDto(
      id: 'work_geometry_conflict',
      status: WorkStatus.publishedPlanned,
      category: 'utility_maintenance',
      latitude: 41.0258,
      longitude: 29.0157,
      startsAt: DateTime.utc(2026, 8, 18, 10),
      expectedEndsAt: DateTime.utc(2026, 8, 18, 13),
      responsibleUnitId: 'unit_water',
      explanation: 'Çakışan altyapı çalışması',
      areaRadiusMeters: 180,
    );
    final impact = const MunicipalImpactAnalyzer().analyze(work, [work, other], clock.nowUtc());
    final workOverlap = impact.overlaps.singleWhere((item) => item.body['sourceId'] == other.id);
    expect(workOverlap.body['timeOverlapMinutes'], 120);
    expect(workOverlap.body['rule'], 'spatial_radius_and_time_interval_overlap');
    expect(impact.suggestions.any((item) => item.contains('Zaman alternatifi')), isTrue);
  });

  test('WP-16 taslak public değildir; analiz açıklanabilir, onaysız publish yasaktır', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final draft = await processor.municipalWork(
      MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_draft_001',
        expectedRevision: seed.revision,
        action: MunicipalWorkAction.saveDraft,
        category: 'road_maintenance',
        latitude: 41.0257,
        longitude: 29.0156,
        startsAt: DateTime.utc(2026, 8, 18, 8),
        expectedEndsAt: DateTime.utc(2026, 8, 18, 14),
        responsibleUnitId: 'unit_road_maintenance',
        explanation: 'Üsküdar sahil yolunda planlı bakım.',
        areaRadiusMeters: 250,
      ),
    );
    final workId = draft.resourceId;
    expect(
      DemoProjections.visiblePins(draft.snapshot, nowUtc: clock.nowUtc()).map((p) => p.id),
      isNot(contains(workId)),
    );

    final analyzed = await processor.municipalWork(
      MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_impact_001',
        expectedRevision: draft.snapshot.revision,
        action: MunicipalWorkAction.analyzeImpact,
        workId: workId,
      ),
    );
    final impact = analyzed.snapshot.payload.municipalWorks.singleWhere((w) => w.id == workId).impact!;
    expect(impact.explanation, contains('AI trafik tahmini kullanılmadı'));
    expect(impact.overlaps, isNotEmpty);
    expect(impact.overlaps.every((o) => (o.body['sourceId'] as String?)?.isNotEmpty ?? false), isTrue);
    expect(impact.overlaps.every((o) => (o.body['explanation'] as String?)?.isNotEmpty ?? false), isTrue);

    final review = await processor.municipalWork(
      MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_review_001',
        expectedRevision: analyzed.snapshot.revision,
        action: MunicipalWorkAction.markReviewReady,
        workId: workId,
      ),
    );
    expect(
      () => MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_publish_invalid',
        expectedRevision: review.snapshot.revision,
        action: MunicipalWorkAction.publish,
        workId: workId,
        publicInformationText: 'Planlı bakım bilgisi.',
        publicPreviewApproved: false,
      ),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.validation)),
    );
  });

  test('WP-16 publish sarı, başlangıç kırmızı/aktif, bitişte live mapten kalkar ve history kalır', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final start = DateTime.utc(2026, 8, 17, 18);
    final end = DateTime.utc(2026, 8, 17, 20);
    final draft = await processor.municipalWork(
      MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_clock_draft',
        expectedRevision: seed.revision,
        action: MunicipalWorkAction.saveDraft,
        category: 'road_maintenance',
        latitude: 41.0257,
        longitude: 29.0156,
        startsAt: start,
        expectedEndsAt: end,
        responsibleUnitId: 'unit_road_maintenance',
        explanation: 'DemoClock planlı saha bakımı.',
        areaRadiusMeters: 180,
      ),
    );
    final workId = draft.resourceId;
    final analyzed = await processor.municipalWork(
      MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_clock_impact',
        expectedRevision: draft.snapshot.revision,
        action: MunicipalWorkAction.analyzeImpact,
        workId: workId,
      ),
    );
    final review = await processor.municipalWork(
      MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_clock_review',
        expectedRevision: analyzed.snapshot.revision,
        action: MunicipalWorkAction.markReviewReady,
        workId: workId,
      ),
    );
    final published = await processor.municipalWork(
      MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_clock_publish',
        expectedRevision: review.snapshot.revision,
        action: MunicipalWorkAction.publish,
        workId: workId,
        publicInformationText: '18.00–20.00 arasında planlı yol bakım çalışması yapılacaktır.',
        publicPreviewApproved: true,
      ),
    );
    final beforeStartPin = DemoProjections.visiblePins(published.snapshot, nowUtc: clock.nowUtc())
        .singleWhere((pin) => pin.id == workId);
    expect(beforeStartPin.kind, PinKind.publishedPlanned);

    clock.value = DateTime.utc(2026, 8, 17, 18, 30);
    final activePin = DemoProjections.visiblePins(published.snapshot, nowUtc: clock.nowUtc())
        .singleWhere((pin) => pin.id == workId);
    expect(activePin.kind, PinKind.verifiedActive);

    clock.value = DateTime.utc(2026, 8, 17, 21);
    expect(
      DemoProjections.visiblePins(published.snapshot, nowUtc: clock.nowUtc()).map((p) => p.id),
      isNot(contains(workId)),
    );
    final reconciled = await processor.municipalWork(
      MunicipalWorkCommand(
        actorId: _staffId,
        clientMutationId: 'work_clock_reconcile',
        expectedRevision: published.snapshot.revision,
        action: MunicipalWorkAction.reconcileClock,
      ),
    );
    final completed = reconciled.snapshot.payload.municipalWorks.singleWhere((w) => w.id == workId);
    expect(completed.status, WorkStatus.completed);
    expect(completed.completedAt, clock.nowUtc());
    final transitions = reconciled.snapshot.payload.auditEvents
        .where((a) => a.body['resourceId'] == workId && a.body['action'] == 'municipal_work_clock_transition')
        .map((a) => ((a.body['after'] as Map<String, Object?>)['status']))
        .toList();
    expect(transitions, containsAllInOrder(['active', 'completed']));
    expect(reconciled.snapshot.payload.municipalWorks.map((w) => w.id), contains(workId));
  });
}

const _staffId = 'usr_supervisor_demo_001';
const _citizenId = 'usr_citizen_demo_001';
const _citizen2Id = 'usr_citizen_demo_002';
const _reportId = 'rpt_demo_0001';

Future<MutationResult> _verify(
  SnapshotCommandProcessor processor,
  AppSnapshotDto snapshot, {
  required String suffix,
}) async {
  final lease = await processor.reviewLease(
    ReviewLeaseCommand(
      actorId: _staffId,
      clientMutationId: 'lease_$suffix',
      expectedRevision: snapshot.revision,
      reportId: _reportId,
      action: ReviewLeaseAction.acquire,
    ),
  );
  return processor.verifyReport(
    VerifyReportCommand(
      actorId: _staffId,
      clientMutationId: 'verify_$suffix',
      expectedRevision: lease.snapshot.revision,
      reportId: _reportId,
      category: 'road_surface_damage',
      unitId: 'unit_road_maintenance',
      reason: 'İnsan doğrulaması tamamlandı.',
      publicPreviewApproved: true,
    ),
  );
}

CitizenReportDto _report(AppSnapshotDto snapshot) =>
    snapshot.payload.reports.singleWhere((r) => r.id == _reportId);

final class _MutableClock implements Clock {
  _MutableClock(this.value);
  DateTime value;

  @override
  DateTime nowUtc() => value;
}
