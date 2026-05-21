import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

class UploadedFile {
  const UploadedFile({required this.path, this.publicUrl});

  final String path;
  final String? publicUrl;
}

class UploadService {
  Future<UploadedFile> uploadTaskImage({
    required String taskId,
    required XFile file,
  }) async {
    final user = supabase.auth.currentUser!;
    final extension = file.name.split('.').last.toLowerCase();
    final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final path =
        '${user.id}/$taskId/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await supabase.storage.from('task-images').uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: const FileOptions(upsert: false),
        );

    return UploadedFile(
      path: path,
      publicUrl: supabase.storage.from('task-images').getPublicUrl(path),
    );
  }
}
