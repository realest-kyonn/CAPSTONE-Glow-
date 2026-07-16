import 'package:flutter/material.dart';
import 'dart:math';

// ─────────────────────────────────────────────────────────────
// AI Processing Screen — Page 8
// This screen shows while the backend analyzes the captured photo.
//
// BACKEND TEAM — HOW TO CONNECT:
// 1. This screen receives the imagePath from ImageValidationScreen
// 2. Call your analysis functions here inside _startAnalysis()
// 3. Each step (skin tone, facial features, recommendations) should
//    update _currentStep and _overallProgress as it completes
// 4. When all steps are done, navigate to analyzing_result.dart (Page 9)
//    and pass the results as parameters
// ─────────────────────────────────────────────────────────────

class FaceAnalyzingScreen extends StatefulWidget {
  // Image path passed from Image Validation Screen
  final String imagePath;

  const FaceAnalyzingScreen({super.key, required this.imagePath});

  @override
  State<FaceAnalyzingScreen> createState() => _FaceAnalyzingScreenState();
}

class _FaceAnalyzingScreenState extends State<FaceAnalyzingScreen>
    with TickerProviderStateMixin {
  // Animation controller for the spinning sun icon
  late AnimationController _spinController;

  // Animation controller for the pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Current step being processed (0, 1, 2)
  int _currentStep = 0;

  // Overall progress value (0.0 to 1.0)
  double _overallProgress = 0.0;

  // Step progress values (0.0 to 1.0 each)
  final List<double> _stepProgress = [0.0, 0.0, 0.0];

  // Step labels shown on screen
  final List<String> _stepLabels = [
    'Detecting Skin Tone',
    'Analyzing Facial Features',
    'Generating Recommendations',
  ];

  // Step icons
  final List<IconData> _stepIcons = [
    Icons.color_lens_rounded,
    Icons.face_rounded,
    Icons.auto_awesome_rounded,
  ];

  @override
  void initState() {
    super.initState();

    // Spin animation — continuous rotation for the sun icon
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Pulse animation — subtle scale in/out for the circle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start the simulated analysis
    _startAnalysis();
  }

  // ─────────────────────────────────────────────────────────────
  // BACKEND TEAM — Replace this simulated analysis with real calls
  // Each step should:
  //   1. Call the relevant backend function (skin tone, face shape, etc.)
  //   2. Update _stepProgress[stepIndex] from 0.0 to 1.0 as it processes
  //   3. Update _overallProgress accordingly
  //   4. When all done, call _onAnalysisComplete(results)
  // ─────────────────────────────────────────────────────────────
  Future<void> _startAnalysis() async {
    // SIMULATED: Step 1 — Detecting Skin Tone
    await _simulateStep(0);

    // SIMULATED: Step 2 — Analyzing Facial Features
    await _simulateStep(1);

    // SIMULATED: Step 3 — Generating Recommendations
    await _simulateStep(2);

    // All steps done — navigate to results
    _onAnalysisComplete();
  }

  // Simulates a single step progressing from 0 to 100%
  Future<void> _simulateStep(int stepIndex) async {
    setState(() => _currentStep = stepIndex);

    for (int i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        setState(() {
          _stepProgress[stepIndex] = i / 20;
          // Overall progress = average of all step progresses
          _overallProgress =
              _stepProgress.reduce((a, b) => a + b) / _stepProgress.length;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BACKEND TEAM — Call this when real analysis is complete
  // Pass your actual results here instead of dummy data
  // ─────────────────────────────────────────────────────────────
  void _onAnalysisComplete() {
    if (!mounted) return;

    // TODO: Replace dummy data with real backend results
    // Example of what to pass:
    // final results = {
    //   'skinTone': 'Warm Medium',        // from skin_tone_detector.py
    //   'faceShape': 'Oval',              // from face_shape_model.tflite
    //   'undertone': 'Golden Warm',       // from skin_tone_detector.py
    //   'recommendedStyles': [...],       // from style_scorer.py
    // };

    // Navigate to Results Screen (Page 9)
    // TODO: Uncomment and pass real results when backend is ready
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => AnalyzingResultScreen(results: results),
    //   ),
    // );

    // TEMP: Show a snackbar for now until Page 9 is connected
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analysis complete! Page 9 coming soon.'),
        backgroundColor: Color(0xFFFF6EB4),
      ),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: contentWidth * 0.06),
              child: Column(
                children: [
                  // Pink header
                  _buildHeader(contentWidth, screenHeight),

                  SizedBox(height: screenHeight * 0.04),

                  // Spinning sun illustration
                  _buildSpinningIcon(contentWidth),

                  SizedBox(height: screenHeight * 0.015),

                  // Subtitle
                  Text(
                    'We\'re reading your unique skin tone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: contentWidth * 0.034,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Step progress list
                  ..._stepLabels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final label = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                      child: _buildStepItem(
                        index: index,
                        label: label,
                        icon: _stepIcons[index],
                        progress: _stepProgress[index],
                        isActive: _currentStep == index,
                        isDone: _stepProgress[index] >= 1.0,
                        contentWidth: contentWidth,
                      ),
                    );
                  }),

                  const Spacer(),

                  // Overall progress bar
                  _buildOverallProgress(contentWidth, screenHeight),

                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Pink header section
  Widget _buildHeader(double contentWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: screenHeight * 0.02),
      padding: EdgeInsets.all(contentWidth * 0.06),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6EB4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLEASE WAIT',
            style: TextStyle(
              fontSize: contentWidth * 0.03,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            'Analyzing Your\nFace',
            style: TextStyle(
              fontSize: contentWidth * 0.1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // Spinning + pulsing sun icon
  Widget _buildSpinningIcon(double contentWidth) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: contentWidth * 0.38,
            height: contentWidth * 0.38,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE4F0),
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: _spinController.value * 2 * pi,
              child: Icon(
                Icons.wb_sunny_rounded,
                size: contentWidth * 0.22,
                color: const Color(0xFFFF6EB4),
              ),
            ),
          ),
        );
      },
    );
  }

  // Individual step progress item
  Widget _buildStepItem({
    required int index,
    required String label,
    required IconData icon,
    required double progress,
    required bool isActive,
    required bool isDone,
    required double contentWidth,
  }) {
    return Row(
      children: [
        // Step icon circle
        Container(
          width: contentWidth * 0.1,
          height: contentWidth * 0.1,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFFFF6EB4)
                : isActive
                    ? const Color(0xFFFFE4F0)
                    : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            color: isDone
                ? Colors.white
                : isActive
                    ? const Color(0xFFFF6EB4)
                    : Colors.grey,
            size: contentWidth * 0.055,
          ),
        ),

        SizedBox(width: contentWidth * 0.03),

        // Label and progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: contentWidth * 0.038,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black87 : Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFF6EB4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Overall progress bar at the bottom
  Widget _buildOverallProgress(double contentWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Progress',
          style: TextStyle(
            fontSize: contentWidth * 0.038,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _overallProgress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0F0F0),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFFF6EB4),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        Text(
          'This will only take a moment',
          style: TextStyle(
            fontSize: contentWidth * 0.03,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}