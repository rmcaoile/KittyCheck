import 'package:flutter/material.dart';

const Color whiteColor = Colors.white;
const Color lightBlue = Color.fromRGBO(185, 211, 223, 1.0);
const Color darkBlue = Color.fromRGBO(20, 108, 148, 1.0);

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