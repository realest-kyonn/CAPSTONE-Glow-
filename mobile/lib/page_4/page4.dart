import 'package:flutter/material.dart';
import '../page_5/page5.dart';
import '../page_14_favorites/favorites.dart';
import '../page_about/about_screen.dart';
import '../page_settings/settings_screen.dart';
import '../page_skin_quiz/bare_face_tutorial_screen.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  static const List<Map<String, String>> _styles = [
    {
      'name': 'Clean Girl Makeup',
      'desc': 'Effortless, skin-first glow',
      'detail':
          'Clean Girl Makeup is all about looking like the best, most '
              'polished version of your bare face. Popularized on social '
              'media, this trend champions glowing, hydrated skin, groomed '
              'brows, and barely-there color — as if you woke up naturally '
              'radiant. Think glass skin, fluffy brows, and a subtle flush.',
    },
    {
      'name': 'No-Makeup Makeup',
      'desc': 'Invisible enhancement',
      'detail':
          'No-Makeup Makeup is the art of looking completely natural while '
              'subtly correcting and enhancing your features. The goal is '
              "for no one to be able to tell you're wearing anything — just "
              'a better, more even version of you.',
    },
    {
      'name': 'Fresh Dewy Makeup',
      'desc': 'Glass skin, lit-from-within radiance',
      'detail':
          'Fresh Dewy Makeup turns up the glow dial several notches. '
              "It's a full-coverage-meets-glassy-skin look where luminosity "
              'is the star. Every product amplifies light reflection — from '
              'a glowing foundation to cream blush to a dab of highlighter.',
    },
    {
      'name': 'Soft Glam Everyday',
      'desc': 'Polished, wearable glam',
      'detail':
          'Soft Glam Everyday bridges the gap between natural and '
              'glamorous — a subtle smoky eye in neutral tones, defined '
              'lashes, a sculpted cheek, and a satin lip. It elevates a '
              'daily look without feeling overdressed.',
    },
    {
      'name': 'Korean Daily Makeup',
      'desc': 'Youthful, dewy, and cute',
      'detail':
          'Korean Daily Makeup (K-Beauty everyday) is defined by '
              'cushion-soft skin, straight or softly rounded brows, a '
              'gradient lip, and a focus on eye-brightening. It values a '
              'youthful, natural freshness with carefully chosen pops of '
              'color.',
    },
    {
      'name': 'Peach Makeup',
      'desc': 'Warm, sun-kissed, peachy-sweet',
      'detail':
          'Peach Makeup is a monochromatic warm look that ties everything '
              'together in soft peach, coral, and golden tones. Eyes, '
              'cheeks, and lips all speak the same warm language, creating '
              'a cohesive, sun-kissed flush.',
    },
    {
      'name': 'Soft Contour Makeup',
      'desc': 'Subtle reshaping, natural finish',
      'detail':
          'Soft Contour Makeup focuses on dimensionality without drama. '
              'Unlike full contouring, soft contour uses slightly deeper '
              'and lighter shades to add structure where the face '
              'naturally has shadows and light.',
    },
    {
      'name': 'Lifted Makeup',
      'desc': 'Visually lift and elongate eyes',
      'detail':
          'Lifted Makeup is a technique-focused style specifically '
              'designed to create the visual illusion of eyes that are '
              'lifted, elongated, and upturned. It works by extending '
              'liner and shadow upward at the outer corner.',
    },
    {
      'name': 'Snatched Everyday',
      'desc': 'Defined, sculpted, sharp',
      'detail':
          'Snatched Everyday Makeup combines a full, even base with '
              'sculpted contour, defined brows, striking eyes, and a '
              'prominent lip — but keeps the execution clean enough to '
              'wear to work, school, or brunch.',
    },
    {
      'name': 'Igari-Inspired',
      'desc': 'Japanese hangover blush',
      'detail':
          'Igari makeup (from Japanese meaning hangover) is characterized '
              'by its distinctive blushy nose-bridge and under-eye area — '
              'mimicking flushed, rosy skin. Named after Japanese makeup '
              "artist Igari Shinobu, it's youthful, romantic, and playful.",
    },
    {
      'name': 'Douyin Natural',
      'desc': 'Porcelain skin meets soft detail',
      'detail':
          'Douyin Makeup features flawlessly smooth, porcelain-like skin, '
              'straight brows, soft feathered lashes, a carefully shaped '
              'bow-shaped lip, and subtle color. It balances precision '
              'with a soft, dreamy quality.',
    },
    {
      'name': 'Strawberry Makeup',
      'desc': 'Red-toned, rosy, sweetly flushed',
      'detail':
          'Strawberry Makeup is inspired by the colors of the fruit — '
              'red-tinged cheeks, rosy lips, peachy-warm eyes, and '
              'optionally faux freckles. Everything leans red and pink '
              'rather than cool or neutral.',
    },
    {
      'name': 'Office Makeup',
      'desc': 'Professional and polished',
      'detail':
          'Office Makeup is defined by being neat, appropriate, and '
              'confidence-boosting without being distracting. It favors '
              'polished neutral tones, well-groomed features, and a clean '
              'base.',
    },
    {
      'name': 'Neutral Glam',
      'desc': 'Understated timeless glamour',
      'detail':
          'Neutral Glam is the elevated cousin of Soft Glam — still '
              'wearable, but with more intention and drama. It lives in '
              'the world of nudes, taupes, browns, and warm champagnes.',
    },
    {
      'name': 'Corporate Clean',
      'desc': 'Minimalist, refined, powerful',
      'detail':
          'Corporate Clean Makeup is the most stripped-back professional '
              'look. It is about precision, immaculate skin, and quiet '
              'confidence. Every product is purposeful and nothing is '
              'excessive.',
    },
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
        return GestureDetector(
          onTap: () => _showStyleDetail(context, style),
          child: _buildStyleCard(style, itemWidth),
        );
      },
    );
  }

  void _showStyleDetail(BuildContext context, Map<String, String> style) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          style['name']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6EB4),
          ),
        ),
        content: Text(style['detail'] ?? style['desc']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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