import 'package:kent_takip_domain/kent_takip_domain.dart';

typedef JsonMap = Map<String, Object?>;

Object? deepFreezeJson(Object? value, String path) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key: deepFreezeJson(entry.value, '$path.${entry.key}'),
    });
  }
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable([
      for (var index = 0; index < value.length; index++)
        deepFreezeJson(value[index], '$path[$index]'),
    ]);
  }
  fail(FailureCode.validation, '$path JSON değeri değildir.', field: path);
}

JsonMap expectMap(Object? value, String path) {
  if (value is! Map<String, Object?>) {
    fail(FailureCode.validation, '$path nesne olmalıdır.', field: path);
  }
  return value;
}

List<Object?> expectList(Object? value, String path) {
  if (value is! List<Object?>) {
    fail(FailureCode.validation, '$path liste olmalıdır.', field: path);
  }
  return value;
}

String expectString(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    fail(FailureCode.validation, '$path metin olmalıdır.', field: path);
  }
  return value;
}

String? expectNullableString(Object? value, String path) {
  if (value == null) {
    return null;
  }
  return expectString(value, path);
}

int expectInt(Object? value, String path) {
  if (value is! int) {
    fail(FailureCode.validation, '$path tam sayı olmalıdır.', field: path);
  }
  return value;
}

bool expectBool(Object? value, String path) {
  if (value is! bool) {
    fail(FailureCode.validation, '$path bool olmalıdır.', field: path);
  }
  return value;
}

DateTime expectUtcDate(Object? value, String path) {
  final text = expectString(value, path);
  final parsed = DateTime.tryParse(text);
  if (parsed == null || !parsed.isUtc || !text.endsWith('Z')) {
    fail(FailureCode.validation, '$path UTC ISO-8601 olmalıdır.', field: path);
  }
  return parsed;
}

E expectEnum<E extends Enum>(
  Object? value,
  String path,
  Map<String, E> values,
) {
  final raw = expectString(value, path);
  final parsed = values[raw];
  if (parsed == null) {
    fail(FailureCode.validation, '$path bilinmeyen enum: $raw', field: path);
  }
  return parsed;
}

String enumWire(Enum value) {
  return value.name.replaceAllMapped(
    RegExp('([a-z0-9])([A-Z])'),
    (match) => '${match.group(1)}_${match.group(2)!.toLowerCase()}',
  );
}

Map<String, E> enumValues<E extends Enum>(Iterable<E> values) {
  return {for (final value in values) enumWire(value): value};
}

List<T> decodeList<T>(
  Object? value,
  String path,
  T Function(Object? value, String path) decode,
) {
  final list = expectList(value, path);
  return List<T>.unmodifiable([
    for (var index = 0; index < list.length; index++)
      decode(list[index], '$path[$index]'),
  ]);
}
