import 'package:flutter/material.dart';
import '../page_6_camera/camera.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  // All 15 makeup styles
  static const List<Map<String, String>> _styles = [
    {'name': 'Clean Girl Makeup', 'desc': 'Effortless, skin-first glow'},
    {'name': 'No-Makeup Makeup', 'desc': 'Invisible enhancement — look done without looking done up'},
    {'name': 'Fresh Dewy Makeup', 'desc': 'Glass skin, flushed cheeks, lit-from-within radiance'},
    {'name': 'Soft Glam Everyday', 'desc': 'Polished, wearable glam for any occasion'},
    {'name': 'Korean Daily Makeup', 'desc': 'Youthful, dewy, and effortlessly cute'},
    {'name': 'Peach Makeup', 'desc': 'Warm, sun-kissed, and peachy-sweet'},
    {'name': 'Soft Contour Makeup', 'desc': 'Subtle reshaping with a natural finish'},
    {'name': 'Lifted Makeup', 'desc': 'Visually lift and elongate the eyes'},
    {'name': 'Snatched Everyday Makeup', 'desc': 'Defined, sculpted, and effortlessly sharp'},
    {'name': 'Igari-Inspired Makeup', 'desc': 'The Japanese hangover blush — effortlessly dreamy'},
    {'name': 'Douyin Natural Makeup', 'desc': 'Chinese social media beauty — porcelain skin meets soft detail'},
    {'name': 'Strawberry Makeup', 'desc': 'Red-toned, rosy, and sweetly flushed'},
    {'name': 'Office Makeup', 'desc': 'Professional, polished, and appropriate for the workplace'},
    {'name': 'Neutral Glam', 'desc': 'Understated glamour in a timeless palette'},
    {'name': 'Corporate Clean Makeup', 'desc': 'Minimalist, refined, and quietly powerful'},
  ];

  // How It Works steps — static final because Icons can't be const
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
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(contentWidth),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: contentWidth * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnalysisCard(context, contentWidth),
                      const SizedBox(height: 28),
                      Text(
                        'How It Works',
                        style: TextStyle(
                          fontSize: contentWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF6EB4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHowItWorks(contentWidth),
                      const SizedBox(height: 28),
                      Text(
                        'Styles We Match You To',
                        style: TextStyle(
                          fontSize: contentWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF6EB4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every recommendation pulls from these looks',
                        style: TextStyle(
                          fontSize: contentWidth * 0.035,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStylesGrid(contentWidth),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: contentWidth * 0.05,
            right: contentWidth * 0.05,
            child: _buildBottomNav(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double contentWidth) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFF6EB4),
      padding: EdgeInsets.only(
        top: 56,
        left: contentWidth * 0.06,
        right: contentWidth * 0.06,
        bottom: 28,
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
          const SizedBox(height: 8),
          Text(
            'A free face scan, matched to your tone and features. See your look before you commit to anything.',
            style: TextStyle(
              fontSize: contentWidth * 0.038,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context, double contentWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: contentWidth * 0.32,
            height: contentWidth * 0.32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.face_retouching_natural,
                  size: contentWidth * 0.18,
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
                    fontSize: contentWidth * 0.042,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF6EB4),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CameraScreen(),
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
                      padding: EdgeInsets.symmetric(vertical: contentWidth * 0.025),
                    ),
                    child: Text(
                      'Begin Analysis',
                      style: TextStyle(
                        fontSize: contentWidth * 0.036,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your photo is analyzed privately and never shared',
                  style: TextStyle(
                    fontSize: contentWidth * 0.028,
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
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF4CAF50), width: 2),
            left: BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks(double contentWidth) {
    return SizedBox(
      height: contentWidth * 0.55,
      child: Row(
        children: [
          Expanded(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(Map<String, dynamic> step, double contentWidth) {
    final cardWidth = contentWidth * 0.42;
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(contentWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            step['icon'] as IconData,
            size: contentWidth * 0.12,
            color: const Color(0xFFFF6EB4),
          ),
          const SizedBox(height: 12),
          Text(
            step['title'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.038,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step['desc'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.03,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylesGrid(double contentWidth) {
    final itemWidth = (contentWidth - contentWidth * 0.1 - 16) / 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _styles.length,
      itemBuilder: (context, index) {
        final style = _styles[index];
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
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style['name']!,
                  style: TextStyle(
                    fontSize: itemWidth * 0.18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  style['desc']!,
                  style: TextStyle(
                    fontSize: itemWidth * 0.14,
                    color: Colors.black45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6EB4),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            iconSize: 26,
          ),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.favorite_rounded, color: Colors.white),
            iconSize: 26,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraScreen(),
                ),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6EB4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.photo_rounded, color: Colors.white),
            iconSize: 26,
          ),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            iconSize: 26,
          ),
        ],
      ),
    );
  }
}