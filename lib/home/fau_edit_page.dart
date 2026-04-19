import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';

class FauEditPage extends StatefulWidget {
  final FGSResult result;
  final String region;
  final int currentScore;

  const FauEditPage({
    super.key,
    required this.result,
    required this.region,
    required this.currentScore,
  });

  @override
  State<FauEditPage> createState() => _FauEditPageState();
}

class _FauEditPageState extends State<FauEditPage> {
  // Reference data for FGS scoring
  static const Map<String, List<Map<String, dynamic>>> referenceData = {
    'Ear': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/ears_0.png'],
        'description': 'The ears are upwards and facing forward.',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/ears_1.png'],
        'description': 'The ears are slightly pulled apart (the distance between the ear tips is increased). Score 1 if uncertain.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/ears_2.png'],
        'description': 'The ears are flattened and rotated outwards. The ear tips are clearly pulled apart. The back of the ears is visible.',
      },
    ],
    'Eyes': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/eyes_0.png'],
        'description': 'The eyes are round and open.',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/eyes_1.png'],
        'description': 'The eyes are partially closed.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/eyes_2.png'],
        'description': 'The eyes are squinted (almost closed).',
      },
    ],
    'Muzzle': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/muzzle_0.png'],
        'description': 'The muzzle is relaxed and has a round shape.',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/muzzle_1.png'],
        'description': 'The muzzle is mildly tense and flattened. Score 1 if uncertain.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/muzzle_2.png'],
        'description': 'The muzzle is clearly tense and flattened/stretched. It has an elliptical shape.',
      },
    ],
    'Whiskers': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/whiskers_0.png'],
        'description': 'The whiskers are relaxed, spread out and loosely curved.',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/whiskers_1.png'],
        'description': 'The whiskers are closer together at their origin. They can be slightly curved or straight. Score 1 if uncertain.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/whiskers_2.png'],
        'description': 'The whiskers are tense and normally spiked at the end (moving forward and away from the face).',
      },
    ],
    'Head Position': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/head_0a.png', 'assets/fgs_manual/head_0b.png'],
        'description': 'The head is above the shoulder line. The cat may be standing or lying (in a comfortable and relaxed position).',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/head_1.png'],
        'description': 'The head is aligned with the shoulder line. Score 1 if uncertain.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/head_2a.png', 'assets/fgs_manual/head_2b.png'],
        'description': 'The head is below the shoulder line OR tilted down (chin towards the chest).',
      },
    ],
  };

  late int _currentScore;
  late int _selectedScore;

  @override
  void initState() {
    super.initState();
    _currentScore = widget.currentScore;
    _selectedScore = _currentScore;
  }

  int _getActualScore() {
    switch (widget.region) {
      case 'Ear':
        return widget.result.earScore;
      case 'Eyes':
        return widget.result.eyesScore;
      case 'Muzzle':
        return widget.result.muzzleScore;
      case 'Whiskers':
        return widget.result.whiskersScore;
      case 'Head Position':
        return widget.result.headPositionScore;
      default:
        return 0;
    }
  }

  String? _getSubjectImagePath() {
    switch (widget.region) {
      case 'Ear':
        return widget.result.earImagePath;
      case 'Eyes':
        return widget.result.eyesImagePath;
      case 'Muzzle':
        return widget.result.muzzleImagePath;
      case 'Whiskers':
        return widget.result.whiskersImagePath;
      case 'Head Position':
        return widget.result.headPositionImagePath;
      default:
        return null;
    }
  }

  List<String> _buildImagePaths() {
    final List<String> paths = [];
    final subjectPath = _getSubjectImagePath();

    if (subjectPath != null && subjectPath.isNotEmpty) {
      paths.add(subjectPath);
    }

    final referenceItems = referenceData[widget.region] ?? [];
    for (final item in referenceItems) {
      final images = item['images'] as List<String>;
      for (final img in images) {
        paths.add(img);
      }
    }

    return paths;
  }

  int _getStartIndex(String tappedImagePath) {
    final subjectPath = _getSubjectImagePath();
    if (subjectPath != null &&
        subjectPath.isNotEmpty &&
        subjectPath == tappedImagePath) {
      return 0;
    }

    final referenceItems = referenceData[widget.region] ?? [];
    int offset = subjectPath != null && subjectPath.isNotEmpty ? 1 : 0;

    for (final item in referenceItems) {
      final images = item['images'] as List<String>;
      for (final img in images) {
        if (img == tappedImagePath) {
          return offset;
        }
        offset++;
      }
    }

    return 0;
  }

  List<bool> _buildIsAssetList() {
    final List<bool> isAssets = [];
    final subjectPath = _getSubjectImagePath();

    if (subjectPath != null && subjectPath.isNotEmpty) {
      isAssets.add(false);
    }

    final referenceItems = referenceData[widget.region] ?? [];
    for (final item in referenceItems) {
      final images = item['images'] as List<String>;
      for (final _ in images) {
        isAssets.add(true);
      }
    }

    return isAssets;
  }

  List<String> _buildLabels() {
    final List<String> labels = [];
    final subjectPath = _getSubjectImagePath();

    if (subjectPath != null && subjectPath.isNotEmpty) {
      labels.add("${widget.result.catName}'s ${widget.region}");
    }

    final referenceItems = referenceData[widget.region] ?? [];
    for (final item in referenceItems) {
      final score = item['score'] as int;
      final images = item['images'] as List<String>;
      for (final _ in images) {
        labels.add('Score $score');
      }
    }

    return labels;
  }

  List<String> _buildDescriptions() {
    final List<String> descriptions = [];
    final subjectPath = _getSubjectImagePath();

    if (subjectPath != null && subjectPath.isNotEmpty) {
      descriptions.add('');
    }

    final referenceItems = referenceData[widget.region] ?? [];
    for (final item in referenceItems) {
      final images = item['images'] as List<String>;
      final description = item['description'] as String;
      for (final _ in images) {
        descriptions.add(description);
      }
    }

    return descriptions;
  }

  void _onImageTap(String imagePath) {
    final paths = _buildImagePaths();
    final isAssets = _buildIsAssetList();
    final labels = _buildLabels();
    final descriptions = _buildDescriptions();
    final startIndex = _getStartIndex(imagePath);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          imagePaths: paths,
          isAssetList: isAssets,
          initialIndex: startIndex,
          labels: labels,
          descriptions: descriptions,
        ),
      ),
    );
  }

  void _onScoreSelected(int score) {
    setState(() {
      _selectedScore = score;
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedScore);
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final subjectImagePath = _getSubjectImagePath();
    final referenceItems = referenceData[widget.region] ?? [];
    final hasChanges = _selectedScore != _currentScore;

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (_selectedScore != _currentScore) {
            final confirmed = await _showDiscardDialog();
            if (confirmed && context.mounted) {
              Navigator.of(context).pop();
            }
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: lightBlue,
          centerTitle: true,
          title: Text(
            'Edit ${widget.region} Score',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_selectedScore != _currentScore) {
                final confirmed = await _showDiscardDialog();
                if (confirmed && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.check,
                color: hasChanges ? darkBlue : Colors.grey,
              ),
              onPressed: hasChanges ? _confirmSelection : null,
              tooltip: 'Confirm selection',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Subject's cropped image
              GestureDetector(
                onTap: () {
                  if (subjectImagePath != null && subjectImagePath.isNotEmpty) {
                    final paths = _buildImagePaths();
                    final isAssets = _buildIsAssetList();
                    final labels = _buildLabels();
                    final descriptions = _buildDescriptions();
                    final startIndex = _getStartIndex(subjectImagePath);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewerPage(
                          imagePaths: paths,
                          isAssetList: isAssets,
                          initialIndex: startIndex,
                          labels: labels,
                          descriptions: descriptions,
                        ),
                      ),
                    );
                  }
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
                    child:
                        subjectImagePath != null && subjectImagePath.isNotEmpty
                            ? Image.file(
                                File(subjectImagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported,
                                        color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Current Score: $_currentScore',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),

              // Reference scoring guide
              ...referenceItems.map((item) {
                final score = item['score'] as int;
                final images = item['images'] as List<String>;
                final description = item['description'] as String;
                final isCurrentScore = score == _currentScore;
                final isSelectedScore = score == _selectedScore;

                return GestureDetector(
                  onTap: () => _onScoreSelected(score),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelectedScore
                          ? lightBlue.withValues(alpha: 0.1)
                          : Colors.white,
                      border: Border.all(
                        color: isSelectedScore ? lightBlue : Colors.grey[300]!,
                        width: isSelectedScore ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Score $score',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelectedScore ? darkBlue : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Reference images
                            if (images.length == 1)
                              GestureDetector(
                                onTap: () => _onImageTap(images[0]),
                                child: Center(
                                  child: Image.asset(
                                    images[0],
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: images.map((image) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: GestureDetector(
                                        onTap: () => _onImageTap(image),
                                        child: Image.asset(
                                          image,
                                          height: 120,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),

                        // Selection indicator (circle in upper right)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelectedScore
                                  ? darkBlue
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelectedScore
                                    ? darkBlue
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: isCurrentScore
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
