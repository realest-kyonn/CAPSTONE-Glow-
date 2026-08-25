import 'package:flutter/material.dart';
import 'skin_quiz_data.dart';

// ─────────────────────────────────────────────────────────────
// Skin Type Quiz — Step 3: result
// Shows the picked skin type's description, skincare routine, and
// makeup guidance. Nothing is saved — a fresh quiz always starts clean.
// ─────────────────────────────────────────────────────────────

class SkinTypeResultScreen extends StatelessWidget {
  final String skinTypeKey;

  const SkinTypeResultScreen({super.key, required this.skinTypeKey});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;
    final SkinTypeInfo type = skinTypes[skinTypeKey] ?? skinTypes['normal']!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, type, contentWidth, screenHeight),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.06,
                      vertical: screenHeight * 0.025,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.description,
                          style: TextStyle(
                            fontSize: contentWidth * 0.037,
                            color: Colors.black54,
                            height: 1.6,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        _buildSection(
                          title: 'SUGGESTED SKINCARE ROUTINE',
                          icon: Icons.spa_rounded,
                          items: type.skincareTips,
                          contentWidth: contentWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        _buildSection(
                          title: 'SUGGESTED MAKEUP GUIDANCE',
                          icon: Icons.brush_rounded,
                          items: type.makeupGuidance,
                          contentWidth: contentWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                              'Retake Test',
                              style: TextStyle(
                                fontSize: contentWidth * 0.045,
                                color: const Color(0xFFFF6EB4),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.012),

                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.popUntil(
                              context,
                              (route) => route.settings.name == '/home',
                            ),
                            child: Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: contentWidth * 0.04,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),

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

  Widget _buildHeader(BuildContext context, SkinTypeInfo type,
      double contentWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: screenHeight * 0.03,
        left: contentWidth * 0.06,
        right: contentWidth * 0.06,
        bottom: screenHeight * 0.03,
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
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            'YOUR SKIN TYPE',
            style: TextStyle(
              fontSize: contentWidth * 0.03,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Row(
            children: [
              Container(
                width: contentWidth * 0.14,
                height: contentWidth * 0.14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type.icon,
                  color: const Color(0xFFFF6EB4),
                  size: contentWidth * 0.075,
                ),
              ),
              SizedBox(width: contentWidth * 0.04),
              Expanded(
                child: Text(
                  type.name,
                  style: TextStyle(
                    fontSize: contentWidth * 0.11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required double contentWidth,
    required double screenHeight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: contentWidth * 0.08,
              height: contentWidth * 0.08,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6EB4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: contentWidth * 0.045),
            ),
            SizedBox(width: contentWidth * 0.03),
            Text(
              title,
              style: TextStyle(
                fontSize: contentWidth * 0.038,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6EB4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.015),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(contentWidth * 0.045),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < items.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == items.length - 1 ? 0 : screenHeight * 0.014,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: contentWidth * 0.012),
                        child: Container(
                          width: contentWidth * 0.016,
                          height: contentWidth * 0.016,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6EB4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(width: contentWidth * 0.03),
                      Expanded(
                        child: Text(
                          items[i],
                          style: TextStyle(
                            fontSize: contentWidth * 0.035,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
