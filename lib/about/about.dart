import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/settings/scoring_settings_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _buildFGSItem(String number, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: darkBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: darkBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: whiteColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo/Title
            // const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/cat_logo.png',
                    height: 150,
                    scale: 0.5,
                  ),
                  const Text(
                    'KittyCheck',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // About Section
            const Text(
              'About This App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'KittyCheck is a mobile application that helps assess acute pain in cats by analyzing facial expressions using the Feline Grimace Scale (FGS). The app combines AI-assisted scoring with the option for users to manually adjust scores, providing both automated and interactive assessment for research and educational purposes. Users can save assessments in history for later review.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
            ),

            const SizedBox(height: 30),

            // FGS Explanation Section
            const Text(
              'The Feline Grimace Scale (FGS)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The Feline Grimace Scale (FGS) is a validated and easy-to-use tool for assessing acute pain in cats through facial expressions (Evangelista et al., 2019). It evaluates five facial action units scored from 0 to 2, with a maximum total of 10. Higher scores indicate a greater likelihood of pain, and a score of 4 or above may suggest the need for analgesic treatment, depending on the cat\'s condition and existing medications. The FGS is intended for acute pain assessment and is not considered reliable for chronic conditions.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The five facial action units are:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFGSItem('1', 'Ear Position'),
                  _buildFGSItem('2', 'Orbital Tightening'),
                  _buildFGSItem('3', 'Muzzle Tension'),
                  _buildFGSItem('4', 'Whiskers Change'),
                  _buildFGSItem('5', 'Head Position'),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Responsible Use Section
            Container(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Responsible Use',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This app is designed to assist cat owners in assessing pain in cats using the Feline Grimace Scale (FGS). Cat owners can use the app for early detection of discomfort, helping you recognize when a veterinary consultation may be needed.\n\n'
                    'This app is not a substitute for professional veterinary judgment or clinical examination. Always consult a qualified veterinarian for accurate diagnosis, pain management, and treatment decisions. Use this app as a supportive tool, not as a standalone decision-maker.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

// How It Works Section
            const Text(
              'How It Works',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepItem(
                    '1',
                    'Capture or Upload',
                    'Take or upload a photo of your cat\'s face',
                  ),
                  _buildStepItem(
                    '2',
                    'Detect Facial Landmarks',
                    'The system detects facial landmarks and extracts key regions for FGS analysis',
                  ),
                  _buildStepItem(
                    '3',
                    'Automated Scoring',
                    'Each facial action unit is scored using trained AI models',
                  ),
                  _buildStepItem(
                    '4',
                    'Manual Adjustment',
                    'Users can manually adjust scores with reference to the in-app guide',
                  ),
                  _buildStepItem(
                    '5',
                    'Save Results',
                    'Results can be saved for tracking and future review',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Attribution Section
            // TODO: make link clickable
            const Text(
              'Attribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• The Feline Grimace Scale (FGS) was developed by Evangelista et al., 2019.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Descriptions of facial action units, instructions, and scoring guidelines used in this application are adapted from the official FGS manual.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Learn more from the official FGS website: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://felinegrimacescale.com');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      'felinegrimacescale.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: lightBlue,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Cat icons: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(
                          'https://www.flaticon.com/free-icons/emoji');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      'Emoji icons created by Ains - Flaticon',
                      style: TextStyle(
                        fontSize: 14,
                        color: lightBlue,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Disclaimer Section
            const Text(
              'Disclaimer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• This app is independently developed and is not affiliated with or endorsed by the official FGS project.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• All images, diagrams, and instructional materials are created specifically for this application. No copyrighted content from the official FGS manual is reproduced.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Credits Section
            const Text(
              'Credits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Models:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'Face detection and Facial Region detection: Custom-trained model (method inspired by Automated Detection of Cat Facial Landmarks, George Martvel, Ilan Shimshoni, Anna Zamansky)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  // SizedBox(height: 8),
                  // Padding(
                  //   padding: EdgeInsets.only(left: 16),
                  //   child: Text(
                  //     'FGS scoring: 5 independent classifiers for each facial action unit',
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       color: Colors.black87,
                  //       height: 1.5,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: 16),
                  Text(
                    'Developer:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'Ralph Philip M. Caoile',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Special Thanks: The Feline Grimace Scale (FGS) team for their pioneering work on acute feline pain assessment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Settings Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScoringSettingsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Scoring Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: lightBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Version Info
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
