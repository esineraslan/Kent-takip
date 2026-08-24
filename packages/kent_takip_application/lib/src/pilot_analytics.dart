import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_application/src/ai_analysis.dart';

/// Privacy-safe pilot analytics. All values are derived from domain/audit
/// events already stored in the demo snapshot; no raw citizen description,
/// media bytes or precise location is copied into KPI output.
final class PilotKpiSnapshot {
  const PilotKpiSnapshot({
    required this.firstHumanReviewMedian,
    required this.firstPassRoutingRate,
    required this.duplicateReportsPerIncident,
    required this.staffAiOverrideRate,
    required this.resolutionWithinTargetRate,
    required this.repeatStatusRequestRate,
    required this.resolutionConfirmedRate,
    required this.northStarRate,
    required this.reviewedReports,
    required this.routedReports,
    required this.resolvedIncidents,
    required this.feedbackCount,
    required this.statusRequestCount,
  });

  final Duration? firstHumanReviewMedian;
  final double? firstPassRoutingRate;
  final double? duplicateReportsPerIncident;
  final double? staffAiOverrideRate;
  final double? resolutionWithinTargetRate;
  final double? repeatStatusRequestRate;
  final double? resolutionConfirmedRate;
  final double? northStarRate;
  final int reviewedReports;
  final int routedReports;
  final int resolvedIncidents;
  final int feedbackCount;
  final int statusRequestCount;
}

abstract final class PilotAnalyticsProjection {
  static PilotKpiSnapshot calculate(
    AppSnapshotDto snapshot, {
    Duration firstReviewTarget = const Duration(minutes: 15),
  }) {
    final firstReviewDurations = <int>[];
    final firstReviewByReport = <String, int>{};
    final routedReports = <String>{};
    final transferredBackReports = <String>{};
    final overriddenReports = <String>{};
    final statusRequestReports = <String>{};
    final feedback = <String, String>{};

    for (final event in snapshot.payload.auditEvents) {
      final action = event.body['action']?.toString();
      final resourceId = event.body['resourceId']?.toString() ?? event.id;
      final after = event.body['after'];
      final afterMap = after is Map<String, Object?> ? after : const <String, Object?>{};
      if (action == 'operational_metric') {
        final key = afterMap['metricKey']?.toString();
        final seconds = _asInt(afterMap['durationSeconds']);
        if (key == 'first_review' && seconds != null && seconds >= 0) {
          firstReviewDurations.add(seconds);
          firstReviewByReport[resourceId] = seconds;
        }
        if (key == 'repeat_status_request') statusRequestReports.add(resourceId);
        if (key == 'citizen_resolution_feedback') {
          feedback[resourceId] = afterMap['feedback']?.toString() ?? 'unknown';
        }
        if (key == 'staff_override') overriddenReports.add(resourceId);
      }
      if (action == 'report_verified' || action == 'report_routed_to_unit' || action == 'report_routed_to_district') {
        routedReports.add(resourceId);
        if (afterMap['aiOverridden'] == true || _nonEmpty(afterMap['aiOverrideReason'])) {
          overriddenReports.add(resourceId);
        }
      }
      if (action == 'report_transferred_back') transferredBackReports.add(resourceId);
      if (action == 'resolution_feedback_submitted') {
        final kind = afterMap['feedback']?.toString() ?? afterMap['kind']?.toString() ?? 'unknown';
        feedback[resourceId] = kind;
      }
      if (action == 'status_request_submitted') statusRequestReports.add(resourceId);
    }

    firstReviewDurations.sort();
    final firstPass = routedReports.where((id) => !transferredBackReports.contains(id)).length;
    final duplicateExtras = snapshot.payload.incidents.fold<int>(
      0,
      (sum, incident) => sum + (incident.reportIds.length > 1 ? incident.reportIds.length - 1 : 0),
    );
    final incidentDenominator = snapshot.payload.incidents.where((incident) => incident.reportIds.isNotEmpty).length;

    var resolved = 0;
    var resolvedWithinTarget = 0;
    for (final incident in snapshot.payload.incidents) {
      if (incident.status != IncidentStatus.resolved || incident.resolvedAt == null) continue;
      resolved += 1;
      final target = incident.slaTargetAt;
      if (target != null && !incident.resolvedAt!.isAfter(target)) resolvedWithinTarget += 1;
    }

    final eligibleStatusReports = snapshot.payload.reports
        .where((report) => !{ReportStatus.rejected, ReportStatus.outOfScope, ReportStatus.merged}.contains(report.status))
        .map((report) => report.id)
        .toSet();
    final confirmed = feedback.values.where((kind) => kind == 'noLongerVisible').length;
    final reviewed = firstReviewByReport.length;

    // North-star is explicitly incident-based, not submission-based. Duplicate
    // reports must therefore never inflate the denominator. The earliest human
    // review observed for an incident is paired with its report routing history;
    // a transfer-back is the deterministic demo signal that the first route was
    // not correct.
    var reviewedIncidents = 0;
    var northStarSuccess = 0;
    for (final incident in snapshot.payload.incidents) {
      final reviewedEntries = <MapEntry<String, int>>[];
      for (final reportId in incident.reportIds) {
        final seconds = firstReviewByReport[reportId];
        if (seconds != null) reviewedEntries.add(MapEntry(reportId, seconds));
      }
      reviewedEntries.sort((a, b) => a.value.compareTo(b.value));
      if (reviewedEntries.isEmpty) continue;
      reviewedIncidents += 1;
      final firstReviewedReport = reviewedEntries.first;
      if (firstReviewedReport.value <= firstReviewTarget.inSeconds &&
          routedReports.contains(firstReviewedReport.key) &&
          !transferredBackReports.contains(firstReviewedReport.key)) {
        northStarSuccess += 1;
      }
    }

    return PilotKpiSnapshot(
      firstHumanReviewMedian: _medianDuration(firstReviewDurations),
      firstPassRoutingRate: _ratio(firstPass, routedReports.length),
      duplicateReportsPerIncident: incidentDenominator == 0 ? null : duplicateExtras / incidentDenominator,
      staffAiOverrideRate: _ratio(overriddenReports.length, routedReports.length),
      resolutionWithinTargetRate: _ratio(resolvedWithinTarget, resolved),
      repeatStatusRequestRate: _ratio(statusRequestReports.length, eligibleStatusReports.length),
      resolutionConfirmedRate: _ratio(confirmed, feedback.length),
      northStarRate: _ratio(northStarSuccess, reviewedIncidents),
      reviewedReports: reviewed,
      routedReports: routedReports.length,
      resolvedIncidents: resolved,
      feedbackCount: feedback.length,
      statusRequestCount: statusRequestReports.length,
    );
  }

  static Duration? _medianDuration(List<int> values) {
    if (values.isEmpty) return null;
    final middle = values.length ~/ 2;
    if (values.length.isOdd) return Duration(seconds: values[middle]);
    return Duration(seconds: ((values[middle - 1] + values[middle]) / 2).round());
  }

  static double? _ratio(int numerator, int denominator) => denominator == 0 ? null : numerator / denominator;
  static int? _asInt(Object? value) => value is int ? value : int.tryParse(value?.toString() ?? '');
  static bool _nonEmpty(Object? value) => value != null && value.toString().trim().isNotEmpty;
}

final class PilotTargets {
  const PilotTargets({
    this.triageImprovement = 0.30,
    this.routingPointImprovement = 0.15,
    this.duplicateHandlingReduction = 0.30,
    this.criticalRecall = 0.95,
    this.maxAiOverrideRate = 0.20,
    this.timelineComprehension = 0.85,
  });

  final double triageImprovement;
  final double routingPointImprovement;
  final double duplicateHandlingReduction;
  final double criticalRecall;
  final double maxAiOverrideRate;
  final double timelineComprehension;
}

final class PilotBaseline {
  const PilotBaseline({
    this.medianTriageMinutes,
    this.firstPassRoutingRate,
    this.duplicateHandlingPerIncident,
    this.repeatStatusRequestRate,
  });

  final double? medianTriageMinutes;
  final double? firstPassRoutingRate;
  final double? duplicateHandlingPerIncident;
  final double? repeatStatusRequestRate;

  bool get complete =>
      medianTriageMinutes != null &&
      firstPassRoutingRate != null &&
      duplicateHandlingPerIncident != null &&
      repeatStatusRequestRate != null;
}

enum PilotGoNoGo { insufficientEvidence, go, noGo }

abstract final class PilotGoNoGoPolicy {
  static PilotGoNoGo evaluate({
    required bool privacyLeakDetected,
    required bool criticalRecallMeasured,
    required bool criticalRecallMet,
    required bool routingMeasured,
    required bool routingImproved,
    required bool staffTimeMeasured,
    required bool staffTimeImproved,
    required bool timelineMeasured,
    required bool timelineUnderstood,
  }) {
    if (privacyLeakDetected) return PilotGoNoGo.noGo;
    if (!criticalRecallMeasured || !routingMeasured || !staffTimeMeasured || !timelineMeasured) {
      return PilotGoNoGo.insufficientEvidence;
    }
    if (!criticalRecallMet || !routingImproved || !staffTimeImproved || !timelineUnderstood) {
      return PilotGoNoGo.noGo;
    }
    return PilotGoNoGo.go;
  }
}

final class RoiInputs {
  const RoiInputs({
    required this.baselineTriageMinutes,
    required this.pilotTriageMinutes,
    required this.monthlyReportCount,
    required this.staffCostPerMinute,
    required this.baselineWrongRoutingCount,
    required this.pilotWrongRoutingCount,
    required this.reworkCost,
    required this.baselineDuplicateCount,
    required this.pilotDuplicateCount,
    required this.processingCostPerRecord,
    required this.baselineStatusRequestCount,
    required this.pilotStatusRequestCount,
    required this.statusRequestCost,
    required this.infrastructureCost,
    required this.aiCost,
    required this.mapCost,
    required this.smsCost,
    required this.supportCost,
    required this.operationsCost,
  });

  final double baselineTriageMinutes;
  final double pilotTriageMinutes;
  final int monthlyReportCount;
  final double staffCostPerMinute;
  final int baselineWrongRoutingCount;
  final int pilotWrongRoutingCount;
  final double reworkCost;
  final int baselineDuplicateCount;
  final int pilotDuplicateCount;
  final double processingCostPerRecord;
  final int baselineStatusRequestCount;
  final int pilotStatusRequestCount;
  final double statusRequestCost;
  final double infrastructureCost;
  final double aiCost;
  final double mapCost;
  final double smsCost;
  final double supportCost;
  final double operationsCost;
}

final class RoiResult {
  const RoiResult({required this.grossBenefit, required this.operatingCost, required this.netMonthlyBenefit});
  final double grossBenefit;
  final double operatingCost;
  final double netMonthlyBenefit;
}

abstract final class RoiCalculator {
  static RoiResult calculate(RoiInputs input) {
    final triageMinutesSaved = (input.baselineTriageMinutes - input.pilotTriageMinutes).clamp(0, double.infinity).toDouble();
    final wrongRoutingSaved = (input.baselineWrongRoutingCount - input.pilotWrongRoutingCount).clamp(0, 1 << 31).toDouble();
    final duplicateSaved = (input.baselineDuplicateCount - input.pilotDuplicateCount).clamp(0, 1 << 31).toDouble();
    final statusRequestsSaved = (input.baselineStatusRequestCount - input.pilotStatusRequestCount).clamp(0, 1 << 31).toDouble();
    final gross = triageMinutesSaved * input.monthlyReportCount * input.staffCostPerMinute +
        wrongRoutingSaved * input.reworkCost +
        duplicateSaved * input.processingCostPerRecord +
        statusRequestsSaved * input.statusRequestCost;
    final operating = input.infrastructureCost + input.aiCost + input.mapCost + input.smsCost + input.supportCost + input.operationsCost;
    return RoiResult(grossBenefit: gross, operatingCost: operating, netMonthlyBenefit: gross - operating);
  }
}

final class JuryDemoStep {
  const JuryDemoStep({required this.startSecond, required this.endSecond, required this.id, required this.route, required this.expectedEvidence});
  final int startSecond;
  final int endSecond;
  final String id;
  final String route;
  final String expectedEvidence;
}

abstract final class JuryDemoScenario {
  static const id = 'jury_7_minute_wp23';
  static const totalDuration = Duration(minutes: 7);
  static const steps = <JuryDemoStep>[
    JuryDemoStep(startSecond: 0, endSecond: 40, id: 'problem_boundary', route: '/demo/start', expectedEvidence: '153/İstanbul Senin giriş kanalı; Kent Takip ortak olay katmanı'),
    JuryDemoStep(startSecond: 40, endSecond: 80, id: 'common_city_view', route: '/citizen/map', expectedEvidence: 'doğrulanmış olay + planlı çalışma + kaynak/güncellik + liste görünümü'),
    JuryDemoStep(startSecond: 80, endSecond: 150, id: 'citizen_report', route: '/citizen/report/type', expectedEvidence: 'gizlilik-safe medya + konum + benzer olay + corroboration'),
    JuryDemoStep(startSecond: 150, endSecond: 195, id: 'ai_boundary', route: '/citizen/report/type', expectedEvidence: 'AI öneri verir; karar/yayın insan yetkisinde'),
    JuryDemoStep(startSecond: 195, endSecond: 270, id: 'staff_workspace', route: '/staff/queues/normal', expectedEvidence: 'çoklu sinyal + kaynak + gizlilik + insan doğrulaması/yönlendirme'),
    JuryDemoStep(startSecond: 270, endSecond: 320, id: 'closed_loop', route: '/staff/tasks', expectedEvidence: 'çözüm kanıtı + vatandaş timeline + takip numarası korunur'),
    JuryDemoStep(startSecond: 320, endSecond: 370, id: 'outage_and_trust', route: '/staff/data-sources', expectedEvidence: 'gerçek şema kanıtı + stale/unavailable fallback + audited original media'),
    JuryDemoStep(startSecond: 370, endSecond: 420, id: 'pilot_and_ask', route: '/staff/reports', expectedEvidence: 'north-star + 6 hafta pilot + formül tabanlı ROI + tek pilot talebi'),
  ];
}

abstract interface class DemoClockControl {
  Duration get offset;
  void advance(Duration duration);
  void reset();
}

final class ControllableDemoAiAnalysisService implements KentAiAnalysisService {
  ControllableDemoAiAnalysisService({DemoAiScenario initialScenario = DemoAiScenario.success}) : _scenario = initialScenario;
  DemoAiScenario _scenario;
  DemoAiScenario get scenario => _scenario;
  void setScenario(DemoAiScenario value) => _scenario = value;
  void reset() => _scenario = DemoAiScenario.success;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisInput input) => DemoAiAnalysisService(scenario: _scenario).analyze(input);
}
