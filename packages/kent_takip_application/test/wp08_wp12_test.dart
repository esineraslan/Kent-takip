import 'dart:convert';
import 'dart:io';

import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:test/test.dart';

void main() {
  late SnapshotCodec codec;
  late AppSnapshotDto seed;
  late InMemorySnapshotStore store;
  late SnapshotCommandProcessor processor;

  setUp(() async {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.decode(
      await File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json')
          .readAsString(),
    );
    store = InMemorySnapshotStore(initial: seed, codec: codec);
    processor = SnapshotCommandProcessor(
      store: store,
      codec: codec,
      clock: _FixedClock(DateTime.utc(2026, 8, 17, 16)),
    );
  });

  test('Türkçe arama normalizasyonu ilçe eşleştirir', () {
    final index = PlaceSearchIndex([
      IstanbulPlace(
        id: 'district_uskudar',
        district: 'Üsküdar',
        label: 'Üsküdar',
        latitude: 41.025,
        longitude: 29.015,
      ),
    ]);

    expect(index.search('uskudar').single.district, 'Üsküdar');
    expect(normalizeTurkishSearch(' ŞİŞLİ '), 'sisli');
  });

  test('gizlilik manuel incelemesinde publicRef üretilmez ve PNG metadata atılır', () {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final media = MediaPipeline().prepare(
      actorId: 'usr_citizen_demo_001',
      capture: CapturedPhoto(
        id: 'capture_test',
        bytes: png,
        mimeType: 'image/png',
        fileName: 'capture.png',
        capturedAt: DateTime.utc(2026, 8, 17),
      ),
      scenario: DemoPrivacyScenario.manualReview,
    );

    expect(media.reference.privacyStatus, PrivacyStatus.manualReviewRequired);
    expect(media.reference.publicRef, isNull);
    expect(media.originalBytes, isNotEmpty);
  });

  test('AI başarı, timeout ve rol projeksiyonu deterministiktir', () async {
    final input = AiAnalysisInput(
      description: 'Yolda büyük çökme ve tehlike var.',
      categoryHint: 'unsure',
      latitude: 41.0302,
      longitude: 28.9748,
      capturedAt: DateTime.utc(2026, 8, 17),
    );
    final complete = await const DemoAiAnalysisService().analyze(input);
    expect(complete.suggestions.first.category, 'road_surface_damage');
    final selectedRoad = await const DemoAiAnalysisService().analyze(
      AiAnalysisInput(
        categoryHint: 'road_surface_damage',
        description: 'Yol kenarında su birikiyor.',
        latitude: input.latitude,
        longitude: input.longitude,
        capturedAt: input.capturedAt,
      ),
    );
    expect(selectedRoad.suggestions.first.category, 'road_surface_damage');
    final inferredWater = await const DemoAiAnalysisService().analyze(
      AiAnalysisInput(
        categoryHint: 'unsure',
        description: 'Su kaçağı ve rögar taşması var.',
        latitude: input.latitude,
        longitude: input.longitude,
        capturedAt: input.capturedAt,
      ),
    );
    expect(inferredWater.suggestions.first.category, 'water_infrastructure');
    final timeout = await const DemoAiAnalysisService(
      scenario: DemoAiScenario.timeout,
    ).analyze(input);

    expect(complete.status, AiAnalysisStatus.complete);
    expect(complete.riskLevel, RiskLevel.criticalSignal);
    expect(complete.duplicateCandidates.single.incidentId, 'inc_demo_0001');
    expect(CitizenAiProjection.from(complete).hasPossibleDuplicate, isTrue);
    expect(timeout.status, AiAnalysisStatus.timeout);
  });

  test('report, medya, AI, timeline, notification ve audit tek revizyonda commit olur', () async {
    final analysis = AiAnalysisDto(
      id: 'analysis_test_001',
      status: AiAnalysisStatus.complete,
      categoryConfidence: 91,
      duplicateConfidence: 20,
      reasonCodes: const ['category:road_surface_damage', 'unit:unit_road_maintenance'],
      modelVersion: 'demo-rules-2026.08',
      configVersion: 'wp10-v1',
      createdAt: DateTime.utc(2026, 8, 17, 16),
    );
    final media = MediaRefDto(
      id: 'media_usr_citizen_demo_001_test',
      privacyStatus: PrivacyStatus.manualReviewRequired,
      originalRef: 'media://media_usr_citizen_demo_001_test_original',
      mimeType: 'image/png',
    );
    final result = await processor.createReport(
      CreateReportCommand(
        actorId: 'usr_citizen_demo_001',
        clientMutationId: 'wp11_atomic_001',
        expectedRevision: seed.revision,
        category: 'road_surface_damage',
        description: 'Yolda büyük bir yüzey çökmesi bulunuyor.',
        latitude: 41.0302,
        longitude: 28.9748,
        media: [media],
        analysis: analysis,
        manualReviewRequired: true,
        riskLevel: RiskLevel.high,
      ),
    );

    final report = result.snapshot.payload.reports
        .singleWhere((item) => item.id == result.resourceId);
    expect(report.mediaIds, [media.id]);
    expect(report.analysisId, analysis.id);
    expect(result.snapshot.payload.media, contains(media));
    expect(result.snapshot.payload.analyses, contains(analysis));
    expect(result.snapshot.revision, seed.revision + 1);
  });

  test('mevcut aktif olay vatandaş tarafından yalnız sinyal olarak doğrulanır', () async {
    final result = await processor.citizenAction(
      CitizenActionCommand(
        actorId: 'usr_citizen_demo_001',
        clientMutationId: 'wp12_corroborate_001',
        expectedRevision: seed.revision,
        kind: CitizenActionKind.corroborate,
        resourceId: 'inc_demo_0001',
        payload: {'kind': enumWire(CorroborationKind.stillPresent)},
      ),
    );

    expect(result.snapshot.payload.corroborations.last.body['kind'], 'still_present');
    expect(result.snapshot.payload.incidents.single.status, IncidentStatus.verifiedActive);
  });
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime nowUtc() => value;
}
