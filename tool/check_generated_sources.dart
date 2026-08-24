import 'dart:io';

void main() {
  final violations = <String>[];
  for (final entity in Directory.current.listSync(recursive: true)) {
    if (entity is! File ||
        !entity.path.endsWith('.dart') ||
        entity.path.endsWith('check_generated_sources.dart')) {
      continue;
    }
    final source = entity.readAsStringSync();
    if (source.contains("part '") && source.contains('.g.dart')) {
      violations.add('${entity.path}: generated part var fakat generator yok.');
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(violations.join('\n'));
    exitCode = 1;
    return;
  }
  stdout.writeln('Generated source gereksinimi yok; guard temiz.');
}
