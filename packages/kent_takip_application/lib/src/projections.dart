import 'package:kent_takip_application/src/municipal_work.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

final class VisibleMapPin {
  const VisibleMapPin({
    required this.id,
    required this.kind,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    this.trackingNumber,
    this.sourceLabel = 'İBB Kent Takip',
    this.freshness = SourceHealth.fresh,
    this.verified = false,
    this.updatedAt,
    this.responsibleUnitId,
  });

  final String id;
  final PinKind kind;
  final String category;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final String? trackingNumber;
  final String sourceLabel;
  final SourceHealth freshness;
  final bool verified;
  final DateTime? updatedAt;
  final String? responsibleUnitId;
}

final class OfficialAlertPin {
  const OfficialAlertPin({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.authority,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final String authority;
  final DateTime updatedAt;
}

final class MapCluster {
  const MapCluster({required this.latitude, required this.longitude, required this.pins});
  final double latitude;
  final double longitude;
  final List<VisibleMapPin> pins;
}

final class SlaEstimate {
  const SlaEstimate({required this.minBusinessDays, required this.maxBusinessDays});
  final int minBusinessDays;
  final int maxBusinessDays;

  String get label => '$minBusinessDays–$maxBusinessDays iş günü';
}

final class CitizenReportDetail {
  const CitizenReportDetail({
    required this.report,
    required this.timeline,
    required this.sla,
    required this.responsibleUnitId,
    required this.sourceHealth,
    required this.provenance,
    this.slaTargetAt,
    this.reestimatedMinAt,
    this.reestimatedMaxAt,
    this.resolutionExplanation,
    this.resolutionPublicMediaRef,
  });

  final CitizenReportDto report;
  final List<OpaqueEntityDto> timeline;
  final SlaEstimate sla;
  final String? responsibleUnitId;
  final SourceHealth sourceHealth;
  final String provenance;
  final DateTime? slaTargetAt;
  final DateTime? reestimatedMinAt;
  final DateTime? reestimatedMaxAt;
  final String? resolutionExplanation;
  final String? resolutionPublicMediaRef;
}

final class MemoizedMapProjectionService {
  int? _revision;
  String? _viewerId;
  bool? _staff;
  int? _clockSignature;
  List<VisibleMapPin>? _pins;
  List<MapCluster>? _clusters;
  int? _alertsRevision;
  List<OfficialAlertPin>? _alerts;

  List<VisibleMapPin> project(
    AppSnapshotDto snapshot, {
    String? viewerId,
    bool staff = false,
    DateTime? nowUtc,
  }) {
    final signature = _workClockSignature(snapshot, nowUtc);
    final sameKey = _revision == snapshot.revision &&
        _viewerId == viewerId &&
        _staff == staff &&
        _clockSignature == signature;
    if (!sameKey || _pins == null) {
      _revision = snapshot.revision;
      _viewerId = viewerId;
      _staff = staff;
      _clockSignature = signature;
      _pins = DemoProjections.visiblePins(
        snapshot,
        viewerId: viewerId,
        staff: staff,
        nowUtc: nowUtc,
      );
      _clusters = null;
    }
    return _pins!;
  }

  List<MapCluster> clusters(Iterable<VisibleMapPin> pins) {
    if (identical(pins, _pins) && _clusters != null) return _clusters!;
    final values = DemoProjections.clusters(pins);
    if (identical(pins, _pins)) _clusters = values;
    return values;
  }

  List<OfficialAlertPin> officialAlerts(AppSnapshotDto snapshot) {
    if (_alertsRevision != snapshot.revision || _alerts == null) {
      _alertsRevision = snapshot.revision;
      _alerts = DemoProjections.officialAlerts(snapshot);
    }
    return _alerts!;
  }

  void clear() {
    _revision = null;
    _viewerId = null;
    _staff = null;
    _clockSignature = null;
    _pins = null;
    _clusters = null;
    _alertsRevision = null;
    _alerts = null;
  }

  int _workClockSignature(AppSnapshotDto snapshot, DateTime? nowUtc) {
    if (nowUtc == null || snapshot.payload.municipalWorks.isEmpty) return 0;
    return Object.hashAll(
      snapshot.payload.municipalWorks.map((work) => Object.hash(
            work.id,
            MunicipalWorkProjection.effectiveStatus(work, nowUtc),
          )),
    );
  }
}

final class MapProjectionService {
  const MapProjectionService();

  List<VisibleMapPin> project(
    AppSnapshotDto snapshot, {
    String? viewerId,
    bool staff = false,
    DateTime? nowUtc,
  }) => DemoProjections.visiblePins(
    snapshot,
    viewerId: viewerId,
    staff: staff,
    nowUtc: nowUtc,
  );

  List<OfficialAlertPin> officialAlerts(AppSnapshotDto snapshot) =>
      DemoProjections.officialAlerts(snapshot);

  List<MapCluster> cluster(Iterable<VisibleMapPin> pins) =>
      DemoProjections.clusters(pins);
}

abstract final class DemoProjections {
  static List<CitizenReportDto> ownedReports(
    AppSnapshotDto snapshot,
    String ownerId,
  ) {
    return snapshot.payload.reports
        .where((report) => report.ownerId == ownerId)
        .toList(growable: false);
  }

  static List<OpaqueEntityDto> ownedNotifications(
    AppSnapshotDto snapshot,
    String ownerId, {
    bool unreadOnly = false,
  }) {
    final values = snapshot.payload.notifications.where((item) =>
        item.body['recipientId'] == ownerId &&
        (!unreadOnly || item.body['readAt'] == null)).toList(growable: false);
    values.sort((left, right) =>
        (right.body['createdAt'] as String? ?? '').compareTo(
          left.body['createdAt'] as String? ?? '',
        ));
    return values;
  }

  static CitizenReportDetail? ownedReportDetail(
    AppSnapshotDto snapshot,
    String ownerId,
    String reportId,
  ) {
    CitizenReportDto? report;
    for (final item in snapshot.payload.reports) {
      if (item.id == reportId && item.ownerId == ownerId) report = item;
    }
    if (report == null) return null;
    UrbanIncidentDto? incident;
    for (final item in snapshot.payload.incidents) {
      if (item.id == report.linkedIncidentId) incident = item;
    }
    var health = SourceHealth.fresh;
    if (incident != null) {
      for (final sourceId in incident.sourceRecordIds) {
        for (final record in snapshot.payload.sourceRecords) {
          if (record.id != sourceId) continue;
          final raw = record.body['health'];
          if (raw is String) {
            health = enumValues(SourceHealth.values)[raw] ?? SourceHealth.unavailable;
          }
        }
      }
    }
    return CitizenReportDetail(
      report: report,
      timeline: timelineFor(snapshot, report.id),
      sla: slaFor(report.category),
      responsibleUnitId: incident?.responsibleUnitId,
      sourceHealth: health,
      provenance: incident == null
          ? 'Vatandaş sinyali · henüz kamusal olay değil'
          : 'İBB tarafından doğrulanan olay bağlantısı',
      slaTargetAt: incident?.slaTargetAt,
      reestimatedMinAt: incident?.reestimatedMinAt,
      reestimatedMaxAt: incident?.reestimatedMaxAt,
      resolutionExplanation:
          report.resolutionExplanation ?? incident?.resolutionExplanation,
      resolutionPublicMediaRef:
          report.resolutionPublicMediaRef ?? incident?.resolutionPublicMediaRef,
    );
  }

  static SlaEstimate slaFor(String category) => switch (category) {
    'road_surface_damage' => const SlaEstimate(minBusinessDays: 2, maxBusinessDays: 4),
    'water_infrastructure' => const SlaEstimate(minBusinessDays: 1, maxBusinessDays: 2),
    'traffic_signal' || 'lighting' => const SlaEstimate(minBusinessDays: 1, maxBusinessDays: 3),
    _ => const SlaEstimate(minBusinessDays: 2, maxBusinessDays: 5),
  };

  static List<CitizenReportDto> reviewQueue(AppSnapshotDto snapshot) {
    const visible = {
      ReportStatus.received,
      ReportStatus.aiReview,
      ReportStatus.ibbReview,
      ReportStatus.manualReview,
      ReportStatus.criticalReview,
    };
    return snapshot.payload.reports
        .where((report) => visible.contains(report.status))
        .toList(growable: false);
  }

  static List<OpaqueEntityDto> timelineFor(
    AppSnapshotDto snapshot,
    String reportId,
  ) {
    return snapshot.payload.timeline
        .where((event) => event.body['resourceId'] == reportId)
        .toList(growable: false)
      ..sort((left, right) =>
          (left.body['at']! as String).compareTo(right.body['at']! as String));
  }

  static List<VisibleMapPin> visiblePins(
    AppSnapshotDto snapshot, {
    String? viewerId,
    bool staff = false,
    DateTime? nowUtc,
  }) {
    final lookup = _MapProjectionLookup(snapshot);
    final pins = <VisibleMapPin>[];
    for (final incident in snapshot.payload.incidents) {
      if (incident.status != IncidentStatus.verifiedActive) continue;
      pins.add(
        VisibleMapPin(
          id: incident.id,
          kind: PinKind.verifiedActive,
          category: incident.category,
          latitude: incident.latitude,
          longitude: incident.longitude,
          locationLabel: _location(incident.latitude, incident.longitude),
          sourceLabel: incident.sourceRecordIds.isEmpty
              ? 'İBB doğrulaması'
              : lookup.sourceLabel(incident.sourceRecordIds),
          freshness: lookup.sourceHealth(incident.sourceRecordIds),
          verified: true,
          updatedAt: incident.updatedAt,
          responsibleUnitId: incident.responsibleUnitId,
        ),
      );
    }
    for (final work in snapshot.payload.municipalWorks) {
      final status = nowUtc == null
          ? work.status
          : MunicipalWorkProjection.effectiveStatus(work, nowUtc);
      if (status != WorkStatus.publishedPlanned && status != WorkStatus.active) {
        continue;
      }
      pins.add(
        VisibleMapPin(
          id: work.id,
          kind: status == WorkStatus.active
              ? PinKind.verifiedActive
              : PinKind.publishedPlanned,
          category: work.category,
          latitude: work.latitude,
          longitude: work.longitude,
          locationLabel: _location(work.latitude, work.longitude),
          sourceLabel: 'Planlanan belediye çalışması',
          verified: true,
          updatedAt: work.startsAt,
          responsibleUnitId: work.responsibleUnitId,
        ),
      );
    }
    for (final report in snapshot.payload.reports) {
      if (!staff && viewerId != report.ownerId) continue;
      if ({
        ReportStatus.resolved,
        ReportStatus.merged,
        ReportStatus.rejected,
        ReportStatus.outOfScope,
      }.contains(report.status)) {
        continue;
      }
      if (report.linkedIncidentId != null) {
        final linkedStatus = lookup.incidentStatus[report.linkedIncidentId!];
        if (linkedStatus == IncidentStatus.verifiedActive ||
            linkedStatus == IncidentStatus.resolved ||
            linkedStatus == IncidentStatus.archived) {
          continue;
        }
      }
      final critical = staff &&
          (report.status == ReportStatus.criticalReview ||
              report.riskLevel == RiskLevel.criticalSignal);
      pins.add(
        VisibleMapPin(
          id: report.id,
          kind: critical ? PinKind.criticalReview : PinKind.pendingVerification,
          category: report.category,
          latitude: report.latitude,
          longitude: report.longitude,
          locationLabel: _location(report.latitude, report.longitude),
          trackingNumber: report.trackingNumber,
          sourceLabel: 'Vatandaş bildirimi',
          verified: false,
          updatedAt: report.updatedAt,
        ),
      );
    }
    return List.unmodifiable(pins);
  }

  static String _location(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  static List<OfficialAlertPin> officialAlerts(AppSnapshotDto snapshot) {
    final lookup = _MapProjectionLookup(snapshot);
    final alerts = <OfficialAlertPin>[];
    for (final record in snapshot.payload.sourceRecords) {
      if (record.body['officialAlert'] != true) continue;
      final authorityId = record.body['authorityId'];
      if (authorityId is! String) continue;
      final authority = lookup.officialAuthorityNames[authorityId];
      if (authority == null) continue;
      final latitude = record.body['latitude'];
      final longitude = record.body['longitude'];
      final updatedAt = DateTime.tryParse(record.body['sourceUpdatedAt'] as String? ?? '');
      if (latitude is! num || longitude is! num || updatedAt == null) continue;
      alerts.add(
        OfficialAlertPin(
          id: record.id,
          title: record.body['title'] as String? ?? 'Resmî kritik uyarı',
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
          authority: authority,
          updatedAt: updatedAt.toUtc(),
        ),
      );
    }
    return List.unmodifiable(alerts);
  }

  static List<MapCluster> clusters(
    Iterable<VisibleMapPin> pins, {
    double cellDegrees = 0.015,
  }) {
    final groups = <String, List<VisibleMapPin>>{};
    for (final pin in pins) {
      final x = (pin.latitude / cellDegrees).floor();
      final y = (pin.longitude / cellDegrees).floor();
      groups.putIfAbsent('$x:$y', () => []).add(pin);
    }
    return groups.values.map((items) {
      final lat = items.fold<double>(0, (sum, item) => sum + item.latitude) / items.length;
      final lon = items.fold<double>(0, (sum, item) => sum + item.longitude) / items.length;
      return MapCluster(latitude: lat, longitude: lon, pins: List.unmodifiable(items));
    }).toList(growable: false);
  }
}

final class _MapProjectionLookup {
  _MapProjectionLookup(AppSnapshotDto snapshot)
      : incidentStatus = {
          for (final incident in snapshot.payload.incidents) incident.id: incident.status,
        },
        sourceRecords = {
          for (final record in snapshot.payload.sourceRecords) record.id: record,
        },
        officialAuthorityNames = {
          for (final item in snapshot.payload.sourceAuthorities)
            if (item.body['officialAlertAuthority'] == true)
              item.id: item.body['displayName'] as String? ?? item.id,
        };

  final Map<String, IncidentStatus> incidentStatus;
  final Map<String, OpaqueEntityDto> sourceRecords;
  final Map<String, String> officialAuthorityNames;

  String sourceLabel(Iterable<String> ids) {
    for (final id in ids) {
      final record = sourceRecords[id];
      if (record != null) {
        return record.body['attribution'] as String? ?? 'Yetkili veri kaynağı';
      }
    }
    return 'Yetkili veri kaynağı';
  }

  SourceHealth sourceHealth(Iterable<String> ids) {
    var health = SourceHealth.fresh;
    for (final id in ids) {
      final raw = sourceRecords[id]?.body['health'];
      final parsed = raw is String ? enumValues(SourceHealth.values)[raw] : null;
      if (parsed == SourceHealth.quarantined || parsed == SourceHealth.unavailable) {
        return parsed!;
      }
      if (parsed == SourceHealth.stale) health = SourceHealth.stale;
    }
    return health;
  }
}
