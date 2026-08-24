import 'dart:io';

void main() {
  final root = Directory.current;
  const required = [
    'PRODUCT.md',
    'USER_FLOWS.md',
    'DESIGN.md',
    'ARCHITECTURE.md',
    'AI_SYSTEM.md',
    'DATA_SOURCES.md',
    'RULES.md',
    'docs/TRACEABILITY.md',
  ];
  final errors = <String>[];
  final documents = <String, String>{};
  for (final relative in required) {
    final file = File('${root.path}/$relative');
    if (!file.existsSync()) {
      errors.add('Eksik belge: $relative');
      continue;
    }
    final content = file.readAsStringSync();
    documents[relative] = content;
    if (!content.contains('İBB Kent Takip')) {
      errors.add('Ürün adı eksik: $relative');
    }
  }

  final product = documents['PRODUCT.md'] ?? '';
  final ai = documents['AI_SYSTEM.md'] ?? '';
  final rules = documents['RULES.md'] ?? '';
  for (final phrase in [
    'İstanbul Senin/153',
    'UrbanIncident',
    'Fotoğrafsız devam',
    'vatandaş güven skoru yoktur',
  ]) {
    if (!product.toLowerCase().contains(phrase.toLowerCase())) {
      errors.add('PRODUCT kararı eksik: $phrase');
    }
  }
  if (!ai.contains('yalnız üç dar yetenek')) {
    errors.add('AI üç yeteneğe daraltılmamış.');
  }
  if (!rules.contains('Doğrudan aktif dosya overwrite yasaktır')) {
    errors.add('RULES atomik persistence kararı eksik.');
  }

  final adrDirectory = Directory('${root.path}/docs/decisions');
  final adrCount = adrDirectory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.split('/').last.startsWith('ADR-'))
      .length;
  if (adrCount < 8) {
    errors.add('En az 8 ADR gerekli; bulunan: $adrCount.');
  }

  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exitCode = 1;
    return;
  }
  stdout.writeln('Belge tutarlılığı doğrulandı: ${required.length} kanonik belge, $adrCount ADR.');
}

