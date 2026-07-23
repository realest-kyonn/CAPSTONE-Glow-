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
//   'skinTone'           → String  e.g. 'warm' / 'cool' / 'neutral'
//   'faceShape'          → String  e.g. 'Oval'
//   'eyeShape'            → String  e.g. 'almond'
//   'undertone'           → String  same value as skinTone (see note below)
//   'monkScale'          → int     1-10, shown alongside undertone
//   'aiInsight'          → String  e.g. 'Your oval face...'
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

  // Official Monk Skin Tone Scale reference colors (M1 lightest -> M10
  // deepest). Index 0 = Monk 01, so use (monkScale - 1) to look up.
  static const List<Color> _monkScaleColors = [
    Color(0xFFF6EDE4), // Monk 01
    Color(0xFFF3E7DB), // Monk 02
    Color(0xFFF7EAD0), // Monk 03
    Color(0xFFEADABA), // Monk 04
    Color(0xFFD7BD96), // Monk 05
    Color(0xFFA07E56), // Monk 06
    Color(0xFF825C43), // Monk 07
    Color(0xFF604134), // Monk 08
    Color(0xFF3A312A), // Monk 09
    Color(0xFF292420), // Monk 10
  ];

  // Returns the real Monk Scale color for the detected value, falling
  // back to a mid-tone default only if no monkScale was provided.
  Color get _skinToneColor {
    final scale = _monkScale;
    if (scale != null && scale >= 1 && scale <= 10) {
      return _monkScaleColors[scale - 1];
    }
    return const Color(0xFFD4956A);
  }

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

  // Capitalizes the first letter — detector values come lowercase
  // ("warm", "almond") but display should read "Warm", "Almond".
  String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

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

                        // All 4 cards in a single row, sized down to fit.
                        Row(
                          children: [
                            // BACKEND: skinTone from skin_tone_detector.py
                            // (Monk Scale shown here since it's a direct
                            // output of the same skin tone analysis step)
                            Expanded(
                              child: _buildAnalysisCard(
                                label: 'SKIN TONE',
                                value: _monkScale != null
                                    ? '${_titleCase(_skinTone)}\nM$_monkScale'
                                    : _titleCase(_skinTone),
                                color: _skinToneColor,
                                isCircle: false,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),

                            // BACKEND: faceShape from face_shape_model.tflite
                            Expanded(
                              child: _buildAnalysisCard(
                                label: 'FACE SHAPE',
                                value: _titleCase(_faceShape),
                                color: const Color(0xFFFFB6D9),
                                icon: Icons.face_rounded,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),

                            // BACKEND: eyeShape from eye_shape_detector.py
                            Expanded(
                              child: _buildAnalysisCard(
                                label: 'EYE SHAPE',
                                value: _titleCase(_eyeShape),
                                color: const Color(0xFFB6D9FF),
                                icon: Icons.remove_red_eye_rounded,
                                contentWidth: contentWidth,
                              ),
                            ),
                            SizedBox(width: contentWidth * 0.02),

                            // BACKEND: undertone — same category as
                            // skinTone (see note at top of file).
                            Expanded(
                              child: _buildAnalysisCard(
                                label: 'UNDERTONE',
                                value: _titleCase(_undertone),
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

  // Analysis card — skin tone, face shape, eye shape, undertone.
  // Pass `icon` for shape-based cards (renders the icon on a tinted
  // circle background); leave it null for color-based cards (renders
  // a solid color swatch instead) — color represents the actual
  // detected value there, so a generic icon would be misleading.
  Widget _buildAnalysisCard({
    required String label,
    required String value,
    required Color color,
    bool isCircle = false,
    IconData? icon,
    required double contentWidth,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: contentWidth * 0.015,
        vertical: contentWidth * 0.025,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Icon (shape cards) or solid swatch (color cards)
          Container(
            width: contentWidth * 0.11,
            height: contentWidth * 0.11,
            decoration: BoxDecoration(
              color: icon != null ? color.withValues(alpha: 0.25) : color,
              shape: (icon != null || isCircle)
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              borderRadius:
                  (icon != null || isCircle) ? null : BorderRadius.circular(8),
            ),
            child: icon != null
                ? Icon(icon, color: color, size: contentWidth * 0.06)
                : null,
          ),
          SizedBox(height: contentWidth * 0.02),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.02,
              color: Colors.grey,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: contentWidth * 0.008),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: contentWidth * 0.028,
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