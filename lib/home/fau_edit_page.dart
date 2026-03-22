import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';

class FauEditPage extends StatefulWidget {
  final FGSResult result;
  final String region;

  const FauEditPage({
    super.key,
    required this.result,
    required this.region,
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

  late int _currentScore;
  late int _selectedScore;

  @override
  void initState() {
    super.initState();
    _currentScore = _getActualScore();
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

  void _onScoreSelected(int score) {
    setState(() {
      _selectedScore = score;
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedScore);
  }

  @override
  Widget build(BuildContext context) {
    final subjectImagePath = _getSubjectImagePath();
    final referenceItems = referenceData[widget.region] ?? [];
    final hasChanges = _selectedScore != _currentScore;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: Text(
          'Edit ${widget.region} Score',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerPage(imagePath: subjectImagePath),
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
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
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
                    color: isSelectedScore ? lightBlue.withValues(alpha: 0.1) : Colors.white,
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
                              color: isSelectedScore ? darkBlue : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Reference images
                          if (images.length == 1)
                            Center(
                              child: Image.asset(
                                images[0],
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: images.map((image) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Image.asset(
                                      image,
                                      height: 120,
                                      fit: BoxFit.contain,
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

                      // Current score indicator (circle in upper right)
                      if (isCurrentScore)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: darkBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
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
    );
  }
}