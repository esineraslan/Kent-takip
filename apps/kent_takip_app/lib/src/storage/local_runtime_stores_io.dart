import 'dart:io';

import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:path_provider/path_provider.dart';

final class LocalRuntimeStores {
  const LocalRuntimeStores({
    required this.snapshotStore,
    required this.mediaStore,
    required this.draftStore,
  });
  final SnapshotStore snapshotStore;
  final MediaStore mediaStore;
  final DraftStore draftStore;
}

Future<LocalRuntimeStores> createLocalRuntimeStores({
  required AppSnapshotDto seed,
  required SnapshotCodec codec,
}) async {
  final support = await getApplicationSupportDirectory();
  final root = Directory('${support.path}/kent_takip_demo');
  return LocalRuntimeStores(
    snapshotStore: IoAtomicSnapshotStore(
      activeFile: File('${root.path}/runtime/snapshot.json'),
      codec: codec,
      seed: seed,
    ),
    mediaStore: IoMediaStore(Directory('${root.path}/media')),
    draftStore: _IoDraftStore(Directory('${root.path}/drafts')),
  );
}

final class _IoDraftStore implements DraftStore {
  _IoDraftStore(this.directory);
  final Directory directory;

  @override
  Future<void> delete(String ownerId) async {
    final target = _file(ownerId);
    if (await target.exists()) await target.delete();
  }

  @override
  Future<String?> read(String ownerId) async {
    final target = _file(ownerId);
    return await target.exists() ? target.readAsString() : null;
  }

  @override
  Future<void> write(String ownerId, String encoded) async {
    await directory.create(recursive: true);
    final target = _file(ownerId);
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    final handle = await temporary.open(mode: FileMode.writeOnly);
    try {
      await handle.writeString(encoded);
      await handle.flush();
    } finally {
      await handle.close();
    }
    if (await backup.exists()) await backup.delete();
    if (await target.exists()) await target.rename(backup.path);
    try {
      await temporary.rename(target.path);
    } on FileSystemException {
      if (!await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      fail(FailureCode.storage, 'Offline taslak atomik kaydedilemedi.');
    }
    if (await backup.exists()) await backup.delete();
  }

  File _file(String ownerId) {
    final safe = ownerId.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
    if (safe.isEmpty) fail(FailureCode.validation, 'Draft owner geçersiz.');
    return File('${directory.path}/$safe.json');
  }
}
