import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class PickedImageFile {
  final Uint8List bytes;
  final String fileName;
  final String? sourcePath;

  const PickedImageFile({
    required this.bytes,
    required this.fileName,
    this.sourcePath,
  });
}

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<PickedImageFile?> pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      return PickedImageFile(
        bytes: bytes,
        fileName: file.name.isNotEmpty ? file.name : 'foto_pilihan.jpg',
        sourcePath: file.path,
      );
    } catch (_) {
      return null;
    }
  }
}
