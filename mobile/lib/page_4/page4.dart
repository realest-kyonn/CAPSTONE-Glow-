import 'package:flutter/material.dart';
import '../page_5/page5.dart';
import '../page_14_favorites/favorites.dart';
import '../page_about/about_screen.dart';
import '../page_settings/settings_screen.dart';
import '../page_skin_quiz/bare_face_tutorial_screen.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  static const List<Map<String, String>> _styles = [
    {'name': 'Clean Girl Makeup', 'desc': 'Effortless, skin-first glow'},
    {'name': 'No-Makeup Makeup', 'desc': 'Invisible enhancement'},
    {'name': 'Fresh Dewy Makeup', 'desc': 'Glass skin, lit-from-within radiance'},
    {'name': 'Soft Glam Everyday', 'desc': 'Polished, wearable glam'},
    {'name': 'Korean Daily Makeup', 'desc': 'Youthful, dewy, and cute'},
    {'name': 'Peach Makeup', 'desc': 'Warm, sun-kissed, peachy-sweet'},
    {'name': 'Soft Contour Makeup', 'desc': 'Subtle reshaping, natural finish'},
    {'name': 'Lifted Makeup', 'desc': 'Visually lift and elongate eyes'},
    {'name': 'Snatched Everyday', 'desc': 'Defined, sculpted, sharp'},
    {'name': 'Igari-Inspired', 'desc': 'Japanese hangover blush'},
    {'name': 'Douyin Natural', 'desc': 'Porcelain skin meets soft detail'},
    {'name': 'Strawberry Makeup', 'desc': 'Red-toned, rosy, sweetly flushed'},
    {'name': 'Office Makeup', 'desc': 'Professional and polished'},
    {'name': 'Neutral Glam', 'desc': 'Understated timeless glamour'},
    {'name': 'Corporate Clean', 'desc': 'Minimalist, refined, powerful'},
  ];

  static final List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.face_retouching_natural,
      'title': 'Scan your face',
      'desc': 'One clear photo, good lighting',
    },
    {
      'icon': Icons.auto_awesome,
      'title': 'AI Analysis',
      'desc': 'We analyze your facial features.',
    },
    {
      'icon': Icons.brush_rounded,
      'title': 'Get Recommendations',
      'desc': 'Receive makeup styles tailored to you.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(context, contentWidth, screenWidth),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(contentWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.025),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: contentWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnalysisCard(context, contentWidth, screenHeight),
                        SizedBox(height: screenHeight * 0.02),
                        _buildSkinQuizCard(context, contentWidth, screenHeight),
                        SizedBox(height: screenHeight * 0.03),
                        Text(
                          'How It Works',
                          style: TextStyle(
                            fontSize: contentWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6EB4),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        _buildHowItWorks(contentWidth, screenHeight),
                        SizedBox(height: screenHeight * 0.03),
                        Text(
                          'Styles We Match You To',
                          style: TextStyle(
                            fontSize: contentWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6EB4),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          'Every recommendation pulls from these looks',
                          style: TextStyle(
                            fontSize: contentWidth * 0.035,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildStylesGrid(contentWidth),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double contentWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFF6EB4),
      padding: EdgeInsets.only(
        top: screenHeight * 0.03,
        left: contentWidth * 0.06,
        right: contentWidth * 0.06,
        bottom: screenHeight * 0.03,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, beautiful!',
            style: TextStyle(
              fontSize: contentWidth * 0.1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'A free face scan, matched to your tone and features.',
            style: TextStyle(
              fontSize: contentWidth * 0.038,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
      BuildContext context, double contentWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: contentWidth * 0.3,
            height: contentWidth * 0.3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.face_retouching_natural,
                  size: contentWidth * 0.16,
                  color: const Color(0xFFFFB6D9),
                ),
                Positioned(top: 8, left: 8, child: _cornerBracket(topLeft: true)),
                Positioned(top: 8, right: 8, child: _cornerBracket(topLeft: false)),
                Positioned(bottom: 8, left: 8, child: _cornerBracket(topLeft: true, flip: true)),
                Positioned(bottom: 8, right: 8, child: _cornerBracket(topLeft: false, flip: true)),
              ],
            ),
          ),
          SizedBox(width: contentWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock your face\'s full potential',
                  style: TextStyle(
                    fontSize: contentWidth * 0.04,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF6EB4),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Scan Prep Screen (Page 5)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanPrepScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: contentWidth * 0.02),
                    ),
                    child: Text(
                      'Begin Analysis',
                      style: TextStyle(
                        fontSize: contentWidth * 0.034,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.007),
                Text(
                  'Your photo is never shared',
                  style: TextStyle(
                    fontSize: contentWidth * 0.026,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinQuizCard(
      BuildContext context, double contentWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: contentWidth * 0.3,
            height: contentWidth * 0.3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.spa_rounded,
              size: contentWidth * 0.16,
              color: const Color(0xFFFFB6D9),
            ),
          ),
          SizedBox(width: contentWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s your skin type?',
                  style: TextStyle(
                    fontSize: contentWidth * 0.04,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF6EB4),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BareFaceTutorialScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: contentWidth * 0.02),
                    ),
                    child: Text(
                      'Try this test',
                      style: TextStyle(
                        fontSize: contentWidth * 0.034,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.007),
                Text(
                  'A quick one-question skin type check',
                  style: TextStyle(
                    fontSize: contentWidth * 0.026,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerBracket({required bool topLeft, bool flip = false}) {
    return Transform.scale(
      scaleX: topLeft ? 1 : -1,
      scaleY: flip ? -1 : 1,
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF4CAF50), width: 2),
            left: BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks(double contentWidth, double screenHeight) {
    return SizedBox(
      height: contentWidth * 0.5,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          final step = _steps[index];
          return Row(
            children: [
              _buildStepCard(step, contentWidth),
              if (index < _steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    color: const Color(0xFFFF6EB4),
                    size: contentWidth * 0.05,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepCard(Map<String, dynamic> step, double contentWidth) {
    final cardWidth = contentWidth * 0.4;
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(contentWidth * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            step['icon'] as IconData,
            size: contentWidth * 0.11,
            color: const Color(0xFFFF6EB4),
          ),
          const SizedBox(height: 10),
          Text(
            step['title'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.036,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step['desc'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.028,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylesGrid(double contentWidth) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _styles.length,
      itemBuilder: (context, index) {
        final style = _styles[index];
        final itemWidth = (contentWidth - contentWidth * 0.1 - 16) / 3;
        return _buildStyleCard(style, itemWidth);
      },
    );
  }

  Widget _buildStyleCard(Map<String, String> style, double itemWidth) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFF6EB4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style['name']!,
                  style: TextStyle(
                    fontSize: itemWidth * 0.17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  style['desc']!,
                  style: TextStyle(
                    fontSize: itemWidth * 0.13,
                    color: Colors.black45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
      BuildContext context, double contentWidth, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(
        left: contentWidth * 0.05,
        right: contentWidth * 0.05,
        bottom: 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFFFF6EB4),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          iconSize: contentWidth * 0.065,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help_outline_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: '',
            ),
          ],
          onTap: (index) {
            if (index == 1) {
              // Favorite button — navigate to Saved Results (Page 15)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            } else if (index == 2) {
              // Camera button — navigate to Scan Prep Screen (Page 5)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanPrepScreen(),
                ),
              );
            } else if (index == 3) {
              // "?" button — navigate to About screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            } else if (index == 4) {
              // Gear button — navigate to Settings screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}