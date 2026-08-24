import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';

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
  throw UnsupportedError('Bu platformda yerel runtime store desteklenmiyor.');
}
