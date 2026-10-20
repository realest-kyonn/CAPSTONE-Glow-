import 'package:flutter/material.dart';
import '../page_6_camera/camera.dart';
import '../widgets/floating_bottom_nav.dart';

// Face Scan Preparation Screen — Page 5
class ScanPrepScreen extends StatelessWidget {
  const ScanPrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: FloatingBottomNav(currentIndex: 2),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                // Pink header
                _buildHeader(contentWidth, screenHeight),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      children: [
                        // Face illustration
                        _buildFaceIllustration(contentWidth, screenHeight),

                        SizedBox(height: screenHeight * 0.01),

                        // Subtitle
                        Text(
                          'Before you face the oval and feel this.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: contentWidth * 0.033,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // Tip cards
                        _buildTipCard(
                          icon: Icons.light_mode_rounded,
                          title: 'Proper Lighting',
                          badge: 'Most Important',
                          badgeColor: const Color(0xFFFF6EB4),
                          desc: 'Face a light source directly, avoid backlight',
                          contentWidth: contentWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        _buildTipCard(
                          icon: Icons.face_rounded,
                          title: 'Face centered',
                          badge: 'Required',
                          badgeColor: Colors.orange,
                          desc: 'Keep your whole face inside the oval',
                          contentWidth: contentWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        _buildTipCard(
                          icon: Icons.sentiment_satisfied_rounded,
                          title: 'Relaxed expression',
                          desc: 'Let your face rest naturally',
                          contentWidth: contentWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        _buildTipCard(
                          icon: Icons.stay_current_portrait_rounded,
                          title: 'Hold steady',
                          desc: 'Keep your phone still to avoid blur',
                          contentWidth: contentWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Open Camera button
                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to Camera Screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CameraScreen(),
                                  settings: const RouteSettings(name: '/camera'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6EB4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Open Camera',
                              style: TextStyle(
                                fontSize: contentWidth * 0.045,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pink header with title
  Widget _buildHeader(double contentWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: screenHeight * 0.025,
        left: contentWidth * 0.06,
        right: contentWidth * 0.06,
        bottom: screenHeight * 0.025,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFF6EB4),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BEFORE YOU SCAN',
            style: TextStyle(
              fontSize: contentWidth * 0.032,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            'Scan Preparation',
            style: TextStyle(
              fontSize: contentWidth * 0.09,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // Face illustration with oval guide and checkmark
  Widget _buildFaceIllustration(double contentWidth, double screenHeight) {
    return SizedBox(
      width: contentWidth * 0.5,
      height: contentWidth * 0.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Light pink circle background
          Container(
            width: contentWidth * 0.45,
            height: contentWidth * 0.45,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE4F0),
              shape: BoxShape.circle,
            ),
          ),

          // Dashed oval guide
          CustomPaint(
            size: Size(contentWidth * 0.38, contentWidth * 0.44),
            painter: DashedOvalPainter(),
          ),

          // Face icon
          Icon(
            Icons.face_rounded,
            size: contentWidth * 0.28,
            color: const Color(0xFFFF6EB4),
          ),

          // Green checkmark at top right
          Positioned(
            top: contentWidth * 0.03,
            right: contentWidth * 0.03,
            child: Container(
              width: contentWidth * 0.1,
              height: contentWidth * 0.1,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: contentWidth * 0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable tip card
  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String desc,
    required double contentWidth,
    required double screenHeight,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: contentWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: contentWidth * 0.11,
            height: contentWidth * 0.11,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE4F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6EB4),
              size: contentWidth * 0.06,
            ),
          ),

          SizedBox(width: contentWidth * 0.04),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: contentWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (badge != null) ...[
                      SizedBox(width: contentWidth * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: contentWidth * 0.02,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFFFF6EB4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: contentWidth * 0.025,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: screenHeight * 0.004),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: contentWidth * 0.033,
                    color: Colors.black54,
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

// Draws a dashed oval around the face
class DashedOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6EB4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const dashWidth = 8.0;
    const dashSpace = 5.0;

    // Draw dashed oval
    final path = Path()..addOval(rect);
    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = dashWidth < metric.length - distance
            ? dashWidth
            : metric.length - distance;
        dest.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(DashedOvalPainter oldDelegate) => false;
}