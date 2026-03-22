import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/services/database_service.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';

class EditResultPage extends StatefulWidget {
  final FGSResult result;
  final bool isTemporary; // true for unsaved results, false for saved results

  const EditResultPage({
    super.key,
    required this.result,
    this.isTemporary = false,
  });

  @override
  State<EditResultPage> createState() => _EditResultPageState();
}

class _EditResultPageState extends State<EditResultPage> {
  late TextEditingController _catNameController;
  late int _earScore;
  late int _eyesScore;
  late int _muzzleScore;
  late int _whiskersScore;
  late int _headPositionScore;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _catNameController = TextEditingController(text: widget.result.catName);
    _earScore = widget.result.earScore;
    _eyesScore = widget.result.eyesScore;
    _muzzleScore = widget.result.muzzleScore;
    _whiskersScore = widget.result.whiskersScore;
    _headPositionScore = widget.result.headPositionScore;

    // Listen for changes
    _catNameController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _catNameController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanges = _catNameController.text != widget.result.catName ||
        _earScore != widget.result.earScore ||
        _eyesScore != widget.result.eyesScore ||
        _muzzleScore != widget.result.muzzleScore ||
        _whiskersScore != widget.result.whiskersScore ||
        _headPositionScore != widget.result.headPositionScore;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  int get _totalScore =>
      _earScore + _eyesScore + _muzzleScore + _whiskersScore + _headPositionScore;

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

  Widget _buildScoreSlider(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                activeColor: darkBlue,
                inactiveColor: lightBlue,
                onChanged: (newValue) {
                  onChanged(newValue.toInt());
                  _checkForChanges();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    final catName = _catNameController.text.trim();
    if (catName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cat name cannot be empty')),
      );
      return;
    }

    final updatedResult = widget.result.copyWith(
      catName: catName,
      totalFgsScore: _totalScore,
      earScore: _earScore,
      eyesScore: _eyesScore,
      muzzleScore: _muzzleScore,
      whiskersScore: _whiskersScore,
      headPositionScore: _headPositionScore,
    );

    if (widget.isTemporary) {
      // For temporary results, return the updated result
      Navigator.of(context).pop(updatedResult);
    } else {
      // For saved results, update in database
      try {
        final dbService = DatabaseService();
        await dbService.updateResult(updatedResult);
        Navigator.of(context).pop(updatedResult);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updatedResult.catName}\'s FGS score edited successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating result: $e')),
        );
      }
    }
  }

  Future<void> _discardChanges() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes'),
          content: const Text('Are you sure you want to discard your changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: const Text(
          'Edit FGS Score',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _discardChanges,
        ),
        actions: [
          TextButton(
            onPressed: _hasChanges ? _saveChanges : null,
            style: TextButton.styleFrom(
              foregroundColor: _hasChanges ? darkBlue : Colors.grey,
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image preview
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerPage(imagePath: widget.result.originalImagePath),
                  ),
                );
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: lightBlue, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(widget.result.originalImagePath),
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

            // Cat name input
            TextField(
              controller: _catNameController,
              decoration: const InputDecoration(
                labelText: 'Cat Name',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: darkBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Individual scores
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

                  _buildScoreSlider('Ear Score', _earScore, (value) => setState(() => _earScore = value)),
                  const SizedBox(height: 16),

                  _buildScoreSlider('Eyes Score', _eyesScore, (value) => setState(() => _eyesScore = value)),
                  const SizedBox(height: 16),

                  _buildScoreSlider('Muzzle Score', _muzzleScore, (value) => setState(() => _muzzleScore = value)),
                  const SizedBox(height: 16),

                  _buildScoreSlider('Whiskers Score', _whiskersScore, (value) => setState(() => _whiskersScore = value)),
                  const SizedBox(height: 16),

                  _buildScoreSlider('Head Position Score', _headPositionScore, (value) => setState(() => _headPositionScore = value)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Total score preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: getScoreColor(_totalScore).withValues(alpha: 0.2),
                border: Border.all(color: getScoreColor(_totalScore), width: 2),
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
                    '$_totalScore / 10',
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

            // Assessment preview
            const Text(
              'Assessment Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getAssessmentText(_totalScore),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}