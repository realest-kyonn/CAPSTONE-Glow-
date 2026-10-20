import 'package:flutter/material.dart';
// Adjust these import paths to match your project structure
import '../page_4/page4_routes_web.dart' if (dart.library.io) '../page_4/page4_routes_native.dart' as routes;
import '../page_4/page4.dart';

class FloatingBottomNav extends StatelessWidget {
  // Pass the active tab index (0 = Home, 1 = Favorites, etc.)
  final int currentIndex;

  const FloatingBottomNav({super.key, required this.currentIndex});

  static const _pink = Color(0xFFFF6EB4);

  void _navigate(BuildContext context, Widget screen) {
    // pushReplacement prevents building an infinite stack of pages 
    // when tapping around the bottom navigation bar.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: contentWidth * 0.05,
          right: contentWidth * 0.05,
          bottom: 12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            backgroundColor: _pink,
            selectedItemColor: Colors.white,
            // Dim unselected items slightly so the active tab is obvious
            unselectedItemColor: Colors.white.withValues(alpha: 0.6),
            type: BottomNavigationBarType.fixed,
            iconSize: contentWidth * 0.065,
            selectedFontSize: 0,
            unselectedFontSize: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favorites'),
              BottomNavigationBarItem(icon: Icon(Icons.camera_alt_rounded), label: 'Analysis'),
              BottomNavigationBarItem(icon: Icon(Icons.help_outline_rounded), label: 'About'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
            onTap: (index) {
              if (index == currentIndex) return; // Do nothing if already on this tab
              
              switch (index) {
                case 0:
                  _navigate(context, const HomeDashboard());
                  break;
                case 1:
                  _navigate(context, routes.favoritesScreen());
                  break;
                case 2:
                  _navigate(context, routes.analysisScreen());
                  break;
                case 3:
                  _navigate(context, routes.aboutScreen());
                  break;
                case 4:
                  _navigate(context, routes.settingsScreen());
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}