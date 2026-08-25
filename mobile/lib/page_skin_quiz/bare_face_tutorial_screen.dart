import 'package:flutter/material.dart';
import 'skin_type_question_screen.dart';

// ─────────────────────────────────────────────────────────────
// Skin Type Quiz — Step 1: Bare-Face Test tutorial
// Explains how to prep skin before answering the quiz question, so the
// user's answer reflects their skin's natural state, not residue from
// product or makeup.
// ─────────────────────────────────────────────────────────────

class BareFaceTutorialScreen extends StatelessWidget {
  const BareFaceTutorialScreen({super.key});

  static const List<Map<String, String>> _steps = [
    {
      'title': 'Wash your face',
      'desc': 'Use a gentle cleanser to remove makeup, sunscreen, and '
          "the day's oil and sweat.",
    },
    {
      'title': 'Pat dry',
      'desc': "Pat — don't rub — with a clean towel.",
    },
    {
      'title': 'Wait 30–60 minutes',
      'desc': "Don't apply any products (no moisturizer, no makeup) "
          'during this time.',
    },
    {
      'title': 'Observe and feel your skin',
      'desc': 'Check how your face looks and feels — that\'s the '
          "answer you'll use on the next screen.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

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
                  _buildHeader(context, contentWidth, screenHeight),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.06,
                      vertical: screenHeight * 0.025,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why this matters',
                          style: TextStyle(
                            fontSize: contentWidth * 0.042,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6EB4),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Leftover product, sunscreen, or makeup can make '
                          'your skin look and feel different from how it '
                          'naturally is. A short bare-face window gives you '
                          'an honest read before you answer.',
                          style: TextStyle(
                            fontSize: contentWidth * 0.037,
                            color: Colors.black54,
                            height: 1.6,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        Text(
                          'The Bare-Face Test',
                          style: TextStyle(
                            fontSize: contentWidth * 0.042,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6EB4),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        ..._steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: screenHeight * 0.015),
                            child: _buildStepCard(
                              stepNumber: index + 1,
                              title: step['title']!,
                              desc: step['desc']!,
                              contentWidth: contentWidth,
                            ),
                          );
                        }),

                        SizedBox(height: screenHeight * 0.02),

                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SkinTypeQuestionScreen(),
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
                              'Next',
                              style: TextStyle(
                                fontSize: contentWidth * 0.045,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),
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

  Widget _buildHeader(
      BuildContext context, double contentWidth, double screenHeight) {
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
            'SKIN TYPE TEST',
            style: TextStyle(
              fontSize: contentWidth * 0.03,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            'Bare-Face Test',
            style: TextStyle(
              fontSize: contentWidth * 0.09,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String desc,
    required double contentWidth,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: contentWidth * 0.08,
            height: contentWidth * 0.08,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6EB4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: contentWidth * 0.038,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: contentWidth * 0.04),
          Expanded(
            child: Column(
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
                SizedBox(height: contentWidth * 0.008),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: contentWidth * 0.035,
                    color: Colors.black54,
                    height: 1.4,
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
