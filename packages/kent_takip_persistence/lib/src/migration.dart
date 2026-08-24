import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

typedef SnapshotMigration = JsonMap Function(JsonMap source);

final class MigrationRegistry {
  MigrationRegistry({required this.currentVersion});

  final int currentVersion;
  final Map<int, SnapshotMigration> _steps = {};

  void register(int fromVersion, SnapshotMigration migration) {
    if (fromVersion < 0 || fromVersion >= currentVersion) {
      fail(FailureCode.validation, 'Geçersiz migration başlangıç sürümü.');
    }
    if (_steps.containsKey(fromVersion)) {
      fail(FailureCode.validation, 'Migration zaten kayıtlı: v$fromVersion.');
    }
    _steps[fromVersion] = migration;
  }

  JsonMap migrate(JsonMap source) {
    var current = Map<String, Object?>.from(source);
    var version = expectInt(current['schemaVersion'], 'schemaVersion');
    if (version > currentVersion) {
      fail(
        FailureCode.unsupportedSchema,
        'Daha yeni snapshot schema sürümü desteklenmiyor: $version.',
      );
    }
    while (version < currentVersion) {
      final migration = _steps[version];
      if (migration == null) {
        fail(
          FailureCode.unsupportedSchema,
          'v$version için migration bulunamadı.',
        );
      }
      current = migration(Map<String, Object?>.from(current));
      final next = expectInt(current['schemaVersion'], 'schemaVersion');
      if (next != version + 1) {
        fail(
          FailureCode.validation,
          'Migration sürümü tam bir artırmalıdır: v$version → v$next.',
        );
      }
      version = next;
    }
    return current;
  }
}

