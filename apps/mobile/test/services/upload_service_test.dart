import 'package:flutter_test/flutter_test.dart';
import 'package:zhao_bang_shou/services/upload_service.dart';

void main() {
  group('UploadService.safeTaskImageExtension', () {
    test('keeps allowed image extensions', () {
      expect(UploadService.safeTaskImageExtension('photo.JPG'), 'jpg');
      expect(UploadService.safeTaskImageExtension('photo.jpeg'), 'jpeg');
      expect(UploadService.safeTaskImageExtension('photo.png'), 'png');
      expect(UploadService.safeTaskImageExtension('photo.webp'), 'webp');
    });

    test('falls back to jpg for unknown extensions', () {
      expect(UploadService.safeTaskImageExtension('photo.gif'), 'jpg');
      expect(UploadService.safeTaskImageExtension('photo'), 'jpg');
    });
  });

  group('UploadService.taskImageContentType', () {
    test('maps known extensions to storage content types', () {
      expect(UploadService.taskImageContentType('png'), 'image/png');
      expect(UploadService.taskImageContentType('webp'), 'image/webp');
      expect(UploadService.taskImageContentType('jpg'), 'image/jpeg');
      expect(UploadService.taskImageContentType('jpeg'), 'image/jpeg');
    });
  });
}
