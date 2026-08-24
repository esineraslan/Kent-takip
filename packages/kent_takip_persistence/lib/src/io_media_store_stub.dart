import 'dart:typed_data';

import 'package:kent_takip_domain/kent_takip_domain.dart';

final class IoMediaStore implements MediaStore {
  IoMediaStore(Object directory);

  @override
  Future<void> delete(String id) => throw UnsupportedError('IO kullanılamaz.');

  @override
  Future<Uint8List?> get(String id) => throw UnsupportedError('IO kullanılamaz.');

  @override
  Future<void> put(String id, Uint8List bytes) =>
      throw UnsupportedError('IO kullanılamaz.');
}

