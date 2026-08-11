import 'package:flutter/material.dart';
import 'dart:math';
import '../page_1/page1.dart';

// Splash Screen — Page 0
//
// Plays once on app launch, then hands off to the Welcome screen (Page 1):
//   1. Rise   (~10s) — the sun bounces up from below the screen to dead
//      centre, against a black background.
//   2. Reveal (~3s)  — once the sun lands, a soft white flash expands
//      outward from the sun (like a sunrise) until it covers the whole
//      screen, then the app moves on to Page 1.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _riseController;
  late final AnimationController _revealController;

  late final Animation<double> _riseAnimation; // 0 (off-screen) -> 1 (rest)
  late final Animation<double> _raysAnimation; // rays settle early in the rise
  late final Animation<double> _bounceScale; // slight overshoot on landing
  late final Animation<double> _revealAnimation; // 0 -> 1 reveal progress

  @override
  void initState() {
    super.initState();

    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _riseAnimation = CurvedAnimation(
      parent: _riseController,
      curve: Curves.bounceOut,
    );
    // Rays assemble within the first 30% of the rise so they don't take
    // the full 10s to look "settled".
    _raysAnimation = Tween<double>(begin: 2.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _riseController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _bounceScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.bounceOut),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutQuart,
    );

    // Chain the two stages: rise -> reveal -> hand off to Page 1.
    _riseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _revealController.forward();
      }
    });
    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToWelcome();
      }
    });

    _riseController.forward();
  }

  void _goToWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _riseController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;
    final double sunSize = contentWidth * 0.32;

    // The sun comes to rest dead centre.
    final double sunRestTop = screenHeight / 2 - sunSize / 2;
    final Offset sunCenter = Offset(screenWidth / 2, screenHeight / 2);
    final double revealMaxRadius =
        sqrt(screenWidth * screenWidth + screenHeight * screenHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black)),

          // Sunrise flash — expands from the sun's resting position and
          // brightens the screen from black to white.
          AnimatedBuilder(
            animation: _revealAnimation,
            builder: (context, child) => Positioned.fill(
              child: CustomPaint(
                painter: SunriseRevealPainter(
                  center: sunCenter,
                  radius: _revealAnimation.value * revealMaxRadius,
                ),
              ),
            ),
          ),

          // The rising sun.
          AnimatedBuilder(
            animation: Listenable.merge([_riseAnimation, _bounceScale]),
            builder: (context, child) {
              final top = _lerp(
                screenHeight + sunSize,
                sunRestTop,
                _riseAnimation.value,
              );
              return Positioned(
                top: top,
                left: (screenWidth - sunSize) / 2,
                child: Transform.scale(
                  scale: _bounceScale.value,
                  child: AnimatedBuilder(
                    animation: _raysAnimation,
                    builder: (context, child) => CustomPaint(
                      size: Size(sunSize, sunSize),
                      painter: SunPainter(_raysAnimation.value),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

// Expanding "sunrise" flash — a soft-edged white circle that grows from
// the sun's position to brighten the black background to white.
class SunriseRevealPainter extends CustomPainter {
  final Offset center;
  final double radius;

  SunriseRevealPainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final paint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(SunriseRevealPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.center != center;
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
