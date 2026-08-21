import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// About Screen
// Reached from the "?" icon in the Home Dashboard's bottom nav.
// Static project/app info — no backend data involved.
// ─────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const List<String> _researchers = [
    'Castro, Zyrell Paul',
    'Collado, Kean Clark',
    'Cloribel, Sofiarose',
    'Mendiola, Rich Ivyl Pie',
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
                          'Project overview',
                          style: TextStyle(
                            fontSize: contentWidth * 0.042,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6EB4),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        _buildOutlinedBox(
                          contentWidth: contentWidth,
                          child: Text(
                            'GLOW is an AI-powered mobile application that '
                            'analyzes facial features to provide personalized '
                            'makeup recommendations.\n\n'
                            'Using MediaPipe and TensorFlow Lite, it detects '
                            'face shape, skin tone, and undertone to suggest '
                            'the best makeup style for each user — all while '
                            'keeping data private and on-device.',
                            style: TextStyle(
                              fontSize: contentWidth * 0.037,
                              color: const Color(0xFFFF6EB4),
                              height: 1.6,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        Text(
                          'Researchers',
                          style: TextStyle(
                            fontSize: contentWidth * 0.042,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6EB4),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        _buildOutlinedBox(
                          contentWidth: contentWidth,
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (int i = 0; i < _researchers.length; i++) ...[
                                _buildResearcherRow(
                                  _researchers[i],
                                  contentWidth,
                                ),
                                if (i < _researchers.length - 1)
                                  Divider(
                                    height: 1,
                                    color: const Color(0xFFFFD9EC),
                                    indent: contentWidth * 0.05,
                                    endIndent: contentWidth * 0.05,
                                  ),
                              ],
                            ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.keyboard_double_arrow_left_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: contentWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: contentWidth * 0.11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Learn more about GLOW',
                      style: TextStyle(
                        fontSize: contentWidth * 0.036,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.025),

          // GLOW / version card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(contentWidth * 0.04),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: contentWidth * 0.14,
                  height: contentWidth * 0.14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: const Color(0xFFE8A855),
                    size: contentWidth * 0.07,
                  ),
                ),
                SizedBox(width: contentWidth * 0.04),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GLOW',
                      style: TextStyle(
                        fontSize: contentWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Version 1.7',
                      style: TextStyle(
                        fontSize: contentWidth * 0.036,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinedBox({
    required double contentWidth,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(contentWidth * 0.045),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFB6D9)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildResearcherRow(String name, double contentWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: contentWidth * 0.045,
        vertical: contentWidth * 0.035,
      ),
      child: Row(
        children: [
          Container(
            width: contentWidth * 0.1,
            height: contentWidth * 0.1,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB6D9),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: contentWidth * 0.04),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: contentWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
