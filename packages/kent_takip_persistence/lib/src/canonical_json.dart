import 'dart:convert';

import 'package:crypto/crypto.dart';

Object? canonicalize(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: canonicalize(value[key]),
    };
  }
  if (value is List<Object?>) {
    return value.map(canonicalize).toList(growable: false);
  }
  return value;
}

String canonicalJson(Object? value) => jsonEncode(canonicalize(value));

String sha256Checksum(Object? value) {
  final bytes = utf8.encode(canonicalJson(value));
  return 'sha256:${sha256.convert(bytes)}';
}

