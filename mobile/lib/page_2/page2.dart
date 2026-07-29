import 'package:flutter/material.dart';
import '../page_4/page4.dart'; // ← changed from camera.dart

// Tutorial / Onboarding Screen — Page 2
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
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

    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: contentWidth * 0.07,
                vertical: screenHeight * 0.03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Glow',
                    style: TextStyle(
                      fontSize: contentWidth * 0.09,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6EB4),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.008),

                  Text(
                    'Everything you need to know:',
                    style: TextStyle(
                      fontSize: contentWidth * 0.042,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  const Divider(color: Color(0xFFFF6EB4), thickness: 1),

                  SizedBox(height: screenHeight * 0.02),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          _buildFeatureCard(
                            icon: Icons.face_retouching_natural,
                            title: 'AI Facial Analysis',
                            subtitle: 'Scan your face with AI',
                            contentWidth: contentWidth,
                            screenHeight: screenHeight,
                          ),

                          SizedBox(height: screenHeight * 0.015),

                          _buildFeatureCard(
                            icon: Icons.menu_book_rounded,
                            title: 'Step-by-Step Tutorials',
                            subtitle: 'Learn to apply your look',
                            contentWidth: contentWidth,
                            screenHeight: screenHeight,
                          ),

                          SizedBox(height: screenHeight * 0.015),

                          _buildFeatureCard(
                            icon: Icons.lock_rounded,
                            title: 'Privacy-Focused',
                            subtitle: 'Your data stays on device',
                            contentWidth: contentWidth,
                            screenHeight: screenHeight,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Get Started button → navigates to Home Dashboard (Page 4)
                  SizedBox(
                    width: double.infinity,
                    height: contentWidth * 0.14,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeDashboard(), // ← changed
                            settings: const RouteSettings(name: '/home'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFF6EB4),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: contentWidth * 0.048,
                          color: const Color(0xFFFF6EB4),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double contentWidth,
    required double screenHeight,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(contentWidth * 0.025),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6EB4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: contentWidth * 0.065,
            ),
          ),

          SizedBox(width: contentWidth * 0.04),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: contentWidth * 0.042,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: contentWidth * 0.034,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}