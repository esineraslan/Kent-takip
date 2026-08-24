import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kent_takip_application/kent_takip_application.dart';

final class ImagePickerCameraGateway implements CameraCaptureGateway {
  ImagePickerCameraGateway({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<CapturedPhoto?> capture() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      return file == null ? null : _toCapture(file);
    } on PlatformException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<CapturedPhoto?> recoverInterruptedCapture() async {
    if (kIsWeb) return null;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      if (response.exception case final exception?) throw _failure(exception);
      final files = response.files;
      if (files == null || files.isEmpty) return null;
      return _toCapture(files.first);
    } on PlatformException catch (error) {
      throw _failure(error);
    }
  }

  Future<CapturedPhoto> _toCapture(XFile file) async {
    final bytes = await file.readAsBytes();
    final lower = file.name.toLowerCase();
    final mime =
        file.mimeType ?? (lower.endsWith('.png') ? 'image/png' : 'image/jpeg');
    final now = DateTime.now().toUtc();
    return CapturedPhoto(
      id: 'capture_${now.microsecondsSinceEpoch}',
      bytes: bytes,
      mimeType: mime,
      fileName: file.name,
      capturedAt: now,
    );
  }

  CameraFailure _failure(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('denied')) {
      return const CameraFailure(
        CameraFailureCode.permissionDenied,
        'Kamera izni reddedildi. Ayarlardan izin verebilir veya fotoğrafsız devam edebilirsin.',
      );
    }
    if (code.contains('restricted')) {
      return const CameraFailure(
        CameraFailureCode.permissionRestricted,
        'Kamera bu cihazda kısıtlanmış. Fotoğrafsız devam edebilirsin.',
      );
    }
    if (code.contains('no_available_camera')) {
      return const CameraFailure(
        CameraFailureCode.unavailable,
        'Bu cihazda kullanılabilir kamera bulunamadı.',
      );
    }
    return CameraFailure(
      CameraFailureCode.interrupted,
      error.message ?? 'Kamera işlemi tamamlanamadı.',
    );
  }
}
