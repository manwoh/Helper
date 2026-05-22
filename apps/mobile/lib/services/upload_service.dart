import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

class UploadedFile {
  const UploadedFile({required this.path, this.publicUrl});

  final String path;
  final String? publicUrl;
}

class UploadService {
  static const maxTaskImageBytes = 10 * 1024 * 1024;

  static String safeTaskImageExtension(String fileName) {
    final parts = fileName.split('.');
    final extension = parts.length > 1 ? parts.last.toLowerCase() : '';
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'jpg';
  }

  static String taskImageContentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<UploadedFile> uploadTaskImage({
    required String taskId,
    required XFile file,
  }) async {
    final user = supabase.auth.currentUser!;
    final size = await file.length();
    if (size > maxTaskImageBytes) {
      throw ArgumentError('图片不能超过 10MB');
    }

    final safeExtension = safeTaskImageExtension(file.name);
    final path =
        '${user.id}/$taskId/${DateTime.now().microsecondsSinceEpoch}.$safeExtension';

    await supabase.storage.from('task-images').uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: FileOptions(
            contentType: taskImageContentType(safeExtension),
            upsert: false,
          ),
        );

    return UploadedFile(
      path: path,
      publicUrl: supabase.storage.from('task-images').getPublicUrl(path),
    );
  }
}
