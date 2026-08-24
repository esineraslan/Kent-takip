import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_demo_server/kent_takip_demo_server.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late SnapshotCodec codec;
  late AppSnapshotDto seed;
  late InMemorySnapshotStore store;
  late KentTakipDemoServer server;

  setUp(() async {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.decode(
      await File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json')
          .readAsString(),
    );
    store = InMemorySnapshotStore(initial: seed, codec: codec);
    server = KentTakipDemoServer(
      store: store,
      mediaStore: InMemoryMediaStore(),
      codec: codec,
      clock: _FixedClock(DateTime.utc(2026, 8, 17, 13)),
    );
  });

  test('health ve readiness revision döndürür', () async {
    final live = await server.handler(_request('GET', '/health/live'));
    final ready = await server.handler(_request('GET', '/health/ready'));
    expect(live.statusCode, 200);
    expect(ready.statusCode, 200);
    expect((await _json(ready))['revision'], seed.revision);
  });

  test('çift retry tek report üretir', () async {
    final body = _createBody(seed.revision);
    final first = await server.handler(
      _request('POST', '/v1/commands/report', credential: 'demo-citizen-001', body: body),
    );
    final retry = await server.handler(
      _request('POST', '/v1/commands/report', credential: 'demo-citizen-001', body: body),
    );

    expect(first.statusCode, 201);
    expect(retry.statusCode, 200);
    expect((await _json(retry))['replayed'], isTrue);
    expect((await store.read()).payload.reports, hasLength(seed.payload.reports.length + 1));
  });

  test('başka aktör clientMutationId replay edemez', () async {
    final body = _createBody(seed.revision);
    final first = await server.handler(
      _request(
        'POST',
        '/v1/commands/report',
        credential: 'demo-citizen-001',
        body: body,
      ),
    );
    final beforeAudit = (await store.read()).payload.auditEvents.length;
    final stolenReplay = await server.handler(
      _request(
        'POST',
        '/v1/commands/report',
        credential: 'demo-citizen-002',
        body: {...body, 'actorId': 'usr_citizen_demo_002'},
      ),
    );

    expect(first.statusCode, 201);
    expect(stolenReplay.statusCode, 403);
    expect((await store.read()).payload.auditEvents.length, beforeAudit + 1);
  });

  test('eşzamanlı iki writer aynı revisionı sessizce ezemez', () async {
    final responses = await Future.wait([
      server.handler(
        _request(
          'POST',
          '/v1/commands/report',
          credential: 'demo-citizen-001',
          body: _createBody(seed.revision),
        ),
      ),
      server.handler(
        _request(
          'POST',
          '/v1/commands/report',
          credential: 'demo-citizen-002',
          body: {
            ..._createBody(seed.revision),
            'actorId': 'usr_citizen_demo_002',
            'clientMutationId': 'server_create_concurrent_002',
          },
        ),
      ),
    ]);

    expect(responses.map((response) => response.statusCode), containsAll([201, 409]));
    expect(
      (await store.read()).payload.reports,
      hasLength(seed.payload.reports.length + 1),
    );
  });

  test('iki citizen pending görünürlüğü ayrışır, doğrulama sonrası birleşir', () async {
    final createdResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/report',
        credential: 'demo-citizen-001',
        body: _createBody(seed.revision),
      ),
    );
    final created = await _json(createdResponse);
    final ownerBefore = await _snapshot(server, 'demo-citizen-001');
    final otherBefore = await _snapshot(server, 'demo-citizen-002');
    expect(() => codec.validate(ownerBefore), returnsNormally);
    expect(() => codec.validate(otherBefore), returnsNormally);
    expect(ownerBefore.payload.reports.any((item) => item.id == created['resourceId']), isTrue);
    expect(otherBefore.payload.reports.any((item) => item.id == created['resourceId']), isFalse);
    expect(otherBefore.payload.media, isEmpty);
    expect(otherBefore.payload.analyses, isEmpty);
    expect(otherBefore.payload.corroborations, isEmpty);

    final leaseResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/review-lease',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_lease_verify_001',
          'expectedRevision': ownerBefore.revision,
          'reportId': created['resourceId'],
          'action': 'acquire',
        },
      ),
    );
    expect(leaseResponse.statusCode, 200);
    final lease = await _json(leaseResponse);
    final verifiedResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/verify',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_verify_001',
          'expectedRevision': lease['revision'],
          'reportId': created['resourceId'],
          'category': 'road_surface_damage',
          'unitId': 'unit_road_maintenance',
          'reason': 'Yetkili insan doğrulaması ve birim yönlendirmesi.',
          'publicPreviewApproved': true,
        },
      ),
    );
    expect(verifiedResponse.statusCode, 200);
    final otherAfter = await _snapshot(server, 'demo-citizen-002');
    final staffAfter = await _snapshot(server, 'demo-staff-supervisor');
    expect(() => codec.validate(otherAfter), returnsNormally);
    expect(() => codec.validate(staffAfter), returnsNormally);
    expect(otherAfter.revision, staffAfter.revision);
    expect(
      otherAfter.payload.incidents.any((item) => item.id == (await _json(verifiedResponse))['resourceId']),
      isTrue,
    );
  });

  test('stale staff kararı 409 ile current snapshot ve retry bilgisi döndürür', () async {
    final createdResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/report',
        credential: 'demo-citizen-001',
        body: _createBody(seed.revision),
      ),
    );
    final created = await _json(createdResponse);
    final response = await server.handler(
      _request(
        'POST',
        '/v1/commands/verify',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_verify_stale',
          'expectedRevision': seed.revision,
          'reportId': created['resourceId'],
          'category': 'road_surface_damage',
          'unitId': 'unit_road_maintenance',
          'reason': 'Stale karar denemesi.',
          'publicPreviewApproved': true,
        },
      ),
    );
    final conflict = await _json(response);
    expect(response.statusCode, 409);
    expect(conflict['retryable'], isTrue);
    expect(conflict['current'], isA<Map<String, Object?>>());
  });

  test('yetkisiz komut reddedilir ve audit edilir', () async {
    final before = (await store.read()).payload.auditEvents.length;
    final response = await server.handler(
      _request(
        'POST',
        '/v1/commands/verify',
        credential: 'demo-citizen-001',
        body: {
          'actorId': 'usr_citizen_demo_001',
          'clientMutationId': 'unauthorized_verify',
          'expectedRevision': seed.revision,
          'reportId': 'rpt_demo_0001',
          'category': 'road_surface_damage',
          'unitId': 'unit_road_maintenance',
          'reason': 'Yetkisiz karar.',
          'publicPreviewApproved': true,
        },
      ),
    );
    expect(response.statusCode, 403);
    final after = await store.read();
    expect(after.payload.auditEvents.length, before + 1);
    expect(after.payload.auditEvents.last.body['action'], 'denied_verify_report');
  });

  test('WP-15 HTTP field-operation saha ataması ve simulated work-order üretir', () async {
    final leaseResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/review-lease',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_wp15_lease',
          'expectedRevision': seed.revision,
          'reportId': 'rpt_demo_0001',
          'action': 'acquire',
        },
      ),
    );
    final lease = await _json(leaseResponse);
    final verifiedResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/verify',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_wp15_verify',
          'expectedRevision': lease['revision'],
          'reportId': 'rpt_demo_0001',
          'category': 'road_surface_damage',
          'unitId': 'unit_road_maintenance',
          'reason': 'WP-15 saha akışı için insan doğrulaması.',
          'publicPreviewApproved': true,
        },
      ),
    );
    expect(verifiedResponse.statusCode, 200);
    final verified = await _json(verifiedResponse);
    final fieldResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/field-operation',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_wp15_assign',
          'expectedRevision': verified['revision'],
          'incidentId': verified['resourceId'],
          'action': 'assign_field',
          'reason': 'Demo saha ekibi atandı.',
          'fieldTeamId': 'team_demo_road_01',
        },
      ),
    );
    expect(fieldResponse.statusCode, 200);
    final current = await store.read();
    final incident = current.payload.incidents.singleWhere((item) => item.id == verified['resourceId']);
    final report = current.payload.reports.singleWhere((item) => item.id == 'rpt_demo_0001');
    expect(report.status, ReportStatus.fieldAssigned);
    expect(incident.fieldTeamId, 'team_demo_road_01');
    expect(incident.workOrderRefs.single.syncStatus, 'simulated');
  });

  test('WP-16 HTTP municipal-work draft public değildir ve impact endpoint state üretir', () async {
    final draftResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/municipal-work',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_wp16_draft',
          'expectedRevision': seed.revision,
          'action': 'save_draft',
          'category': 'road_maintenance',
          'latitude': 41.0257,
          'longitude': 29.0156,
          'startsAt': '2026-08-18T08:00:00.000Z',
          'expectedEndsAt': '2026-08-18T14:00:00.000Z',
          'responsibleUnitId': 'unit_road_maintenance',
          'explanation': 'Üsküdar sahil yolunda planlı bakım.',
          'areaRadiusMeters': 250,
        },
      ),
    );
    expect(draftResponse.statusCode, 200);
    final draft = await _json(draftResponse);
    final workId = draft['resourceId'] as String;
    var current = await store.read();
    expect(current.payload.municipalWorks.singleWhere((w) => w.id == workId).status, WorkStatus.draft);

    final impactResponse = await server.handler(
      _request(
        'POST',
        '/v1/commands/municipal-work',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_wp16_impact',
          'expectedRevision': draft['revision'],
          'action': 'analyze_impact',
          'workId': workId,
        },
      ),
    );
    expect(impactResponse.statusCode, 200);
    current = await store.read();
    final work = current.payload.municipalWorks.singleWhere((w) => w.id == workId);
    expect(work.status, WorkStatus.impactReady);
    expect(work.impact?.explanation, contains('AI trafik tahmini kullanılmadı'));
  });

  test('WP-17 source-operation shared endpoint RBAC ve simulation provenance uygular', () async {
    final denied = await server.handler(
      _request(
        'POST',
        '/v1/commands/source-operation',
        credential: 'demo-citizen-001',
        body: {
          'actorId': 'usr_citizen_demo_001',
          'clientMutationId': 'server_wp17_source_denied',
          'expectedRevision': seed.revision,
          'action': 'sync153_mock',
          'payload': {
            'externalApplicationId': '153-DENIED',
            'statusSync': 'received_simulated',
            'linkedReportId': 'rpt_demo_0001',
          },
        },
      ),
    );
    expect(denied.statusCode, 403);
    final revision = (await store.read()).revision;
    final accepted = await server.handler(
      _request(
        'POST',
        '/v1/commands/source-operation',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_wp17_153',
          'expectedRevision': revision,
          'action': 'sync153_mock',
          'payload': {
            'externalApplicationId': '153-SERVER-001',
            'statusSync': 'received_simulated',
            'linkedReportId': 'rpt_demo_0001',
          },
        },
      ),
    );
    expect(accepted.statusCode, 200);
    final current = await store.read();
    expect(
      current.payload.sourceRecords.singleWhere((item) => item.body['sourceId'] == 'external_153_mock').body['integrationMode'],
      'simulated_contract',
    );
  });

  test('WP-18 administration shared endpoint KVKK tracking ve active role audit üretir', () async {
    final response = await server.handler(
      _request(
        'POST',
        '/v1/commands/administration',
        credential: 'demo-citizen-001',
        body: {
          'actorId': 'usr_citizen_demo_001',
          'clientMutationId': 'server_wp18_privacy',
          'expectedRevision': seed.revision,
          'action': 'create_privacy_request',
          'payload': {
            'type': 'access',
            'note': 'Shared mod KVKK erişim talebi.',
          },
        },
      ),
    );
    expect(response.statusCode, 200);
    final body = await _json(response);
    expect(body['trackingNumber']?.toString(), startsWith('KV-2026-'));
    final current = await store.read();
    final audit = current.payload.auditEvents.last;
    expect((audit.body['after'] as Map)['activeRoleContext'], 'citizen');
  });

  test('medya upload aktör namespace ve immutable byte kuralına uyar', () async {
    final foreign = await server.handler(
      _request(
        'PUT',
        '/v1/media/media_usr_citizen_demo_002_evidence_001',
        credential: 'demo-citizen-001',
        body: Uint8List.fromList([1, 2, 3]),
        encodeJson: false,
      ),
    );
    const ownedPath = '/v1/media/media_usr_citizen_demo_001_evidence_001';
    final accepted = await server.handler(
      _request(
        'PUT',
        ownedPath,
        credential: 'demo-citizen-001',
        body: Uint8List.fromList([1, 2, 3]),
        encodeJson: false,
      ),
    );
    final overwrite = await server.handler(
      _request(
        'PUT',
        ownedPath,
        credential: 'demo-citizen-001',
        body: Uint8List.fromList([4]),
        encodeJson: false,
      ),
    );

    expect(foreign.statusCode, 403);
    expect(accepted.statusCode, 204);
    expect(overwrite.statusCode, 409);
  });

  test('citizen projeksiyonu originalRef sızdırmaz, orijinal erişim gerekçe ve audit ister', () async {
    const originalId = 'media_usr_citizen_demo_001_private_original';
    const publicId = 'media_usr_citizen_demo_001_private_public';
    for (final id in [originalId, publicId]) {
      final uploaded = await server.handler(
        _request(
          'PUT',
          '/v1/media/$id',
          credential: 'demo-citizen-001',
          body: Uint8List.fromList([1, 2, 3]),
          encodeJson: false,
        ),
      );
      expect(uploaded.statusCode, 204);
    }
    final created = await server.handler(
      _request(
        'POST',
        '/v1/commands/report',
        credential: 'demo-citizen-001',
        body: {
          ..._createBody(seed.revision),
          'clientMutationId': 'server_media_projection_001',
          'media': [
            {
              'id': 'media_usr_citizen_demo_001_private',
              'privacyStatus': 'safe',
              'originalRef': 'media://$originalId',
              'publicRef': 'media://$publicId',
              'mimeType': 'image/png',
            },
          ],
        },
      ),
    );
    expect(created.statusCode, 201);
    final citizen = await _snapshot(server, 'demo-citizen-001');
    expect(citizen.payload.media.single.originalRef, isNull);
    expect(citizen.payload.media.single.publicRef, 'media://$publicId');

    final withoutReason = await server.handler(
      _request('GET', '/v1/media/$originalId', credential: 'demo-staff-supervisor'),
    );
    expect(withoutReason.statusCode, 422);
    final beforeAudit = (await store.read()).payload.auditEvents.length;
    final accessed = await server.handler(
      _request(
        'GET',
        '/v1/media/$originalId?reason=Municipal+evidence+review',
        credential: 'demo-staff-supervisor',
      ),
    );
    expect(accessed.statusCode, 200);
    expect((await store.read()).payload.auditEvents.length, beforeAudit + 1);
  });


  test('WP-19 CORS fail-closed, security headers ve origin echo uygular', () async {
    final foreign = await server.handler(
      _request(
        'POST',
        '/v1/commands/report',
        credential: 'demo-citizen-001',
        body: _createBody(seed.revision),
        headers: const {'origin': 'https://evil.example'},
      ),
    );
    expect(foreign.statusCode, 403);
    expect(foreign.headers['access-control-allow-origin'], isNull);
    expect(foreign.headers['x-content-type-options'], 'nosniff');

    final allowed = await server.handler(
      _request(
        'GET',
        '/health/live',
        headers: const {'origin': 'http://localhost:5173'},
      ),
    );
    expect(allowed.statusCode, 200);
    expect(
      allowed.headers['access-control-allow-origin'],
      'http://localhost:5173',
    );
    expect(allowed.headers['access-control-allow-origin'], isNot('*'));
    expect(allowed.headers['x-frame-options'], 'DENY');
  });

  test('WP-19 import privilege escalation güvenli hata ile reddedilir ve ham payload sızmaz', () async {
    final beforeAudit = (await store.read()).payload.auditEvents.length;
    final response = await server.handler(
      _request(
        'POST',
        '/v1/commands/source-operation',
        credential: 'demo-staff-supervisor',
        body: {
          'actorId': 'usr_supervisor_demo_001',
          'clientMutationId': 'server_wp19_escalation',
          'expectedRevision': seed.revision,
          'action': 'import_fixture',
          'payload': {
            'format': 'json',
            'sourceId': 'traffic_events_fixture',
            'content': '[{"externalId":"evil-secret-marker","permissions":["manage_users"]}]',
          },
        },
      ),
    );
    final body = await response.readAsString();
    expect(response.statusCode, 403);
    expect(body, isNot(contains('evil-secret-marker')));
    expect(body, isNot(contains('manage_users')));
    final after = await store.read();
    expect(after.payload.auditEvents.length, beforeAudit + 1);
    expect(after.payload.auditEvents.last.body['action'], contains('denied'));
  });

  test('WP-19 media traversal, enumeration ve original erişim fail-closed kalır', () async {
    final traversal = await server.handler(
      _request(
        'GET',
        '/v1/media/%2E%2E%2Fsecret_file',
        credential: 'demo-staff-supervisor',
      ),
    );
    expect(traversal.statusCode, greaterThanOrEqualTo(400));
    expect(await traversal.readAsString(), isNot(contains('secret_file')));

    final enumerated = await server.handler(
      _request(
        'GET',
        '/v1/media/media_nonexistent_original?reason=Municipal+evidence+review',
        credential: 'demo-staff-supervisor',
      ),
    );
    expect(enumerated.statusCode, 404);

    final beforeDeniedAudit = (await store.read()).payload.auditEvents.length;
    final citizen = await server.handler(
      _request(
        'GET',
        '/v1/media/media_nonexistent_original?reason=Citizen+should+not+read',
        credential: 'demo-citizen-001',
      ),
    );
    expect(citizen.statusCode, 403);
    final afterDenied = await store.read();
    expect(afterDenied.payload.auditEvents.length, beforeDeniedAudit + 1);
    expect(afterDenied.payload.auditEvents.last.body['action'], contains('denied'));
  });

  test('WP-19 citizen/public snapshot hassas staff alanlarını taşımaz', () async {
    final response = await server.handler(
      _request('GET', '/v1/snapshot', credential: 'demo-citizen-001'),
    );
    final body = await _json(response);
    final projected = AppSnapshotDto.fromJson(body);
    expect(response.statusCode, 200);
    expect(projected.payload.auditEvents, isEmpty);
    expect(projected.payload.media.every((item) => item.originalRef == null), isTrue);
    expect(
      projected.payload.reports.every((item) => item.humanDecisionReason == null),
      isTrue,
    );
    final raw = jsonEncode(body);
    expect(raw, isNot(contains('trustScore')));
    expect(raw, isNot(contains('abuseProfile')));
  });

  test('WP-19 server demo session 8 saat sonra expire olur', () async {
    final mutableClock = _MutableClock(DateTime.utc(2026, 8, 17, 8));
    final isolatedStore = InMemorySnapshotStore(initial: seed, codec: codec);
    final isolated = KentTakipDemoServer(
      store: isolatedStore,
      mediaStore: InMemoryMediaStore(),
      codec: codec,
      clock: mutableClock,
    );
    final before = await isolated.handler(
      _request('GET', '/v1/snapshot', credential: 'demo-citizen-001'),
    );
    expect(before.statusCode, 200);
    mutableClock.value = DateTime.utc(2026, 8, 17, 16, 0, 1);
    final expired = await isolated.handler(
      _request('GET', '/v1/snapshot', credential: 'demo-citizen-001'),
    );
    expect(expired.statusCode, 403);
    expect(await expired.readAsString(), isNot(contains('demo-citizen-001')));
  });

  test('runtime restart ve bozuk active recovery son geçerli veriyi korur', () async {
    final directory = await Directory.systemTemp.createTemp('kt-server-recovery-');
    addTearDown(() => directory.delete(recursive: true));
    final active = File('${directory.path}/snapshot.json');
    final ioStore = IoAtomicSnapshotStore(activeFile: active, codec: codec, seed: seed);
    final ioProcessor = SnapshotCommandProcessor(
      store: ioStore,
      codec: codec,
      clock: _FixedClock(DateTime.utc(2026, 8, 17, 14)),
    );
    final created = await ioProcessor.createReport(
      CreateReportCommand.fromJson(_createBody(seed.revision)),
    );

    final reopened = IoAtomicSnapshotStore(activeFile: active, codec: codec, seed: seed);
    expect((await reopened.read()).revision, created.snapshot.revision);
    await File('${active.path}.bak').writeAsString(codec.encode(created.snapshot));
    await active.writeAsString('{corrupt');
    expect((await reopened.read()).revision, created.snapshot.revision);
  });
}

Request _request(
  String method,
  String path, {
  String? credential,
  Object? body,
  bool encodeJson = true,
  Map<String, String> headers = const {},
}) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: {
      if (credential != null) 'authorization': 'Bearer $credential',
      if (body != null)
        'content-type': encodeJson ? 'application/json' : 'application/octet-stream',
      ...headers,
    },
    body: body == null || !encodeJson ? body : jsonEncode(body),
  );
}

Map<String, Object?> _createBody(int revision) => {
  'actorId': 'usr_citizen_demo_001',
  'clientMutationId': 'server_create_001',
  'expectedRevision': revision,
  'category': 'road_surface_damage',
  'description': 'Meşrutiyet Caddesi üzerinde büyük çukur var.',
  'latitude': 41.0302,
  'longitude': 28.9748,
};

Future<JsonMap> _json(Response response) async {
  return expectMap(jsonDecode(await response.readAsString()), 'response');
}

Future<AppSnapshotDto> _snapshot(
  KentTakipDemoServer server,
  String credential,
) async {
  final response = await server.handler(
    _request('GET', '/v1/snapshot', credential: credential),
  );
  return AppSnapshotDto.fromJson(await _json(response));
}

final class _FixedClock implements Clock {
  _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _MutableClock implements Clock {
  _MutableClock(this.value);
  DateTime value;

  @override
  DateTime nowUtc() => value;
}
