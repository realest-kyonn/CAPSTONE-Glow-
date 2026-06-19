import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const GlowApp());
}

class GlowApp extends StatelessWidget {
  const GlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GLOW',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _raysAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    // Get screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Scale everything based on screen size
    final sunSize = screenWidth * 0.32;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            children: [
              const Spacer(),

              // Sun illustration
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

              Text(
                'GLOW',
                style: TextStyle(
                  fontSize: screenWidth * 0.13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6EB4),
                  letterSpacing: 8,
                ),
              ),

              Text(
                'facial analysis',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: const Color(0xFFFF6EB4),
                  letterSpacing: 4,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              Text(
                'Discover your perfect aesthetic based on your unique features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.034,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.065,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6EB4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Start my Journey',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
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
    );
  }
}

class SunPainter extends CustomPainter {
  final double progress;

  SunPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Light pink ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFFB6D9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.52, ringPaint);

    // Pink center circle
    final circlePaint = Paint()
      ..color = const Color(0xFFFF6EB4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.34, circlePaint);

    // Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFB6D9)
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    const int numRays = 8;
    final double rayStart = radius * 0.62;
    final double rayMax = radius * 0.88;

    for (int i = 0; i < numRays; i++) {
      final angle = (2 * pi / numRays) * i - pi / 2;
      final animatedEnd = rayStart + (rayMax - rayStart) * progress;

      final start = Offset(
        center.dx + rayStart * cos(angle),
        center.dy + rayStart * sin(angle),
      );
      final end = Offset(
        center.dx + animatedEnd * cos(angle),
        center.dy + animatedEnd * sin(angle),
      );

      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(SunPainter oldDelegate) =>
      oldDelegate.progress != progress;
}