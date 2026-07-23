import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:image/image.dart' as img;
import '../backend/mesh_provider.dart';
import '../backend/face_shape_detector.dart';
import '../backend/eye_shape_detector.dart' as eyes;
import '../backend/skin_tone_detector.dart';
import '../backend/style_scorer.dart';
import '../page_9_analyzing_result/analyzing_result.dart';

// ─────────────────────────────────────────────────────────────
// AI Processing Screen — Page 8
// Runs the real detector pipeline (mesh -> face shape -> eye shape,
// plus skin tone) on the captured photo while showing progress.
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

    // Kick off the real detector pipeline
    _startAnalysis();
  }

  // ─────────────────────────────────────────────────────────────
  // Real analysis pipeline: skin tone -> mesh/landmarks -> face shape
  // -> eye shape. Recommendation scoring (style_scorer.py /
  // recommendations.py) has no Dart port yet, so Step 3 is a
  // placeholder — wire it in once that port exists.
  // ─────────────────────────────────────────────────────────────
  Future<void> _startAnalysis() async {
    try {
      // Step 1 — Skin Tone (undertone + Monk Scale)
      setState(() => _currentStep = 0);
      final skinResult = detectSkinTone(widget.imagePath);
      _completeStep(0);

      // Step 2 — Facial Features: mesh/bounding box -> face shape -> eye shape
      setState(() => _currentStep = 1);
      final meshProvider = await MeshProvider.load();
      final meshResult = await meshProvider.analyzePhoto(widget.imagePath);

      // DIAGNOSTIC — checking whether mesh/face detection is silently
      // failing on real captured photos (would explain identical results
      // across different people via fallback paths in both detectors).
      debugPrint('=== MESH DETECTION CHECK ===');
      debugPrint('  hasFace: ${meshResult.hasFace}');
      debugPrint('  boundingBox: ${meshResult.boundingBox}');
      debugPrint('  meshLandmarks count: ${meshResult.meshLandmarks.length}');
      debugPrint('  mesh error: ${meshResult.error}');

      FaceShapeResult? faceResult;
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final faceShapeDetector = await FaceShapeDetector.load();
        faceResult = faceShapeDetector.detectFaceShape(
          decoded,
          box: meshResult.boundingBox,
        );
        faceShapeDetector.dispose();
      }

      final eyeResult = eyes.detectEyeShape(meshResult.meshLandmarks);
      meshProvider.dispose();
      _completeStep(1);

      // Step 3 — Recommendations: score all 15 styles against the
      // detected features, take the top 3.
      setState(() => _currentStep = 2);
      final topStyles = scoreStyles(
        undertone: skinResult.skinTone ?? 'neutral',
        faceShape: faceResult?.faceShape ?? 'Oval',
        eyeShape: eyeResult.eyeShape,
      );
      _completeStep(2);

      final Map<String, dynamic> analysisResults = {
        'skinTone': skinResult.skinTone,
        // Python's own main.py treats undertone as the same value as
        // skin_tone (undertone = skin_result["skin_tone"]) — there's no
        // separate "undertone" concept in the detector, so we mirror that
        // here rather than inventing a value that doesn't exist upstream.
        'undertone': skinResult.skinTone,
        'monkScale': skinResult.monkScale,
        'skinConfidence': skinResult.confidence,
        'faceShape': faceResult?.faceShape,
        'faceConfidence': faceResult?.confidence,
        'eyeShape': eyeResult.eyeShape,
        'eyeConfidence': eyeResult.confidence,
        // Mapped to the {'name', 'subtitle', 'description'} shape
        // analyzing_result.dart's _recommendedStyles getter expects.
        // NOTE: style_scorer.dart has no "subtitle" field of its own —
        // reusing `description` for both is a placeholder; a real
        // subtitle (short tagline distinct from the full description)
        // would need to come from recommendations.json once that's
        // ported too.
        'recommendedStyles': topStyles
            .map((s) => {
                  'name': s.styleName,
                  'subtitle': s.description,
                  'description': s.description,
                  'matchPct': s.matchPct.toString(),
                })
            .toList(),
      };

      // TEMPORARY — remove once Page 9 actually displays these values.
      debugPrint('=== LIVE CAMERA ANALYSIS RESULT ===');
      debugPrint('  skinTone: ${skinResult.skinTone}');
      debugPrint('  monkScale: ${skinResult.monkScale}');
      debugPrint('  top styles: ${topStyles.map((s) => '${s.styleName} (${s.matchPct}%)').join(', ')}');
      debugPrint('  faceShape: ${faceResult?.faceShape}  error: ${faceResult?.error}');
      debugPrint('  faceShape allScores: ${faceResult?.allScores}');
      debugPrint('  eyeShape: ${eyeResult.eyeShape}  error: ${eyeResult.error}');
      debugPrint('  eyeShape metrics: ${eyeResult.metrics}');

      _onAnalysisComplete(analysisResults);
    } catch (e) {
      debugPrint('Analysis pipeline error: $e');
      _onAnalysisComplete({'error': e.toString()});
    }
  }

  // Marks one step's progress bar complete and updates the overall bar.
  void _completeStep(int stepIndex) {
    if (!mounted) return;
    setState(() {
      _stepProgress[stepIndex] = 1.0;
      _overallProgress =
          _stepProgress.reduce((a, b) => a + b) / _stepProgress.length;
    });
  }

  // Navigates to Page 9 with the real analysis results.
  //
  // NOTE: AnalyzingResultScreen's actual constructor wasn't available when
  // this was wired up — confirm it accepts `analysisResults` as shown below
  // and adjust if its real signature differs.
  void _onAnalysisComplete(Map<String, dynamic> analysisResults) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyzingResultScreen(
          analysisResults: analysisResults,
        ),
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
              color: Colors.white.withValues(alpha: 0.85),
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