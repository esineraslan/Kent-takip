import 'dart:io';

import 'package:kent_takip_demo_server/kent_takip_demo_server.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  final host = Platform.environment['KT_DEMO_HOST'] ?? '127.0.0.1';
  final port = int.tryParse(Platform.environment['KT_DEMO_PORT'] ?? '') ?? 8080;
  final runtimePath = Platform.environment['KT_DEMO_RUNTIME'] ??
      'apps/demo_server/runtime/snapshot.json';
  final seedPath = Platform.environment['KT_DEMO_SEED'] ??
      'apps/kent_takip_app/assets/demo_data/v1/snapshot.json';
  final codec = SnapshotCodec(migrations: MigrationRegistry(currentVersion: 1));
  final seed = codec.decode(await File(seedPath).readAsString());
  final runtimeFile = File(runtimePath);
  final store = IoAtomicSnapshotStore(
    activeFile: runtimeFile,
    codec: codec,
    seed: seed,
  );
  final app = KentTakipDemoServer(
    store: store,
    mediaStore: IoMediaStore(Directory('${runtimeFile.parent.path}/media')),
    codec: codec,
    clock: const _SystemClock(),
  );
  final server = await shelf_io.serve(app.handler, host, port);
  server.autoCompress = true;
  stdout.writeln('Kent Takip demo server: http://${server.address.host}:${server.port}');
}

final class _SystemClock implements Clock {
  const _SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
