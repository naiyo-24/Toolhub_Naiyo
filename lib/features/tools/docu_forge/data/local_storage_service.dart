import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static Future<String> getAppStoragePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/ToolHub';
    await Directory(path).create(recursive: true);
    return path;
  }

  static Future<String> getPdfStoragePath() async {
    final basePath = await getAppStoragePath();
    final path = '$basePath/documents/pdf';
    await Directory(path).create(recursive: true);
    return path;
  }

  static Future<String> getThumbnailStoragePath() async {
    final basePath = await getAppStoragePath();
    final path = '$basePath/documents/thumbnails';
    await Directory(path).create(recursive: true);
    return path;
  }

  static Future<String> getCameraTempPath() async {
    final basePath = await getAppStoragePath();
    final path = '$basePath/temp/camera';
    await Directory(path).create(recursive: true);
    return path;
  }

  static Future<String> getCropTempPath() async {
    final basePath = await getAppStoragePath();
    final path = '$basePath/temp/crop';
    await Directory(path).create(recursive: true);
    return path;
  }

  static Future<void> cleanupCache() async {
    final basePath = await getAppStoragePath();
    
    // Cleanup old temp files
    final tempDir = Directory('$basePath/temp');
    if (await tempDir.exists()) {
      final now = DateTime.now();
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (now.difference(stat.modified).inHours > 24) {
            await entity.delete();
          }
        }
      }
    }
  }
}
