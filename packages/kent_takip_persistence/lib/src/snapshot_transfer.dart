import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/src/snapshot_codec.dart';
import 'package:kent_takip_persistence/src/snapshot_store.dart';

final class SnapshotTransferService {
  SnapshotTransferService({
    required this.store,
    required this.codec,
    required this.clock,
  });

  final SnapshotStore store;
  final SnapshotCodec codec;
  final Clock clock;

  Future<String> exportSnapshot({required bool canExport}) async {
    if (!canExport) {
      fail(FailureCode.unauthorized, 'Snapshot export yetkisi yok.');
    }
    return codec.encode(await store.read());
  }

  Future<AppSnapshotDto> importSnapshot({
    required String source,
    required bool canImport,
    required bool synthetic,
  }) async {
    if (!canImport) {
      fail(FailureCode.unauthorized, 'Snapshot import yetkisi yok.');
    }
    if (!synthetic) {
      fail(
        FailureCode.validation,
        'Demo ortamına yalnız sentetik veri aktarılabilir.',
      );
    }
    final imported = codec.decode(source);
    final current = await store.read();
    final candidate = codec.seal(
      imported.copyWith(
        revision: current.revision + 1,
        updatedAt: clock.nowUtc(),
        checksum: 'sha256:unsealed',
      ),
    );
    return store.write(candidate);
  }
}
