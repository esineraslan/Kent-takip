import 'dart:io';

import 'package:kent_takip_persistence/kent_takip_persistence.dart';

Future<void> main() async {
  final registry = MigrationRegistry(currentVersion: 1);
  final codec = SnapshotCodec(migrations: registry);
  final file = File(
    'apps/kent_takip_app/assets/demo_data/v1/snapshot.json',
  );
  final snapshot = codec.decode(await file.readAsString());
  stdout.writeln(
    'Seed doğrulandı: revision=${snapshot.revision}, '
    'reports=${snapshot.payload.reports.length}, '
    'incidents=${snapshot.payload.incidents.length}.',
  );
}

