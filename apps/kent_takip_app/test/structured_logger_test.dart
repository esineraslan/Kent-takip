import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';

void main() {
  test('structured logger redacts secrets and identifiers', () {
    final lines = <String>[];
    final logger = StructuredLogger(writer: lines.add);

    logger.info(
      'security.redaction_test',
      fields: {
        'phone': '+905550001122',
        'password': 'secret',
        'email': 'person@demo.invalid',
        'description': 'Home address and free text',
        'location': {'latitude': 41.0, 'longitude': 29.0},
        'nested': {'authorizationToken': 'Bearer abc'},
        'unkeyedSecretLike': 'Bearer should-not-leak',
        'safe': 'demo',
      },
    );

    final record = jsonDecode(lines.single) as Map<String, Object?>;
    final fields = record['fields']! as Map<String, Object?>;
    final nested = fields['nested']! as Map<String, Object?>;
    expect(fields['phone'], '[REDACTED]');
    expect(fields['password'], '[REDACTED]');
    expect(fields['email'], '[REDACTED]');
    expect(fields['description'], '[REDACTED]');
    expect(fields['location'], '[REDACTED]');
    expect(nested['authorizationToken'], '[REDACTED]');
    expect(fields['unkeyedSecretLike'], '[REDACTED]');
    expect(lines.single, isNot(contains('+905550001122')));
    expect(lines.single, isNot(contains('person@demo.invalid')));
    expect(lines.single, isNot(contains('Home address')));
    expect(lines.single, isNot(contains('should-not-leak')));
    expect(fields['safe'], 'demo');
  });
}
