import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

abstract final class StaffOperationsPolicy {
  static const int lowConfidenceCategoryThreshold = 55;
  static const int minimumPageSize = 10;
  static const int maximumPageSize = 200;
  static const int criticalPriorityWeight = 1000;
  static const int highPriorityWeight = 400;
  static const int privacyPriorityWeight = 220;
  static const int manualAiPriorityWeight = 160;
  static const int maximumAgePriorityHours = 240;
}

enum ReviewQueueType {
  critical,
  high,
  normal,
  lowConfidence,
  privacy,
  abuse,
  manualAiError,
}

enum StaffQueueSort { priorityOldest, oldest, newest, duplicateProbability }

final class StaffQueueFilters {
  const StaffQueueFilters({
    this.search = '',
    this.category,
    this.riskLevel,
    this.status,
    this.unitId,
    this.minDuplicateConfidence,
    this.sort = StaffQueueSort.priorityOldest,
    this.page = 1,
    this.pageSize = 50,
  });

  final String search;
  final String? category;
  final RiskLevel? riskLevel;
  final ReportStatus? status;
  final String? unitId;
  final int? minDuplicateConfidence;
  final StaffQueueSort sort;
  final int page;
  final int pageSize;

  StaffQueueFilters copyWith({
    String? search,
    String? category,
    bool clearCategory = false,
    RiskLevel? riskLevel,
    bool clearRiskLevel = false,
    ReportStatus? status,
    bool clearStatus = false,
    String? unitId,
    bool clearUnitId = false,
    int? minDuplicateConfidence,
    bool clearDuplicate = false,
    StaffQueueSort? sort,
    int? page,
    int? pageSize,
  }) {
    return StaffQueueFilters(
      search: search ?? this.search,
      category: clearCategory ? null : category ?? this.category,
      riskLevel: clearRiskLevel ? null : riskLevel ?? this.riskLevel,
      status: clearStatus ? null : status ?? this.status,
      unitId: clearUnitId ? null : unitId ?? this.unitId,
      minDuplicateConfidence:
          clearDuplicate ? null : minDuplicateConfidence ?? this.minDuplicateConfidence,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

final class ReviewLeaseView {
  const ReviewLeaseView({
    required this.reportId,
    required this.lockedBy,
    required this.lockedAt,
    required this.expiresAt,
    required this.revision,
  });

  final String reportId;
  final String lockedBy;
  final DateTime lockedAt;
  final DateTime expiresAt;
  final int revision;

  bool activeAt(DateTime now) => expiresAt.isAfter(now);
}

final class StaffQueueEntry {
  const StaffQueueEntry({
    required this.report,
    required this.queues,
    required this.age,
    required this.priorityScore,
    required this.analysis,
    required this.incident,
    required this.sourceRecords,
    required this.publicMediaRefs,
    required this.originalMediaRefs,
    required this.sourceHealth,
    required this.sourceConflict,
    required this.lease,
    required this.duplicateConfidence,
  });

  final CitizenReportDto report;
  final Set<ReviewQueueType> queues;
  final Duration age;
  final int priorityScore;
  final AiAnalysisDto? analysis;
  final UrbanIncidentDto? incident;
  final List<OpaqueEntityDto> sourceRecords;
  final List<String> publicMediaRefs;
  final List<String> originalMediaRefs;
  final SourceHealth sourceHealth;
  final bool sourceConflict;
  final ReviewLeaseView? lease;
  final int? duplicateConfidence;
}

final class StaffQueuePage {
  const StaffQueuePage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<StaffQueueEntry> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
}

final class StaffDashboardMetrics {
  const StaffDashboardMetrics({
    required this.queueCounts,
    required this.activeIncidentCount,
    required this.plannedWorkCount,
    required this.staleSourceCount,
    required this.unavailableSourceCount,
    required this.oldestReviewAge,
    required this.firstReviewMedian,
    required this.routingMedian,
    required this.resolutionMedian,
  });

  final Map<ReviewQueueType, int> queueCounts;
  final int activeIncidentCount;
  final int plannedWorkCount;
  final int staleSourceCount;
  final int unavailableSourceCount;
  final Duration oldestReviewAge;
  final Duration? firstReviewMedian;
  final Duration? routingMedian;
  final Duration? resolutionMedian;

  int count(ReviewQueueType type) => queueCounts[type] ?? 0;
}

abstract final class StaffOperationsProjection {
  static const Set<ReportStatus> _reviewableStatuses = {
    ReportStatus.received,
    ReportStatus.aiReview,
    ReportStatus.ibbReview,
    ReportStatus.manualReview,
    ReportStatus.criticalReview,
  };

  static StaffDashboardMetrics dashboard(AppSnapshotDto snapshot, DateTime now) {
    final counts = {for (final type in ReviewQueueType.values) type: 0};
    final lookup = _StaffProjectionLookup(snapshot);
    for (final report in snapshot.payload.reports) {
      if (!_reviewableStatuses.contains(report.status) &&
          !lookup.reopenReportIds.contains(report.id)) {
        continue;
      }
      final entry = _entry(report, now, lookup);
      for (final type in entry.queues) {
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }
    var stale = 0;
    var unavailable = 0;
    for (final item in snapshot.payload.dataSourceHealth) {
      final raw = item.body['health'];
      final parsed = raw is String ? enumValues(SourceHealth.values)[raw] : null;
      if (parsed == SourceHealth.stale) stale += 1;
      if (parsed == SourceHealth.unavailable || parsed == SourceHealth.quarantined) {
        unavailable += 1;
      }
    }
    var oldest = Duration.zero;
    for (final report in snapshot.payload.reports) {
      if (!_reviewableStatuses.contains(report.status) &&
          !lookup.reopenReportIds.contains(report.id)) {
        continue;
      }
      final age = now.difference(report.createdAt);
      if (!age.isNegative && age > oldest) oldest = age;
    }
    return StaffDashboardMetrics(
      queueCounts: Map.unmodifiable(counts),
      activeIncidentCount: snapshot.payload.incidents
          .where((item) => item.status == IncidentStatus.verifiedActive)
          .length,
      plannedWorkCount: snapshot.payload.municipalWorks
          .where((item) => item.status == WorkStatus.publishedPlanned)
          .length,
      staleSourceCount: stale,
      unavailableSourceCount: unavailable,
      oldestReviewAge: oldest,
      firstReviewMedian: _metricMedian(snapshot, 'first_review'),
      routingMedian: _metricMedian(snapshot, 'routing'),
      resolutionMedian: _metricMedian(snapshot, 'resolution'),
    );
  }

  static Duration? _metricMedian(AppSnapshotDto snapshot, String metricKey) {
    final values = <int>[];
    for (final event in snapshot.payload.auditEvents) {
      if (event.body['action'] != 'operational_metric') continue;
      final after = event.body['after'];
      if (after is! Map<String, Object?> || after['metricKey'] != metricKey) continue;
      final seconds = after['durationSeconds'];
      if (seconds is int && seconds >= 0) values.add(seconds);
    }
    if (values.isEmpty) return null;
    values.sort();
    final middle = values.length ~/ 2;
    final seconds = values.length.isOdd
        ? values[middle]
        : (values[middle - 1] + values[middle]) ~/ 2;
    return Duration(seconds: seconds);
  }

  static StaffQueuePage queue(
    AppSnapshotDto snapshot,
    ReviewQueueType type, {
    required DateTime now,
    StaffQueueFilters filters = const StaffQueueFilters(),
  }) {
    final entries = <StaffQueueEntry>[];
    final lookup = _StaffProjectionLookup(snapshot);
    for (final report in snapshot.payload.reports) {
      if (!_reviewableStatuses.contains(report.status) &&
          !lookup.reopenReportIds.contains(report.id)) {
        continue;
      }
      final entry = _entry(report, now, lookup);
      if (!entry.queues.contains(type)) continue;
      if (!_matches(entry, filters)) continue;
      entries.add(entry);
    }
    _sort(entries, filters.sort);
    final pageSize = filters.pageSize.clamp(StaffOperationsPolicy.minimumPageSize, StaffOperationsPolicy.maximumPageSize).toInt();
    final totalPages = entries.isEmpty ? 1 : ((entries.length + pageSize - 1) ~/ pageSize);
    final page = filters.page.clamp(1, totalPages).toInt();
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, entries.length).toInt();
    return StaffQueuePage(
      items: List.unmodifiable(entries.sublist(start, end)),
      total: entries.length,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  static StaffQueueEntry? entryByReportId(
    AppSnapshotDto snapshot,
    String reportId, {
    required DateTime now,
  }) {
    final lookup = _StaffProjectionLookup(snapshot);
    for (final report in snapshot.payload.reports) {
      if (report.id == reportId) return _entry(report, now, lookup);
    }
    return null;
  }

  static ReviewLeaseView? activeLease(
    AppSnapshotDto snapshot,
    String reportId,
    DateTime now,
  ) {
    final lease = latestLease(snapshot, reportId);
    return lease != null && lease.activeAt(now) ? lease : null;
  }

  static ReviewLeaseView? latestLease(AppSnapshotDto snapshot, String reportId) {
    OpaqueEntityDto? latest;
    for (final event in snapshot.payload.auditEvents) {
      if (event.body['resourceId'] != reportId) continue;
      final action = event.body['action'];
      if (action != 'review_lease_acquired' &&
          action != 'review_lease_taken_over' &&
          action != 'review_lease_released') {
        continue;
      }
      if (latest == null || _leaseEventIsNewer(event, latest)) latest = event;
    }
    if (latest == null || latest.body['action'] == 'review_lease_released') return null;
    final after = latest.body['after'];
    if (after is! Map<String, Object?>) return null;
    final lockedBy = after['lockedBy'];
    final lockedAt = DateTime.tryParse(after['lockedAt'] as String? ?? '');
    final expiresAt = DateTime.tryParse(after['expiresAt'] as String? ?? '');
    final revision = after['revision'];
    if (lockedBy is! String || lockedAt == null || expiresAt == null || revision is! int) {
      return null;
    }
    return ReviewLeaseView(
      reportId: reportId,
      lockedBy: lockedBy,
      lockedAt: lockedAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
      revision: revision,
    );
  }

  static StaffQueueEntry _entry(
    CitizenReportDto report,
    DateTime now,
    _StaffProjectionLookup lookup,
  ) {
    final analysis = report.analysisId == null ? null : lookup.analyses[report.analysisId!];
    final incident = report.linkedIncidentId == null
        ? null
        : lookup.incidents[report.linkedIncidentId!];
    final sourceRecords = <OpaqueEntityDto>[];
    if (incident != null) {
      for (final sourceId in incident.sourceRecordIds) {
        final record = lookup.sourceRecords[sourceId];
        if (record != null) sourceRecords.add(record);
      }
    }
    final media = <MediaRefDto>[];
    for (final mediaId in report.mediaIds) {
      final item = lookup.media[mediaId];
      if (item != null) media.add(item);
    }
    final publicRefs = <String>[];
    final originalRefs = <String>[];
    var privacyQueue = false;
    for (final item in media) {
      if (item.publicRef != null && item.privacyStatus == PrivacyStatus.safe) {
        publicRefs.add(item.publicRef!);
      }
      if (item.originalRef != null) originalRefs.add(item.originalRef!);
      if (item.privacyStatus == PrivacyStatus.pending ||
          item.privacyStatus == PrivacyStatus.manualReviewRequired ||
          item.privacyStatus == PrivacyStatus.failed ||
          item.privacyStatus == PrivacyStatus.processing) {
        privacyQueue = true;
      }
    }
    var sourceHealth = SourceHealth.fresh;
    final healths = <SourceHealth>{};
    for (final record in sourceRecords) {
      final raw = record.body['health'];
      final parsed = raw is String ? enumValues(SourceHealth.values)[raw] : null;
      if (parsed != null) healths.add(parsed);
      if (parsed == SourceHealth.unavailable || parsed == SourceHealth.quarantined) {
        sourceHealth = parsed!;
      } else if (parsed == SourceHealth.stale && sourceHealth == SourceHealth.fresh) {
        sourceHealth = SourceHealth.stale;
      }
    }
    final queues = <ReviewQueueType>{};
    final critical = report.status == ReportStatus.criticalReview ||
        report.riskLevel == RiskLevel.criticalSignal;
    if (critical) queues.add(ReviewQueueType.critical);
    if (report.riskLevel == RiskLevel.high) queues.add(ReviewQueueType.high);
    if (report.riskLevel == RiskLevel.low ||
        (analysis?.categoryConfidence != null && analysis!.categoryConfidence! < StaffOperationsPolicy.lowConfidenceCategoryThreshold)) {
      queues.add(ReviewQueueType.lowConfidence);
    }
    if (privacyQueue) queues.add(ReviewQueueType.privacy);
    final manualAi = report.manualReviewRequired ||
        analysis == null ||
        analysis.status != AiAnalysisStatus.complete;
    if (manualAi) queues.add(ReviewQueueType.manualAiError);
    if (lookup.abuseReportIds.contains(report.id)) queues.add(ReviewQueueType.abuse);
    if (lookup.reopenReportIds.contains(report.id)) queues.add(ReviewQueueType.high);
    if (!critical &&
        report.riskLevel != RiskLevel.high &&
        !queues.contains(ReviewQueueType.lowConfidence) &&
        !queues.contains(ReviewQueueType.privacy) &&
        !queues.contains(ReviewQueueType.abuse) &&
        !queues.contains(ReviewQueueType.manualAiError)) {
      queues.add(ReviewQueueType.normal);
    }
    if (queues.isEmpty) queues.add(ReviewQueueType.normal);

    final age = now.difference(report.createdAt);
    final priority = _priorityScore(report, analysis, queues, age);
    return StaffQueueEntry(
      report: report,
      queues: Set.unmodifiable(queues),
      age: age.isNegative ? Duration.zero : age,
      priorityScore: priority,
      analysis: analysis,
      incident: incident,
      sourceRecords: List.unmodifiable(sourceRecords),
      publicMediaRefs: List.unmodifiable(publicRefs),
      originalMediaRefs: List.unmodifiable(originalRefs),
      sourceHealth: sourceHealth,
      sourceConflict: healths.length > 1,
      lease: lookup.activeLease(report.id, now),
      duplicateConfidence: analysis?.duplicateConfidence,
    );
  }

  static bool _matches(StaffQueueEntry entry, StaffQueueFilters filters) {
    final report = entry.report;
    if (filters.category != null && report.category != filters.category) return false;
    if (filters.riskLevel != null && report.riskLevel != filters.riskLevel) return false;
    if (filters.status != null && report.status != filters.status) return false;
    if (filters.unitId != null) {
      final suggestedUnit = _suggestedUnit(entry.analysis);
      if (entry.incident?.responsibleUnitId != filters.unitId && suggestedUnit != filters.unitId) {
        return false;
      }
    }
    if (filters.minDuplicateConfidence != null &&
        (entry.duplicateConfidence ?? 0) < filters.minDuplicateConfidence!) {
      return false;
    }
    final q = _normalize(filters.search);
    if (q.isNotEmpty) {
      final haystack = _normalize([
        report.trackingNumber,
        report.category,
        report.status.name,
        report.id,
        entry.incident?.responsibleUnitId ?? '',
        ...entry.sourceRecords.map((item) => item.body['attribution']?.toString() ?? ''),
      ].join(' '));
      if (!haystack.contains(q)) return false;
    }
    return true;
  }

  static String? _suggestedUnit(AiAnalysisDto? analysis) {
    if (analysis == null) return null;
    for (final code in analysis.reasonCodes) {
      if (code.startsWith('unit:') && code.length > 5) return code.substring(5);
    }
    return null;
  }

  static void _sort(List<StaffQueueEntry> items, StaffQueueSort sort) {
    switch (sort) {
      case StaffQueueSort.priorityOldest:
        items.sort((a, b) {
          final byPriority = b.priorityScore.compareTo(a.priorityScore);
          if (byPriority != 0) return byPriority;
          return b.age.compareTo(a.age);
        });
        break;
      case StaffQueueSort.oldest:
        items.sort((a, b) => b.age.compareTo(a.age));
        break;
      case StaffQueueSort.newest:
        items.sort((a, b) => a.age.compareTo(b.age));
        break;
      case StaffQueueSort.duplicateProbability:
        items.sort((a, b) => (b.duplicateConfidence ?? -1).compareTo(a.duplicateConfidence ?? -1));
        break;
    }
  }

  static int _priorityScore(
    CitizenReportDto report,
    AiAnalysisDto? analysis,
    Set<ReviewQueueType> queues,
    Duration age,
  ) {
    var score = 0;
    if (queues.contains(ReviewQueueType.critical)) score += StaffOperationsPolicy.criticalPriorityWeight;
    if (report.riskLevel == RiskLevel.high) score += StaffOperationsPolicy.highPriorityWeight;
    if (queues.contains(ReviewQueueType.privacy)) score += StaffOperationsPolicy.privacyPriorityWeight;
    if (queues.contains(ReviewQueueType.manualAiError)) score += StaffOperationsPolicy.manualAiPriorityWeight;
    score += (analysis?.duplicateConfidence ?? 0) ~/ 5;
    score += age.inHours.clamp(0, StaffOperationsPolicy.maximumAgePriorityHours).toInt();
    return score;
  }


  static bool _leaseEventIsNewer(OpaqueEntityDto candidate, OpaqueEntityDto current) {
    final candidateAfter = candidate.body['after'];
    final currentAfter = current.body['after'];
    final candidateRevision = candidateAfter is Map<String, Object?>
        ? candidateAfter['revision']
        : null;
    final currentRevision = currentAfter is Map<String, Object?>
        ? currentAfter['revision']
        : null;
    if (candidateRevision is int && currentRevision is int && candidateRevision != currentRevision) {
      return candidateRevision > currentRevision;
    }
    return _eventAt(candidate).isAfter(_eventAt(current));
  }

  static DateTime _eventAt(OpaqueEntityDto event) {
    return DateTime.tryParse(event.body['at'] as String? ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }
}

final class _StaffProjectionLookup {
  _StaffProjectionLookup(AppSnapshotDto snapshot)
      : analyses = {for (final item in snapshot.payload.analyses) item.id: item},
        incidents = {for (final item in snapshot.payload.incidents) item.id: item},
        media = {for (final item in snapshot.payload.media) item.id: item},
        sourceRecords = {for (final item in snapshot.payload.sourceRecords) item.id: item} {
    for (final signal in snapshot.payload.corroborations) {
      if (signal.body['reopenReviewRequested'] != true) continue;
      final incidentId = signal.body['incidentId'];
      if (incidentId is! String) continue;
      final incident = incidents[incidentId];
      if (incident == null) continue;
      reopenReportIds.addAll(incident.reportIds);
    }
    for (final event in snapshot.payload.auditEvents) {
      final reportId = event.body['resourceId'];
      if (reportId is! String) continue;
      final after = event.body['after'];
      if ((after is Map<String, Object?> && after['rateLimitedToManualReview'] == true) ||
          event.body['action'] == 'abuse_review_requested') {
        abuseReportIds.add(reportId);
      }
      final action = event.body['action'];
      if (action != 'review_lease_acquired' &&
          action != 'review_lease_taken_over' &&
          action != 'review_lease_released') {
        continue;
      }
      final current = latestLeaseEvents[reportId];
      if (current == null || StaffOperationsProjection._leaseEventIsNewer(event, current)) {
        latestLeaseEvents[reportId] = event;
      }
    }
  }

  final Map<String, AiAnalysisDto> analyses;
  final Map<String, UrbanIncidentDto> incidents;
  final Map<String, MediaRefDto> media;
  final Map<String, OpaqueEntityDto> sourceRecords;
  final Map<String, OpaqueEntityDto> latestLeaseEvents = {};
  final Set<String> abuseReportIds = {};
  final Set<String> reopenReportIds = {};

  ReviewLeaseView? activeLease(String reportId, DateTime now) {
    final latest = latestLeaseEvents[reportId];
    if (latest == null || latest.body['action'] == 'review_lease_released') return null;
    final after = latest.body['after'];
    if (after is! Map<String, Object?>) return null;
    final lockedBy = after['lockedBy'];
    final lockedAt = DateTime.tryParse(after['lockedAt'] as String? ?? '');
    final expiresAt = DateTime.tryParse(after['expiresAt'] as String? ?? '');
    final revision = after['revision'];
    if (lockedBy is! String || lockedAt == null || expiresAt == null || revision is! int) {
      return null;
    }
    final lease = ReviewLeaseView(
      reportId: reportId,
      lockedBy: lockedBy,
      lockedAt: lockedAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
      revision: revision,
    );
    return lease.activeAt(now) ? lease : null;
  }
}

/// Revision-scoped staff projection index. UI surfaces that need dashboard,
/// queue and detail in the same frame should construct this once so 10k-record
/// lookups are built once instead of once per projection.
final class StaffOperationsProjectionIndex {
  StaffOperationsProjectionIndex(this.snapshot) : _lookup = _StaffProjectionLookup(snapshot);

  final AppSnapshotDto snapshot;
  final _StaffProjectionLookup _lookup;

  StaffDashboardMetrics dashboard(DateTime now) {
    final counts = {for (final type in ReviewQueueType.values) type: 0};
    var oldest = Duration.zero;
    for (final report in snapshot.payload.reports) {
      if (!StaffOperationsProjection._reviewableStatuses.contains(report.status) &&
          !_lookup.reopenReportIds.contains(report.id)) {
        continue;
      }
      final entry = StaffOperationsProjection._entry(report, now, _lookup);
      for (final type in entry.queues) {
        counts[type] = (counts[type] ?? 0) + 1;
      }
      final age = now.difference(report.createdAt);
      if (!age.isNegative && age > oldest) oldest = age;
    }
    var stale = 0;
    var unavailable = 0;
    for (final item in snapshot.payload.dataSourceHealth) {
      final raw = item.body['health'];
      final parsed = raw is String ? enumValues(SourceHealth.values)[raw] : null;
      if (parsed == SourceHealth.stale) stale += 1;
      if (parsed == SourceHealth.unavailable || parsed == SourceHealth.quarantined) {
        unavailable += 1;
      }
    }
    return StaffDashboardMetrics(
      queueCounts: Map.unmodifiable(counts),
      activeIncidentCount: snapshot.payload.incidents
          .where((item) => item.status == IncidentStatus.verifiedActive)
          .length,
      plannedWorkCount: snapshot.payload.municipalWorks
          .where((item) => item.status == WorkStatus.publishedPlanned)
          .length,
      staleSourceCount: stale,
      unavailableSourceCount: unavailable,
      oldestReviewAge: oldest,
      firstReviewMedian: StaffOperationsProjection._metricMedian(snapshot, 'first_review'),
      routingMedian: StaffOperationsProjection._metricMedian(snapshot, 'routing'),
      resolutionMedian: StaffOperationsProjection._metricMedian(snapshot, 'resolution'),
    );
  }

  StaffQueuePage queue(
    ReviewQueueType type, {
    required DateTime now,
    StaffQueueFilters filters = const StaffQueueFilters(),
  }) {
    final entries = <StaffQueueEntry>[];
    for (final report in snapshot.payload.reports) {
      if (!StaffOperationsProjection._reviewableStatuses.contains(report.status) &&
          !_lookup.reopenReportIds.contains(report.id)) {
        continue;
      }
      final entry = StaffOperationsProjection._entry(report, now, _lookup);
      if (!entry.queues.contains(type)) continue;
      if (!StaffOperationsProjection._matches(entry, filters)) continue;
      entries.add(entry);
    }
    StaffOperationsProjection._sort(entries, filters.sort);
    final pageSize = filters.pageSize
        .clamp(StaffOperationsPolicy.minimumPageSize, StaffOperationsPolicy.maximumPageSize)
        .toInt();
    final totalPages = entries.isEmpty ? 1 : ((entries.length + pageSize - 1) ~/ pageSize);
    final page = filters.page.clamp(1, totalPages).toInt();
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, entries.length).toInt();
    return StaffQueuePage(
      items: List.unmodifiable(entries.sublist(start, end)),
      total: entries.length,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  StaffQueueEntry? entryByReportId(String reportId, {required DateTime now}) {
    for (final report in snapshot.payload.reports) {
      if (report.id == reportId) {
        return StaffOperationsProjection._entry(report, now, _lookup);
      }
    }
    return null;
  }
}
