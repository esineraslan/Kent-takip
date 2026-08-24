import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:test/test.dart';

void main() {
  late SnapshotCodec codec;
  late AppSnapshotDto seed;

  setUp(() async {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.decode(
      await File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json').readAsString(),
    );
  });

  test('web active slot corruption recovers from last valid slot', () async {
    final storage = InMemoryKeyValueStore();
    final store = DualSlotSnapshotStore(storage: storage, codec: codec, seed: seed);
    final next = seed.copyWith(
      revision: seed.revision + 1,
      updatedAt: seed.updatedAt.add(const Duration(minutes: 1)),
    );
    await store.write(next);
    final pointer = await storage.read('kt.demo.snapshot.active');
    final activeKey = pointer == 'b' ? 'kt.demo.snapshot.b' : 'kt.demo.snapshot.a';
    await storage.write(activeKey, '{malformed');
    final recovered = await store.read();
    expect(recovered.revision, seed.revision);
  });

  test('migration failure in preferred slot falls back instead of destroying backup', () async {
    final storage = InMemoryKeyValueStore();
    final store = DualSlotSnapshotStore(storage: storage, codec: codec, seed: seed);
    await storage.write('kt.demo.snapshot.a', codec.encode(seed));
    final unsupported = jsonDecode(codec.encode(seed)) as Map<String, Object?>;
    unsupported['schemaVersion'] = 0;
    await storage.write('kt.demo.snapshot.b', jsonEncode(unsupported));
    await storage.write('kt.demo.snapshot.active', 'b');

    final recovered = await store.read();
    expect(recovered.revision, seed.revision);
    expect(await storage.read('kt.demo.snapshot.a'), isNotNull);
  });
  test('web media quota failure is mapped to a storage failure', () async {
    final store = KeyValueMediaStore(storage: _FailingKeyValueStore());
    await expectLater(
      store.put('media_quota_0001', Uint8List.fromList([1, 2, 3])),
      throwsA(isA<DomainFailure>().having((e) => e.code, 'code', FailureCode.storage)),
    );
  });

}

final class _FailingKeyValueStore implements StringKeyValueStore {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async => throw StateError('quota');
}
