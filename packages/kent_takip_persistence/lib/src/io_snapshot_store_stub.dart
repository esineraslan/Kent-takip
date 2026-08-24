import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_persistence/src/snapshot_codec.dart';

final class IoAtomicSnapshotStore {
  IoAtomicSnapshotStore({
    required Object activeFile,
    required SnapshotCodec codec,
    required AppSnapshotDto seed,
  }) {
    throw UnsupportedError('IO snapshot store bu platformda kullanılamaz.');
  }
}

