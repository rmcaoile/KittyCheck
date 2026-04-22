import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/fgs_result.dart';

class FileService {
  /// TODO: toggle between cropped and placeholder images.
  static bool saveCroppedImagesFromAI = true;

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

  static Future<List<String>> createCroppedImageCopies(
      String originalPath, int resultId,
      {Map<String, String>? croppedImagePaths}) async {
    final List<String> imagePaths = [];

    final regionKeys = ['ears', 'eyes', 'muzzle', 'whiskers', 'head'];
    final regionNames = ['ears', 'eyes', 'muzzle', 'whiskers', 'head'];

    for (int i = 0; i < regionKeys.length; i++) {
      final regionKey = regionKeys[i];
      final regionName = regionNames[i];
      final fileName =
          '${resultId}_${regionName}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      String sourcePath;
      if (saveCroppedImagesFromAI &&
          croppedImagePaths != null &&
          croppedImagePaths.containsKey(regionKey)) {
        sourcePath = croppedImagePaths[regionKey]!;
      } else {
        sourcePath = originalPath;
      }

      final copiedPath = await copyImage(sourcePath, fileName);
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