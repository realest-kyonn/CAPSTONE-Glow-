import 'package:flutter/material.dart';
import 'skin_quiz_data.dart';
import 'skin_type_result_screen.dart';

// ─────────────────────────────────────────────────────────────
// Skin Type Quiz — Step 2: the question
// One prompt, four descriptions to choose from. Tapping an option IS
// the answer — it goes straight to that skin type's result.
// ─────────────────────────────────────────────────────────────

class SkinTypeQuestionScreen extends StatelessWidget {
  const SkinTypeQuestionScreen({super.key});

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
                          'What does your skin feel like right now?',
                          style: TextStyle(
                            fontSize: contentWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          'Pick the description that matches best.',
                          style: TextStyle(
                            fontSize: contentWidth * 0.036,
                            color: Colors.grey,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        ...skinTypes.values.map((type) => Padding(
                              padding: EdgeInsets.only(
                                  bottom: screenHeight * 0.015),
                              child: _buildOptionCard(
                                context: context,
                                type: type,
                                contentWidth: contentWidth,
                              ),
                            )),

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
            'One Question',
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

  Widget _buildOptionCard({
    required BuildContext context,
    required SkinTypeInfo type,
    required double contentWidth,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SkinTypeResultScreen(skinTypeKey: type.key),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(contentWidth * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: contentWidth * 0.11,
              height: contentWidth * 0.11,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type.icon,
                color: const Color(0xFFFF6EB4),
                size: contentWidth * 0.06,
              ),
            ),
            SizedBox(width: contentWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: TextStyle(
                      fontSize: contentWidth * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: contentWidth * 0.006),
                  Text(
                    type.feelDescription,
                    style: TextStyle(
                      fontSize: contentWidth * 0.034,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: contentWidth * 0.02),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFFF6EB4),
              size: contentWidth * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}
