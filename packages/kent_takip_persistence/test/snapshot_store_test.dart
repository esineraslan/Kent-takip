import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:test/test.dart';

final class _FixedClock implements Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _QuotaKeyValueStore implements StringKeyValueStore {
  final InMemoryKeyValueStore delegate = InMemoryKeyValueStore();
  bool rejectWrites = false;

  @override
  Future<void> delete(String key) => delegate.delete(key);

  @override
  Future<String?> read(String key) => delegate.read(key);

  @override
  Future<void> write(String key, String value) {
    if (rejectWrites) {
      throw StateError('quota');
    }
    return delegate.write(key, value);
  }
}

void main() {
  late SnapshotCodec codec;
  late AppSnapshotDto seed;

  setUp(() {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.seal(
      AppSnapshotDto(
        schemaVersion: 1,
        seedVersion: 'test-1',
        revision: 1,
        updatedAt: DateTime.utc(2026, 8, 17),
        checksum: 'sha256:unsealed',
        payload: SnapshotPayloadDto.empty(),
      ),
    );
  });

  AppSnapshotDto next(int revision) => codec.seal(
    seed.copyWith(
      revision: revision,
      updatedAt: DateTime.utc(2026, 8, 17, revision),
    ),
  );

  test('codec round-trips canonical snapshot', () {
    final decoded = codec.decode(codec.encode(seed));

    expect(decoded.revision, 1);
    expect(decoded.checksum, seed.checksum);
  });

  test('in-memory store rejects stale revision', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);

    await expectLater(
      store.write(seed),
      throwsA(
        isA<DomainFailure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.conflict,
        ),
      ),
    );
  });

  test('dual slot keeps last valid snapshot after active corruption', () async {
    final keyValue = InMemoryKeyValueStore();
    final store = DualSlotSnapshotStore(
      storage: keyValue,
      codec: codec,
      seed: seed,
    );
    await store.write(next(2));
    await store.write(next(3));
    await keyValue.write('kt.demo.snapshot.active', 'b');
    await keyValue.write('kt.demo.snapshot.b', '{corrupt');

    final recovered = await store.read();

    expect(recovered.revision, 2);
  });

  test('dual slot repairs a corrupt pointed slot without erasing fallback', () async {
    final keyValue = InMemoryKeyValueStore();
    final store = DualSlotSnapshotStore(
      storage: keyValue,
      codec: codec,
      seed: seed,
    );
    await store.write(next(2));
    await store.write(next(3));
    await keyValue.write('kt.demo.snapshot.b', '{corrupt');

    await store.write(next(4));

    expect((await store.read()).revision, 4);
    expect(codec.decode((await keyValue.read('kt.demo.snapshot.a'))!).revision, 2);
  });

  test('IO store writes atomically and recovers backup', () async {
    final directory = await Directory.systemTemp.createTemp('kent_takip_store_');
    addTearDown(() => directory.delete(recursive: true));
    final active = File('${directory.path}/snapshot.json');
    final store = IoAtomicSnapshotStore(
      activeFile: active,
      codec: codec,
      seed: seed,
    );
    await store.write(next(2));
    await store.write(next(3));
    await active.writeAsString('{corrupt');

    final recovered = await store.read();

    expect(recovered.revision, 2);
  });

  test('forbidden citizen profile score is rejected', () {
    final payload = SnapshotPayloadDto(
      accounts: const [],
      reports: const [],
      incidents: const [],
      municipalWorks: const [],
      media: const [],
      analyses: const [],
      sourceAuthorities: const [],
      sourceRecords: const [],
      dataSourceHealth: const [],
      corroborations: const [],
      timeline: const [],
      notifications: const [],
      auditEvents: [
        OpaqueEntityDto(
          id: 'audit-001',
          body: const {'id': 'audit-001', 'citizenTrustScore': 50},
        ),
      ],
      privacyRequests: const [],
      restrictions: const [],
      demoScenarios: const [],
    );
    final invalid = AppSnapshotDto(
      schemaVersion: 1,
      seedVersion: 'test-1',
      revision: 2,
      updatedAt: DateTime.utc(2026, 8, 17),
      checksum: sha256Checksum(payload.toJson()),
      payload: payload,
    );

    expect(() => codec.validate(invalid), throwsA(isA<DomainFailure>()));
  });

  test('transaction queue continues after a failed operation', () async {
    final queue = SnapshotTransactionQueue();
    final first = queue.run<int>(() async {
      throw DomainFailure(code: FailureCode.storage, message: 'failure');
    });
    final second = queue.run<int>(() async => 42);

    await expectLater(first, throwsA(isA<DomainFailure>()));
    await expectLater(second, completion(42));
  });

  test('migration is one-step and idempotent after reaching target', () {
    final registry = MigrationRegistry(currentVersion: 2)
      ..register(1, (source) => {...source, 'schemaVersion': 2});
    final v1 = seed.toJson();

    final migrated = registry.migrate(v1);
    final migratedAgain = registry.migrate(migrated);

    expect(migrated['schemaVersion'], 2);
    expect(migratedAgain, migrated);
  });

  test('newer schema fails closed', () {
    final json = seed.toJson()..['schemaVersion'] = 2;

    expect(
      () => codec.decode(jsonEncode(json)),
      throwsA(
        isA<DomainFailure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.unsupportedSchema,
        ),
      ),
    );
  });

  test('web quota failure keeps the active snapshot readable', () async {
    final keyValue = _QuotaKeyValueStore();
    final store = DualSlotSnapshotStore(
      storage: keyValue,
      codec: codec,
      seed: seed,
    );
    await store.write(next(2));
    keyValue.rejectWrites = true;

    await expectLater(store.write(next(3)), throwsA(isA<DomainFailure>()));
    expect((await store.read()).revision, 2);
  });

  test('authorized synthetic import advances local revision', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final service = SnapshotTransferService(
      store: store,
      codec: codec,
      clock: _FixedClock(DateTime.utc(2026, 8, 17, 12)),
    );

    final imported = await service.importSnapshot(
      source: codec.encode(seed),
      canImport: true,
      synthetic: true,
    );

    expect(imported.revision, 2);
    await expectLater(
      service.importSnapshot(
        source: codec.encode(seed),
        canImport: false,
        synthetic: true,
      ),
      throwsA(isA<DomainFailure>()),
    );
  });

  test('reset restores seed payload and removes dynamic media with audit', () async {
    final store = InMemorySnapshotStore(initial: seed, codec: codec);
    final media = InMemoryMediaStore();
    await media.put('media_dynamic_01', Uint8List.fromList([1, 2, 3]));
    final reset = DemoResetCoordinator(
      store: store,
      mediaStore: media,
      codec: codec,
      clock: _FixedClock(DateTime.utc(2026, 8, 17, 13)),
      seed: seed,
    );

    final result = await reset.reset(
      actorId: 'supervisor-001',
      dynamicMediaIds: const ['media_dynamic_01'],
    );

    expect(result.revision, 2);
    expect(result.payload.auditEvents.single.body['action'], 'demo_reset');
    expect(await media.get('media_dynamic_01'), isNull);
  });
}
