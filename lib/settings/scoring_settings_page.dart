import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/services/scoring_settings_service.dart';

class ScoringSettingsPage extends StatefulWidget {
  const ScoringSettingsPage({super.key});

  @override
  State<ScoringSettingsPage> createState() => _ScoringSettingsPageState();
}

class _ScoringSettingsPageState extends State<ScoringSettingsPage> {
  final ScoringSettingsService _settingsService = ScoringSettingsService();
  bool _useAIScoring = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final useAI = await _settingsService.getUseAIScoring();
    setState(() {
      _useAIScoring = useAI;
    });
  }

  Future<void> _toggleAIScoring(bool value) async {
    await _settingsService.setUseAIScoring(value);
    setState(() {
      _useAIScoring = value;
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'AI scoring enabled. Images will be analyzed using trained models.'
                : 'Random scoring enabled. Images will use random scores for testing.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: const Text(
          'Scoring Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FGS Scoring Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose how FGS scores are calculated from cat images.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),

            // AI Scoring Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _useAIScoring ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useAIScoring ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _useAIScoring ? Icons.smart_toy : Icons.smart_toy_outlined,
                        color: _useAIScoring ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'AI Scoring (Trained Models)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: _useAIScoring,
                        onChanged: _toggleAIScoring,
                        activeColor: const Color.fromRGBO(76, 175, 80, 1),
                      ),
                    ],
                  ),
                  if (_useAIScoring) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Active - Using AI models for scoring',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Random Scoring Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_useAIScoring ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_useAIScoring ? Colors.orange : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        !_useAIScoring ? Icons.shuffle : Icons.shuffle_outlined,
                        color: !_useAIScoring ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Random Scoring (Testing)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: !_useAIScoring,
                        onChanged: (value) => _toggleAIScoring(!value),
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                  if (!_useAIScoring) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Active - Using random scores for testing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 40)

            // // Information Section
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.blue.withValues(alpha: 0.1),
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(
            //       color: Colors.blue,
            //       width: 1,
            //     ),
            //   ),
            //   // child: const Column(
            //   //   crossAxisAlignment: CrossAxisAlignment.start,
            //   //   children: [
            //   //     Row(
            //   //       children: [
            //   //         Icon(Icons.info_outline, color: Colors.blue),
            //   //         SizedBox(width: 8),
            //   //         Text(
            //   //           'About FGS Scoring',
            //   //           style: TextStyle(
            //   //             fontSize: 16,
            //   //             fontWeight: FontWeight.bold,
            //   //             color: Colors.blue,
            //   //           ),
            //   //         ),
            //   //       ],
            //   //     ),
            //   //     SizedBox(height: 8),
            //   //     // Text(
            //   //     //   'FGS (Facial Grimace Scale) is a standardized method for assessing pain in cats by analyzing facial expressions. The AI models have been trained on a thousand of cat images to provide accurate pain assessments.',
            //   //     //   style: TextStyle(
            //   //     //     fontSize: 14,
            //   //     //     color: Colors.black87,
            //   //     //     height: 1.4,
            //   //     //   ),
            //   //     // ),
            //   //   ],
            //   // ),
            // ),
          ],
        ),
      ),
    );
  }
}