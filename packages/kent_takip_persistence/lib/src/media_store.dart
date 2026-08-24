import 'dart:convert';
import 'dart:typed_data';

import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/src/web_slot_store.dart';

String validateMediaId(String value) {
  if (!RegExp(r'^[a-zA-Z0-9_-]{8,128}$').hasMatch(value)) {
    fail(FailureCode.validation, 'Geçersiz media ID.', field: 'mediaId');
  }
  return value;
}

final class InMemoryMediaStore implements MediaStore {
  final Map<String, Uint8List> _values = {};

  @override
  Future<void> delete(String id) async => _values.remove(validateMediaId(id));

  @override
  Future<Uint8List?> get(String id) async {
    final value = _values[validateMediaId(id)];
    return value == null ? null : Uint8List.fromList(value);
  }

  @override
  Future<void> put(String id, Uint8List bytes) async {
    _values[validateMediaId(id)] = Uint8List.fromList(bytes);
  }
}

final class KeyValueMediaStore implements MediaStore {
  KeyValueMediaStore({required this.storage, this.namespace = 'kt.demo.media'});

  final StringKeyValueStore storage;
  final String namespace;

  @override
  Future<void> delete(String id) => storage.delete(_key(id));

  @override
  Future<Uint8List?> get(String id) async {
    final raw = await storage.read(_key(id));
    if (raw == null) {
      return null;
    }
    try {
      return base64Decode(raw);
    } on FormatException {
      fail(FailureCode.corruption, 'Web medya kaydı bozuk.');
    }
  }

  @override
  Future<void> put(String id, Uint8List bytes) async {
    try {
      await storage.write(_key(id), base64Encode(bytes));
    } on Object {
      fail(
        FailureCode.storage,
        'Web medya kotası veya depolama sınırı nedeniyle kayıt yapılamadı.',
        retryable: false,
      );
    }
  }

  String _key(String id) => '$namespace.${validateMediaId(id)}';
}
