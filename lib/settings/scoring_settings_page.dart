import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/services/scoring_settings_service.dart';
import 'package:cat_pain_detector/services/ai_scoring_service.dart';
import 'package:cat_pain_detector/services/file_service.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';

class ScoringSettingsPage extends StatefulWidget {
  const ScoringSettingsPage({super.key});

  @override
  State<ScoringSettingsPage> createState() => _ScoringSettingsPageState();
}

class _ScoringSettingsPageState extends State<ScoringSettingsPage> {
  final ScoringSettingsService _settingsService = ScoringSettingsService();
  bool _useAIScoring = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final useAI = await _settingsService.getUseAIScoring();
    setState(() {
      _useAIScoring = useAI;
    });
  }

  Future<void> _toggleAIScoring(bool value) async {
    await _settingsService.setUseAIScoring(value);
    setState(() {
      _useAIScoring = value;
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'AI scoring enabled. Images will be analyzed using trained models.'
                : 'Random scoring enabled. Images will use random scores for testing.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _runAIPipelineTest() async {
    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Testing AI Pipeline...'),
          ],
        ),
      ),
    );

    try {
      // Initialize AI service
      final aiService = AIScoringService();
      await aiService.initialize();

      // Load test image from assets
      final imageData = await rootBundle.load('assets/images/test_sample.png');
      final bytes = imageData.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await FileService.getAppDirectory();
      final tempImagePath = '$tempDir/test_sample_temp.png';
      final tempFile = File(tempImagePath);
      await tempFile.writeAsBytes(bytes);

      // Run the test
      final result = await aiService.scoreImage(tempImagePath);
      final scores = result['scores'] as Map<String, int>;
      final croppedImages = result['croppedImages'] as Map<String, Uint8List>;
      final debugImages = result['debugImages'] as Map<String, Uint8List>?;

      // Save cropped images to app documents directory for comparison
      final appDir = await FileService.getAppDirectory();
      final debugDir = Directory('$appDir/debug_output');
      if (!debugDir.existsSync()) {
        debugDir.createSync(recursive: true);
      }

      final savedPaths = <String, String>{};
      for (final entry in croppedImages.entries) {
        final regionName = entry.key;
        final imageData = entry.value;
        final imagePath = '${debugDir.path}/${regionName}_crop.jpg';
        File(imagePath).writeAsBytesSync(imageData);
        savedPaths[regionName] = imagePath;
      }

      // Save debug images
      final debugSavedPaths = <String, String>{};
      if (debugImages != null) {
        for (final entry in debugImages.entries) {
          final imageName = entry.key;
          final imageData = entry.value;
          final imagePath = '${debugDir.path}/${imageName}.jpg';
          File(imagePath).writeAsBytesSync(imageData);
          debugSavedPaths[imageName] = imagePath;
        }
      }

      // Calculate total score
      final totalScore = scores.values.reduce((a, b) => a + b);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show results dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('AI Pipeline Test Results'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Test Image: test_sample.png'),
                  const SizedBox(height: 16),
                  const Text('Individual Scores:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...scores.entries.map((e) => Text('  ${e.key}: ${e.value}')),
                  const SizedBox(height: 8),
                  Text('Total FGS Score: $totalScore',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Cropped Region Images:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...savedPaths.entries.map((e) => Row(
                        children: [
                          Expanded(child: Text('  ${e.key}')),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ImageViewerPage(
                                    imagePath: e.value,
                                    isAsset: false,
                                  ),
                                ),
                              );
                            },
                            child: const Text('View'),
                          ),
                        ],
                      )),
                  if (debugSavedPaths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Debug Images:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...debugSavedPaths.entries.map((e) => Row(
                          children: [
                            Expanded(child: Text('  ${e.key}')),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ImageViewerPage(
                                      imagePath: e.value,
                                      isAsset: false,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View'),
                            ),
                          ],
                        )),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

      aiService.dispose();

    } catch (e, stackTrace) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        _showErrorDialog('Test failed: $e\n\nStack trace: $stackTrace');
      }
    }
  }

  Future<void> _runCNNScorersTest() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Testing CNN FGS Scorers...'),
          ],
        ),
      ),
    );

    try {
      final aiService = AIScoringService();
      await aiService.initialize();

      final regionNames = ['ears', 'eyes', 'muzzle', 'whiskers', 'head'];
      final scores = <String, int>{};

      for (final regionName in regionNames) {
        final imageData = await rootBundle
            .load('assets/images/output_tflite/$regionName.png');
        final bytes = imageData.buffer.asUint8List();

        final image = img.decodeImage(bytes);
        if (image == null) {
          continue;
        }
        // DEBUG: Log image dimensions for head
        if (regionName == 'head') {
          debugPrint(
              '[SETTINGS DEBUG] head image: width=${image.width}, height=${image.height}');
        }

        final resizedImage = img.copyResize(image,
            width: 224, height: 224, interpolation: img.Interpolation.linear);
        if (regionName == 'head') {
          debugPrint(
              '[SETTINGS DEBUG] resized head: width=${resizedImage.width}, height=${resizedImage.height}');
        }
        final inputData = aiService.prepareImageForInference(resizedImage,
            normalize: true, regionName: regionName);

        final scorer = switch (regionName) {
          'ears' => aiService.earsScorer,
          'eyes' => aiService.eyesScorer,
          'muzzle' => aiService.muzzleScorer,
          'whiskers' => aiService.whiskersScorer,
          'head' => aiService.headScorer,
          _ => null,
        };

        if (scorer != null) {
          final outputData = aiService.runInference(scorer, inputData);
          final probabilities = outputData.first as List<double>;
          // DEBUG: Log raw model outputs for head
          if (regionName == 'head') {
            debugPrint(
                '[SETTINGS DEBUG] head_scorer raw outputs: $probabilities');
          }
          final predictedClass = probabilities
              .indexOf(probabilities.reduce((a, b) => a > b ? a : b));
          scores[regionName] = predictedClass;
          if (regionName == 'head') {
            debugPrint(
                '[SETTINGS DEBUG] head_scorer predicted class: $predictedClass');
          }
        }
      }

      final totalScore = scores.values.fold(0, (a, b) => a + b);

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('CNN FGS Scorers Test Results'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pre-cropped Images from output_tflite:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Individual Scores:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...scores.entries.map((e) => Text('  ${e.key}: ${e.value}')),
                  const SizedBox(height: 8),
                  Text('Total FGS Score: $totalScore',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

      aiService.dispose();
    } catch (e, stackTrace) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        _showErrorDialog('Test failed: $e\n\nStack trace: $stackTrace');
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Error'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: const Text(
          'Scoring Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FGS Scoring Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose how FGS scores are calculated from cat images.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),

            // AI Scoring Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _useAIScoring ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useAIScoring ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _useAIScoring ? Icons.smart_toy : Icons.smart_toy_outlined,
                        color: _useAIScoring ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'AI Scoring (Trained Models)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: _useAIScoring,
                        onChanged: _toggleAIScoring,
                        activeColor: const Color.fromRGBO(76, 175, 80, 1),
                      ),
                    ],
                  ),
                  if (_useAIScoring) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Active - Using AI models for scoring',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Random Scoring Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_useAIScoring ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_useAIScoring ? Colors.orange : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        !_useAIScoring ? Icons.shuffle : Icons.shuffle_outlined,
                        color: !_useAIScoring ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Random Scoring (Testing)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: !_useAIScoring,
                        onChanged: (value) => _toggleAIScoring(!value),
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                  if (!_useAIScoring) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Active - Using random scores for testing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Test AI Pipeline Button
            if (_useAIScoring) ...[
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runAIPipelineTest,
                  icon: const Icon(Icons.science),
                  label: const Text('Test AI Pipeline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test the AI pipeline on the sample image and view cropped regions.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runCNNScorersTest,
                  icon: const Icon(Icons.model_training),
                  label: const Text('Test CNN FGS Scorers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test CNN FGS scorers using pre-cropped images from output_tflite.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }
}
