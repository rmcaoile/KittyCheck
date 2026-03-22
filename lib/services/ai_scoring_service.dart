import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Service for AI-based FGS scoring using TFLite models
class AIScoringService {
  // Model interpreters
  Interpreter? _faceDetector;
  Interpreter? _regionDetector;
  Interpreter? _earsScorer;
  Interpreter? _eyesScorer;
  Interpreter? _muzzleScorer;
  Interpreter? _whiskersScorer;
  Interpreter? _headScorer;

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
      throw Exception('Failed to initialize AI models: $e');
    }
  }

  /// Load a TFLite model from assets
  Future<Interpreter> _loadModel(String modelPath) async {
    try {
      final interpreterOptions = InterpreterOptions();
      return await Interpreter.fromAsset(modelPath, options: interpreterOptions);
    } catch (e) {
      throw Exception('Failed to load model $modelPath: $e');
    }
  }

  /// Score image using AI models
  Future<Map<String, dynamic>> scoreImage(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('AI models not initialized. Call initialize() first.');
    }

    try {
      // Load and preprocess image
      final imageBytes = await File(imagePath).readAsBytes();
      final processedImage = await _preprocessImage(imageBytes);

      // Step 1: Face detection
      final faceRect = await _detectFace(processedImage);
      if (faceRect == null) {
        throw Exception('No cat face detected in image');
      }

      // Step 2: Region detection
      final landmarks = await _detectLandmarks(processedImage);
      if (landmarks.isEmpty) {
        throw Exception('Could not identify facial features');
      }

      // Step 3: Crop regions
      final regions = await _cropRegions(processedImage, faceRect, landmarks);

      // Step 4: Score each region
      final scores = <String, int>{};
      final croppedImages = <String, Uint8List>{};

      scores['ears'] = await _scoreRegion(regions['ears']!, _earsScorer!);
      scores['eyes'] = await _scoreRegion(regions['eyes']!, _eyesScorer!);
      scores['muzzle'] = await _scoreRegion(regions['muzzle']!, _muzzleScorer!);
      scores['whiskers'] = await _scoreRegion(regions['whiskers']!, _whiskersScorer!);
      scores['head'] = await _scoreRegion(regions['head']!, _headScorer!);

      // Store cropped images
      croppedImages['ears'] = regions['ears']!;
      croppedImages['eyes'] = regions['eyes']!;
      croppedImages['muzzle'] = regions['muzzle']!;
      croppedImages['whiskers'] = regions['whiskers']!;
      croppedImages['head'] = regions['head']!;

      return {
        'scores': scores,
        'croppedImages': croppedImages,
      };
    } catch (e) {
      throw Exception('AI scoring failed: $e');
    }
  }

  /// Preprocess image for model input
  Future<Uint8List> _preprocessImage(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Invalid image format');

    // Resize to 224x224 (model input size)
    final resized = img.copyResize(image, width: 224, height: 224);

    // Convert to RGB if needed
    final rgbImage = resized.convert(numChannels: 3);

    return Uint8List.fromList(img.encodeJpg(rgbImage));
  }

  /// Detect cat face in image
  Future<Rect?> _detectFace(Uint8List imageBytes) async {
    if (_faceDetector == null) return null;

    // Prepare input tensor
    final inputShape = _faceDetector!.getInputTensors().first.shape;
    final input = _prepareImageTensor(imageBytes, inputShape);

    // Run inference
    final output = _faceDetector!.getOutputTensors().first;
    _faceDetector!.run(input, output);

    // Parse output (assuming normalized bbox: x1, y1, x2, y2)
    final bbox = output.data as List<double>;
    if (bbox.length != 4) return null;

    return Rect.fromLTRB(bbox[0], bbox[1], bbox[2], bbox[3]);
  }

  /// Detect facial landmarks
  Future<Map<String, Point>> _detectLandmarks(Uint8List imageBytes) async {
    if (_regionDetector == null) return {};

    // Prepare input tensor
    final inputShape = _regionDetector!.getInputTensors().first.shape;
    final input = _prepareImageTensor(imageBytes, inputShape);

    // Run inference
    final output = _regionDetector!.getOutputTensors().first;
    _regionDetector!.run(input, output);

    // Parse output (assuming 5 points: left_eye, right_eye, nose, left_ear, right_ear)
    final coords = output.data as List<double>;
    if (coords.length != 10) return {}; // 5 points × 2 coords

    return {
      'left_eye': Point(coords[0], coords[1]),
      'right_eye': Point(coords[2], coords[3]),
      'nose': Point(coords[4], coords[5]),
      'left_ear': Point(coords[6], coords[7]),
      'right_ear': Point(coords[8], coords[9]),
    };
  }

  /// Crop facial regions
  Future<Map<String, Uint8List>> _cropRegions(
    Uint8List imageBytes,
    Rect faceRect,
    Map<String, Point> landmarks,
  ) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Invalid image');

    final regions = <String, Uint8List>{};

    // Crop ears region
    regions['ears'] = _cropEarsRegion(image, landmarks);

    // Crop eyes region
    regions['eyes'] = _cropEyesRegion(image, landmarks);

    // Crop muzzle region
    regions['muzzle'] = _cropMuzzleRegion(image, landmarks);

    // Crop whiskers region
    regions['whiskers'] = _cropWhiskersRegion(image, landmarks);

    // Crop head region
    regions['head'] = _cropHeadRegion(image, faceRect);

    return regions;
  }

  /// Score individual region
  Future<int> _scoreRegion(Uint8List regionBytes, Interpreter scorer) async {
    // Prepare input tensor
    final inputShape = scorer.getInputTensors().first.shape;
    final input = _prepareImageTensor(regionBytes, inputShape);

    // Run inference
    final output = scorer.getOutputTensors().first;
    scorer.run(input, output);

    // Parse output (assuming 3-class classification: 0, 1, 2)
    final scores = output.data as List<double>;
    if (scores.length != 3) throw Exception('Invalid scorer output');

    // Return class with highest probability
    int maxIndex = 0;
    double maxScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  /// Prepare image tensor for model input
  List<List<List<List<double>>>> _prepareImageTensor(Uint8List imageBytes, List<int> inputShape) {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Invalid image');

    // Resize to model input size
    final resized = img.copyResize(image, width: inputShape[2], height: inputShape[1]);

    // Convert to RGB if needed
    final rgbImage = resized.convert(numChannels: 3);

    // Normalize to [0, 1] and convert to tensor format [1, H, W, C]
    final tensor = List.generate(
      1, // batch size
      (b) => List.generate(
        inputShape[1], // height
        (h) => List.generate(
          inputShape[2], // width
          (w) {
            final pixel = rgbImage.getPixel(w, h);
            return [
              pixel.r / 255.0, // R
              pixel.g / 255.0, // G
              pixel.b / 255.0, // B
            ];
          },
        ),
      ),
    );

    return tensor;
  }

  /// Crop ears region
  Uint8List _cropEarsRegion(img.Image image, Map<String, Point> landmarks) {
    final leftEar = landmarks['left_ear']!;
    final rightEar = landmarks['right_ear']!;

    final xMin = (leftEar.x - 45).clamp(0, image.width - 1).toInt();
    final xMax = (rightEar.x + 45).clamp(0, image.width - 1).toInt();
    final yMin = (leftEar.y - 70).clamp(0, image.height - 1).toInt();
    final yMax = (rightEar.y + 40).clamp(0, image.height - 1).toInt();

    final cropped = img.copyCrop(image, x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin);
    final resized = img.copyResize(cropped, width: 224, height: 150);
    return Uint8List.fromList(img.encodeJpg(resized));
  }

  /// Crop eyes region
  Uint8List _cropEyesRegion(img.Image image, Map<String, Point> landmarks) {
    final leftEye = landmarks['left_eye']!;
    final rightEye = landmarks['right_eye']!;

    final xMin = (leftEye.x - 35).clamp(0, image.width - 1).toInt();
    final xMax = (rightEye.x + 35).clamp(0, image.width - 1).toInt();
    final yMin = (leftEye.y - 25).clamp(0, image.height - 1).toInt();
    final yMax = (rightEye.y + 25).clamp(0, image.height - 1).toInt();

    final cropped = img.copyCrop(image, x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin);
    final resized = img.copyResize(cropped, width: 224, height: 150);
    return Uint8List.fromList(img.encodeJpg(resized));
  }

  /// Crop muzzle region
  Uint8List _cropMuzzleRegion(img.Image image, Map<String, Point> landmarks) {
    final nose = landmarks['nose']!;

    final xMin = 0;
    final xMax = image.width - 1;
    final yMin = (nose.y - 40).clamp(0, image.height - 1).toInt();
    final yMax = (nose.y + 90).clamp(0, image.height - 1).toInt();

    final cropped = img.copyCrop(image, x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin);
    final resized = img.copyResize(cropped, width: 224, height: 180);
    return Uint8List.fromList(img.encodeJpg(resized));
  }

  /// Crop whiskers region
  Uint8List _cropWhiskersRegion(img.Image image, Map<String, Point> landmarks) {
    final nose = landmarks['nose']!;

    final xMin = (nose.x - 50).clamp(0, image.width - 1).toInt();
    final xMax = (nose.x + 50).clamp(0, image.width - 1).toInt();
    final yMin = (nose.y - 20).clamp(0, image.height - 1).toInt();
    final yMax = (nose.y + 80).clamp(0, image.height - 1).toInt();

    final cropped = img.copyCrop(image, x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin);
    final resized = img.copyResize(cropped, width: 224, height: 150);
    return Uint8List.fromList(img.encodeJpg(resized));
  }

  /// Crop head region
  Uint8List _cropHeadRegion(img.Image image, Rect faceRect) {
    final xMin = faceRect.left.toInt().clamp(0, image.width - 1);
    final yMin = faceRect.top.toInt().clamp(0, image.height - 1);
    final width = faceRect.width.toInt().clamp(1, image.width - xMin);
    final height = faceRect.height.toInt().clamp(1, image.height - yMin);

    final cropped = img.copyCrop(image, x: xMin, y: yMin, width: width, height: height);
    final resized = img.copyResize(cropped, width: 224, height: 224);
    return Uint8List.fromList(img.encodeJpg(resized));
  }

  /// Dispose of model interpreters
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
}

/// Simple Point class
class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}

/// Simple Rect class
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect.fromLTRB(this.left, this.top, this.right, this.bottom);

  double get width => right - left;
  double get height => bottom - top;
}