import 'dart:convert';

import 'package:flutter/foundation.dart';

enum AppLogLevel { info, warning, error }

typedef LogWriter = void Function(String line);

final class CorrelationIdGenerator {
  CorrelationIdGenerator({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  int _sequence = 0;

  String next() {
    _sequence += 1;
    return 'kt-${_now().toUtc().microsecondsSinceEpoch}-$_sequence';
  }
}

final class StructuredLogger {
  StructuredLogger({LogWriter? writer, CorrelationIdGenerator? ids})
    : _writer = writer ?? ((line) => debugPrint(line)),
      ids = ids ?? CorrelationIdGenerator();

  final LogWriter _writer;
  final CorrelationIdGenerator ids;

  void info(
    String event, {
    String? correlationId,
    Map<String, Object?> fields = const {},
  }) {
    _write(AppLogLevel.info, event, correlationId, fields);
  }

  void warning(
    String event, {
    String? correlationId,
    Map<String, Object?> fields = const {},
  }) {
    _write(AppLogLevel.warning, event, correlationId, fields);
  }

  void error(
    String event, {
    required Object error,
    StackTrace? stackTrace,
    String? correlationId,
    Map<String, Object?> fields = const {},
  }) {
    _write(
      AppLogLevel.error,
      event,
      correlationId,
      {
        ...fields,
        'errorType': error.runtimeType.toString(),
        if (kDebugMode && stackTrace != null)
          'stackFrames': stackTrace.toString().split('\n').take(4).toList(),
      },
    );
  }

  void _write(
    AppLogLevel level,
    String event,
    String? correlationId,
    Map<String, Object?> fields,
  ) {
    final safe = <String, Object?>{
      'at': DateTime.now().toUtc().toIso8601String(),
      'level': level.name,
      'event': event,
      'correlationId': correlationId ?? ids.next(),
      'fields': _redact(fields),
    };
    _writer(jsonEncode(safe));
  }

  Object? _redact(Object? value, [String key = '']) {
    final normalizedKey = key.toLowerCase();
    if ({
      'phone',
      'email',
      'otp',
      'password',
      'mfa',
      'token',
      'authorization',
      'cookie',
      'session',
      'originalref',
      'originalmedia',
      'description',
      'freetext',
      'note',
      'reason',
      'address',
      'latitude',
      'longitude',
      'location',
    }.any(normalizedKey.contains)) {
      return '[REDACTED]';
    }
    if (value is Map<String, Object?>) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key: _redact(entry.value, entry.key),
      };
    }
    if (value is Iterable<Object?>) {
      return value.map((item) => _redact(item, key)).toList(growable: false);
    }
    if (value is String) {
      final looksLikeEmail = RegExp(r'\b[^\s@]+@[^\s@]+\.[^\s@]+\b').hasMatch(value);
      final looksLikePhone = RegExp(r'(?<!\d)(?:\+?90|0)?5\d{9}(?!\d)').hasMatch(value.replaceAll(RegExp(r'[ ()-]'), ''));
      final looksLikeBearer = value.toLowerCase().contains('bearer ') ||
          RegExp(r'(api[_-]?key|secret|access[_-]?token)', caseSensitive: false).hasMatch(value);
      if (looksLikeEmail || looksLikePhone || looksLikeBearer) {
        return '[REDACTED]';
      }
    }
    return value;
  }
}
