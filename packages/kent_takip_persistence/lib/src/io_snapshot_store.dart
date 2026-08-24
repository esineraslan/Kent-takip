import 'dart:io';

import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/src/snapshot_codec.dart';
import 'package:kent_takip_persistence/src/snapshot_store.dart';

final class IoAtomicSnapshotStore implements SnapshotStore {
  IoAtomicSnapshotStore({
    required this.activeFile,
    required this.codec,
    required this.seed,
  });

  final File activeFile;
  final SnapshotCodec codec;
  final AppSnapshotDto seed;
  final SnapshotTransactionQueue _queue = SnapshotTransactionQueue();

  File get _temporaryFile => File('${activeFile.path}.tmp');
  File get _backupFile => File('${activeFile.path}.bak');

  @override
  Future<AppSnapshotDto> read() async {
    final active = await _tryRead(activeFile);
    if (active != null) {
      return active;
    }
    final backup = await _tryRead(_backupFile);
    if (backup != null) {
      return backup;
    }
    codec.validate(seed);
    return seed;
  }

  @override
  Future<AppSnapshotDto> write(AppSnapshotDto snapshot) {
    return _queue.run(() async {
      codec.validate(snapshot);
      final current = await read();
      if (snapshot.revision <= current.revision) {
        fail(FailureCode.conflict, 'Revision ileri gitmelidir.');
      }
      await activeFile.parent.create(recursive: true);
      if (await _temporaryFile.exists()) {
        await _temporaryFile.delete();
      }

      final handle = await _temporaryFile.open(mode: FileMode.writeOnly);
      try {
        await handle.writeString(codec.encode(snapshot));
        await handle.flush();
      } finally {
        await handle.close();
      }
      final verifiedTemporary = await _tryRead(_temporaryFile);
      if (verifiedTemporary == null) {
        await _temporaryFile.delete();
        fail(FailureCode.storage, 'Geçici snapshot doğrulanamadı.');
      }

      final activeIsValid = await _tryRead(activeFile) != null;
      if (activeIsValid) {
        if (await _backupFile.exists()) {
          await _backupFile.delete();
        }
        await activeFile.rename(_backupFile.path);
      } else if (await activeFile.exists()) {
        // Bozuk active dosya geçerli backup'ın üzerine döndürülmez.
        await activeFile.delete();
      }
      try {
        await _temporaryFile.rename(activeFile.path);
      } on FileSystemException {
        if (!await activeFile.exists() && await _backupFile.exists()) {
          await _backupFile.rename(activeFile.path);
        }
        fail(
          FailureCode.storage,
          'Snapshot aktifleştirilemedi; son geçerli kopya korundu.',
          retryable: true,
        );
      }

      final committed = await _tryRead(activeFile);
      if (committed == null) {
        if (await activeFile.exists()) {
          await activeFile.delete();
        }
        if (await _backupFile.exists()) {
          await _backupFile.rename(activeFile.path);
        }
        fail(FailureCode.corruption, 'Commit sonrası snapshot doğrulanamadı.');
      }
      return committed;
    });
  }

  Future<AppSnapshotDto?> _tryRead(File file) async {
    if (!await file.exists()) {
      return null;
    }
    try {
      return codec.decode(await file.readAsString());
    } on DomainFailure {
      return null;
    } on FileSystemException {
      return null;
    }
  }
}
