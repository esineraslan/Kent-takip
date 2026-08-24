import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:test/test.dart';

void main() {
  final clock = _FixedClock(DateTime.utc(2026, 8, 17, 15));

  test('kamera fake her çağrıda izlenebilir yeni sonuç üretir', () async {
    final camera = DeterministicFakeCamera(clock: clock);

    final first = await camera.capture();
    final second = await camera.capture();

    expect(first.id, isNot(second.id));
    expect(first.bytes, isNot(equals(second.bytes)));
    expect(first.capturedAt, clock.value);
  });

  test('AI fake açıklama sinyalinden gerekçeli öneri üretir', () async {
    final ai = DeterministicFakeAi(clock: clock);

    final result = await ai.analyze(
      mediaId: null,
      description: 'Asfaltta büyük çukur var.',
      location: GeoPoint(latitude: 41, longitude: 29),
      capturedAt: clock.value,
    );

    expect(result.suggestedCategory, 'road_surface_damage');
    expect(result.reasonCodes, containsAll(['no_media', 'description_keyword_match']));
    expect(result.modelVersion, 'deterministic-fake-v1');
  });

  test('harita fake çağrı sayısını URL sonucuna yansıtır', () async {
    final map = DeterministicFakeMap();
    final point = GeoPoint(latitude: 41, longitude: 29);

    final first = await map.externalMapUri(point);
    final second = await map.externalMapUri(point);

    expect(first.queryParameters['invocation'], '1');
    expect(second.queryParameters['invocation'], '2');
  });
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}
