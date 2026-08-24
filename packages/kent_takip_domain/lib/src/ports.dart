import 'dart:async';
import 'dart:typed_data';

import 'package:kent_takip_domain/src/entities.dart';
import 'package:kent_takip_domain/src/events.dart';
import 'package:kent_takip_domain/src/snapshot.dart';
import 'package:kent_takip_domain/src/value_objects.dart';

abstract interface class Clock {
  DateTime nowUtc();
}

abstract interface class IdGenerator {
  String nextId(String prefix);

  String nextTrackingNumber(String prefix);
}

abstract interface class SnapshotRepository {
  Future<DomainSnapshot> read();

  Future<DomainSnapshot> update(
    DomainSnapshot Function(DomainSnapshot current) mutation,
  );
}

abstract interface class ReportRepository {
  Stream<List<CitizenReport>> watchOwned(String ownerId);

  Future<CitizenReport> findById(String id);

  Future<CitizenReport> save(CitizenReport report);
}

abstract interface class IncidentRepository {
  Future<UrbanIncident> findById(String id);

  Future<UrbanIncident> save(UrbanIncident incident);
}

abstract interface class MunicipalWorkRepository {
  Future<MunicipalWork> findById(String id);

  Future<MunicipalWork> save(MunicipalWork work);
}

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchFor(String recipientId);
}

abstract interface class AuditRepository {
  Future<void> append(AuditEvent event);
}

abstract interface class DataSourceRepository {
  Stream<List<DataSourceHealth>> watchHealth();
}

abstract interface class LocationService {
  Future<GeoPoint> currentLocation();

  Future<String> reverseGeocode(GeoPoint point);
}

abstract interface class MapGateway {
  Future<Uri> externalMapUri(GeoPoint point);
}

abstract interface class NotificationGateway {
  Future<void> deliver(AppNotification notification);
}

abstract interface class SourceAdapter {
  String get sourceId;

  Future<List<SourceRecord>> fetchSince(DateTime sinceUtc);
}

abstract interface class DomainEventSink {
  Future<void> publish(DomainEvent event);
}

abstract interface class PrivacyRequestRepository {
  Future<PrivacyRequest> submit(PrivacyRequest request);
}

abstract interface class AiAnalysisService {
  Future<AiAnalysis> analyze({
    required String? mediaId,
    required String description,
    required GeoPoint location,
    required DateTime capturedAt,
  });
}

abstract interface class MediaStore {
  Future<void> put(String id, Uint8List bytes);

  Future<Uint8List?> get(String id);

  Future<void> delete(String id);
}
