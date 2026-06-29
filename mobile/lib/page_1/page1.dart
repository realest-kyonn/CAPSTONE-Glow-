import 'package:flutter/material.dart';
import 'dart:math';
import '../page_2/page2.dart';

// Splash Screen — Page 1
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _raysAnimation;

  @override
  void initState() {
    super.initState();

    // Animation plays once when screen opens
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Rays come in from far out to normal position
    _raysAnimation = Tween<double>(begin: 2.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Limit max width for PC screens
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;
    final double sunSize = contentWidth * 0.32;
    final double titleSize = contentWidth * 0.13;
    final double subtitleSize = contentWidth * 0.045;
    final double taglineSize = contentWidth * 0.038;
    final double buttonFontSize = contentWidth * 0.048;
    final double buttonHeight = contentWidth * 0.14;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: contentWidth,
          height: screenHeight,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: contentWidth * 0.08),
              child: Column(
                children: [
                  const Spacer(),

                  // Animated sun illustration
                  AnimatedBuilder(
                    animation: _raysAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(sunSize, sunSize),
                        painter: SunPainter(_raysAnimation.value),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // GLOW title
                  Text(
                    'GLOW',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6EB4),
                      letterSpacing: titleSize * 0.15,
                    ),
                  ),

                  // Subtitle
                  Text(
                    'facial analysis',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: const Color(0xFFFF6EB4),
                      letterSpacing: subtitleSize * 0.2,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Tagline
                  Text(
                    'Discover your perfect aesthetic based on your unique features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: taglineSize,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),

                  const Spacer(),

                  // Start my Journey button — navigates to Tutorial Screen
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                     onPressed: () {
  // Navigate to Tutorial Screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const TutorialScreen(),
    ),
  );
},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6EB4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Start my Journey',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Sun painter — draws the sun with animated rays
class SunPainter extends CustomPainter {
  final double raysDistance;

  SunPainter(this.raysDistance);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Light pink ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFFB6D9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.52, ringPaint);

    // Hot pink center circle
    final circlePaint = Paint()
      ..color = const Color(0xFFFF6EB4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.34, circlePaint);

    // Ray styling
    final rayPaint = Paint()
      ..color = const Color(0xFFFFB6D9)
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    const int numRays = 8;
    final double rayEnd = radius * 0.88;
    final double rayStart = radius * 0.62 * raysDistance;

    for (int i = 0; i < numRays; i++) {
      final angle = (2 * pi / numRays) * i - pi / 2;

      final startPoint = Offset(
        center.dx + rayStart * cos(angle),
        center.dy + rayStart * sin(angle),
      );
      final endPoint = Offset(
        center.dx + rayEnd * cos(angle),
        center.dy + rayEnd * sin(angle),
      );

      if (rayStart <= rayEnd) {
        canvas.drawLine(startPoint, endPoint, rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(SunPainter oldDelegate) =>
      oldDelegate.raysDistance != raysDistance;
}