import 'dart:typed_data';

import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/src/snapshot_codec.dart';
import 'package:kent_takip_persistence/src/snapshot_store.dart';

final class DemoResetCoordinator {
  DemoResetCoordinator({
    required this.store,
    required this.mediaStore,
    required this.codec,
    required this.clock,
    required this.seed,
  });

  final SnapshotStore store;
  final MediaStore mediaStore;
  final SnapshotCodec codec;
  final Clock clock;
  final AppSnapshotDto seed;

  Future<AppSnapshotDto> reset({
    required String actorId,
    required Iterable<String> dynamicMediaIds,
  }) async {
    requireText(actorId, 'actorId');
    final current = await store.read();
    final seedMediaIds = _mediaIds(seed);
    final discoveredDynamicIds = _mediaIds(current).difference(seedMediaIds);
    final targetMediaIds = {
      ...dynamicMediaIds,
      ...discoveredDynamicIds,
    };
    final mediaBackup = <String, Uint8List>{};
    for (final id in targetMediaIds) {
      final bytes = await mediaStore.get(id);
      if (bytes != null) {
        mediaBackup[id] = bytes;
      }
    }

    try {
      for (final id in targetMediaIds) {
        await mediaStore.delete(id);
      }
      final now = clock.nowUtc();
      final nextRevision = current.revision + 1;
      final audit = OpaqueEntityDto(
        id: 'audit_reset_$nextRevision',
        body: {
          'id': 'audit_reset_$nextRevision',
          'actorId': actorId,
          'action': 'demo_reset',
          'resourceId': 'app_snapshot',
          'at': now.toIso8601String(),
          'reason': 'Authorized deterministic demo reset',
          'before': {'revision': current.revision},
          'after': {'seedVersion': seed.seedVersion},
        },
      );
      final payload = seed.payload.copyWith(
        auditEvents: [...current.payload.auditEvents, audit],
      );
      final resetSnapshot = codec.seal(
        seed.copyWith(
          revision: nextRevision,
          updatedAt: now,
          checksum: 'sha256:unsealed',
          payload: payload,
        ),
      );
      return await store.write(resetSnapshot);
    } on Object {
      for (final entry in mediaBackup.entries) {
        await mediaStore.put(entry.key, entry.value);
      }
      rethrow;
    }
  }
}

Set<String> _mediaIds(AppSnapshotDto snapshot) {
  final result = <String>{};
  for (final media in snapshot.payload.media) {
    for (final ref in [media.originalRef, media.publicRef]) {
      if (ref != null && ref.startsWith('media://')) {
        result.add(ref.substring('media://'.length));
      }
    }
  }
  return result;
}
