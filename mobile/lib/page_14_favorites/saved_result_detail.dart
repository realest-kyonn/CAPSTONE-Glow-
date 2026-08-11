import 'package:flutter/material.dart';
import '../backend/recommendation_data.dart';
import '../page_11_and_12/makeup_tutorial_and_whattouse.dart';
import '../widgets/analysis_card.dart';
import 'favorites.dart';

// ─────────────────────────────────────────────────────────────
// Saved Result Detail Screen — Page 15 (revisit)
// Shows the facial analysis snapshot captured when this look was
// saved. Tapping the chosen style opens the full tutorial, rebuilt
// live from styleKey via RecommendationData — no tutorial content
// is duplicated in the saved record itself.
// ─────────────────────────────────────────────────────────────

class SavedResultDetailScreen extends StatelessWidget {
  final SavedResult result;

  const SavedResultDetailScreen({super.key, required this.result});

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
                      horizontal: contentWidth * 0.05,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FACE ANALYSIS',
                          style: TextStyle(
                            fontSize: contentWidth * 0.032,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6EB4),
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Row(
                          children: [
                            Expanded(
                              child: AnalysisCard(
                                label: 'SKIN TONE',
                                value: '${titleCase(result.skinTone)}\n'
                                    'M${result.monkScale}',
                                color: monkScaleColor(result.monkScale),
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),
                            Expanded(
                              child: AnalysisCard(
                                label: 'FACE SHAPE',
                                value: titleCase(result.faceShape),
                                color: const Color(0xFFFFB6D9),
                                icon: Icons.face_rounded,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),
                            Expanded(
                              child: AnalysisCard(
                                label: 'EYE SHAPE',
                                value: titleCase(result.eyeShape),
                                color: const Color(0xFFB6D9FF),
                                icon: Icons.remove_red_eye_rounded,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),
                            Expanded(
                              child: AnalysisCard(
                                label: 'UNDERTONE',
                                value: titleCase(result.undertone),
                                color: const Color(0xFFE8A855),
                                contentWidth: contentWidth,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        Text(
                          'CHOSEN STYLE',
                          style: TextStyle(
                            fontSize: contentWidth * 0.032,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6EB4),
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        _buildStyleCard(context, contentWidth),
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
            'SAVED LOOK',
            style: TextStyle(
              fontSize: contentWidth * 0.03,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            result.savedName,
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

  // Tapping this — the arrow through to the tutorial.
  Widget _buildStyleCard(BuildContext context, double contentWidth) {
    return GestureDetector(
      onTap: () => _openTutorial(context),
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
              width: contentWidth * 0.1,
              height: contentWidth * 0.1,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFFFF6EB4),
                size: contentWidth * 0.055,
              ),
            ),
            SizedBox(width: contentWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.styleName,
                    style: TextStyle(
                      fontSize: contentWidth * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (result.matchPct != null)
                    Text(
                      '${result.matchPct}% match',
                      style: TextStyle(
                        fontSize: contentWidth * 0.032,
                        color: const Color(0xFFFF6EB4),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: contentWidth * 0.09,
              height: contentWidth * 0.09,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6EB4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTutorial(BuildContext context) async {
    final styleData = await RecommendationData.buildStyleData(
      styleKey: result.styleKey,
      undertone: result.undertone,
      monkScale: result.monkScale,
      styleIndex: result.styleIndex,
    );
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeupTutorialScreen(styleData: styleData),
      ),
    );
  }
}
