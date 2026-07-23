import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Recommendation Explanation Screen — Page 10
//
// BACKEND TEAM — HOW TO CONNECT:
// This screen receives a single style Map from Page 9
// when the user taps on a recommended style card.
//
// Expected keys in `style`:
//   'name'        → String  e.g. 'Clean Girl Makeup'
//   'subtitle'    → String  e.g. 'Effortless, skin-first glow'
//   'description' → String  e.g. 'Glowing, hydrated skin...'
//   'imageUrl'    → String  (BACKEND: URL or asset path for style image)
// ─────────────────────────────────────────────────────────────

class RecommendationResultScreen extends StatelessWidget {
  // Style data passed from analyzing_result.dart
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
                  // Back button + title header
                  _buildHeader(context, contentWidth, screenHeight),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Style name
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

                        // Why this look was chosen
                        Text(
                          'Why this look was chosen for you',
                          style: TextStyle(
                            fontSize: contentWidth * 0.035,
                            color: Colors.grey,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Subtitle in italics
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
                        // BACKEND: Replace this placeholder with a real
                        // image from recommendations.json or assets folder
                        Container(
                          width: double.infinity,
                          height: screenHeight * 0.3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_rounded,
                                size: contentWidth * 0.15,
                                color: const Color(0xFFFFB6D9),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Picture',
                                style: TextStyle(
                                  fontSize: contentWidth * 0.04,
                                  color: Colors.grey,
                                ),
                              ),
                              // BACKEND: Uncomment when image is available
                              // Image.network(style['imageUrl']!)
                              // OR
                              // Image.asset('assets/styles/${style['name']}.jpg')
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // ── DESCRIPTION BOX ──
                        // BACKEND: Description comes from recommendations.json
                        Container(
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
                              // BACKEND: description from recommendations.json
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
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Start Tutorial button
                        // TODO: Navigate to Step-by-Step Tutorial (Page 13)
                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to Tutorial Screen (Page 13)
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
          // Back button
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