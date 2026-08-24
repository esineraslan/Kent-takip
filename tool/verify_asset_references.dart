import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final file = File('apps/kent_takip_app/assets/demo_data/v1/snapshot.json');
  final decoded = jsonDecode(await file.readAsString()) as Map<String, Object?>;
  final payload = decoded['payload'] as Map<String, Object?>;
  final media = payload['media'] as List<Object?>;
  final errors = <String>[];
  for (final item in media.cast<Map<String, Object?>>()) {
    for (final key in ['originalRef', 'publicRef']) {
      final reference = item[key];
      if (reference == null) {
        continue;
      }
      if (reference is! String || !reference.startsWith('asset://demo_media/')) {
        errors.add('Geçersiz medya referansı: $reference');
        continue;
      }
      final relative = reference.replaceFirst('asset://', '');
      final file = File('apps/kent_takip_app/assets/$relative');
      if (!file.existsSync()) {
        errors.add('Eksik medya asseti: ${file.path}');
      }
    }
  }
  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exitCode = 1;
    return;
  }
  stdout.writeln('Asset referans sözleşmeleri doğrulandı.');
}
