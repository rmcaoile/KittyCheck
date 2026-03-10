import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: whiteColor,
      child: const Center(
        child: Text('About Page'),
      ),
    );
  }
}
