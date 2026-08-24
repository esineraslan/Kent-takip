import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/src/snapshot_codec.dart';
import 'package:kent_takip_persistence/src/snapshot_store.dart';

abstract interface class StringKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

final class InMemoryKeyValueStore implements StringKeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

final class DualSlotSnapshotStore implements SnapshotStore {
  DualSlotSnapshotStore({
    required this.storage,
    required this.codec,
    required this.seed,
    this.namespace = 'kt.demo.snapshot',
  });

  final StringKeyValueStore storage;
  final SnapshotCodec codec;
  final AppSnapshotDto seed;
  final String namespace;
  final SnapshotTransactionQueue _queue = SnapshotTransactionQueue();

  String get _slotA => '$namespace.a';
  String get _slotB => '$namespace.b';
  String get _active => '$namespace.active';

  @override
  Future<AppSnapshotDto> read() async {
    final pointer = await storage.read(_active);
    final preferred = pointer == 'b' ? _slotB : _slotA;
    final fallback = pointer == 'b' ? _slotA : _slotB;
    final activeSnapshot = await _tryRead(preferred);
    if (activeSnapshot != null) {
      return activeSnapshot;
    }
    final backupSnapshot = await _tryRead(fallback);
    if (backupSnapshot != null) {
      return backupSnapshot;
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
      final pointer = await storage.read(_active);
      final pointedSlot = pointer == 'b' ? _slotB : _slotA;
      final pointedSnapshot = await _tryRead(pointedSlot);
      // Pointer bozuksa geçerli fallback'i ezmek yerine bozuk slotu onar.
      final nextPointer = pointedSnapshot == null
          ? (pointer == 'b' ? 'b' : 'a')
          : (pointer == 'a' ? 'b' : 'a');
      final nextSlot = nextPointer == 'a' ? _slotA : _slotB;
      final encoded = codec.encode(snapshot);
      try {
        await storage.write(nextSlot, encoded);
      } on Object {
        fail(
          FailureCode.storage,
          'Web snapshot yazılamadı; aktif pointer korunuyor.',
          retryable: true,
        );
      }
      final verified = await _tryRead(nextSlot);
      if (verified == null) {
        await storage.delete(nextSlot);
        fail(FailureCode.storage, 'Web snapshot slot doğrulanamadı.');
      }
      try {
        await storage.write(_active, nextPointer);
      } on Object {
        fail(
          FailureCode.storage,
          'Web commit pointer yazılamadı; önceki snapshot aktif kaldı.',
          retryable: true,
        );
      }
      return verified;
    });
  }

  Future<AppSnapshotDto?> _tryRead(String key) async {
    final raw = await storage.read(key);
    if (raw == null) {
      return null;
    }
    try {
      return codec.decode(raw);
    } on DomainFailure {
      return null;
    }
  }
}
