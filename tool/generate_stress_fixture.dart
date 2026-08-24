import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final output = arguments.isEmpty
      ? File('artifacts/stress_fixture_10000.json')
      : File(arguments.first);
  await output.parent.create(recursive: true);
  final incidents = <Map<String, Object?>>[];
  for (var index = 0; index < 10000; index++) {
    incidents.add({
      'id': 'stress_inc_${index.toString().padLeft(5, '0')}',
      'status': index.isEven ? 'verified_active' : 'pending_verification',
      'category': index % 3 == 0 ? 'road_surface_damage' : 'water_leak',
      'location': {
        'latitude': 40.85 + (index % 300) / 1000,
        'longitude': 28.65 + (index % 500) / 1000,
        'coordinateSystem': 'EPSG:4326',
      },
      'createdAt': '2026-08-17T08:00:00.000Z',
    });
  }
  await output.writeAsString(jsonEncode({'synthetic': true, 'incidents': incidents}));
  stdout.writeln('10.000 sentetik olay üretildi: ${output.path}');
}

