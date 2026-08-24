import 'dart:io';
import 'dart:typed_data';

import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/src/media_store.dart';

final class IoMediaStore implements MediaStore {
  IoMediaStore(this.directory);

  final Directory directory;

  @override
  Future<void> delete(String id) async {
    final file = _file(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<Uint8List?> get(String id) async {
    final file = _file(id);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> put(String id, Uint8List bytes) async {
    try {
      await directory.create(recursive: true);
      final temporary = File('${_file(id).path}.tmp');
      final handle = await temporary.open(mode: FileMode.writeOnly);
      try {
        await handle.writeFrom(bytes);
        await handle.flush();
      } finally {
        await handle.close();
      }
      final target = _file(id);
      final backup = File('${target.path}.bak');
      if (await backup.exists()) {
        await backup.delete();
      }
      if (await target.exists()) {
        await target.rename(backup.path);
      }
      try {
        await temporary.rename(target.path);
      } on FileSystemException {
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(target.path);
        }
        fail(FailureCode.storage, 'Medya atomik olarak kaydedilemedi.');
      }
      if (await backup.exists()) {
        await backup.delete();
      }
    } on DomainFailure {
      rethrow;
    } on FileSystemException {
      fail(
        FailureCode.storage,
        'Medya için yeterli yer yok veya depolama erişilemiyor.',
        retryable: false,
      );
    }
  }

  File _file(String id) => File('${directory.path}/${validateMediaId(id)}.bin');
}
