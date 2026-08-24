import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:test/test.dart';

void main() {
  test('unknown enum fails closed', () {
    expect(
      () => AccountDto.fromObject({
        'id': 'account-001',
        'role': 'super_user',
        'permissions': <Object?>[],
        'unitId': null,
        'deletionRequested': false,
      }, 'account'),
      throwsA(
        isA<DomainFailure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validation,
        ),
      ),
    );
  });

  test('camelCase enums serialize as snake_case', () {
    expect(enumWire(UserRole.demoSupervisor), 'demo_supervisor');
    expect(enumWire(Permission.viewOriginalMedia), 'view_original_media');
  });

  test('non UTC timestamps are rejected', () {
    expect(
      () => expectUtcDate('2026-08-17T11:00:00+03:00', 'createdAt'),
      throwsA(isA<DomainFailure>()),
    );
  });

  test('WGS84 coordinate system is mandatory', () {
    expect(
      () => CitizenReportDto.fromObject({
        'id': 'report-001',
        'trackingNumber': 'KT-2026-000001',
        'ownerId': 'owner-001',
        'status': 'received',
        'category': 'road_surface_damage',
        'location': {
          'latitude': 41.0,
          'longitude': 29.0,
          'coordinateSystem': 'EPSG:3857',
        },
        'createdAt': '2026-08-17T08:00:00.000Z',
        'updatedAt': '2026-08-17T08:00:00.000Z',
        'clientMutationId': 'mutation-001',
        'mediaIds': <Object?>[],
        'analysisId': null,
        'linkedIncidentId': null,
        'manualReviewRequired': false,
        'riskLevel': 'medium',
        'humanDecisionReason': null,
        'resolutionExplanation': null,
        'resolvedAt': null,
        'resolutionPublicMediaRef': null,
      }, 'report'),
      throwsA(isA<DomainFailure>()),
    );
  });

  test('auxiliary JSON is deeply immutable', () {
    final values = <Object?>['first'];
    final dto = OpaqueEntityDto(
      id: 'entity-001',
      body: {'id': 'entity-001', 'values': values},
    );

    values.add('second');

    expect(dto.body['values'], ['first']);
  });
}
