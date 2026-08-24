import 'package:kent_takip_domain/src/failure.dart';

DateTime requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    fail(FailureCode.validation, '$field UTC olmalıdır.', field: field);
  }
  return value;
}

String requireText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    fail(FailureCode.validation, '$field boş olamaz.', field: field);
  }
  return normalized;
}

int requireScore(int value, String field) {
  if (value < 0 || value > 100) {
    fail(FailureCode.validation, '$field 0–100 aralığında olmalıdır.', field: field);
  }
  return value;
}

String requireUuid(String value, String field) {
  final normalized = requireText(value, field).toLowerCase();
  final valid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(normalized);
  if (!valid) {
    fail(FailureCode.validation, '$field UUID olmalıdır.', field: field);
  }
  return normalized;
}

String requireTrackingNumber(String value, String field) {
  final normalized = requireText(value, field).toUpperCase();
  if (!RegExp(r'^KT-[0-9]{4}-[0-9]{6}$').hasMatch(normalized)) {
    fail(
      FailureCode.validation,
      '$field KT-YYYY-NNNNNN biçiminde olmalıdır.',
      field: field,
    );
  }
  return normalized;
}

final class GeoPoint {
  GeoPoint({
    required double latitude,
    required double longitude,
    this.district,
    this.neighborhood,
    this.outsideServiceArea = false,
  }) : latitude = _latitude(latitude),
       longitude = _longitude(longitude);

  final double latitude;
  final double longitude;
  final String? district;
  final String? neighborhood;
  final bool outsideServiceArea;

  static double _latitude(double value) {
    if (!value.isFinite || value < -90 || value > 90) {
      fail(FailureCode.validation, 'Geçersiz latitude.', field: 'latitude');
    }
    return value;
  }

  static double _longitude(double value) {
    if (!value.isFinite || value < -180 || value > 180) {
      fail(FailureCode.validation, 'Geçersiz longitude.', field: 'longitude');
    }
    return value;
  }
}

final class ExternalApplicationRef {
  ExternalApplicationRef({
    required String sourceSystem,
    required String externalApplicationId,
    required DateTime sourceUpdatedAt,
    required String syncStatus,
    this.lastSyncError,
  }) : sourceSystem = requireText(sourceSystem, 'sourceSystem'),
       externalApplicationId = requireText(
         externalApplicationId,
         'externalApplicationId',
       ),
       sourceUpdatedAt = requireUtc(sourceUpdatedAt, 'sourceUpdatedAt'),
       syncStatus = requireText(syncStatus, 'syncStatus');

  final String sourceSystem;
  final String externalApplicationId;
  final DateTime sourceUpdatedAt;
  final String syncStatus;
  final String? lastSyncError;
}

final class ExternalWorkOrderRef {
  ExternalWorkOrderRef({
    required String sourceSystem,
    required String externalWorkOrderId,
    required DateTime sourceUpdatedAt,
    required String syncStatus,
    this.lastSyncError,
  }) : sourceSystem = requireText(sourceSystem, 'sourceSystem'),
       externalWorkOrderId = requireText(
         externalWorkOrderId,
         'externalWorkOrderId',
       ),
       sourceUpdatedAt = requireUtc(sourceUpdatedAt, 'sourceUpdatedAt'),
       syncStatus = requireText(syncStatus, 'syncStatus');

  final String sourceSystem;
  final String externalWorkOrderId;
  final DateTime sourceUpdatedAt;
  final String syncStatus;
  final String? lastSyncError;
}

final class SlaClock {
  SlaClock({
    required DateTime startedAt,
    required DateTime targetAt,
    this.pausedAt,
    this.delayReason,
  }) : startedAt = requireUtc(startedAt, 'startedAt'),
       targetAt = requireUtc(targetAt, 'targetAt') {
    if (!targetAt.isAfter(startedAt)) {
      fail(FailureCode.validation, 'SLA hedefi başlangıçtan sonra olmalıdır.');
    }
    if (pausedAt != null) {
      requireUtc(pausedAt!, 'pausedAt');
    }
  }

  final DateTime startedAt;
  final DateTime targetAt;
  final DateTime? pausedAt;
  final String? delayReason;
}

final class ResolutionEvidence {
  ResolutionEvidence({
    required String explanation,
    required DateTime resolvedAt,
    this.publicMediaRef,
    this.citizenConfirmed,
  }) : explanation = requireText(explanation, 'explanation'),
       resolvedAt = requireUtc(resolvedAt, 'resolvedAt');

  final String explanation;
  final DateTime resolvedAt;
  final String? publicMediaRef;
  final bool? citizenConfirmed;
}
