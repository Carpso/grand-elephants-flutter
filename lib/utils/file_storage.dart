import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStorage {
  static Future<Directory> get _imagesDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> saveImageLocally(String sourceUri) async {
    try {
      final dir = await _imagesDir;
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}.jpg';
      final dest = File('${dir.path}/$filename');

      final sourceFile = File(Uri.parse(sourceUri).toFilePath());
      await sourceFile.copy(dest.path);

      return dest.path;
    } catch (e) {
      // ignore: avoid_print
      print('Error saving image locally: $e');
      return sourceUri;
    }
  }

  static Future<void> deleteImage(String uri) async {
    try {
      final file = File(Uri.parse(uri).toFilePath());
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting image: $e');
    }
  }

  static Future<List<String>> getAllImages() async {
    try {
      final dir = await _imagesDir;
      final contents = dir.listSync();
      return contents
          .whereType<File>()
          .map((f) => f.path)
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error getting all images: $e');
      return [];
    }
  }

  static Future<void> clearAllImages() async {
    try {
      final images = await getAllImages();
      for (final uri in images) {
        await deleteImage(uri);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error clearing all images: $e');
    }
  }
}
