import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/services/database_service.dart';
import 'package:cat_pain_detector/services/file_service.dart';
import 'package:cat_pain_detector/history/comparison_page.dart';

class ResultDetailPage extends StatelessWidget {
  final FGSResult result;
  final bool showDeleteButton; // true for history view, false for result view
  final VoidCallback? onResultDeleted;

  const ResultDetailPage({
    super.key,
    required this.result,
    this.showDeleteButton = false,
    this.onResultDeleted,
  });

  Color _getScoreColor(int score) {
    if (score == 0) {
      return const Color.fromRGBO(176, 209, 153, 1.0);
    } else if (score >= 1 && score <= 3) {
      return const Color.fromRGBO(255, 246, 155, 1.0);
    } else if (score >= 4 && score <= 8) {
      return const Color.fromRGBO(224, 119, 91, 1.0);
    } else if (score >= 9 && score <= 10) {
      return const Color.fromRGBO(205, 23, 25, 1.0);
    } else {
      return const Color(0xFF2196F3); // fallback blue
    }
  }

  void _navigateToEdit(BuildContext context) {
    // TODO: Navigate to edit page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Edit result page')),
    );
  }

  void _navigateToComparison(BuildContext context, String facialRegion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComparisonPage(result: result, region: facialRegion),
      ),
    );
  }

  void _deleteResult(BuildContext context) async {
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

        // Delete associated image files
        await FileService.deleteResultImages(result);

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

  Widget _buildFauItem(BuildContext context, String region, String imagePath, int score) {
    return InkWell(
      onTap: () => _navigateToComparison(context, region),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Cropped image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: lightBlue, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: imagePath.isNotEmpty
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Region name and score
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Score: $score/2',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
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
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
            tooltip: 'Edit result',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cat face image
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
            const SizedBox(height: 20),

            // Total FGS Score box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getScoreColor(result.totalFgsScore).withValues(alpha: 0.2),
                border: Border.all(color: _getScoreColor(result.totalFgsScore), width: 2),
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

            // FAU Scores List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Facial Action Units',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ear
                  _buildFauItem(context, 'Ear', result.earImagePath ?? '', result.earScore),
                  const SizedBox(height: 8),

                  // Eyes
                  _buildFauItem(context, 'Eyes', result.eyesImagePath ?? '', result.eyesScore),
                  const SizedBox(height: 8),

                  // Muzzle
                  _buildFauItem(context, 'Muzzle', result.muzzleImagePath ?? '', result.muzzleScore),
                  const SizedBox(height: 8),

                  // Whiskers
                  _buildFauItem(context, 'Whiskers', result.whiskersImagePath ?? '', result.whiskersScore),
                  const SizedBox(height: 8),

                  // Head Position
                  _buildFauItem(context, 'Head Position', result.headPositionImagePath ?? '', result.headPositionScore),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Action button (Delete for history view)
            if (showDeleteButton)
              ElevatedButton.icon(
                onPressed: () => _deleteResult(context),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Delete Result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}