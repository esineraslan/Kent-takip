import 'package:kent_takip_domain/src/failure.dart';
import 'package:kent_takip_domain/src/value_objects.dart';

enum DomainEventType {
  reportReceived,
  reportStatusChanged,
  reportMerged,
  incidentVerified,
  incidentResolved,
  workPublished,
  workCompleted,
  additionalInfoRequested,
  privacyRequestReceived,
  accountRestricted,
  demoReset,
}

final class DomainEvent {
  DomainEvent({
    required String id,
    required this.type,
    required String aggregateId,
    required DateTime occurredAt,
    required Map<String, Object?> data,
  }) : id = requireText(id, 'id'),
       aggregateId = requireText(aggregateId, 'aggregateId'),
       occurredAt = requireUtc(occurredAt, 'occurredAt'),
       data = Map<String, Object?>.unmodifiable(data) {
    if (data.keys.any((key) => key.trim().isEmpty)) {
      fail(FailureCode.validation, 'Domain event veri anahtarı boş olamaz.');
    }
  }

  final String id;
  final DomainEventType type;
  final String aggregateId;
  final DateTime occurredAt;
  final Map<String, Object?> data;
}
