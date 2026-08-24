import 'dart:typed_data';

import 'package:kent_takip_application/src/media_pipeline.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

final class DeterministicFakeCamera implements CameraCaptureGateway {
  DeterministicFakeCamera({required this.clock});
  final Clock clock;
  var _sequence = 0;

  @override
  Future<CapturedPhoto> capture() async {
    _sequence += 1;
    final now = clock.nowUtc();
    return CapturedPhoto(
      id: 'fake_capture_${now.microsecondsSinceEpoch}_$_sequence',
      bytes: Uint8List.fromList([0x4B, 0x54, _sequence % 256]),
      mimeType: 'image/jpeg',
      fileName: 'fake_$_sequence.jpg',
      capturedAt: now,
    );
  }

  @override
  Future<CapturedPhoto?> recoverInterruptedCapture() async => null;
}

final class DeterministicFakeAi implements AiAnalysisService {
  DeterministicFakeAi({required this.clock});
  final Clock clock;
  var _sequence = 0;

  @override
  Future<AiAnalysis> analyze({
    required String? mediaId,
    required String description,
    required GeoPoint location,
    required DateTime capturedAt,
  }) async {
    _sequence += 1;
    final normalized = description.toLowerCase();
    final category = normalized.contains('çukur') || normalized.contains('asfalt')
        ? 'road_surface_damage'
        : null;
    return AiAnalysis(
      id: 'fake_analysis_${clock.nowUtc().microsecondsSinceEpoch}_$_sequence',
      status: category == null ? AiAnalysisStatus.partial : AiAnalysisStatus.complete,
      categoryConfidence: category == null ? null : 76,
      duplicateConfidence: null,
      reasonCodes: [
        if (mediaId == null) 'no_media',
        if (category != null) 'description_keyword_match',
      ],
      modelVersion: 'deterministic-fake-v1',
      configVersion: 'wp06',
      createdAt: clock.nowUtc(),
      suggestedCategory: category,
    );
  }
}

final class DeterministicFakeMap implements MapGateway {
  var invocationCount = 0;

  @override
  Future<Uri> externalMapUri(GeoPoint point) async {
    invocationCount += 1;
    return Uri.https('maps.invalid', '/demo', {
      'lat': point.latitude.toString(),
      'lng': point.longitude.toString(),
      'invocation': '$invocationCount',
    });
  }
}
