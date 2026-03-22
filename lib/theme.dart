import 'package:flutter/material.dart';

const Color whiteColor = Colors.white;
const Color lightBlue = Color.fromRGBO(185, 211, 223, 1.0);
const Color darkBlue = Color.fromRGBO(20, 108, 148, 1.0);

// Score colors
const Color lightGreen = Color.fromRGBO(176, 209, 153, 1.0);
const Color lightYellow = Color.fromRGBO(255, 246, 155, 1.0);
const Color lightRed = Color.fromRGBO(224, 119, 91, 1.0);
const Color darkRed = Color.fromRGBO(205, 23, 25, 1.0);

// Function to get score color based on score value
Color getScoreColor(int score) {
  if (score == 0) {
    return const Color.fromARGB(255, 90, 175, 30);
  } else if (score >= 1 && score <= 3) {
    return const Color.fromARGB(255, 198, 185, 36);
  } else if (score >= 4 && score <= 8) {
    return lightRed;
  } else if (score >= 9 && score <= 10) {
    return darkRed;
  } else {
    return darkBlue;
  }
}

ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: lightBlue,
    primary: darkBlue,
    surface: whiteColor,
    onSurface: darkBlue,
  ),
  scaffoldBackgroundColor: whiteColor,
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: darkBlue),
    bodyMedium: TextStyle(color: darkBlue),
    bodySmall: TextStyle(color: darkBlue),
    headlineLarge: TextStyle(color: darkBlue),
    headlineMedium: TextStyle(color: darkBlue),
    headlineSmall: TextStyle(color: darkBlue),
  ),
);