import 'dart:convert';
import 'dart:io';

import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';

Future<void> main(List<String> args) async {
  final outIndex = args.indexOf('--out');
  final outPath = outIndex >= 0 && outIndex + 1 < args.length
      ? args[outIndex + 1]
      : 'build/wp21/performance_report.json';
  final seedFile = File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json');
  final source = await seedFile.readAsString();
  final codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
  const probe = PerformanceProbe();
  final samples = <BenchmarkSample>[];

  late AppSnapshotDto seed;
  samples.add(
    probe.measureSync(
      metric: PerformanceMetric.jsonParseValidation,
      budget: PerformanceBudgets.seedParseValidation,
      operation: () => seed = codec.decode(source),
      note: 'canonical seed parse + validation',
    ),
  );

  final seedBytes = utf8.encode(codec.encode(seed)).length;
  if (seedBytes > PerformanceBudgets.maxSnapshotBytes) {
    stderr.writeln(
      'Snapshot budget exceeded: $seedBytes > ${PerformanceBudgets.maxSnapshotBytes}',
    );
    exitCode = 2;
  }

  final stress = _stressSnapshot(seed, count: 10000);
  final index = StaffOperationsProjectionIndex(stress);
  samples.add(
    probe.measureSync(
      metric: PerformanceMetric.queueFilterSort,
      budget: PerformanceBudgets.queueFilterSort,
      itemCount: 10000,
      operation: () {
        final page = index.queue(
          ReviewQueueType.manualAiError,
          now: DateTime.utc(2026, 8, 17, 16),
          filters: const StaffQueueFilters(
            search: 'road',
            sort: StaffQueueSort.priorityOldest,
            pageSize: 100,
          ),
        );
        if (page.total == 0) {
          throw StateError('10k queue benchmark produced no results.');
        }
      },
      note: 'indexed staff queue search/filter/sort',
    ),
  );

  samples.add(
    probe.measureSync(
      metric: PerformanceMetric.mapProjection,
      budget: PerformanceBudgets.mapProjection,
      itemCount: 10000,
      operation: () {
        final pins = DemoProjections.visiblePins(
          stress,
          staff: true,
          nowUtc: DateTime.utc(2026, 8, 17, 16),
        );
        if (pins.length < 10000) {
          throw StateError('10k map projection unexpectedly dropped records.');
        }
        final clusters = DemoProjections.clusters(pins);
        if (clusters.isEmpty) throw StateError('Map clustering returned no clusters.');
      },
      note: '10k visible pin projection + clustering',
    ),
  );

  final ai = const DemoAiAnalysisService();
  samples.add(
    await probe.measureAsync(
      metric: PerformanceMetric.aiLatency,
      budget: PerformanceBudgets.aiManualFallback,
      operation: () async {
        final result = await ai.analyze(
          AiAnalysisInput(
            description: 'Asfaltta çukur var',
            categoryHint: 'road_surface_damage',
            latitude: 41.03,
            longitude: 28.98,
            capturedAt: DateTime.utc(2026, 8, 17, 16),
          ),
        );
        if (result.status != AiAnalysisStatus.complete) {
          throw StateError('Deterministic AI benchmark did not complete.');
        }
      },
      note: 'deterministic local AI path',
    ),
  );

  final report = <String, Object?>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'seedBytes': seedBytes,
    'snapshotBudgetBytes': PerformanceBudgets.maxSnapshotBytes,
    'samples': samples.map((item) => item.toJson()).toList(growable: false),
    'runtimeOnlyBudgets': {
      'warmInteractiveMicros': PerformanceBudgets.warmInteractive.inMicroseconds,
      'webInteractiveMicros': PerformanceBudgets.webInteractive.inMicroseconds,
      'frame60HzMicros': PerformanceBudgets.frame60Hz.inMicroseconds,
      'evidenceRequired': 'Flutter integration trace / DevTools profile',
    },
  };
  final target = File(outPath);
  await target.parent.create(recursive: true);
  await target.writeAsString(const JsonEncoder.withIndent('  ').convert(report));

  var failed = false;
  for (final sample in samples) {
    stdout.writeln(
      '${sample.metric.name}: ${sample.elapsed.inMicroseconds / 1000} ms '
      '(budget ${sample.budget.inMicroseconds / 1000} ms) '
      '${sample.withinBudget ? 'PASS' : 'FAIL'}',
    );
    if (!sample.withinBudget) failed = true;
  }
  stdout.writeln('seed snapshot: $seedBytes bytes / ${PerformanceBudgets.maxSnapshotBytes} bytes');
  stdout.writeln('report: ${target.path}');
  if (failed || seedBytes > PerformanceBudgets.maxSnapshotBytes) exitCode = 2;
}

AppSnapshotDto _stressSnapshot(AppSnapshotDto seed, {required int count}) {
  final now = DateTime.utc(2026, 8, 17, 10);
  final ownerId = seed.payload.accounts
      .firstWhere((item) => item.role == UserRole.citizen)
      .id;
  final reports = <CitizenReportDto>[];
  for (var index = 0; index < count; index++) {
    reports.add(
      CitizenReportDto(
        id: 'stress_report_${index.toString().padLeft(5, '0')}',
        trackingNumber: 'KT-2026-${index.toString().padLeft(6, '0')}',
        ownerId: ownerId,
        status: index % 11 == 0 ? ReportStatus.criticalReview : ReportStatus.ibbReview,
        category: index % 3 == 0 ? 'road_surface_damage' : 'water_infrastructure',
        latitude: 40.85 + (index % 300) / 1000,
        longitude: 28.65 + (index % 500) / 1000,
        createdAt: now.subtract(Duration(minutes: index % 7200)),
        updatedAt: now,
        clientMutationId: 'stress_mutation_${index.toString().padLeft(5, '0')}',
        mediaIds: const [],
        manualReviewRequired: true,
        riskLevel: index % 11 == 0 ? RiskLevel.criticalSignal : RiskLevel.medium,
      ),
    );
  }
  return seed.copyWith(
    revision: seed.revision + 1,
    updatedAt: now,
    payload: seed.payload.copyWith(
      reports: reports,
      incidents: const [],
      municipalWorks: const [],
      media: const [],
      analyses: const [],
      corroborations: const [],
      timeline: const [],
      notifications: const [],
      auditEvents: const [],
    ),
  );
}
