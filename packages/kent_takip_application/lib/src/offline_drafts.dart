import 'dart:convert';

import 'package:kent_takip_application/src/commands.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';

abstract interface class DraftStore {
  Future<String?> read(String ownerId);

  Future<void> write(String ownerId, String encoded);

  Future<void> delete(String ownerId);
}

final class InMemoryDraftStore implements DraftStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String ownerId) async => _values.remove(ownerId);

  @override
  Future<String?> read(String ownerId) async => _values[ownerId];

  @override
  Future<void> write(String ownerId, String encoded) async {
    _values[ownerId] = encoded;
  }
}

final class OfflineDraftQueue {
  OfflineDraftQueue({required this.store});
  final DraftStore store;

  Future<void> save(CreateReportCommand command) {
    return store.write(command.actorId, jsonEncode(command.toJson()));
  }

  Future<CreateReportCommand?> load(String ownerId) async {
    final encoded = await store.read(ownerId);
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded);
    return CreateReportCommand.fromJson(expectMap(decoded, 'draft'));
  }

  Future<void> clear(String ownerId) => store.delete(ownerId);
}
