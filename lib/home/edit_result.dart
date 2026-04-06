import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/services/database_service.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';
import 'package:cat_pain_detector/home/fau_edit_page.dart';

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



  Widget _buildFauItem(String region, String imagePath, int score, Function() onTap) {
    return InkWell(
      onTap: onTap,
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

            // Region name
            Expanded(
              child: Text(
                region,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            // Score
            Text(
              'Score: $score/2',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 8),

            // Edit icon
            Icon(
              Icons.edit,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    String? catName;
    if (!widget.isTemporary) {
      catName = _catNameController.text.trim();
      if (catName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cat name cannot be empty')),
        );
        return;
      }
    } else {
      catName = widget.result.catName;
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

  Future<void> _navigateToFauEdit(String region) async {
    int currentScore;
    switch (region) {
      case 'Ear':
        currentScore = _earScore;
        break;
      case 'Eyes':
        currentScore = _eyesScore;
        break;
      case 'Muzzle':
        currentScore = _muzzleScore;
        break;
      case 'Whiskers':
        currentScore = _whiskersScore;
        break;
      case 'Head Position':
        currentScore = _headPositionScore;
        break;
      default:
        currentScore = 0;
    }

    final newScore = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => FauEditPage(
          result: widget.result,
          region: region,
          currentScore: currentScore,
        ),
      ),
    );

    if (newScore != null) {
      setState(() {
        switch (region) {
          case 'Ear':
            _earScore = newScore;
            break;
          case 'Eyes':
            _eyesScore = newScore;
            break;
          case 'Muzzle':
            _muzzleScore = newScore;
            break;
          case 'Whiskers':
            _whiskersScore = newScore;
            break;
          case 'Head Position':
            _headPositionScore = newScore;
            break;
        }
        _checkForChanges();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _discardChanges();
        }
      },
      child: Scaffold(
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
                      builder: (context) => ImageViewerPage(
                          imagePath: widget.result.originalImagePath),
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
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sow edit cat name input only for saved results
              if (!widget.isTemporary) ...[
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
              ],

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
                    _buildFauItem('Ear', widget.result.earImagePath ?? '',
                        _earScore, () => _navigateToFauEdit('Ear')),
                    const SizedBox(height: 8),
                    _buildFauItem('Eyes', widget.result.eyesImagePath ?? '',
                        _eyesScore, () => _navigateToFauEdit('Eyes')),
                    const SizedBox(height: 8),
                    _buildFauItem('Muzzle', widget.result.muzzleImagePath ?? '',
                        _muzzleScore, () => _navigateToFauEdit('Muzzle')),
                    const SizedBox(height: 8),
                    _buildFauItem(
                        'Whiskers',
                        widget.result.whiskersImagePath ?? '',
                        _whiskersScore,
                        () => _navigateToFauEdit('Whiskers')),
                    const SizedBox(height: 8),
                    _buildFauItem(
                        'Head Position',
                        widget.result.headPositionImagePath ?? '',
                        _headPositionScore,
                        () => _navigateToFauEdit('Head Position')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
