import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/services/database_service.dart';
import 'package:cat_pain_detector/services/file_service.dart';
import 'package:cat_pain_detector/history/result_detail.dart';
import 'package:cat_pain_detector/history/history.dart';
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

  @override
  void initState() {
    super.initState();
    _generateDummyScores();
  }

  void _generateDummyScores() {
    final random = Random();
    earScore = random.nextInt(3); // 0-2
    eyesScore = random.nextInt(3);
    muzzleScore = random.nextInt(3);
    whiskersScore = random.nextInt(3);
    headPositionScore = random.nextInt(3);
    totalFgsScore = earScore + eyesScore + muzzleScore + whiskersScore + headPositionScore;
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
                Navigator.of(context).pop();

                try {
                  await _saveResult(catName);
                  if (mounted) {
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
      final tempResultId = DateTime.now().millisecondsSinceEpoch; // Temporary ID for file naming
      final croppedPaths = await FileService.createCroppedImageCopies(savedImagePath, tempResultId);

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
            Container(
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
            const SizedBox(height: 20),

            // View more details button
            TextButton.icon(
              onPressed: () {
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
                  // No cropped images yet since not saved
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultDetailPage(result: tempResult),
                  ),
                );
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
                color: lightBlue.withValues(alpha: 0.1),
                border: Border.all(color: lightBlue, width: 2),
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
            // TODO: Assessment based on score
            const Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),

            // Lorem ipsum text
            const Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
              style: TextStyle(
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
                  onPressed: () {
                    // TODO: Edit result
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('TODO: Edit result page')),
                    );
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
      ),
    );
  }
}
