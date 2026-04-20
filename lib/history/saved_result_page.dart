import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/services/database_service.dart';
import 'package:cat_pain_detector/history/result_detail.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';
import 'package:cat_pain_detector/home/edit_result.dart';

class SavedResultPage extends StatefulWidget {
  final FGSResult result;
  final VoidCallback? onResultDeleted;
  final VoidCallback? onResultUpdated;

  const SavedResultPage({
    super.key,
    required this.result,
    this.onResultDeleted,
    this.onResultUpdated,
  });

  @override
  State<SavedResultPage> createState() => _SavedResultPageState();
}

class _SavedResultPageState extends State<SavedResultPage> {
  late FGSResult _currentResult;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
  }

  Future<void> _deleteResult(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Result'),
          content: const Text('Are you sure you want to delete this result? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (_currentResult.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Cannot delete result without ID')),
        );
        return;
      }

      try {
        // Delete from database
        final dbService = DatabaseService();
        await dbService.deleteResult(_currentResult.id!);

        // Notify parent to refresh the list
        widget.onResultDeleted?.call();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Result deleted successfully')),
        );

        // Navigate back
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting result: $e')),
        );
      }
    }
  }

  String _getAssessmentText(int score) {
    if (score == 0) {
      return 'This cat shows no observable signs of pain. \nHowever, if you are concerned about your cat’s condition or suspect discomfort, it is recommended to seek advice from a licensed veterinarian.';
    } else if (score >= 1 && score <= 3) {
      return 'This cat shows either no signs of pain or only mild discomfort. \nHowever, if you are concerned about your cat’s condition or suspect discomfort, it is recommended to seek advice from a licensed veterinarian.';
    } else if (score >= 4 && score <= 8) {
      return 'The cat is likely in pain, and additional analgesia may be needed. Cat owners should consult a licensed veterinarian if they have any concerns about their cat’s health and avoid giving medications without professional advice. \nTreatment decisions must be based on clinical judgement, considering the cat’s condition and prior medications. If uncertain, reassess after 10–15 minutes, as scores may also be influenced by stress, fear, or sedation.';
    } else if (score >= 9 && score <= 10) {
      return 'The cat is likely experiencing severe pain, and additional analgesia may be needed. Cat owners should consult a licensed veterinarian if they have any concerns about their cat’s health and avoid giving medications without professional advice. \nTreatment decisions must be based on clinical judgement, considering the cat’s condition and prior medications. If uncertain, reassess after 10–15 minutes, as scores may also be influenced by stress, fear, or sedation.';
    } else {
      return 'Invalid score';
    }
  }

  Future<void> _refreshResult() async {
    if (_currentResult.id != null) {
      try {
        final dbService = DatabaseService();
        final updatedResult = await dbService.getResult(_currentResult.id!);
        if (updatedResult != null && mounted) {
          setState(() {
            _currentResult = updatedResult;
          });
        }
      } catch (e) {
        // Ignore refresh errors
      }
    }
  }

  void _navigateToEdit(BuildContext context) async {
    final editedResult = await Navigator.push<FGSResult>(
      context,
      MaterialPageRoute(
        builder: (context) => EditResultPage(
          result: _currentResult,
          isTemporary: false,
        ),
      ),
    );

    // If result was edited, refresh the data
    if (editedResult != null) {
      await _refreshResult();
      widget.onResultUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: Text(
          _currentResult.catName,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            // Image display
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerPage(imagePath: _currentResult.originalImagePath),
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
                    File(_currentResult.originalImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // View more details button
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultDetailPage(
                      result: _currentResult,
                      showDeleteButton: false, // Don't show delete in details view
                      onResultUpdated: (updatedResult) {
                        _refreshResult();
                        widget.onResultUpdated?.call();
                      },
                    ),
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
                color: getScoreColor(_currentResult.totalFgsScore).withValues(alpha: 0.2),
                border: Border.all(color: getScoreColor(_currentResult.totalFgsScore), width: 2),
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
                    '${_currentResult.totalFgsScore} / 10',
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
              _getAssessmentText(_currentResult.totalFgsScore),
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
                  onPressed: () => _navigateToEdit(context),
                  icon: const Icon(Icons.edit, color: darkBlue),
                  label: const Text('Edit result'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightBlue,
                    foregroundColor: darkBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _deleteResult(context),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Delete result'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
