import 'package:flutter/material.dart';
import '../backend/recommendation_data.dart';
import '../page_11_and_12/makeup_tutorial_and_whattouse.dart';

// ─────────────────────────────────────────────────────────────
// Recommendation Explanation Screen — Page 10
//
// BACKEND TEAM — HOW TO CONNECT:
// This screen receives a single style Map from Page 9
// when the user taps on a recommended style card.
//
// Expected keys in `style` Map:
//   'name'        → String  e.g. 'Clean Girl Makeup'
//   'subtitle'    → String  e.g. 'Effortless, skin-first glow'
//   'description' → String  e.g. 'Glowing, hydrated skin...'
//   'imagePath'   → String  asset path e.g. 'assets/styles/clean_girl.jpg'
//                           (BACKEND: add this key to recommendations.json)
//
// HOW IMAGE WORKS:
// 1. Add images to assets/styles/ folder
// 2. Register them in pubspec.yaml under assets:
//      - assets/styles/
// 3. In recommendations.json, add 'imagePath' key per style:
//      { "name": "Clean Girl Makeup", "imagePath": "assets/styles/clean_girl.jpg", ... }
// 4. Pass imagePath through the style Map from Page 9
// ─────────────────────────────────────────────────────────────

class RecommendationResultScreen extends StatelessWidget {
  // Style data passed from analyzing_result.dart (Page 9)
  final Map<String, String> style;

  const RecommendationResultScreen({super.key, required this.style});

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
                  // Back button header
                  _buildHeader(context, contentWidth, screenHeight),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.06,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Style name
                        // BACKEND: 'name' from recommendations.json
                        Text(
                          style['name']!,
                          style: TextStyle(
                            fontSize: contentWidth * 0.09,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.1,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.005),

                        // Why this look was chosen subtitle
                        Text(
                          'Why this look was chosen for you',
                          style: TextStyle(
                            fontSize: contentWidth * 0.035,
                            color: Colors.grey,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Style subtitle in italics
                        // BACKEND: 'subtitle' from recommendations.json
                        Text(
                          '"${style['subtitle']!}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: contentWidth * 0.038,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFFF6EB4),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // ── STYLE IMAGE ──
                        // BACKEND: Pass 'imagePath' key in the style Map
                        // pointing to an asset or network image.
                        // Steps:
                        //   1. Add image files to assets/styles/ folder
                        //   2. Add - assets/styles/ in pubspec.yaml
                        //   3. Add 'imagePath' key in recommendations.json
                        //   4. Pass it through the style Map from Page 9
                        _buildStyleImage(
                          contentWidth: contentWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // ── DESCRIPTION BOX ──
                        // BACKEND: 'description' from recommendations.json
                        _buildDescriptionBox(
                          contentWidth: contentWidth,
                          screenHeight: screenHeight,
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Start Tutorial button
                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: ElevatedButton(
                           onPressed: () async {
                            final styleKey = style['styleKey'];
                            Map<String, dynamic> styleData;

                            if (styleKey != null) {
                              // Real per-style tutorial/product data,
                              // shades resolved to the user's detected
                              // undertone + Monk Scale.
                              styleData = await RecommendationData.buildStyleData(
                                styleKey: styleKey,
                                undertone: style['undertone'] ?? 'neutral',
                                monkScale:
                                    int.tryParse(style['monkScale'] ?? '') ?? 5,
                                styleIndex:
                                    int.tryParse(style['styleIndex'] ?? '') ?? 1,
                              );
                              // Carried through so the tutorial screen can
                              // save this exact result (styleKey/undertone/
                              // monkScale are what's needed to re-derive it
                              // later — see favorites.dart).
                              styleData = {
                                ...styleData,
                                'styleKey': styleKey,
                                'undertone': style['undertone'] ?? 'neutral',
                                'monkScale': style['monkScale'] ?? '5',
                                'matchPct': style['matchPct'],
                                'skinTone': style['skinTone'],
                                'faceShape': style['faceShape'],
                                'eyeShape': style['eyeShape'],
                              };
                            } else {
                              // No styleKey available (e.g. dummy fallback
                              // path) — fall back to just name/subtitle.
                              styleData = {
                                'name': style['name']!,
                                'subtitle': style['subtitle']!,
                                'styleIndex': style['styleIndex'] ?? '1',
                                'totalStyles': '3',
                              };
                            }

                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MakeupTutorialScreen(
                                  styleData: styleData,
                                ),
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
                              'Start Tutorial',
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

  // ── Style image widget ──
  // Shows asset image if 'imagePath' key exists in style Map,
  // otherwise shows a placeholder until backend provides images.
  Widget _buildStyleImage({
    required double contentWidth,
    required double screenHeight,
  }) {
    // BACKEND: Check if imagePath is provided in recommendations.json
    final imagePath = style['imagePath'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.3,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: imagePath != null && imagePath.isNotEmpty
            // BACKEND: Real image from assets/styles/ folder
            // Add images to assets/styles/ and register in pubspec.yaml
            ? Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Falls back to placeholder if image file not found
                  return _buildImagePlaceholder(contentWidth, screenHeight);
                },
              )
            // Placeholder shown until backend provides images
            : _buildImagePlaceholder(contentWidth, screenHeight),
      ),
    );
  }

  // Placeholder shown when no image is available yet
  Widget _buildImagePlaceholder(double contentWidth, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_rounded,
          size: contentWidth * 0.15,
          color: const Color(0xFFFFB6D9),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          'Style image coming soon',
          style: TextStyle(
            fontSize: contentWidth * 0.035,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          // Shows which image file to add
          style['name'] != null
              ? 'Add: assets/styles/${style['name']!.toLowerCase().replaceAll(' ', '_')}.jpg'
              : '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: contentWidth * 0.025,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  // Description box widget
  Widget _buildDescriptionBox({
    required double contentWidth,
    required double screenHeight,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Info icon
              Container(
                width: contentWidth * 0.08,
                height: contentWidth * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6EB4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: contentWidth * 0.045,
                ),
              ),
              SizedBox(width: contentWidth * 0.03),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: contentWidth * 0.042,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          // BACKEND: 'description' key from recommendations.json
          // This text explains why this style suits the user's features
          Text(
            style['description']!,
            style: TextStyle(
              fontSize: contentWidth * 0.035,
              color: Colors.black54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Header with back button
  Widget _buildHeader(
      BuildContext context, double contentWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: contentWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF0F6),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFFFF6EB4),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}