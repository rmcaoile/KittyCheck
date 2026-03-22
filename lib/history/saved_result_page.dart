import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/services/database_service.dart';
import 'package:cat_pain_detector/history/result_detail.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';

class SavedResultPage extends StatelessWidget {
  final FGSResult result;
  final VoidCallback? onResultDeleted;

  const SavedResultPage({
    super.key,
    required this.result,
    this.onResultDeleted,
  });

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
      if (result.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Cannot delete result without ID')),
        );
        return;
      }

      try {
        // Delete from database
        final dbService = DatabaseService();
        await dbService.deleteResult(result.id!);

        // Notify parent to refresh the list
        onResultDeleted?.call();

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



  void _navigateToEdit(BuildContext context) {
    // TODO: Navigate to edit page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Edit result page')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: Text(
          result.catName,
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
                    builder: (context) => ImageViewerPage(imagePath: result.originalImagePath),
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
                    File(result.originalImagePath),
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
                      result: result,
                      showDeleteButton: false, // Don't show delete in details view
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
                color: getScoreColor(result.totalFgsScore).withValues(alpha: 0.2),
                border: Border.all(color: getScoreColor(result.totalFgsScore), width: 2),
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
                    '${result.totalFgsScore} / 10',
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
              _getAssessmentText(result.totalFgsScore),
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