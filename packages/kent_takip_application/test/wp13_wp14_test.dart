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

  setUp(() async {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.decode(
      await File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json').readAsString(),
    );
    clock = _FixedClock(DateTime.utc(2026, 8, 17, 15));
  });

  test('WP-13 dashboard ve normal kuyruk snapshot domain verisinden türetilir', () {
    final metrics = StaffOperationsProjection.dashboard(seed, clock.nowUtc());
    final normal = StaffOperationsProjection.queue(
      seed,
      ReviewQueueType.normal,
      now: clock.nowUtc(),
    );

    expect(metrics.count(ReviewQueueType.normal), 1);
    expect(normal.total, 1);
    expect(normal.items.single.report.id, 'rpt_demo_0001');
    expect(metrics.activeIncidentCount, 1);
    expect(metrics.queueCounts.keys, containsAll(ReviewQueueType.values));
  });

  test('WP-13 kritik ve privacy kayıtları ayrı kuyruklarda kaybolmaz', () {
    final critical = _copyReport(
      seed.payload.reports.single,
      id: 'rpt_demo_0002',
      trackingNumber: 'KT-2026-000002',
      clientMutationId: 'mutation_demo_0002',
      riskLevel: RiskLevel.criticalSignal,
      analysisId: null,
      mediaIds: const [],
    );
    final privacyMedia = MediaRefDto(
      id: 'media_demo_privacy_0002',
      privacyStatus: PrivacyStatus.pending,
      originalRef: 'asset://demo_media/original/privacy_0002.bin',
      publicRef: null,
      mimeType: 'image/jpeg',
    );
    final privacy = _copyReport(
      seed.payload.reports.single,
      id: 'rpt_demo_0003',
      trackingNumber: 'KT-2026-000003',
      clientMutationId: 'mutation_demo_0003',
      analysisId: 'analysis_demo_0001',
      mediaIds: [privacyMedia.id],
    );
    final snapshot = seed.copyWith(
      payload: seed.payload.copyWith(
        reports: [...seed.payload.reports, critical, privacy],
        media: [...seed.payload.media, privacyMedia],
      ),
    );

    final criticalQueue = StaffOperationsProjection.queue(
      snapshot,
      ReviewQueueType.critical,
      now: clock.nowUtc(),
    );
    final privacyQueue = StaffOperationsProjection.queue(
      snapshot,
      ReviewQueueType.privacy,
      now: clock.nowUtc(),
    );

    expect(criticalQueue.items.map((item) => item.report.id), contains(critical.id));
    expect(privacyQueue.items.map((item) => item.report.id), contains(privacy.id));
  });

  test('WP-13 arama filtre sıralama sayfalama 10k kayıtta bounded sonuç üretir', () {
    final base = seed.payload.reports.single;
    final reports = List<CitizenReportDto>.generate(10000, (index) {
      final number = index + 1;
      return _copyReport(
        base,
        id: 'rpt_perf_${number.toString().padLeft(5, '0')}',
        trackingNumber: 'KT-2026-${number.toString().padLeft(6, '0')}',
        clientMutationId: 'mutation_perf_$number',
        createdAt: clock.nowUtc().subtract(Duration(minutes: number)),
        updatedAt: clock.nowUtc().subtract(Duration(minutes: number)),
        analysisId: null,
        mediaIds: const [],
      );
    });
    final media = List<MediaRefDto>.generate(10000, (index) {
      final number = index + 1;
      return MediaRefDto(
        id: 'media_perf_$number',
        privacyStatus: PrivacyStatus.safe,
        originalRef: 'asset://perf/original/$number.jpg',
        publicRef: 'asset://perf/public/$number.jpg',
        mimeType: 'image/jpeg',
      );
    });
    final reportsWithMedia = [
      for (var index = 0; index < reports.length; index++)
        _copyReport(reports[index], mediaIds: [media[index].id]),
    ];
    final snapshot = seed.copyWith(
      payload: seed.payload.copyWith(reports: reportsWithMedia, media: media),
    );
    final watch = Stopwatch()..start();
    final page = StaffOperationsProjection.queue(
      snapshot,
      ReviewQueueType.manualAiError,
      now: clock.nowUtc(),
      filters: const StaffQueueFilters(page: 2, pageSize: 50, sort: StaffQueueSort.oldest),
    );
    watch.stop();

    expect(page.total, 10000);
    expect(page.items, hasLength(50));
    expect(page.page, 2);
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('WP-13 incident external work-order referansı contract round-trip ile korunur', () {
    final base = seed.payload.incidents.first;
    final ref = ExternalWorkOrderRefDto(
      sourceSystem: 'ibb_work_orders',
      externalWorkOrderId: 'WO-2026-0001',
      sourceUpdatedAt: clock.nowUtc(),
      syncStatus: 'fresh',
    );
    final incident = UrbanIncidentDto(
      id: base.id,
      status: base.status,
      category: base.category,
      latitude: base.latitude,
      longitude: base.longitude,
      reportIds: base.reportIds,
      sourceRecordIds: base.sourceRecordIds,
      workOrderRefs: [ref],
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      responsibleUnitId: base.responsibleUnitId,
      resolutionExplanation: base.resolutionExplanation,
      resolvedAt: base.resolvedAt,
    );

    final decoded = UrbanIncidentDto.fromObject(incident.toJson(), 'incident');
    expect(decoded.workOrderRefs, hasLength(1));
    expect(decoded.workOrderRefs.single.externalWorkOrderId, 'WO-2026-0001');
  });

  test('WP-13 lease conflict sessiz overwrite edilmez; release aynı timestampte revision ile kazanır', () async {
    final reviewer = AccountDto(
      id: 'usr_reviewer_demo_002',
      role: UserRole.reviewer,
      permissions: const [Permission.viewReviewQueue, Permission.reviewReport],
      unitId: null,
      deletionRequested: false,
    );
    final prepared = codec.seal(
      seed.copyWith(payload: seed.payload.copyWith(accounts: [...seed.payload.accounts, reviewer])),
    );
    final store = InMemorySnapshotStore(initial: prepared, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);

    final first = await processor.reviewLease(
      ReviewLeaseCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'lease_first',
        expectedRevision: prepared.revision,
        reportId: 'rpt_demo_0001',
        action: ReviewLeaseAction.acquire,
      ),
    );
    await expectLater(
      processor.reviewLease(
        ReviewLeaseCommand(
          actorId: reviewer.id,
          clientMutationId: 'lease_conflict',
          expectedRevision: first.snapshot.revision,
          reportId: 'rpt_demo_0001',
          action: ReviewLeaseAction.acquire,
        ),
      ),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.conflict)),
    );
    final released = await processor.reviewLease(
      ReviewLeaseCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'lease_release',
        expectedRevision: first.snapshot.revision,
        reportId: 'rpt_demo_0001',
        action: ReviewLeaseAction.release,
      ),
    );
    final second = await processor.reviewLease(
      ReviewLeaseCommand(
        actorId: reviewer.id,
        clientMutationId: 'lease_second',
        expectedRevision: released.snapshot.revision,
        reportId: 'rpt_demo_0001',
        action: ReviewLeaseAction.acquire,
      ),
    );

    expect(
      StaffOperationsProjection.activeLease(second.snapshot, 'rpt_demo_0001', clock.nowUtc())?.lockedBy,
      reviewer.id,
    );
  });

  test('WP-14 reject nedeni allow-list dışındaysa komut oluşturulamaz', () {
    expect(
      () => StaffDecisionCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'decision_invalid_reason_code',
        expectedRevision: seed.revision,
        reportId: 'rpt_demo_0001',
        action: StaffDecisionAction.reject,
        reason: 'İnsan açıklaması var ama kod sözleşme dışı.',
        reasonCode: 'free_form_unknown_code',
      ),
      throwsA(
        isA<DomainFailure>().having((error) => error.code, 'code', FailureCode.validation),
      ),
    );
  });

  test('WP-14 reject seçilmiş gerekçe ile audite edilir ve public incident üretmez', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final lease = await _lease(processor, seed, 'rpt_demo_0001', 'reject');
    final beforeIncidentCount = lease.snapshot.payload.incidents.length;

    final result = await processor.staffDecision(
      StaffDecisionCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'decision_reject_001',
        expectedRevision: lease.snapshot.revision,
        reportId: 'rpt_demo_0001',
        action: StaffDecisionAction.reject,
        reason: 'Fotoğraf ve konum incelemesinde belediye müdahalesi gerektiren sorun doğrulanamadı.',
        reasonCode: StaffDecisionReasonCodes.insufficientEvidence,
      ),
    );

    final report = result.snapshot.payload.reports.singleWhere((item) => item.id == 'rpt_demo_0001');
    expect(report.status, ReportStatus.rejected);
    expect(report.linkedIncidentId, isNull);
    expect(result.snapshot.payload.incidents, hasLength(beforeIncidentCount));
    final audit = result.snapshot.payload.auditEvents.last;
    expect(audit.body['actorId'], 'usr_supervisor_demo_001');
    expect(audit.body['action'], 'report_rejected');
    expect(audit.body['reason'], isNotEmpty);
    expect((audit.body['after'] as Map<String, Object?>)['reasonCode'], 'insufficient_evidence');
    expect(result.snapshot.payload.timeline.last.body['resourceId'], 'rpt_demo_0001');
    expect(result.snapshot.payload.notifications.last.body['recipientId'], 'usr_citizen_demo_001');
  });

  test('WP-14 ek bilgi isteği ve vatandaş cevabı aynı tracking kaydını sürdürür', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final lease = await _lease(processor, seed, 'rpt_demo_0001', 'info');
    final requested = await processor.staffDecision(
      StaffDecisionCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'decision_info_001',
        expectedRevision: lease.snapshot.revision,
        reportId: 'rpt_demo_0001',
        action: StaffDecisionAction.requestAdditionalInfo,
        reason: 'Konum doğrulaması için yakın plan kanıt gerekli.',
        message: 'Lütfen çukurun yakın plan fotoğrafını ve yaklaşık genişliğini ekleyin.',
      ),
    );
    expect(
      requested.snapshot.payload.reports.singleWhere((r) => r.id == 'rpt_demo_0001').status,
      ReportStatus.additionalInfoRequired,
    );

    final responded = await processor.citizenAction(
      CitizenActionCommand(
        actorId: 'usr_citizen_demo_001',
        clientMutationId: 'citizen_info_response_001',
        expectedRevision: requested.snapshot.revision,
        kind: CitizenActionKind.additionalInfoResponse,
        resourceId: 'rpt_demo_0001',
        payload: const {'response': 'Çukur yaklaşık 80 cm genişliğinde; yakın plan fotoğrafı eklendi.'},
      ),
    );
    final report = responded.snapshot.payload.reports.singleWhere((r) => r.id == 'rpt_demo_0001');
    expect(report.status, ReportStatus.ibbReview);
    expect(report.trackingNumber, 'KT-2026-000001');
  });

  test('WP-14 merge veri ve tracking kaybetmez; verify pending incidenti kırmızı public olaya çevirir', () async {
    final source = _copyReport(
      seed.payload.reports.single,
      id: 'rpt_demo_0002',
      trackingNumber: 'KT-2026-000002',
      clientMutationId: 'mutation_demo_merge_source',
      analysisId: null,
      mediaIds: const [],
    );
    final prepared = codec.seal(seed.copyWith(payload: seed.payload.copyWith(reports: [...seed.payload.reports, source])));
    final store = InMemorySnapshotStore(initial: prepared, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final sourceLease = await _lease(processor, prepared, source.id, 'merge_source');

    final merged = await processor.staffDecision(
      StaffDecisionCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'decision_merge_001',
        expectedRevision: sourceLease.snapshot.revision,
        reportId: source.id,
        action: StaffDecisionAction.merge,
        reason: 'Aynı konum ve aynı fiziksel yol hasarı olduğu insan incelemesinde doğrulandı.',
        targetReportId: 'rpt_demo_0001',
      ),
    );
    final mergedReport = merged.snapshot.payload.reports.singleWhere((r) => r.id == source.id);
    final targetReport = merged.snapshot.payload.reports.singleWhere((r) => r.id == 'rpt_demo_0001');
    final pendingIncident = merged.snapshot.payload.incidents.singleWhere((i) => i.id == merged.resourceId);
    expect(mergedReport.status, ReportStatus.merged);
    expect(mergedReport.trackingNumber, 'KT-2026-000002');
    expect(targetReport.trackingNumber, 'KT-2026-000001');
    expect(pendingIncident.status, IncidentStatus.pendingVerification);
    expect(pendingIncident.reportIds, containsAll([source.id, targetReport.id]));
    expect(DemoProjections.visiblePins(merged.snapshot).any((pin) => pin.id == pendingIncident.id), isFalse);

    final targetLease = await processor.reviewLease(
      ReviewLeaseCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'lease_merge_target',
        expectedRevision: merged.snapshot.revision,
        reportId: targetReport.id,
        action: ReviewLeaseAction.acquire,
      ),
    );
    await expectLater(
      processor.staffDecision(
        StaffDecisionCommand(
          actorId: 'usr_supervisor_demo_001',
          clientMutationId: 'decision_merge_reverse_cycle',
          expectedRevision: targetLease.snapshot.revision,
          reportId: targetReport.id,
          action: StaffDecisionAction.merge,
          reason: 'Ters zincir denemesi.',
          targetReportId: source.id,
        ),
      ),
      throwsA(
        isA<DomainFailure>().having((error) => error.code, 'code', FailureCode.invalidTransition),
      ),
    );

    final verified = await processor.verifyReport(
      VerifyReportCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'verify_merge_target',
        expectedRevision: targetLease.snapshot.revision,
        reportId: targetReport.id,
        category: targetReport.category,
        unitId: 'unit_road_maintenance',
        reason: 'Birleştirilmiş kanıt seti insan tarafından doğrulandı.',
        publicPreviewApproved: true,
      ),
    );
    final incident = verified.snapshot.payload.incidents.singleWhere((i) => i.id == pendingIncident.id);
    expect(incident.status, IncidentStatus.verifiedActive);
    expect(DemoProjections.visiblePins(verified.snapshot).singleWhere((pin) => pin.id == incident.id).kind, PinKind.verifiedActive);
  });

  test('WP-14 AI önerisi değiştirildiğinde insan override gerekçesi zorunludur', () async {
    final baseAnalysis = seed.payload.analyses.single;
    final analysis = AiAnalysisDto(
      id: 'analysis_override_test',
      status: AiAnalysisStatus.complete,
      categoryConfidence: 94,
      duplicateConfidence: 10,
      reasonCodes: const [
        'category:road_surface_damage',
        'unit:unit_road_maintenance',
      ],
      modelVersion: baseAnalysis.modelVersion,
      configVersion: baseAnalysis.configVersion,
      createdAt: baseAnalysis.createdAt,
    );
    final baseReport = seed.payload.reports.single;
    final report = _copyReport(baseReport, analysisId: analysis.id);
    final prepared = codec.seal(
      seed.copyWith(
        payload: seed.payload.copyWith(
          reports: [report],
          analyses: [analysis],
        ),
      ),
    );
    final store = InMemorySnapshotStore(initial: prepared, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final lease = await _lease(processor, prepared, report.id, 'ai_override');

    await expectLater(
      processor.verifyReport(
        VerifyReportCommand(
          actorId: 'usr_supervisor_demo_001',
          clientMutationId: 'verify_override_without_reason',
          expectedRevision: lease.snapshot.revision,
          reportId: report.id,
          category: report.category,
          unitId: 'unit_traffic',
          reason: 'İnsan saha bağlamını farklı değerlendirdi.',
          publicPreviewApproved: true,
        ),
      ),
      throwsA(
        isA<DomainFailure>().having((error) => error.code, 'code', FailureCode.validation),
      ),
    );
  });

  test('WP-14 routing ve transfer-back sorumluluk geçmişini korur, tracking sıfırlanmaz', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final lease = await _lease(processor, seed, 'rpt_demo_0001', 'route_verify');
    final verified = await processor.verifyReport(
      VerifyReportCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'verify_route_001',
        expectedRevision: lease.snapshot.revision,
        reportId: 'rpt_demo_0001',
        category: 'road_surface_damage',
        unitId: 'unit_road_maintenance',
        reason: 'İnsan doğrulaması tamamlandı.',
        publicPreviewApproved: true,
      ),
    );
    final routed = await processor.staffDecision(
      StaffDecisionCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'route_district_001',
        expectedRevision: verified.snapshot.revision,
        reportId: 'rpt_demo_0001',
        action: StaffDecisionAction.routeToDistrict,
        reason: 'Saha yetki sınırı ilçe belediyesine ait.',
        targetId: 'district_beyoglu',
      ),
    );
    final routedIncident = routed.snapshot.payload.incidents.singleWhere((i) => i.id == verified.resourceId);
    expect(routedIncident.responsibleUnitId, 'district_beyoglu');

    final back = await processor.staffDecision(
      StaffDecisionCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'transfer_back_001',
        expectedRevision: routed.snapshot.revision,
        reportId: 'rpt_demo_0001',
        action: StaffDecisionAction.transferBack,
        reason: 'İlçe yetki sınırı teyidi hatalı çıktı; merkezi incelemeye geri alındı.',
      ),
    );
    final report = back.snapshot.payload.reports.singleWhere((r) => r.id == 'rpt_demo_0001');
    final incident = back.snapshot.payload.incidents.singleWhere((i) => i.id == verified.resourceId);
    expect(report.status, ReportStatus.ibbReview);
    expect(report.trackingNumber, 'KT-2026-000001');
    expect(incident.responsibleUnitId, isNull);
    final audit = back.snapshot.payload.auditEvents.last;
    expect((audit.body['after'] as Map<String, Object?>)['previousResponsibleUnitId'], 'district_beyoglu');
  });

  test('WP-14 public incident oluşturulduktan sonra reject ile incident orphan bırakılamaz', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final lease = await _lease(processor, seed, 'rpt_demo_0001', 'post_verify_guard');
    final verified = await processor.verifyReport(
      VerifyReportCommand(
        actorId: 'usr_supervisor_demo_001',
        clientMutationId: 'verify_post_guard',
        expectedRevision: lease.snapshot.revision,
        reportId: 'rpt_demo_0001',
        category: 'road_surface_damage',
        unitId: 'unit_road_maintenance',
        reason: 'İnsan doğrulaması tamamlandı.',
        publicPreviewApproved: true,
      ),
    );

    await expectLater(
      processor.staffDecision(
        StaffDecisionCommand(
          actorId: 'usr_supervisor_demo_001',
          clientMutationId: 'reject_after_verify',
          expectedRevision: verified.snapshot.revision,
          reportId: 'rpt_demo_0001',
          action: StaffDecisionAction.reject,
          reason: 'Bu karar artık doğrulama öncesi aşamaya ait.',
          reasonCode: StaffDecisionReasonCodes.insufficientEvidence,
        ),
      ),
      throwsA(
        isA<DomainFailure>().having((error) => error.code, 'code', FailureCode.invalidTransition),
      ),
    );
    expect(
      verified.snapshot.payload.incidents.singleWhere((item) => item.id == verified.resourceId).status,
      IncidentStatus.verifiedActive,
    );
  });

  test('WP-14 stale karar yetkili aktörde current revision ile reddedilir', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final processor = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final lease = await _lease(processor, seed, 'rpt_demo_0001', 'stale');

    await expectLater(
      processor.staffDecision(
        StaffDecisionCommand(
          actorId: 'usr_supervisor_demo_001',
          clientMutationId: 'decision_stale_001',
          expectedRevision: seed.revision,
          reportId: 'rpt_demo_0001',
          action: StaffDecisionAction.reject,
          reason: 'Stale deneme.',
          reasonCode: StaffDecisionReasonCodes.insufficientEvidence,
        ),
      ),
      throwsA(
        isA<CommandConflict>().having((e) => e.current.revision, 'current revision', lease.snapshot.revision),
      ),
    );
  });
}

Future<MutationResult> _lease(
  SnapshotCommandProcessor processor,
  AppSnapshotDto snapshot,
  String reportId,
  String suffix,
) {
  return processor.reviewLease(
    ReviewLeaseCommand(
      actorId: 'usr_supervisor_demo_001',
      clientMutationId: 'lease_$suffix',
      expectedRevision: snapshot.revision,
      reportId: reportId,
      action: ReviewLeaseAction.acquire,
    ),
  );
}

CitizenReportDto _copyReport(
  CitizenReportDto source, {
  required String id,
  required String trackingNumber,
  required String clientMutationId,
  RiskLevel? riskLevel,
  String? analysisId,
  Iterable<String>? mediaIds,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return CitizenReportDto(
    id: id,
    trackingNumber: trackingNumber,
    ownerId: source.ownerId,
    status: ReportStatus.ibbReview,
    category: source.category,
    latitude: source.latitude,
    longitude: source.longitude,
    createdAt: createdAt ?? source.createdAt,
    updatedAt: updatedAt ?? source.updatedAt,
    clientMutationId: clientMutationId,
    mediaIds: mediaIds ?? source.mediaIds,
    analysisId: analysisId,
    linkedIncidentId: null,
    manualReviewRequired: false,
    riskLevel: riskLevel ?? source.riskLevel,
    humanDecisionReason: null,
    resolutionExplanation: null,
    resolvedAt: null,
    resolutionPublicMediaRef: null,
  );
}

final class _FixedClock implements Clock {
  _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime nowUtc() => value;
}
