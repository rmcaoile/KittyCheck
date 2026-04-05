import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/services/database_service.dart';
import 'package:cat_pain_detector/services/file_service.dart';
import 'package:cat_pain_detector/services/scoring_settings_service.dart';
import 'package:cat_pain_detector/services/ai_scoring_service.dart';
import 'package:cat_pain_detector/history/result_detail.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';
import 'package:cat_pain_detector/home/edit_result.dart';
import 'package:cat_pain_detector/main.dart';

class FGSResultPage extends StatefulWidget {
  final String imagePath;

  const FGSResultPage({super.key, required this.imagePath});

  @override
  State<FGSResultPage> createState() => _FGSResultPageState();
}

class _FGSResultPageState extends State<FGSResultPage> {
  late int earScore;
  late int eyesScore;
  late int muzzleScore;
  late int whiskersScore;
  late int headPositionScore;
  late int totalFgsScore;

  bool _isLoading = true;
  String? _errorMessage;
  bool _useAIScoring = false;

  final AIScoringService _aiService = AIScoringService();
  final ScoringSettingsService _settingsService = ScoringSettingsService();

  @override
  void initState() {
    super.initState();
    _initializeScoring();
  }

  @override
  void dispose() {
    // Clean up temporary images when the widget is disposed
    _cleanupTempImages();
    super.dispose();
  }

  Future<void> _cleanupTempImages() async {
    if (_tempCroppedImagePaths != null) {
      for (final path in _tempCroppedImagePaths!.values) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      }
      _tempCroppedImagePaths = null;
    }
  }

  Future<void> _initializeScoring() async {
    _useAIScoring = await _settingsService.getUseAIScoring();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_useAIScoring) {
        await _runAIScoring();
      } else {
        await _runRandomScoring();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, String>? _tempCroppedImagePaths;

  Future<void> _runAIScoring() async {
    try {
      // Initialize AI models (only once)
      await _aiService.initialize();

      // Perform AI cropping and scoring
      final result = await _aiService.scoreImage(widget.imagePath);
      final scores = result['scores'] as Map<String, int>;
      final croppedImages = result['croppedImages'] as Map<String, Uint8List>;

      // Save cropped images temporarily
      _tempCroppedImagePaths = await _saveTempCroppedImages(croppedImages);

      // Use AI-calculated scores
      earScore = scores['ears'] ?? 0;
      eyesScore = scores['eyes'] ?? 0;
      muzzleScore = scores['muzzle'] ?? 0;
      whiskersScore = scores['whiskers'] ?? 0;
      headPositionScore = scores['head'] ?? 0;
      totalFgsScore = earScore + eyesScore + muzzleScore + whiskersScore + headPositionScore;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      throw Exception('AI scoring failed: $e');
    }
  }

  Future<void> _runRandomScoring() async {
    try {
      // Generate random scores
      final random = Random();
      earScore = random.nextInt(3); // 0-2
      eyesScore = random.nextInt(3);
      muzzleScore = random.nextInt(3);
      whiskersScore = random.nextInt(3);
      headPositionScore = random.nextInt(3);
      totalFgsScore = earScore + eyesScore + muzzleScore + whiskersScore + headPositionScore;

      // Create duplicate images for display (no AI processing)
      final tempDir = await FileService.getAppDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final paths = <String, String>{};

      // Create copies of the original image for each region
      final regions = ['ears', 'eyes', 'muzzle', 'whiskers', 'head'];
      for (final region in regions) {
        final fileName = 'temp_${region}_${timestamp}.jpg';
        final filePath = '$tempDir/$fileName';

        // Copy the original image
        await File(widget.imagePath).copy(filePath);
        paths[region] = filePath;
      }

      _tempCroppedImagePaths = paths;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      throw Exception('Random scoring failed: $e');
    }
  }

  Future<Map<String, String>> _saveTempCroppedImages(Map<String, Uint8List> croppedImages) async {
    final tempDir = await FileService.getAppDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final paths = <String, String>{};

    // Save each cropped image as a temporary file
    for (final entry in croppedImages.entries) {
      final region = entry.key;
      final imageData = entry.value;
      final fileName = 'temp_${region}_${timestamp}.jpg';
      final filePath = '$tempDir/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(imageData);
      paths[region] = filePath;
    }

    return paths;
  }



  Future<void> _showSaveDialog() async {
    final TextEditingController nameController = TextEditingController();
    final dbService = DatabaseService();
    // TODO: add name suggestion
    // Get next number
    int nextNumber = 1;
    try {
      nextNumber = await dbService.getNextCatNumber();
    } catch (e) {
      // Use default if error
    }
    nameController.text = 'Cat No. $nextNumber';

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save FGS Result'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Cat Name',
              hintText: 'Enter cat name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final catName = nameController.text.trim();
                FocusScope.of(context).unfocus();

                try {
                  await _saveResult(catName);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Result saved successfully!')),
                    );
                    // Navigate to history tab
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    homePageKey.currentState?.switchToHistory();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving result: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveResult(String catName) async {
    try {
      final dbService = DatabaseService();

      // Save original image
      final originalFileName = 'original_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = await FileService.saveImage(File(widget.imagePath), originalFileName);

      // Create cropped image copies (dummy for now)
      final tempResultId =
          DateTime.now().millisecondsSinceEpoch; // Temporary ID for file naming
      final croppedPaths = await FileService.createCroppedImageCopies(
        savedImagePath,
        tempResultId,
        croppedImagePaths: _tempCroppedImagePaths,
      );

      // Create FGS result
      final finalCatName = catName.isEmpty ? 'Cat No. ${await dbService.getNextCatNumber()}' : catName;
      final result = FGSResult(
        catName: finalCatName,
        dateTime: DateTime.now(),
        totalFgsScore: totalFgsScore,
        earScore: earScore,
        eyesScore: eyesScore,
        muzzleScore: muzzleScore,
        whiskersScore: whiskersScore,
        headPositionScore: headPositionScore,
        originalImagePath: savedImagePath,
        earImagePath: croppedPaths[0],
        eyesImagePath: croppedPaths[1],
        muzzleImagePath: croppedPaths[2],
        whiskersImagePath: croppedPaths[3],
        headPositionImagePath: croppedPaths[4],
      );

      // Save to database
      await dbService.insertResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving result: $e')),
        );
      }
    }
  }

  String _getAssessmentText(int score) {
    if (score == 0) {
      return 'This cat is not in pain. However, if you are a cat owner and you are concerned or think your cat may be in pain, please consult your veterinary surgeon.';
    } else if (score >= 1 && score <= 3) {
      return 'This cat is not in pain or has mild pain. Pain should be reevaluated at regular intervals since FGS scores could increase, and the cat might require analgesics.';
    } else if (score >= 4 && score <= 8) {
      return 'This cat is likely to be in pain. This score indicates the need for additional analgesia. This decision should be made by a veterinary surgeon based on clinical judgement, and in consideration of the physical status of the patient and other drugs previously administered. If in doubt, reassess the cat in 10-15 minutes to reconfirm scores. Clinical judgement will differentiate if the FGS scores are high due to pain, rather than other factors such as stress, fear or sedation.';
    } else if (score >= 9 && score <= 10) {
      return 'This cat is likely to be in severe pain. This score indicates the need for additional analgesia. This decision should be made by a veterinary surgeon based on clinical judgement, and in consideration of the physical status of the patient and other drugs previously administered. If in doubt, reassess the cat in 10-15 minutes to reconfirm scores. Clinical judgement will differentiate if the FGS scores are high due to pain, rather than other factors such as stress, fear or sedation.';
    } else {
      return 'Invalid score';
    }
  }

  /// Build a tile for displaying a cropped region
  Widget _buildCroppedRegionTile(String regionName, String imagePath, int score) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerPage(imagePath: imagePath),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Text(
                    regionName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a score display widget
  Widget _buildScoreDisplay(String regionName, int score) {
    return Column(
      children: [
        Text(
          regionName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getScoreColor(score).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getScoreColor(score),
              width: 1,
            ),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
        ),
      ],
    );
  }

  /// Get color for score display
  Color _getScoreColor(int score) {
    if (score == 0) return Colors.green;
    if (score == 1) return Colors.yellow;
    if (score == 2) return Colors.red;
    return Colors.grey;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: const Text(
          'FGS Analysis Result',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TODO: Focus on face
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerPage(imagePath: widget.imagePath),
                  ),
                );
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: lightBlue, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Show loading indicator if AI is processing
            if (_isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: _useAIScoring
                        ? Colors.green.withValues(alpha: 0.05)
                        : Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _useAIScoring ? Colors.green : Colors.orange,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _useAIScoring
                            ? 'Analyzing cat expression...'
                            : 'Generating random scores...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                    ],
                  ),
                ),
              )
            // Show error message if AI failed
            else if (_errorMessage != null)
              Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 10),
                  const Text(
                    'Analysis Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _initializeScoring,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            // Show results when ready
            else
              Column(
                children: [
                  // Scoring method indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _useAIScoring ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _useAIScoring ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _useAIScoring ? 'AI Scoring' : 'Random Scoring',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _useAIScoring ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DEBUG: Show cropped regions for AI validation
                  if (_useAIScoring && _tempCroppedImagePaths != null)
                    Column(
                      children: [
                        const Text(
                          'AI-Cropped Regions (Debug View)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Grid of cropped region images
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            _buildCroppedRegionTile('Ears', _tempCroppedImagePaths!['ears']!, earScore),
                            _buildCroppedRegionTile('Eyes', _tempCroppedImagePaths!['eyes']!, eyesScore),
                            _buildCroppedRegionTile('Muzzle', _tempCroppedImagePaths!['muzzle']!, muzzleScore),
                            _buildCroppedRegionTile('Whiskers', _tempCroppedImagePaths!['whiskers']!, whiskersScore),
                            _buildCroppedRegionTile('Head', _tempCroppedImagePaths!['head']!, headPositionScore),
                            // Empty tile for spacing
                            Container(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Individual scores display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Individual AI Scores',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildScoreDisplay('Ears', earScore),
                                  _buildScoreDisplay('Eyes', eyesScore),
                                  _buildScoreDisplay('Muzzle', muzzleScore),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildScoreDisplay('Whiskers', whiskersScore),
                                  _buildScoreDisplay('Head', headPositionScore),
                                  Container(width: 60), // Spacer
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // View more details button
                  TextButton.icon(
                    onPressed: () async {
                      // Create temporary result for viewing details
                      final tempResult = FGSResult(
                        catName: 'Unsaved Result',
                        dateTime: DateTime.now(),
                        totalFgsScore: totalFgsScore,
                        earScore: earScore,
                        eyesScore: eyesScore,
                        muzzleScore: muzzleScore,
                        whiskersScore: whiskersScore,
                        headPositionScore: headPositionScore,
                        originalImagePath: widget.imagePath,
                        // Include temporary cropped images if available (AI scoring)
                        earImagePath: _tempCroppedImagePaths?['ears'],
                        eyesImagePath: _tempCroppedImagePaths?['eyes'],
                        muzzleImagePath: _tempCroppedImagePaths?['muzzle'],
                        whiskersImagePath: _tempCroppedImagePaths?['whiskers'],
                        headPositionImagePath: _tempCroppedImagePaths?['head'],
                      );

                      final updatedResult = await Navigator.push<FGSResult>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultDetailPage(
                            result: tempResult,
                            isTemporary: true,
                          ),
                        ),
                      );

                      // Update local scores if user made changes from details page
                      if (updatedResult != null && mounted) {
                        setState(() {
                          earScore = updatedResult.earScore;
                          eyesScore = updatedResult.eyesScore;
                          muzzleScore = updatedResult.muzzleScore;
                          whiskersScore = updatedResult.whiskersScore;
                          headPositionScore = updatedResult.headPositionScore;
                          totalFgsScore = updatedResult.totalFgsScore;
                        });
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View more details >'),
                    style: TextButton.styleFrom(
                      foregroundColor: darkBlue,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Total FGS Score box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: getScoreColor(totalFgsScore).withValues(alpha: 0.2),
                      border: Border.all(color: getScoreColor(totalFgsScore), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total FGS Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$totalFgsScore / 10',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Assessment
                  const Text(
                    'Assessment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getAssessmentText(totalFgsScore),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Create temporary result for editing
                          final tempResult = FGSResult(
                            catName: 'Unsaved Result',
                            dateTime: DateTime.now(),
                            totalFgsScore: totalFgsScore,
                            earScore: earScore,
                            eyesScore: eyesScore,
                            muzzleScore: muzzleScore,
                            whiskersScore: whiskersScore,
                            headPositionScore: headPositionScore,
                            originalImagePath: widget.imagePath,
                            earImagePath: _tempCroppedImagePaths?['ears'],
                            eyesImagePath: _tempCroppedImagePaths?['eyes'],
                            muzzleImagePath: _tempCroppedImagePaths?['muzzle'],
                            whiskersImagePath: _tempCroppedImagePaths?['whiskers'],
                            headPositionImagePath: _tempCroppedImagePaths?['head'],
                          );

                          final editedResult = await Navigator.push<FGSResult>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditResultPage(
                                result: tempResult,
                                isTemporary: true,
                              ),
                            ),
                          );

                          // Update local scores if user made changes
                          if (editedResult != null && mounted) {
                            setState(() {
                              earScore = editedResult.earScore;
                              eyesScore = editedResult.eyesScore;
                              muzzleScore = editedResult.muzzleScore;
                              whiskersScore = editedResult.whiskersScore;
                              headPositionScore = editedResult.headPositionScore;
                              totalFgsScore = editedResult.totalFgsScore;
                            });
                          }
                        },
                        icon: const Icon(Icons.edit, color: darkBlue),
                        label: const Text('Edit result'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightBlue,
                          foregroundColor: darkBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showSaveDialog,
                        icon: const Icon(Icons.save),
                        label: const Text('Save result'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
