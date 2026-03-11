import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/fgs_result.dart';

class FileService {
  static Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory(path.join(directory.path, 'cat_pain_detector'));

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return appDir.path;
  }

  static Future<String> saveImage(File imageFile, String fileName) async {
    final appDir = await getAppDirectory();
    final filePath = path.join(appDir, fileName);

    // Copy the image to app directory
    await imageFile.copy(filePath);

    return filePath;
  }

  static Future<String> copyImage(String sourcePath, String fileName) async {
    final sourceFile = File(sourcePath);
    return await saveImage(sourceFile, fileName);
  }

  static Future<void> deleteImage(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<List<String>> createCroppedImageCopies(String originalPath, int resultId) async {
    final List<String> imagePaths = [];

    // TODO: for now, just create copies of the original image for each facial region
    final regions = ['ear', 'eyes', 'muzzle', 'whiskers', 'head'];

    for (final region in regions) {
      final fileName = '${resultId}_${region}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final copiedPath = await copyImage(originalPath, fileName);
      imagePaths.add(copiedPath);
    }

    return imagePaths;
  }

  static Future<void> deleteResultImages(FGSResult result) async {
    final imagePaths = [
      result.originalImagePath,
      result.earImagePath,
      result.eyesImagePath,
      result.muzzleImagePath,
      result.whiskersImagePath,
      result.headPositionImagePath,
    ];

    for (final path in imagePaths) {
      if (path != null) {
        await deleteImage(path);
      }
    }
  }

  static String generateFileName(String prefix, int resultId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_${resultId}_$timestamp.jpg';
  }
}