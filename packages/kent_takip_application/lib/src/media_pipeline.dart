import 'dart:math';
import 'dart:typed_data';

import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

enum CameraFailureCode {
  permissionDenied,
  permissionRestricted,
  unavailable,
  cancelled,
  interrupted,
  quotaExceeded,
  invalidMedia,
}

final class CameraFailure implements Exception {
  const CameraFailure(this.code, this.message);
  final CameraFailureCode code;
  final String message;

  @override
  String toString() => 'CameraFailure(${code.name}, $message)';
}

final class CapturedPhoto {
  const CapturedPhoto({
    required this.id,
    required this.bytes,
    required this.mimeType,
    required this.fileName,
    required this.capturedAt,
  });

  final String id;
  final Uint8List bytes;
  final String mimeType;
  final String fileName;
  final DateTime capturedAt;
}

abstract interface class CameraCaptureGateway {
  Future<CapturedPhoto?> capture();

  Future<CapturedPhoto?> recoverInterruptedCapture();
}

enum DemoPrivacyScenario { noSensitiveContent, manualReview, processingFailure }

final class PreparedMedia {
  const PreparedMedia({
    required this.reference,
    required this.originalId,
    required this.originalBytes,
    this.publicId,
    this.publicBytes,
  });

  final MediaRefDto reference;
  final String originalId;
  final Uint8List originalBytes;
  final String? publicId;
  final Uint8List? publicBytes;
}

final class MediaPipeline {
  MediaPipeline({Random? random}) : _random = random ?? Random.secure();

  static const maxBytes = 8 * 1024 * 1024;
  static const maxDimension = 4096;
  static const maxPixels = 12 * 1024 * 1024;

  final Random _random;

  PreparedMedia prepare({
    required String actorId,
    required CapturedPhoto capture,
    required DemoPrivacyScenario scenario,
  }) {
    requireText(actorId, 'actorId');
    if (capture.bytes.isEmpty || capture.bytes.length > maxBytes) {
      throw const CameraFailure(
        CameraFailureCode.quotaExceeded,
        'Fotoğraf 8 MB sınırını aşmamalıdır.',
      );
    }
    final sanitized = _sanitize(capture.bytes, capture.mimeType);
    final base = 'media_${actorId}_${_token(18)}';
    final originalId = '${base}_original';
    switch (scenario) {
      case DemoPrivacyScenario.noSensitiveContent:
        final publicId = '${base}_public';
        return PreparedMedia(
          reference: MediaRefDto(
            id: base,
            privacyStatus: PrivacyStatus.safe,
            originalRef: 'media://$originalId',
            publicRef: 'media://$publicId',
            mimeType: capture.mimeType,
          ),
          originalId: originalId,
          originalBytes: sanitized,
          publicId: publicId,
          publicBytes: Uint8List.fromList(sanitized),
        );
      case DemoPrivacyScenario.manualReview:
        return PreparedMedia(
          reference: MediaRefDto(
            id: base,
            privacyStatus: PrivacyStatus.manualReviewRequired,
            originalRef: 'media://$originalId',
            mimeType: capture.mimeType,
          ),
          originalId: originalId,
          originalBytes: sanitized,
        );
      case DemoPrivacyScenario.processingFailure:
        return PreparedMedia(
          reference: MediaRefDto(
            id: base,
            privacyStatus: PrivacyStatus.failed,
            originalRef: 'media://$originalId',
            mimeType: capture.mimeType,
          ),
          originalId: originalId,
          originalBytes: sanitized,
        );
    }
  }

  Uint8List _sanitize(Uint8List bytes, String mimeType) {
    return switch (mimeType.toLowerCase()) {
      'image/jpeg' || 'image/jpg' => _sanitizeJpeg(bytes),
      'image/png' => _sanitizePng(bytes),
      _ => throw const CameraFailure(
          CameraFailureCode.invalidMedia,
          'Yalnız JPEG ve PNG fotoğraflar desteklenir.',
        ),
    };
  }

  Uint8List _sanitizeJpeg(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
      throw const CameraFailure(CameraFailureCode.invalidMedia, 'JPEG başlığı geçersiz.');
    }
    final output = BytesBuilder(copy: false)..add([0xff, 0xd8]);
    var offset = 2;
    var dimensionsChecked = false;
    while (offset + 1 < bytes.length) {
      while (offset + 1 < bytes.length &&
          bytes[offset] == 0xff &&
          bytes[offset + 1] == 0xff) {
        offset += 1;
      }
      if (offset + 1 >= bytes.length) {
        throw const CameraFailure(CameraFailureCode.invalidMedia, 'JPEG sonu geçersiz.');
      }
      if (bytes[offset] != 0xff) {
        throw const CameraFailure(CameraFailureCode.invalidMedia, 'JPEG segmenti bozuk.');
      }
      final marker = bytes[offset + 1];
      if (marker == 0xda) {
        output.add(bytes.sublist(offset));
        break;
      }
      if (marker == 0xd9) {
        output.add([0xff, 0xd9]);
        break;
      }
      if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) {
        output.add([0xff, marker]);
        offset += 2;
        continue;
      }
      if (offset + 3 >= bytes.length) {
        throw const CameraFailure(CameraFailureCode.invalidMedia, 'JPEG uzunluğu geçersiz.');
      }
      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (length < 2 || offset + 2 + length > bytes.length) {
        throw const CameraFailure(CameraFailureCode.invalidMedia, 'JPEG segment uzunluğu geçersiz.');
      }
      final isSof = {
        0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf,
      }.contains(marker);
      if (isSof) {
        if (length < 7) {
          throw const CameraFailure(CameraFailureCode.invalidMedia, 'JPEG boyutu okunamadı.');
        }
        final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        _validateDimensions(width, height);
        dimensionsChecked = true;
      }
      final sensitiveMetadata =
          (marker >= 0xe1 && marker <= 0xef) || marker == 0xfe;
      if (!sensitiveMetadata) {
        output.add(bytes.sublist(offset, offset + 2 + length));
      }
      offset += 2 + length;
    }
    if (!dimensionsChecked) {
      throw const CameraFailure(CameraFailureCode.invalidMedia, 'JPEG boyutu bulunamadı.');
    }
    return output.takeBytes();
  }

  Uint8List _sanitizePng(Uint8List bytes) {
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 33 || !_startsWith(bytes, signature)) {
      throw const CameraFailure(CameraFailureCode.invalidMedia, 'PNG başlığı geçersiz.');
    }
    final output = BytesBuilder(copy: false)..add(signature);
    var offset = 8;
    var dimensionsChecked = false;
    var sawEnd = false;
    while (offset + 12 <= bytes.length) {
      final length = _u32(bytes, offset);
      final end = offset + 12 + length;
      if (length > maxBytes || end > bytes.length) {
        throw const CameraFailure(CameraFailureCode.invalidMedia, 'PNG segmenti bozuk.');
      }
      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      if (type == 'IHDR') {
        if (length != 13) {
          throw const CameraFailure(CameraFailureCode.invalidMedia, 'PNG IHDR geçersiz.');
        }
        _validateDimensions(_u32(bytes, offset + 8), _u32(bytes, offset + 12));
        dimensionsChecked = true;
      }
      final critical = type == 'IHDR' || type == 'PLTE' || type == 'IDAT' || type == 'IEND';
      if (critical) output.add(bytes.sublist(offset, end));
      offset = end;
      if (type == 'IEND') {
        sawEnd = true;
        break;
      }
    }
    if (!dimensionsChecked || !sawEnd) {
      throw const CameraFailure(CameraFailureCode.invalidMedia, 'PNG yapısı tamamlanmamış.');
    }
    return output.takeBytes();
  }

  void _validateDimensions(int width, int height) {
    if (width <= 0 || height <= 0 ||
        width > maxDimension || height > maxDimension || width * height > maxPixels) {
      throw const CameraFailure(
        CameraFailureCode.invalidMedia,
        'Fotoğraf çözünürlüğü güvenli sınırların dışında.',
      );
    }
  }

  String _token(int length) {
    const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
  }
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) return false;
  }
  return true;
}

int _u32(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];
