import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';
import 'package:cat_pain_detector/home/fau_edit_page.dart';
import 'package:cat_pain_detector/services/database_service.dart';

class ComparisonPage extends StatefulWidget {
  final FGSResult result;
  final String region;

  const ComparisonPage({
    super.key,
    required this.result,
    required this.region,
  });

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  late FGSResult _currentResult;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
  }

  // Reference data for FGS scoring
  static const Map<String, List<Map<String, dynamic>>> referenceData = {
    'Ear': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/ears_0.jpeg'],
        'description': 'The ears are upwards and facing forward.',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/ears_1.jpeg'],
        'description': 'The ears are slightly pulled apart (the distance between the ear tips is increased). Score 1 if uncertain.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/ears_2.jpeg'],
        'description': 'The ears are flattened and rotated outwards. The ear tips are clearly pulled apart. The back of the ears is visible.',
      },
    ],
    'Eyes': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/eyes_0.jpeg'],
        'description': 'The eyes are round and open.',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/eyes_1.jpeg'],
        'description': 'The eyes are partially closed.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/eyes_2.jpeg'],
        'description': 'The eyes are squinted (almost closed).',
      },
    ],
    'Muzzle': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/muzzle_0.jpeg'],
        'description': 'The muzzle is relaxed and has a round shape.',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/muzzle_1.jpeg'],
        'description': 'The muzzle is mildly tense and flattened. Score 1 if uncertain.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/muzzle_2.jpeg'],
        'description': 'The muzzle is clearly tense and flattened/stretched. It has an elliptical shape.',
      },
    ],
    'Whiskers': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/whiskers_0.jpeg'],
        'description': 'The whiskers are relaxed, spread out and loosely curved.',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/whiskers_1.jpeg'],
        'description': 'The whiskers are closer together at their origin. They can be slightly curved or straight. Score 1 if uncertain.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/whiskers_2.jpeg'],
        'description': 'The whiskers are tense and normally spiked at the end (moving forward and away from the face).',
      },
    ],
    'Head Position': [
      {
        'score': 0,
        'images': ['assets/fgs_manual/head_0a.jpeg', 'assets/fgs_manual/head_0b.jpeg'],
        'description': 'The head is above the shoulder line. The cat may be standing or lying (in a comfortable and relaxed position).',
      },
      {
        'score': 1,
        'images': ['assets/fgs_manual/head_1.jpeg'],
        'description': 'The head is aligned with the shoulder line. Score 1 if uncertain.',
      },
      {
        'score': 2,
        'images': ['assets/fgs_manual/head_2a.jpeg', 'assets/fgs_manual/head_2b.jpeg'],
        'description': 'The head is below the shoulder line OR tilted down (chin towards the chest).',
      },
    ],
  };

  int _getActualScore() {
    switch (widget.region) {
      case 'Ear':
        return _currentResult.earScore;
      case 'Eyes':
        return _currentResult.eyesScore;
      case 'Muzzle':
        return _currentResult.muzzleScore;
      case 'Whiskers':
        return _currentResult.whiskersScore;
      case 'Head Position':
        return _currentResult.headPositionScore;
      default:
        return 0;
    }
  }

  String? _getSubjectImagePath() {
    switch (widget.region) {
      case 'Ear':
        return _currentResult.earImagePath;
      case 'Eyes':
        return _currentResult.eyesImagePath;
      case 'Muzzle':
        return _currentResult.muzzleImagePath;
      case 'Whiskers':
        return _currentResult.whiskersImagePath;
      case 'Head Position':
        return _currentResult.headPositionImagePath;
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
    final actualScore = _getActualScore();

    if (subjectPath != null && subjectPath.isNotEmpty) {
      labels.add(
          // "${_currentResult.catName}'s ${widget.region} (Score: $actualScore)");
          "${_currentResult.catName}'s ${widget.region}");

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

  Future<void> _navigateToEdit() async {
    final currentScore = _getActualScore();

    final newScore = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => FauEditPage(
          result: _currentResult,
          region: widget.region,
          currentScore: currentScore,
        ),
      ),
    );

    if (newScore != null && mounted) {
      // Calculate what each score will be after update
      final newEarScore =
          (widget.region == 'Ear') ? newScore : _currentResult.earScore;
      final newEyesScore =
          (widget.region == 'Eyes') ? newScore : _currentResult.eyesScore;
      final newMuzzleScore =
          (widget.region == 'Muzzle') ? newScore : _currentResult.muzzleScore;
      final newWhiskersScore = (widget.region == 'Whiskers')
          ? newScore
          : _currentResult.whiskersScore;
      final newHeadPositionScore = (widget.region == 'Head Position')
          ? newScore
          : _currentResult.headPositionScore;

      final newTotalScore = newEarScore +
          newEyesScore +
          newMuzzleScore +
          newWhiskersScore +
          newHeadPositionScore;

      setState(() {
        switch (widget.region) {
          case 'Ear':
            _currentResult = _currentResult.copyWith(
              earScore: newScore,
              totalFgsScore: newTotalScore,
            );
            break;
          case 'Eyes':
            _currentResult = _currentResult.copyWith(
              eyesScore: newScore,
              totalFgsScore: newTotalScore,
            );
            break;
          case 'Muzzle':
            _currentResult = _currentResult.copyWith(
              muzzleScore: newScore,
              totalFgsScore: newTotalScore,
            );
            break;
          case 'Whiskers':
            _currentResult = _currentResult.copyWith(
              whiskersScore: newScore,
              totalFgsScore: newTotalScore,
            );
            break;
          case 'Head Position':
            _currentResult = _currentResult.copyWith(
              headPositionScore: newScore,
              totalFgsScore: newTotalScore,
            );
            break;
        }
      });

      // Save to database and return updated result to parent
      if (_currentResult.id != null) {
        try {
          final dbService = DatabaseService();
          await dbService.updateResult(_currentResult);
          if (mounted) {
            Navigator.of(context).pop(_currentResult);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating score: $e')),
            );
          }
        }
      } else {
        // For temporary results, also return updated result
        if (mounted) {
          Navigator.of(context).pop(_currentResult);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actualScore = _getActualScore();
    final subjectImagePath = _getSubjectImagePath();
    final referenceItems = referenceData[widget.region] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: Text(
          '${widget.region} Comparison',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
            tooltip: 'Edit ${widget.region} score',
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
                  child: subjectImagePath != null && subjectImagePath.isNotEmpty
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
              // '${_currentResult.catName}\'s ${widget.region} (Score: $actualScore)',
              '${_currentResult.catName}\'s ${widget.region}',
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
              final isActualScore = score == actualScore;

              return Container(
                margin: const EdgeInsets.only(bottom: 30),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActualScore
                      ? lightBlue.withValues(alpha: 0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isActualScore ? lightBlue : Colors.grey[300]!,
                    width: isActualScore ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score $score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActualScore ? lightBlue : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reference images
                    if (images.length == 1)
                      GestureDetector(
                        onTap: () {
                          final paths = _buildImagePaths();
                          final isAssets = _buildIsAssetList();
                          final labels = _buildLabels();
                          final descriptions = _buildDescriptions();
                          final startIndex = _getStartIndex(images[0]);
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
                        },
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
                        children: images.asMap().entries.map((entry) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () {
                                  final paths = _buildImagePaths();
                                  final isAssets = _buildIsAssetList();
                                  final labels = _buildLabels();
                                  final descriptions = _buildDescriptions();
                                  final startIndex =
                                      _getStartIndex(entry.value);
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
                                },
                                child: Image.asset(
                                  entry.value,
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
              );
            }),
          ],
        ),
      ),
    );
  }
}
