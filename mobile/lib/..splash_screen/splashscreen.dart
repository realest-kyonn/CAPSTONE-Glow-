import 'package:flutter/material.dart';
import '../shared/sun_painter.dart';
import '../page_1/page1.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _riseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Sun rises from below into its resting position
    _riseAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // starts lower on screen
      end: Offset.zero,            // ends at natural position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Fades in while rising
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Wait for rise animation + a short pause, then jump to Page 1
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double sunSize = (screenWidth > 420 ? 420 : screenWidth) * 0.32;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SlideTransition(
          position: _riseAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomPaint(
              size: Size(sunSize, sunSize),
              painter: SunPainter(1.0),
            ),
          ),
        ),
      ),
    );
  }
}