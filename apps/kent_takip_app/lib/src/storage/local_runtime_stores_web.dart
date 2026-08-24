import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:web/web.dart' as web;

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
  final storage = _BrowserKeyValueStore();
  return LocalRuntimeStores(
    snapshotStore: DualSlotSnapshotStore(
      storage: storage,
      codec: codec,
      seed: seed,
    ),
    mediaStore: KeyValueMediaStore(storage: storage),
    draftStore: _BrowserDraftStore(storage),
  );
}

final class _BrowserKeyValueStore implements StringKeyValueStore {
  @override
  Future<void> delete(String key) async => web.window.localStorage.removeItem(key);

  @override
  Future<String?> read(String key) async => web.window.localStorage.getItem(key);

  @override
  Future<void> write(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }
}

final class _BrowserDraftStore implements DraftStore {
  _BrowserDraftStore(this.storage);
  final StringKeyValueStore storage;

  String _key(String ownerId) => 'kt.demo.draft.$ownerId';

  @override
  Future<void> delete(String ownerId) => storage.delete(_key(ownerId));

  @override
  Future<String?> read(String ownerId) => storage.read(_key(ownerId));

  @override
  Future<void> write(String ownerId, String encoded) =>
      storage.write(_key(ownerId), encoded);
}
