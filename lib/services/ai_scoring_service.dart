import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';

/// Service for AI-based FGS scoring using TFLite models
class AIScoringService {
  // TFLite interpreters for each model
  Interpreter? _faceDetector;
  Interpreter? _regionDetector;
  Interpreter? _earsScorer;
  Interpreter? _eyesScorer;
  Interpreter? _muzzleScorer;
  Interpreter? _whiskersScorer;
  Interpreter? _headScorer;

  Interpreter? get earsScorer => _earsScorer;
  Interpreter? get eyesScorer => _eyesScorer;
  Interpreter? get muzzleScorer => _muzzleScorer;
  Interpreter? get whiskersScorer => _whiskersScorer;
  Interpreter? get headScorer => _headScorer;

  bool _isInitialized = false;

  /// Initialize all TFLite models
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load face detector
      _faceDetector = await _loadModel('assets/models/face_detector.tflite');

      // Load region detector
      _regionDetector = await _loadModel('assets/models/region_detector.tflite');

      // Load FGS scorers
      _earsScorer = await _loadModel('assets/models/ears_scorer.tflite');
      _eyesScorer = await _loadModel('assets/models/eyes_scorer.tflite');
      _muzzleScorer = await _loadModel('assets/models/muzzle_scorer.tflite');
      _whiskersScorer = await _loadModel('assets/models/whiskers_scorer.tflite');
      _headScorer = await _loadModel('assets/models/head_scorer.tflite');

      _isInitialized = true;
    } catch (e) {
      dispose();
      rethrow;
    }
  }

  Future<Interpreter> _loadModel(String assetPath) async {
    final interpreterOptions = InterpreterOptions();
    final interpreter = await Interpreter.fromAsset(assetPath, options: interpreterOptions);

    interpreter.allocateTensors();
    return interpreter;
  }

  void dispose() {
    _faceDetector?.close();
    _regionDetector?.close();
    _earsScorer?.close();
    _eyesScorer?.close();
    _muzzleScorer?.close();
    _whiskersScorer?.close();
    _headScorer?.close();

    _faceDetector = null;
    _regionDetector = null;
    _earsScorer = null;
    _eyesScorer = null;
    _muzzleScorer = null;
    _whiskersScorer = null;
    _headScorer = null;

    _isInitialized = false;
  }

  /// Main scoring method for test pipeline
  /// Returns {'scores': Map<String, int>, 'croppedImages': Map<String, Uint8List>}
  Future<Map<String, dynamic>> scoreImage(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('AIScoringService not initialized. Call initialize() first.');
    }

    final image = img.decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return await _runScoringPipeline(image);
  }

  /// Production method that returns FGSResult for the main app
  Future<FGSResult> scoreImageForResult(String imagePath, String catName) async {
    final result = await scoreImage(imagePath);
    final scores = result['scores'] as Map<String, int>;

    return FGSResult(
      catName: catName,
      dateTime: DateTime.now(),
      totalFgsScore: scores.values.reduce((a, b) => a + b),
      earScore: scores['ears'] ?? 0,
      eyesScore: scores['eyes'] ?? 0,
      muzzleScore: scores['muzzle'] ?? 0,
      whiskersScore: scores['whiskers'] ?? 0,
      headPositionScore: scores['head'] ?? 0,
      originalImagePath: imagePath,
    );
  }

  /// Run the complete scoring pipeline
  Future<Map<String, dynamic>> _runScoringPipeline(img.Image originalImage) async {
    final faceBbox = await _detectFace(originalImage);

    final landmarks = await _loadLandmarksIfAvailable();
    final expandedBbox = _expandBbox(faceBbox, originalImage.width, originalImage.height, landmarks: landmarks);
    final croppedFace = _cropImage(originalImage, expandedBbox);

    final croppedFaceResized = img.copyResize(croppedFace,
        width: 224, height: 224, interpolation: img.Interpolation.linear);

    final regionCenters = await _detectRegions(croppedFaceResized);

    final rotationAngle = _calculateRotationAngle(regionCenters);

    final rotatedData = _rotateFace(croppedFaceResized, regionCenters, rotationAngle);
    final rotatedFace = rotatedData['image'] as img.Image;
    final rotatedCenters = rotatedData['centers'] as Map<String, List<double>>;

    final croppedRegions = _cropRegions(rotatedFace, rotatedCenters);

    // Prepare head image before scoring 
    final headImage = _prepareHeadImage(originalImage, faceBbox);
    croppedRegions['head'] = headImage;

    final scores = await _scoreRegions(croppedRegions);

    final croppedImages = <String, Uint8List>{};
    for (final entry in croppedRegions.entries) {
      croppedImages[entry.key] = Uint8List.fromList(img.encodeJpg(entry.value as img.Image));
    }

    // Create debug images
    final rotatedFaceWithLandmarks =
        _createLandmarksImage(rotatedFace, rotatedCenters);
    final croppedFaceWithLandmarks =
        _createLandmarksImage(croppedFaceResized, regionCenters);

    final debugImages = <String, Uint8List>{
      'rotatedFace': Uint8List.fromList(img.encodeJpg(rotatedFace)),
      'rotatedFaceWithLandmarks':
          Uint8List.fromList(img.encodeJpg(rotatedFaceWithLandmarks)),
      'croppedFace': Uint8List.fromList(img.encodeJpg(croppedFaceResized)),
      'croppedFaceWithLandmarks':
          Uint8List.fromList(img.encodeJpg(croppedFaceWithLandmarks)),
    };

    return {
      'scores': scores,
      'croppedImages': croppedImages,
      'debugImages': debugImages,
    };
  }

  /// Detect face using TFLite model
  Future<List<int>> _detectFace(img.Image image) async {
    if (_faceDetector == null) {
      throw Exception('Face detector not loaded');
    }

    final resizedImage = _resizeWithPadding(image, 224, 224);
    final inputData = prepareImageForInference(resizedImage, normalize: false);
    final outputData = runInference(_faceDetector!, inputData);

    // Output is [x1, y1, x2, y2] normalized coordinates
    final predBboxNorm = outputData.first as List<dynamic>;

    // Convert normalized coordinates to pixel coordinates
    final x1 = ((predBboxNorm[0] as num) * image.width).round();
    final y1 = ((predBboxNorm[1] as num) * image.height).round();
    final x2 = ((predBboxNorm[2] as num) * image.width).round();
    final y2 = ((predBboxNorm[3] as num) * image.height).round();

    // Clamp to image bounds
    final clampedX1 = math.max(0, x1);
    final clampedY1 = math.max(0, y1);
    final clampedX2 = math.min(image.width, x2);
    final clampedY2 = math.min(image.height, y2);

    final faceBbox = [clampedX1, clampedY1, clampedX2, clampedY2];

    return faceBbox;
  }

  List<int> _expandBbox(List<int> bbox, int imgWidth, int imgHeight, {List<List<double>>? landmarks}) {
    var x1 = bbox[0], y1 = bbox[1], x2 = bbox[2], y2 = bbox[3];

    // Include landmarks in bbox if available
    if (landmarks != null && landmarks.isNotEmpty) {
      final landmarksArray = landmarks;
      double minX = double.infinity;
      double maxX = double.negativeInfinity;
      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (final landmark in landmarksArray) {
        minX = math.min(minX, landmark[0]);
        maxX = math.max(maxX, landmark[0]);
        minY = math.min(minY, landmark[1]);
        maxY = math.max(maxY, landmark[1]);
      }

      x1 = math.min(x1, minX.round());
      y1 = math.min(y1, minY.round());
      x2 = math.max(x2, maxX.round());
      y2 = math.max(y2, maxY.round());
    }

    final bw = x2 - x1;
    final bh = y2 - y1;
    final dx = (bw * 0.25).round();
    final dy = (bh * 0.25).round();
    final topMarginExtra = (bh * 0.30).round();

    final expandedX1 = math.max(0, x1 - dx);
    final expandedY1 = math.max(0, y1 - dy - topMarginExtra);
    final expandedX2 = math.min(imgWidth, x2 + dx);
    final expandedY2 = math.min(imgHeight, y2 + dy);

    return [expandedX1, expandedY1, expandedX2, expandedY2];
  }

  img.Image _cropImage(img.Image image, List<int> bbox) {
    final x1 = bbox[0], y1 = bbox[1], x2 = bbox[2], y2 = bbox[3];
    final width = x2 - x1;
    final height = y2 - y1;

    if (width <= 0 || height <= 0) {
      throw Exception('Invalid bbox for cropping');
    }
    return img.copyCrop(image, x: x1, y: y1, width: width, height: height);
  }

  Future<Map<String, List<double>>> _detectRegions(img.Image image) async {
    if (_regionDetector == null) {
      throw Exception('Region detector not loaded');
    }

    final resizedImage = img.copyResize(image,
        width: 224, height: 224, interpolation: img.Interpolation.linear);
    final inputData = prepareImageForInference(resizedImage, normalize: false);
    final outputData = runInference(_regionDetector!, inputData);

    // Output is 10 values: [x1,y1,x2,y2,x3,y3,x4,y4,x5,y5] for 5 regions
    final predCoords = outputData.first as List<double>;

    final regionOrder = ["left_eye", "right_eye", "nose", "left_ear", "right_ear"];
    final regionCenters = <String, List<double>>{};

    for (int i = 0; i < regionOrder.length; i++) {
      final xNorm = predCoords[i * 2];
      final yNorm = predCoords[i * 2 + 1];

      final x = math.max(0.0, math.min(224.0, xNorm * 224));
      final y = math.max(0.0, math.min(224.0, yNorm * 224));

      regionCenters[regionOrder[i]] = [x, y];
    }

    return regionCenters;
  }

  double _calculateRotationAngle(Map<String, List<double>> regionCenters) {
    final leftEye = regionCenters['left_eye'];
    final rightEye = regionCenters['right_eye'];

    if (leftEye == null || rightEye == null) return 0.0;

    final eyeVector = [rightEye[0] - leftEye[0], rightEye[1] - leftEye[1]];

    const earAlignmentTolerance = 0.02;
    if (eyeVector[0].abs() > 1e-6) {
      final horizontalRatio = eyeVector[1].abs() / (eyeVector[0].abs() + 1e-6);
      if (horizontalRatio < earAlignmentTolerance) {
        return 0.0;
      }
    }

    final angleRad = math.atan2(eyeVector[1], eyeVector[0]);
    final angleDeg = -angleRad * 180.0 / math.pi;

    const minAngleThreshold = 5.0;
    if (angleDeg.abs() < minAngleThreshold) {
      return 0.0;
    }

    return math.max(-30.0, math.min(30.0, angleDeg));
  }

  Map<String, dynamic> _rotateFace(img.Image image, Map<String, List<double>> centers, double angle) {
    if (angle.abs() < 0.1) {
      return {'image': image, 'centers': centers};
    }

    final leftEye = centers['left_eye'];
    final rightEye = centers['right_eye'];
    if (leftEye == null || rightEye == null) {
      return {'image': image, 'centers': centers};
    }

    final centerX = (leftEye[0] + rightEye[0]) / 2;
    final centerY = (leftEye[1] + rightEye[1]) / 2;

    final cosA = math.cos(angle * math.pi / 180.0);
    final sinA = math.sin(angle * math.pi / 180.0);

    final h = image.height.toDouble();
    final w = image.width.toDouble();
    final absCosA = cosA.abs();
    final absSinA = sinA.abs();
    final newW = ((h * absSinA) + (w * absCosA)).round();
    final newH = ((h * absCosA) + (w * absSinA)).round();

    final rotatedImage = img.Image(width: newW, height: newH);
    
    for (int y = 0; y < newH; y++) {
      for (int x = 0; x < newW; x++) {
        final dx = x - newW / 2;
        final dy = y - newH / 2;

        final srcX =  cosA * dx + sinA * dy + centerX;
        final srcY = -sinA * dx + cosA * dy + centerY;

        final srcXInt = srcX.floor();
        final srcYInt = srcY.floor();
        final srcXFrac = srcX - srcXInt;
        final srcYFrac = srcY - srcYInt;

        if (srcXInt >= 0 && srcXInt < image.width - 1 &&
            srcYInt >= 0 && srcYInt < image.height - 1) {
          final p00 = image.getPixel(srcXInt, srcYInt);
          final p10 = image.getPixel(srcXInt + 1, srcYInt);
          final p01 = image.getPixel(srcXInt, srcYInt + 1);
          final p11 = image.getPixel(srcXInt + 1, srcYInt + 1);

          final r = _lerp(_lerp(p00.r.toDouble(), p10.r.toDouble(), srcXFrac), _lerp(p01.r.toDouble(), p11.r.toDouble(), srcXFrac), srcYFrac);
          final g = _lerp(_lerp(p00.g.toDouble(), p10.g.toDouble(), srcXFrac), _lerp(p01.g.toDouble(), p11.g.toDouble(), srcXFrac), srcYFrac);
          final b = _lerp(_lerp(p00.b.toDouble(), p10.b.toDouble(), srcXFrac), _lerp(p01.b.toDouble(), p11.b.toDouble(), srcXFrac), srcYFrac);

          rotatedImage.setPixel(x, y, img.ColorRgb8(r.round(), g.round(), b.round()));
        } else {
          rotatedImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }

    final rotatedCenters = <String, List<double>>{};
    for (final entry in centers.entries) {
      final name = entry.key;
      final center = entry.value;

      final lx = center[0];
      final ly = center[1];

      final dx = cosA * (lx - centerX) - sinA * (ly - centerY);
      final dy = sinA * (lx - centerX) + cosA * (ly - centerY);

      rotatedCenters[name] = [dx + newW / 2, dy + newH / 2];
    }

    return {'image': rotatedImage, 'centers': rotatedCenters};
  }

  /// Create image with landmark points marked
  img.Image _createLandmarksImage(img.Image faceImage, Map<String, List<double>> regionCenters) {
    final markedImage = img.Image.from(faceImage);

    const int dotSize = 3;
    final dotColor = img.ColorRgb8(255, 0, 0);

    for (final entry in regionCenters.entries) {
      final center = entry.value;
      final x = center[0].round();
      final y = center[1].round();

      for (int dy = -dotSize; dy <= dotSize; dy++) {
        for (int dx = -dotSize; dx <= dotSize; dx++) {
          final drawX = x + dx;
          final drawY = y + dy;

          if (drawX >= 0 && drawX < markedImage.width &&
              drawY >= 0 && drawY < markedImage.height) {
            markedImage.setPixel(drawX, drawY, dotColor);
          }
        }
      }
    }

    return markedImage;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Map<String, img.Image> _cropRegions(img.Image image, Map<String, List<double>> centers) {
    final regions = <String, img.Image>{};

    // Crop ears region
    final leftEar = centers['left_ear'];
    final rightEar = centers['right_ear'];
    if (leftEar != null && rightEar != null) {
      final xMin = math.max(0, (math.min(leftEar[0], rightEar[0]) - 45).round());
      final xMax = math.min(image.width, (math.max(leftEar[0], rightEar[0]) + 45).round());
      final yMin = math.max(0, (math.min(leftEar[1], rightEar[1]) - 70).round());
      final yMax = math.min(image.height, (math.max(leftEar[1], rightEar[1]) + 40).round());

      if (xMax > xMin && yMax > yMin) {
        final cropped = img.copyCrop(image, x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin);
        regions['ears'] = img.copyResize(cropped,
            width: 224, height: 150, interpolation: img.Interpolation.linear);
      }
    }

    // Crop eyes region
    final leftEye = centers['left_eye'];
    final rightEye = centers['right_eye'];
    if (leftEye != null && rightEye != null) {
      final xMin = math.max(0, (math.min(leftEye[0], rightEye[0]) - 35).round());
      final xMax = math.min(image.width, (math.max(leftEye[0], rightEye[0]) + 35).round());
      final yMin = math.max(0, (math.min(leftEye[1], rightEye[1]) - 25).round());
      final yMax = math.min(image.height, (math.max(leftEye[1], rightEye[1]) + 25).round());

      if (xMax > xMin && yMax > yMin) {
        final cropped = img.copyCrop(image, x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin);
        regions['eyes'] = img.copyResize(cropped,
            width: 224, height: 150, interpolation: img.Interpolation.linear);
      }
    }

    // Crop muzzle region
    final nose = centers['nose'];
    final leftEyeLocal = centers['left_eye'];
    final rightEyeLocal = centers['right_eye'];
    if (nose != null && leftEyeLocal != null && rightEyeLocal != null) {
      final cx = nose[0];
      final cy = nose[1];

      // Width: eye-to-eye distance * 0.6 
      final eyeDistance = math.sqrt(
          math.pow(rightEyeLocal[0] - leftEyeLocal[0], 2) +
              math.pow(rightEyeLocal[1] - leftEyeLocal[1], 2));
      final muzzleWidth = math.max(100.0, eyeDistance * 0.6);

      // Height: focus on muzzle around nose
      final noseToEyeDist = leftEyeLocal[1] - nose[1];
      final marginYTop = math.max(35.0, noseToEyeDist * 0.5);
      final marginYBottom = math.max(45.0, noseToEyeDist * 0.5);

      final xMin = math.max(0, (cx - muzzleWidth / 2).round());
      final xMax = math.min(image.width, (cx + muzzleWidth / 2).round());
      final yMin = math.max(0, (cy - marginYTop).round());
      final yMax = math.min(image.height, (cy + marginYBottom).round());

      if (xMax > xMin && yMax > yMin) {
        final cropped = img.copyCrop(image, x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin);
        regions['muzzle'] = _resizeWithPadding(cropped, 224, 224);
      }
    }

    // Crop whiskers region
    final leftEarLocal = centers['left_ear'];
    final rightEarLocal = centers['right_ear'];
    if (nose != null &&
        leftEarLocal != null &&
        rightEarLocal != null &&
        leftEyeLocal != null &&
        rightEyeLocal != null) {
      final cx = nose[0];
      final cy = nose[1];

      // Width: ear-to-ear distance * 2.0
      final earDistance = math.sqrt(
          math.pow(rightEarLocal[0] - leftEarLocal[0], 2) +
              math.pow(rightEarLocal[1] - leftEarLocal[1], 2));
      final whiskersWidth = math.max(160.0, earDistance * 2.0);

      // Height: focus on lower face
      final avgEyeY = (leftEyeLocal[1] + rightEyeLocal[1]) / 2;
      final noseToEyeDist = avgEyeY - nose[1];
      final marginYTop = math.max(25.0, noseToEyeDist * 0.3);
      final marginYBottom = math.max(70.0, noseToEyeDist * 1.2);

      final xMin = math.max(0, (cx - whiskersWidth / 2).round());
      final xMax = math.min(image.width, (cx + whiskersWidth / 2).round());
      final yMin = math.max(0, (cy - marginYTop).round());
      final yMax = math.min(image.height, (cy + marginYBottom).round());

      if (xMax > xMin && yMax > yMin) {
        final cropped = img.copyCrop(image, x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin);
        regions['whiskers'] = _resizeWithPadding(cropped, 224, 224);
      }
    }

    return regions;
  }

  Future<Map<String, int>> _scoreRegions(Map<String, img.Image> regions) async {
    final scores = <String, int>{};

    final regionModelMap = {
      'ears': _earsScorer,
      'eyes': _eyesScorer,
      'muzzle': _muzzleScorer,
      'whiskers': _whiskersScorer,
      'head': _headScorer,
    };

    for (final regionName in ['ears', 'eyes', 'muzzle', 'whiskers', 'head']) {
      final regionImage = regions[regionName];
      final scorer = regionModelMap[regionName];

      if (regionImage != null && scorer != null) {
        final resizedImage = img.copyResize(regionImage,
            width: 224, height: 224, interpolation: img.Interpolation.linear);
        final inputData = prepareImageForInference(resizedImage,
            normalize: true, regionName: regionName);
        final outputData = runInference(scorer, inputData);

        final probabilities = outputData.first as List<double>;

        final predictedClass =
            probabilities.indexOf(probabilities.reduce(math.max));
        scores[regionName] = predictedClass;
      } else {
        scores[regionName] = 0;
      }
    }

    return scores;
  }

  img.Image _prepareHeadImage(img.Image originalImage, List<int> faceBbox) {
    final imageWithBox = img.Image.from(originalImage);
    img.drawRect(imageWithBox,
        x1: faceBbox[0],
        y1: faceBbox[1],
        x2: faceBbox[2],
        y2: faceBbox[3],
        color: img.ColorRgb8(255, 0, 0),
        thickness: 3);

    return _resizeWithPadding(imageWithBox, 224, 224);
  }

  /// Resize image with padding to maintain aspect ratio
  img.Image _resizeWithPadding(
      img.Image image, int targetWidth, int targetHeight) {
    final srcWidth = image.width;
    final srcHeight = image.height;

    final scale = math.min(targetWidth / srcWidth, targetHeight / srcHeight);
    final newWidth = (srcWidth * scale).toInt();
    final newHeight = (srcHeight * scale).toInt();
    final resized = img.copyResize(image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear);
    final result = img.Image(width: targetWidth, height: targetHeight);
    img.fill(result, color: img.ColorRgb8(0, 0, 0));
    final pasteX = (targetWidth - newWidth) ~/ 2;
    final pasteY = (targetHeight - newHeight) ~/ 2;

    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        final srcPixel = resized.getPixel(x, y);
        result.setPixel(x + pasteX, y + pasteY, srcPixel);
      }
    }

    return result;
  }

  /// Prepare image for TFLite inference (NHWC format)
  List<List<List<List<double>>>> prepareImageForInference(img.Image image,
      {bool normalize = true, String regionName = "unknown"}) {
    // Ensure we have an RGB image
    img.Image rgbImage;
    if (image.numChannels == 4) {
      // Handle RGBA - convert to RGB
      rgbImage = img.Image(width: image.width, height: image.height);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          rgbImage.setPixel(x, y,
              img.ColorRgb8(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()));
        }
      }
    } else {
      rgbImage = image;
    }

    final width = rgbImage.width;
    final height = rgbImage.height;

    // Build NHWC tensor (batch, height, width, channels)
    final tensor = List.generate(
        1, // batch size = 1
        (b) => List.generate(
            height,
            (y) => List.generate(width, (x) {
                  final pixel = rgbImage.getPixel(x, y);
                  final r = pixel.r.toDouble() / 255.0;
                  final g = pixel.g.toDouble() / 255.0;
                  final b = pixel.b.toDouble() / 255.0;

                  // Apply ImageNet normalization
                  final normalizedR = normalize ? (r - 0.485) / 0.229 : r;
                  final normalizedG = normalize ? (g - 0.456) / 0.224 : g;
                  final normalizedB = normalize ? (b - 0.406) / 0.225 : b;

                  return [normalizedR, normalizedG, normalizedB];
                })));

    return tensor;
  }

  Future<List<List<double>>?> _loadLandmarksIfAvailable() async {
    try {
      final landmarksPath = 'temp_folder_training_models_arch/sample/test_sample.json';
      final file = File(landmarksPath);
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final labelsRaw = jsonData['labels'];
      if (labelsRaw is! List) return null;

      final landmarks = <List<double>>[];
      for (final label in labelsRaw) {
        if (label is List) {
          final landmark = <double>[];
          for (final coord in label) {
            landmark.add((coord as num).toDouble());
          }
          if (landmark.length >= 2) {
            landmarks.add(landmark);
          }
        }
      }

      return landmarks.isNotEmpty ? landmarks : null;
    } catch (e) {
      return null;
    }
  }

  /// Run inference with TFLite interpreter
  List<dynamic> runInference(Interpreter interpreter, List<List<List<List<double>>>> inputData) {
    final outputShape = interpreter.getOutputTensors()[0].shape;

    List output;
    if (outputShape.length == 2 && outputShape[0] == 1) {
      final featureSize = outputShape[1];
      output = [List.filled(featureSize, 0.0)];
    } else if (outputShape.length == 1) {
      final featureSize = outputShape[0];
      output = List.filled(featureSize, 0.0);
    } else {
      final outputSize = outputShape.reduce((a, b) => a * b);
      output = List.filled(outputSize, 0.0);
    }

    interpreter.run(inputData, output);

    if (output is List && output.isNotEmpty && output[0] is List) {
      return [output[0]];
    }
    return [output];
  }
}
