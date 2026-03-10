import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: lightBlue, width: 2),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: currentIndex == 0 ? const Icon(Icons.home) : const Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: currentIndex == 1 ? const Icon(Icons.history) : const Icon(Icons.history_outlined),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: currentIndex == 2 ? const Icon(Icons.info) : const Icon(Icons.info_outlined),
              label: 'About',
            ),
          ],
          currentIndex: currentIndex,
          selectedItemColor: colorScheme.onSurface,
          unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: onTap,
        ),
      ),
    );
  }
}
