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
    clock = _FixedClock(DateTime.utc(2026, 8, 17, 16));
  });

  test('WP-17 GTFS gerçek-şema fixture normalize eder, bozuk satırı karantinaya alır', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final sources = SourceGovernanceProcessor(processor: core);

    final result = await sources.execute(
      SourceOperationCommand(
        actorId: _staffId,
        clientMutationId: 'wp17_gtfs_001',
        expectedRevision: seed.revision,
        action: SourceOperationAction.refreshGtfsSchema,
        payload: const {},
      ),
    );

    final gtfs = result.snapshot.payload.sourceRecords
        .where((item) => item.body['sourceId'] == 'transit_gtfs_schema')
        .toList(growable: false);
    expect(gtfs.where((item) => item.body['health'] == 'fresh'), hasLength(2));
    expect(gtfs.where((item) => item.body['health'] == 'quarantined'), hasLength(1));
    expect(
      gtfs.where((item) => item.body['health'] == 'fresh').every(
            (item) => (item.body['normalized'] as Map<String, Object?>)['entityKind'] == 'transit_stop',
          ),
      isTrue,
    );
    final health = result.snapshot.payload.dataSourceHealth
        .singleWhere((item) => item.body['sourceId'] == 'transit_gtfs_schema');
    expect(health.body['receivedCount'], 3);
    expect(health.body['acceptedCount'], 2);
    expect(health.body['quarantinedCount'], 1);
    expect(health.body['retryPolicy'], contains('backoff'));
  });

  test('WP-17 retry/backoff başarısızlığı stale cache korur ve circuit breaker açar', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final sources = SourceGovernanceProcessor(processor: core);

    final recovered = await sources.execute(
      SourceOperationCommand(
        actorId: _staffId,
        clientMutationId: 'wp17_retry_recover',
        expectedRevision: seed.revision,
        action: SourceOperationAction.refreshFixture,
        payload: const {
          'sourceId': 'traffic_events_fixture',
          'simulateTransientFailures': 2,
        },
      ),
    );
    final recoveredHealth = recovered.snapshot.payload.dataSourceHealth
        .singleWhere((item) => item.body['sourceId'] == 'traffic_events_fixture');
    expect(recoveredHealth.body['attemptCount'], 3);
    expect(recoveredHealth.body['health'], 'fresh');
    final cachedIds = recovered.snapshot.payload.sourceRecords
        .where((item) => item.body['sourceId'] == 'traffic_events_fixture')
        .map((item) => item.id)
        .toSet();

    final failed = await sources.execute(
      SourceOperationCommand(
        actorId: _staffId,
        clientMutationId: 'wp17_retry_fail',
        expectedRevision: recovered.snapshot.revision,
        action: SourceOperationAction.refreshFixture,
        payload: const {
          'sourceId': 'traffic_events_fixture',
          'simulateTransientFailures': 3,
        },
      ),
    );
    final failedHealth = failed.snapshot.payload.dataSourceHealth
        .singleWhere((item) => item.body['sourceId'] == 'traffic_events_fixture');
    expect(failedHealth.body['health'], 'unavailable');
    expect(failedHealth.body['attemptCount'], 3);
    expect(failedHealth.body['circuitState'], 'open');
    expect(failedHealth.body['staleCacheRetained'], isTrue);
    expect(
      failed.snapshot.payload.sourceRecords
          .where((item) => item.body['sourceId'] == 'traffic_events_fixture')
          .map((item) => item.id)
          .toSet(),
      cachedIds,
    );
  });

  test('WP-17 authority priority newer low-authority record over ownership authority yapmaz', () {
    expect(
      SourceAuthorityPolicy.shouldReplace(
        existingRank: SourceAuthorityRank.owningAuthority,
        existingUpdatedAt: DateTime.utc(2026, 8, 17, 10),
        incomingRank: SourceAuthorityRank.thirdPartyUnverified,
        incomingUpdatedAt: DateTime.utc(2026, 8, 17, 15),
      ),
      isFalse,
    );
    expect(
      SourceAuthorityPolicy.shouldReplace(
        existingRank: SourceAuthorityRank.licensedOpenData,
        existingUpdatedAt: DateTime.utc(2026, 8, 17, 10),
        incomingRank: SourceAuthorityRank.owningAuthority,
        incomingUpdatedAt: DateTime.utc(2026, 8, 17, 9),
      ),
      isTrue,
    );
  });

  test('WP-17 fixture import manageSources ister ve export provenance alanlarını korur', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final sources = SourceGovernanceProcessor(processor: core);
    await expectLater(
      sources.execute(
        SourceOperationCommand(
          actorId: _citizenId,
          clientMutationId: 'wp17_import_denied',
          expectedRevision: seed.revision,
          action: SourceOperationAction.importFixture,
          payload: const {
            'format': 'json',
            'sourceId': 'traffic_fixture',
            'content': '[{"externalId":"demo","sourceTimestamp":"2026-08-17T15:00:00Z"}]',
          },
        ),
      ),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.unauthorized)),
    );
    final csv = SourceFixtureExport.toCsv(seed.payload.sourceRecords);
    expect(csv, contains('sourceId'));
  });

  test('WP-17 yetkili manuel olay provenance taşır ve 153 mock gerçek entegrasyon gibi davranmaz', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final sources = SourceGovernanceProcessor(processor: core);

    final manual = await sources.execute(
      SourceOperationCommand(
        actorId: _staffId,
        clientMutationId: 'wp17_manual_001',
        expectedRevision: seed.revision,
        action: SourceOperationAction.manualActiveIncident,
        payload: const {
          'category': 'road_surface_damage',
          'unitId': 'unit_road_maintenance',
          'reason': 'Yetkili saha teyidi.',
          'latitude': 41.0082,
          'longitude': 28.9784,
        },
      ),
    );
    final manualRecord = manual.snapshot.payload.sourceRecords.lastWhere(
      (item) => item.body['sourceId'] == 'municipal_authorized_entry',
    );
    expect(manualRecord.body['sourceType'], 'manual_authorized');
    expect((manualRecord.body['provenance'] as Map<String, Object?>)['actorId'], _staffId);

    final mocked = await sources.execute(
      SourceOperationCommand(
        actorId: _staffId,
        clientMutationId: 'wp17_153_001',
        expectedRevision: manual.snapshot.revision,
        action: SourceOperationAction.sync153Mock,
        payload: const {
          'externalApplicationId': '153-DEMO-001',
          'statusSync': 'received_simulated',
          'linkedReportId': _reportId,
        },
      ),
    );
    final external = mocked.snapshot.payload.sourceRecords
        .singleWhere((item) => item.body['sourceId'] == 'external_153_mock');
    expect(external.body['integrationMode'], 'simulated_contract');
    expect(external.body['attribution'], contains('simüle'));
  });

  test('WP-18 rol matrisi rol dışı permission atamasını reddeder ve ikinci onay ister', () async {
    expect(
      () => RolePermissionMatrix.requireAllowed(UserRole.reviewer, const [Permission.manageUsers]),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.unauthorized)),
    );
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final admin = AdministrationProcessor(processor: core);
    await expectLater(
      admin.execute(
        AdministrationCommand(
          actorId: _staffId,
          clientMutationId: 'wp18_role_no_confirm',
          expectedRevision: seed.revision,
          action: AdministrationAction.updateUserAccess,
          payload: {
            'accountId': _citizen2Id,
            'role': enumWire(UserRole.reviewer),
            'unitId': null,
            'permissions': RolePermissionMatrix.permissionsFor(UserRole.reviewer).map(enumWire).toList(),
            'secondConfirmation': false,
          },
        ),
      ),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.validation)),
    );
  });

  test('WP-18 KVKK takip no üretir; hesap silme reauth ister ve yeni bildirimi bloke eder', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final admin = AdministrationProcessor(processor: core);

    final privacy = await admin.execute(
      AdministrationCommand(
        actorId: _citizenId,
        clientMutationId: 'wp18_privacy_001',
        expectedRevision: seed.revision,
        action: AdministrationAction.createPrivacyRequest,
        payload: const {
          'type': 'access',
          'note': 'Hakkımda tutulan demo verilerini görmek istiyorum.',
        },
      ),
    );
    expect(privacy.trackingNumber, startsWith('KV-2026-'));

    await expectLater(
      admin.execute(
        AdministrationCommand(
          actorId: _citizenId,
          clientMutationId: 'wp18_delete_no_reauth',
          expectedRevision: privacy.snapshot.revision,
          action: AdministrationAction.requestAccountDeletion,
          payload: const {'reauthVerified': false, 'confirmed': true},
        ),
      ),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.unauthorized)),
    );

    final deletion = await admin.execute(
      AdministrationCommand(
        actorId: _citizenId,
        clientMutationId: 'wp18_delete_001',
        expectedRevision: privacy.snapshot.revision,
        action: AdministrationAction.requestAccountDeletion,
        payload: const {'reauthVerified': true, 'confirmed': true},
      ),
    );
    expect(
      deletion.snapshot.payload.accounts.singleWhere((item) => item.id == _citizenId).deletionRequested,
      isTrue,
    );
    await expectLater(
      core.createReport(
        CreateReportCommand(
          actorId: _citizenId,
          clientMutationId: 'wp18_blocked_report',
          expectedRevision: deletion.snapshot.revision,
          category: 'lighting',
          description: 'Silme talebi sonrası bu bildirim kabul edilmemeli.',
          latitude: 41.01,
          longitude: 29.01,
        ),
      ),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.privacy)),
    );
  });

  test('WP-18 restriction yalnız kademeli, geçici karar insan onaylı ve itiraz insan incelemesine gider', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final admin = AdministrationProcessor(processor: core);

    await expectLater(
      admin.execute(
        AdministrationCommand(
          actorId: _staffId,
          clientMutationId: 'wp18_restrict_jump',
          expectedRevision: seed.revision,
          action: AdministrationAction.decideRestriction,
          payload: const {
            'accountId': _citizenId,
            'level': 'temporaryRestriction',
            'reason': 'Kademeli süreç atlanmamalı.',
            'confirmedByHuman': true,
          },
        ),
      ),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.validation)),
    );

    final warning = await admin.execute(
      AdministrationCommand(
        actorId: _staffId,
        clientMutationId: 'wp18_warning',
        expectedRevision: seed.revision,
        action: AdministrationAction.decideRestriction,
        payload: const {
          'accountId': _citizenId,
          'level': 'warning',
          'reason': 'Tekrarlanan düşük kaliteli gönderimler için insan uyarısı.',
          'confirmedByHuman': true,
        },
      ),
    );
    final restriction = warning.snapshot.payload.restrictions.last;
    final appeal = await admin.execute(
      AdministrationCommand(
        actorId: _citizenId,
        clientMutationId: 'wp18_appeal',
        expectedRevision: warning.snapshot.revision,
        action: AdministrationAction.appealRestriction,
        payload: {
          'restrictionId': restriction.id,
          'reason': 'Uyarının bağlamının yeniden incelenmesini istiyorum.',
        },
      ),
    );
    expect(appeal.snapshot.payload.restrictions.last.body['appealStatus'], 'human_review_required');
    expect(appeal.snapshot.payload.restrictions.last.body['permanent'], isFalse);
  });

  test('WP-18 audit export reason, active-role ve original-media erişim olayını taşır', () async {
    const originalId = 'media_usr_citizen_demo_001_wp18_original';
    final auditableSeed = codec.seal(
      seed.copyWith(
        checksum: 'sha256:unsealed',
        payload: seed.payload.copyWith(
          media: [
            ...seed.payload.media,
            MediaRefDto(
              id: 'media_usr_citizen_demo_001_wp18',
              privacyStatus: PrivacyStatus.safe,
              originalRef: 'media://$originalId',
              publicRef: null,
              mimeType: 'image/png',
            ),
          ],
        ),
      ),
    );
    final store = InMemorySnapshotStore(initial: auditableSeed, codec: codec);
    final core = SnapshotCommandProcessor(store: store, codec: codec, clock: clock);
    final audited = await core.recordOriginalMediaAccess(
      actorId: _staffId,
      mediaId: originalId,
      reason: 'İnceleme için özgün görsel doğrulaması.',
    );
    final events = audited.payload.auditEvents.where((item) => item.body['action'] == 'original_media_accessed');
    expect(events, isNotEmpty);
    expect(events.single.body['activeRoleContext'], enumWire(UserRole.demoSupervisor));
    expect(AuditExport.toCsv(events), contains('original_media_accessed'));
    expect(AuditExport.toCsv(events), contains('demo_supervisor'));
    expect(AuditExport.toJson(events), contains('İnceleme için özgün görsel'));
  });

  test('WP-18 başarısız otomasyon audit olayı yönetim uyarısına projekte edilir', () {
    final alertEvent = OpaqueEntityDto(
      id: 'audit_automation_demo',
      body: const {
        'id': 'audit_automation_demo',
        'actorId': _staffId,
        'activeRoleContext': 'demo_supervisor',
        'action': 'admin_alert',
        'resourceId': 'work_demo_001',
        'at': '2026-08-17T16:00:00Z',
        'reason': 'Demo clock transition failed.',
        'before': <String, Object?>{},
        'after': <String, Object?>{'alertCode': 'municipal_work_transition_failed'},
      },
    );
    final projected = seed.copyWith(
      payload: seed.payload.copyWith(auditEvents: [...seed.payload.auditEvents, alertEvent]),
    );
    expect(
      AdministrationProjection.alerts(projected, clock.nowUtc())
          .where((item) => item.kind == GovernanceAlertKind.automationFailure),
      isNotEmpty,
    );
  });
}

const _staffId = 'usr_supervisor_demo_001';
const _citizenId = 'usr_citizen_demo_001';
const _citizen2Id = 'usr_citizen_demo_002';
const _reportId = 'rpt_demo_0001';

final class _FixedClock implements Clock {
  const _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime nowUtc() => value;
}
