import 'package:flutter/material.dart';
import 'retakephoto.dart';

// ─────────────────────────────────────────────────────────────
// Beauty Profile / Facial Analysis Results Screen — Page 9
//
// BACKEND TEAM — HOW TO CONNECT:
// This screen receives a Map<String, dynamic> called `analysisResults`
// from the AI Processing Screen (Page 8).
//
// Expected keys in analysisResults:
//   'skinTone'           → String  e.g. 'Warm Medium'
//   'faceShape'          → String  e.g. 'Oval'
//   'undertone'          → String  e.g. 'Golden Warm'
//   'aiInsight'          → String  e.g. 'Your oval face...'
//   'recommendedStyles'  → List<Map<String, String>>
//     [
//       {
//         'name': 'Clean Girl Makeup',
//         'subtitle': 'Effortless, skin-first glow',
//         'description': 'Glowing, hydrated skin...',
//       },
//     ]
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

  // BACKEND: Get this from skin_tone_detector.py → Monk Scale + undertone
  String get _undertone => analysisResults?['undertone'] ?? 'Golden Warm';

  // BACKEND: Generate this insight text by combining all 3 results
  String get _aiInsight =>
      analysisResults?['aiInsight'] ??
      'Your oval face and golden warm undertone suit peach, copper, and coral '
          'palettes beautifully. Focus on dewy skin and warm-toned products to '
          'bring out your natural radiance.';

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
        child: Center(
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

                        // 3 result cards
                        Row(
                          children: [
                            // BACKEND: skinTone from skin_tone_detector.py
                            Expanded(
                              child: _buildAnalysisCard(
                                label: 'SKIN TONE',
                                value: _skinTone,
                                color: const Color(0xFFD4956A),
                                isCircle: false,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.03),

                            // BACKEND: faceShape from face_shape_model.tflite
                            Expanded(
                              child: _buildAnalysisCard(
                                label: 'FACE SHAPE',
                                value: _faceShape,
                                color: const Color(0xFFFFB6D9),
                                isCircle: true,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.03),

                            // BACKEND: undertone from skin_tone_detector.py
                            Expanded(
                              child: _buildAnalysisCard(
                                label: 'UNDERTONE',
                                value: _undertone,
                                color: const Color(0xFFE8A855),
                                isCircle: false,
                                contentWidth: contentWidth,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // ── AI INSIGHT BOX ──
                        // BACKEND: Generate this text by combining
                        // skinTone + faceShape + undertone results
                        _buildInsightBox(contentWidth, screenHeight),

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
                        ..._recommendedStyles.map(
                          (style) => Padding(
                            padding: EdgeInsets.only(
                                bottom: screenHeight * 0.015),
                            child: _buildStyleCard(
                              style: style,
                              contentWidth: contentWidth,
                              screenHeight: screenHeight,
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

                              // If user confirmed, go back to home
                              if (confirm == true && context.mounted) {
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
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
              color: Colors.white.withOpacity(0.85),
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

  // Analysis card — skin tone, face shape, undertone
  Widget _buildAnalysisCard({
    required String label,
    required String value,
    required Color color,
    required bool isCircle,
    required double contentWidth,
  }) {
    return Container(
      padding: EdgeInsets.all(contentWidth * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Color swatch
          Container(
            width: contentWidth * 0.12,
            height: contentWidth * 0.12,
            decoration: BoxDecoration(
              color: color,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(8),
            ),
          ),
          SizedBox(height: contentWidth * 0.02),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.025,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: contentWidth * 0.01),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.035,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // AI Insight box
  Widget _buildInsightBox(double contentWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI INSIGHT',
            style: TextStyle(
              fontSize: contentWidth * 0.028,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          // BACKEND: Replace with generated insight text
          Text(
            _aiInsight,
            style: TextStyle(
              fontSize: contentWidth * 0.036,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Recommended style card
  Widget _buildStyleCard({
    required Map<String, String> style,
    required double contentWidth,
    required double screenHeight,
  }) {
    return Container(
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
                    // BACKEND: style name from style_scorer.py
                    Text(
                      style['name']!,
                      style: TextStyle(
                        fontSize: contentWidth * 0.042,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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
              // Arrow — TODO: navigate to style detail page
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
    );
  }
}