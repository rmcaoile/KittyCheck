import 'package:flutter/material.dart';
import 'package:cat_pain_detector/navbar.dart';
import 'package:cat_pain_detector/home/home.dart';
import 'package:cat_pain_detector/home/onboarding_page.dart';
import 'package:cat_pain_detector/history/history.dart';
import 'package:cat_pain_detector/about/about.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<_MyHomePageState> homePageKey = GlobalKey<_MyHomePageState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // DEBUG: set to true to always show onboarding
  const bool debugForceOnboarding = false;
  final hasSeenOnboarding = debugForceOnboarding
      ? false
      : (prefs.getBool('hasSeenOnboarding') ?? false);
  runApp(MyApp(showOnboarding: !hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KittyCheck',
      theme: appTheme,
      home: showOnboarding
          ? const OnboardingPage()
          : MyHomePage(key: homePageKey),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    HistoryPage(),
    AboutPage(),
  ];

  static const List<String> _titles = <String>[
    'KittyCheck',
    'History',
    'About',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void switchToHistory() {
    setState(() {
      _selectedIndex = 1; // History index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
