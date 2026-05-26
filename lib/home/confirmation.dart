import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/home/result.dart';

class ConfirmationPage extends StatelessWidget {
  final String imagePath;

  const ConfirmationPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: const Text(
          'Confirm Image',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Image display
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Bottom buttons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: lightBlue, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                ElevatedButton.icon(
                  onPressed: () {
                    // Go back to camera
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.cancel, color: darkBlue),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightBlue,
                    foregroundColor: darkBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                // Score FGS button
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to FGS result page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FGSResultPage(imagePath: imagePath),
                      ),
                    );
                  },
                  icon: Icon(Icons.assessment, color: Colors.white),
                  label: const Text('Score FGS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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