import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_pain_detector/main.dart';
import 'package:cat_pain_detector/widgets/image_viewer_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  _AppPurposePage(),
                  _HowItWorksPage(),
                  _PhotoGuidePage(),
                  _ResponsibleUsePage(),
                  _DisclaimerPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? darkBlue
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 4) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlue,
                        foregroundColor: whiteColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < 4 ? 'Next' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppPurposePage extends StatelessWidget {
  const _AppPurposePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset(
            'assets/images/cat_logo.png',
            height: 180,
            scale: 0.5,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to KittyCheck',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'App Purpose',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'KittyCheck is a mobile application that helps assess acute pain in cats by analyzing facial expressions using the Feline Grimace Scale (FGS). The app combines AI-assisted scoring with the option for users to manually adjust scores, providing both automated and interactive assessment for research and educational purposes.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // const SizedBox(height: 8),
          Image.asset(
            'assets/images/cat_icons/cat_1.png',
            height: 150,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.settings_suggest, size: 80, color: lightBlue);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _StepWidget(
            number: '1',
            title: 'Capture or Upload',
            description: 'Take or upload a photo of your cat\'s face',
          ),
          _StepWidget(
            number: '2',
            title: 'Detect Facial Landmarks',
            description:
                'The system detects facial landmarks and extracts key regions for FGS analysis',
          ),
          _StepWidget(
            number: '3',
            title: 'Automated Scoring',
            description:
                'Each facial action unit is scored using trained AI models',
          ),
          _StepWidget(
            number: '4',
            title: 'Manual Adjustment',
            description:
                'Users can manually adjust scores with reference to the in-app guide',
          ),
          _StepWidget(
            number: '5',
            title: 'Save Results',
            description: 'Results can be saved for tracking and future review',
          ),
        ],
      ),
    );
  }
}

class _StepWidget extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepWidget({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
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
}

class _PhotoGuidePage extends StatelessWidget {
  const _PhotoGuidePage();

  List<String> get _sampleImages =>
      List.generate(9, (index) => 'assets/images/sample/${index + 1}.png');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          // const SizedBox(height: 40),
          // Icon(Icons.photo_camera, size: 80, color: lightBlue),
          // const SizedBox(height: 24),
          const Text(
            'Photo Guide',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you take a photo, wait until your cat is done:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildActivityIcon(
                        'assets/images/cat_icons/tongue.png', 'Grooming'),
                    const SizedBox(width: 8),
                    _buildActivityIcon(
                        'assets/images/cat_icons/sleep.png', 'Sleeping'),
                    const SizedBox(width: 8),
                    _buildActivityIcon(
                        'assets/images/cat_icons/happy.png', 'Playing'),
                    const SizedBox(width: 8),
                    _buildActivityIcon(
                        'assets/images/cat_icons/yummy.png', 'Eating'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Make sure the cat\'s face is in frame before taking the photo.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Good Photo Angles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Position your camera to capture these angles for more accurate results.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _sampleImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerPage(
                        imagePaths: _sampleImages,
                        isAssetList: List.filled(_sampleImages.length, true),
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    _sampleImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: lightBlue.withValues(alpha: 0.3),
                        child: Icon(
                          Icons.image_not_supported,
                          color: darkBlue.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(String imagePath, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.help_outline, color: darkBlue);
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ResponsibleUsePage extends StatelessWidget {
  const _ResponsibleUsePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          const Text(
            'Responsible Use',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'This app is designed to assist cat owners in assessing acute pain in cats using the Feline Grimace Scale (FGS). Cat owners can use the app for early detection of discomfort, helping you recognize when a veterinary consultation may be needed.\n\nUse this app as a supportive tool, not as a standalone decision-maker.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerPage extends StatelessWidget {
  const _DisclaimerPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.gavel, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 24),
          const Text(
            'Disclaimer',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade200,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This app is not a substitute for professional veterinary judgment or clinical examination.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Always consult a qualified veterinarian for accurate diagnosis, pain management, and treatment decisions.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This app is independently developed and is not affiliated with or endorsed by the official FGS project.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
