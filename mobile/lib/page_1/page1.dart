import 'package:flutter/material.dart';
import 'dart:math';
import '../page_2/page2.dart';

// Welcome Screen — Page 1
// Reached automatically once the splash screen (Page 0) finishes its
// rise + sunrise-reveal animation. The sun/title/tagline fade in first;
// once fully visible, the button fades in a second later.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _titleController;
  late final AnimationController _buttonController;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _titleController.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _buttonController.forward();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buttonController.dispose();
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

                  FadeTransition(
                    opacity: _titleController,
                    child: Column(
                      children: [
                        // Sun illustration
                        CustomPaint(
                          size: Size(sunSize, sunSize),
                          painter: SunPainter(),
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
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Start my Journey button — fades in 1s after the title
                  // block is fully shown; navigates to Tutorial Screen.
                  FadeTransition(
                    opacity: _buttonController,
                    child: AnimatedBuilder(
                      animation: _buttonController,
                      builder: (context, child) => IgnorePointer(
                        ignoring: _buttonController.value < 1.0,
                        child: child,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
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

// Sun painter — draws the static sun icon (rays fully settled).
class SunPainter extends CustomPainter {
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
    final double rayStart = radius * 0.62;

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

      canvas.drawLine(startPoint, endPoint, rayPaint);
    }
  }

  @override
  bool shouldRepaint(SunPainter oldDelegate) => false;
}
