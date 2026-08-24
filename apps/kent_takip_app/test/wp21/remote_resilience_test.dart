import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kent_takip_app/src/storage/remote_demo_data_gateway.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SnapshotCodec codec;
  late AppSnapshotDto seed;

  setUp(() async {
    codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
    seed = codec.decode(await rootBundle.loadString('assets/demo_data/v1/snapshot.json'));
  });

  test('429 ve 503 flapping sonrası snapshot aynı read çağrısında toparlanır', () async {
    var attempts = 0;
    final client = MockClient((request) async {
      attempts += 1;
      if (attempts == 1) {
        return http.Response('{"message":"rate limited"}', 429);
      }
      if (attempts == 2) {
        return http.Response('{"message":"restart"}', 503);
      }
      return http.Response(codec.encode(seed), 200);
    });
    final gateway = RemoteDemoDataGateway(
      apiBase: Uri.parse('http://127.0.0.1:8080'),
      codec: codec,
      tokenProvider: () => 'demo-guest',
      client: client,
      retryPolicy: const ResilienceRetryPolicy(
        maxAttempts: 3,
        baseDelay: Duration.zero,
        jitterRatio: 0,
      ),
      delay: (_) async {},
      cacheStore: InMemorySnapshotStore(initial: seed, codec: codec),
    );
    addTearDown(gateway.close);

    final result = await gateway.fetchSnapshot();
    expect(result.revision, seed.revision);
    expect(attempts, 3);
    expect(gateway.lastReadWasOfflineCache, isFalse);
  });

  test('malformed JSON bütün uygulamayı düşürmek yerine son geçerli cachee döner', () async {
    final client = MockClient((request) async => http.Response('{malformed', 200));
    final cache = InMemorySnapshotStore(initial: seed, codec: codec);
    final gateway = RemoteDemoDataGateway(
      apiBase: Uri.parse('http://127.0.0.1:8080'),
      codec: codec,
      tokenProvider: () => 'demo-guest',
      client: client,
      retryPolicy: const ResilienceRetryPolicy(
        maxAttempts: 2,
        baseDelay: Duration.zero,
        jitterRatio: 0,
      ),
      delay: (_) async {},
      cacheStore: cache,
    );
    addTearDown(gateway.close);

    final result = await gateway.fetchSnapshot();
    expect(result.revision, seed.revision);
    expect(gateway.lastReadWasOfflineCache, isTrue);
  });

  test('successful remote truth is not poisoned by a failing optional cache', () async {
    final client = MockClient((request) async => http.Response(codec.encode(seed), 200));
    final gateway = RemoteDemoDataGateway(
      apiBase: Uri.parse('http://127.0.0.1:8080'),
      codec: codec,
      tokenProvider: () => 'demo-guest',
      client: client,
      cacheStore: _ThrowingSnapshotStore(),
      retryPolicy: const ResilienceRetryPolicy(
        maxAttempts: 1,
        baseDelay: Duration.zero,
        jitterRatio: 0,
      ),
      delay: (_) async {},
    );
    addTearDown(gateway.close);

    final result = await gateway.fetchSnapshot();
    expect(result.revision, seed.revision);
    expect(gateway.lastReadWasOfflineCache, isFalse);
  });

  test('stable media PUT retries transient 503 without duplicating resource id', () async {
    var attempts = 0;
    final seenPaths = <String>[];
    final client = MockClient((request) async {
      attempts += 1;
      seenPaths.add(request.url.path);
      if (attempts == 1) return http.Response('{"message":"restart"}', 503);
      return http.Response('', 204);
    });
    final gateway = RemoteDemoDataGateway(
      apiBase: Uri.parse('http://127.0.0.1:8080'),
      codec: codec,
      tokenProvider: () => 'demo-guest',
      client: client,
      retryPolicy: const ResilienceRetryPolicy(
        maxAttempts: 2,
        baseDelay: Duration.zero,
        jitterRatio: 0,
      ),
      delay: (_) async {},
    );
    addTearDown(gateway.close);

    await gateway.putMedia('media_wp21_retry', Uint8List.fromList([1, 2, 3]));
    expect(attempts, 2);
    expect(seenPaths.toSet(), {'/v1/media/media_wp21_retry'});
  });
}

final class _ThrowingSnapshotStore implements SnapshotStore {
  @override
  Future<AppSnapshotDto> read() async => throw StateError('synthetic cache read failure');

  @override
  Future<AppSnapshotDto> write(AppSnapshotDto snapshot) async =>
      throw StateError('synthetic cache write failure');
}
