import 'package:flutter/material.dart';
import 'retakephoto.dart';
import '../page_10_recommendation_explanation/recommendation_result.dart';
import '../widgets/analysis_card.dart';

// ─────────────────────────────────────────────────────────────
// Beauty Profile / Facial Analysis Results Screen — Page 9
//
// BACKEND TEAM — HOW TO CONNECT:
// This screen receives a Map<String, dynamic> called `analysisResults`
// from the AI Processing Screen (Page 8).
//
// Expected keys in analysisResults:
//   'skinTone'           → String  e.g. 'warm' / 'cool' / 'neutral'
//   'faceShape'          → String  e.g. 'Oval'
//   'eyeShape'            → String  e.g. 'almond'
//   'undertone'           → String  same value as skinTone (see note below)
//   'monkScale'          → int     1-10, shown alongside undertone
//   'recommendedStyles'  → List<Map<String, String>>
//     [
//       {
//         'name': 'Clean Girl Makeup',
//         'subtitle': 'Effortless, skin-first glow',
//         'description': 'Glowing, hydrated skin...',
//       },
//     ]
//
// NOTE on undertone vs skinTone: the detector pipeline (see main.py)
// treats these as the same underlying category — there's no separate,
// richer "undertone" value like "Golden Warm" produced anywhere upstream.
// The Undertone card here shows that same category plus Monk Scale
// instead, since that's the real numeric detail the pipeline provides.
// ─────────────────────────────────────────────────────────────

class AnalyzingResultScreen extends StatelessWidget {
  // BACKEND TEAM: Pass real results from Page 8 here
  final Map<String, dynamic>? analysisResults;

  const AnalyzingResultScreen({super.key, this.analysisResults});

  // ── DUMMY DATA — Replace with real backend results ──

  // BACKEND: Get this from skin_tone_detector.py → undertone classification
  String get _skinTone => analysisResults?['skinTone'] ?? 'Warm Medium';

  // BACKEND: Get this from face_shape_model.tflite → shape classification
  String get _faceShape => analysisResults?['faceShape'] ?? 'Oval';

  // BACKEND: Get this from eye_shape_detector.py → eye shape classification
  String get _eyeShape => analysisResults?['eyeShape'] ?? 'Almond';

  // BACKEND: Same category as skinTone (see note at top of file) — the
  // pipeline has no separate "undertone" concept, so this mirrors it.
  String get _undertone => analysisResults?['undertone'] ??
      analysisResults?['skinTone'] ??
      'Golden Warm';

  // BACKEND: Get this from skin_tone_detector.py → Monk Scale (1-10)
  int? get _monkScale => analysisResults?['monkScale'] as int?;

  // BACKEND: Get top 3 styles from style_scorer.py based on face+skin results
  List<Map<String, String>> get _recommendedStyles =>
      (analysisResults?['recommendedStyles'] as List<Map<String, String>>?) ??
      [
        {
          'name': 'Clean Girl Makeup',
          'subtitle': 'Effortless, skin-first glow',
          'description':
              'Glowing, hydrated skin, groomed brows, and a subtle flush. '
                  'Glass skin meets fluffy brows and a juicy dewy pout.',
        },
        {
          'name': 'Peach Makeup',
          'subtitle': 'Warm, sun-kissed, peachy-sweet',
          'description':
              'Monochromatic warm look tying eyes, cheeks, and lips in peach, '
                  'coral, and golden copper — a cohesive sun-kissed flush.',
        },
        {
          'name': 'Soft Glam Everyday',
          'subtitle': 'Polished, wearable glam',
          'description':
              'Subtle smoky eye in warm neutrals, sculpted cheeks, defined '
                  'lashes, and a satin lip. Elevated but never overdressed.',
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
                  // Pink header
                  _buildHeader(contentWidth, screenHeight),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.05,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── FACE ANALYSIS SECTION ──
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

                        // All 4 cards in a single row, sized down to fit.
                        Row(
                          children: [
                            // BACKEND: skinTone from skin_tone_detector.py
                            // (Monk Scale shown here since it's a direct
                            // output of the same skin tone analysis step)
                            Expanded(
                              child: AnalysisCard(
                                label: 'SKIN TONE',
                                value: _monkScale != null
                                    ? '${titleCase(_skinTone)}\nM$_monkScale'
                                    : titleCase(_skinTone),
                                color: monkScaleColor(_monkScale),
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),

                            // BACKEND: faceShape from face_shape_model.tflite
                            Expanded(
                              child: AnalysisCard(
                                label: 'FACE SHAPE',
                                value: titleCase(_faceShape),
                                color: const Color(0xFFFFB6D9),
                                icon: Icons.face_rounded,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),

                            // BACKEND: eyeShape from eye_shape_detector.py
                            Expanded(
                              child: AnalysisCard(
                                label: 'EYE SHAPE',
                                value: titleCase(_eyeShape),
                                color: const Color(0xFFB6D9FF),
                                icon: Icons.remove_red_eye_rounded,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),

                            // BACKEND: undertone — same category as
                            // skinTone (see note at top of file).
                            Expanded(
                              child: AnalysisCard(
                                label: 'UNDERTONE',
                                value: titleCase(_undertone),
                                color: const Color(0xFFE8A855),
                                contentWidth: contentWidth,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // ── RECOMMENDED STYLES SECTION ──
                        Text(
                          'RECOMMENDED STYLES',
                          style: TextStyle(
                            fontSize: contentWidth * 0.032,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6EB4),
                            letterSpacing: 1.5,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // BACKEND: Replace dummy styles with top 3 results
                        // from style_scorer.py based on user's features
                        ..._recommendedStyles.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                                bottom: screenHeight * 0.015),
                            child: _buildStyleCard(
                              style: entry.value,
                              rank: entry.key + 1,
                              contentWidth: contentWidth,
                              screenHeight: screenHeight,
                              context: context,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Retake Scan button — shows confirmation dialog
                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: OutlinedButton(
                            onPressed: () async {
                              // Show retake confirmation dialog
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) =>
                                    const RetakeScanDialog(),
                              );

                              // If user confirmed, go back to the camera
                              // to retake the photo (skips Home/Scan Prep)
                              if (confirm == true && context.mounted) {
                                Navigator.popUntil(
                                  context,
                                  (route) => route.settings.name == '/camera',
                                );
                              }
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
                              'Retake Scan',
                              style: TextStyle(
                                fontSize: contentWidth * 0.045,
                                color: const Color(0xFFFF6EB4),
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

  // Pink header
  Widget _buildHeader(double contentWidth, double screenHeight) {
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
          Text(
            'ANALYSIS COMPLETE',
            style: TextStyle(
              fontSize: contentWidth * 0.03,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            'Beauty Profile',
            style: TextStyle(
              fontSize: contentWidth * 0.11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // Recommended style card
  Widget _buildStyleCard({
    required Map<String, String> style,
    required int rank,
    required double contentWidth,
    required double screenHeight,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to Recommendation Explanation Screen (Page 10),
        // carrying along what's needed to resolve real tutorial/product
        // data later: which style (styleKey), its rank among the top 3,
        // and the detected undertone + Monk Scale for shade matching.
        final styleWithContext = {
          ...style,
          'styleIndex': '$rank',
          'undertone': _undertone,
          'monkScale': '${_monkScale ?? 5}',
          'skinTone': _skinTone,
          'faceShape': _faceShape,
          'eyeShape': _eyeShape,
        };
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecommendationResultScreen(style: styleWithContext),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Style icon
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
                    // BACKEND: style name from style_scorer.py, plus a
                    // match % badge (style_scorer.dart's matchPct) when
                    // available — not present on the dummy fallback data.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            style['name']!,
                            style: TextStyle(
                              fontSize: contentWidth * 0.042,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (style['matchPct'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: contentWidth * 0.02,
                              vertical: contentWidth * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${style['matchPct']}% match',
                              style: TextStyle(
                                fontSize: contentWidth * 0.028,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF6EB4),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // BACKEND: style subtitle from recommendations.json
                    Text(
                      style['subtitle']!,
                      style: TextStyle(
                        fontSize: contentWidth * 0.032,
                        color: const Color(0xFFFF6EB4),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow — navigates to Page 10 (whole card is tappable)
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          // BACKEND: style description from recommendations.json
          Text(
            style['description']!,
            style: TextStyle(
              fontSize: contentWidth * 0.033,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
      ),
    );
  }
}