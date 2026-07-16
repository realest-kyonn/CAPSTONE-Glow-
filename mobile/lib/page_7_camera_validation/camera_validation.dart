import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../page_8_face_analyzing/face_analyzing.dart';

// Image Validation Screen — Page 7
class ImageValidationScreen extends StatefulWidget {
  // The captured photo path passed in from the Camera Screen
  final String imagePath;

  // Real-time results from the Camera Screen
  final bool brightnessOk;
  final bool faceDetected;
  final bool distanceOk;
  final bool blurOk;

  const ImageValidationScreen({
    super.key,
    required this.imagePath,
    required this.brightnessOk,
    required this.faceDetected,
    required this.distanceOk,
    required this.blurOk,
  });

  @override
  State<ImageValidationScreen> createState() => _ImageValidationScreenState();
}

class _ImageValidationScreenState extends State<ImageValidationScreen> {
  bool _blurCheckPassed = false;
  bool _brightnessCheckPassed = false;
  late bool _faceVisibilityPassed;
  bool _isAnalyzing = true;

  // Calibration thresholds
  static const double _blurThreshold = 25.0;
  static const double _minBrightness = 60.0;
  static const double _maxBrightness = 220.0;

  bool get _allChecksPassed =>
      _blurCheckPassed && _brightnessCheckPassed && _faceVisibilityPassed;

  @override
  void initState() {
    super.initState();
    // Face visibility = face detected AND at the right distance
    _faceVisibilityPassed = widget.faceDetected && widget.distanceOk;
    _analyzePhoto();
  }

  // Decodes the real captured photo and runs accurate blur + brightness checks
  Future<void> _analyzePhoto() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        if (mounted) {
          setState(() {
            _blurCheckPassed = false;
            _brightnessCheckPassed = false;
            _isAnalyzing = false;
          });
        }
        return;
      }

      // Downsize for fast, consistent analysis
      final resized = img.copyResize(decoded, width: 300);
      final grayscale = img.grayscale(resized);

      final brightness = _calculateBrightness(grayscale);
      final blurScore = _calculateBlurScore(grayscale);

      // Uncomment while calibrating on your device:
      // debugPrint('Real photo — brightness: $brightness, blur: $blurScore');

      final brightnessOk =
          brightness >= _minBrightness && brightness <= _maxBrightness;
      final blurOk = blurScore >= _blurThreshold;

      if (mounted) {
        setState(() {
          _brightnessCheckPassed = brightnessOk;
          _blurCheckPassed = blurOk;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Photo analysis error: $e');
      if (mounted) {
        setState(() {
          _blurCheckPassed = false;
          _brightnessCheckPassed = false;
          _isAnalyzing = false;
        });
      }
    }
  }

  // Average luminance across the image (0-255)
  double _calculateBrightness(img.Image grayscale) {
    double sum = 0;
    int count = 0;
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        sum += grayscale.getPixel(x, y).luminance;
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  // Variance of Laplacian — sharp = high variance, blurry = low variance
  double _calculateBlurScore(img.Image grayscale) {
    final width = grayscale.width;
    final height = grayscale.height;
    final List<double> laplacianValues = [];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final center = grayscale.getPixel(x, y).luminance;
        final top = grayscale.getPixel(x, y - 1).luminance;
        final bottom = grayscale.getPixel(x, y + 1).luminance;
        final left = grayscale.getPixel(x - 1, y).luminance;
        final right = grayscale.getPixel(x + 1, y).luminance;

        final laplacian = (4 * center - top - bottom - left - right).abs();
        laplacianValues.add(laplacian.toDouble());
      }
    }

    if (laplacianValues.isEmpty) return 0;

    final mean =
        laplacianValues.reduce((a, b) => a + b) / laplacianValues.length;
    final variance = laplacianValues
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        laplacianValues.length;

    return variance;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFFF6EB4),
      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: contentWidth * 0.06),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),

                  // Title changes based on state
                  Text(
                    _isAnalyzing
                        ? 'Checking your photo...'
                        : (_allChecksPassed
                            ? 'You look great!'
                            : 'Almost there'),
                    style: TextStyle(
                      fontSize: contentWidth * 0.075,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  Text(
                    'Image Validation',
                    style: TextStyle(
                      fontSize: contentWidth * 0.06,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.025),

                  // Captured photo preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(widget.imagePath),
                      width: contentWidth * 0.55,
                      height: contentWidth * 0.55,
                      fit: BoxFit.cover,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // White card with validation checklist
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(contentWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isAnalyzing)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF6EB4),
                              ),
                            ),
                          )
                        else ...[
                          _buildCheckItem(
                            label: 'Blur detection',
                            passed: _blurCheckPassed,
                            contentWidth: contentWidth,
                          ),
                          SizedBox(height: screenHeight * 0.012),

                          _buildCheckItem(
                            label: 'Brightness check',
                            passed: _brightnessCheckPassed,
                            contentWidth: contentWidth,
                          ),
                          SizedBox(height: screenHeight * 0.012),

                          _buildCheckItem(
                            label: 'Face visibility',
                            passed: _faceVisibilityPassed,
                            contentWidth: contentWidth,
                          ),
                        ],

                        SizedBox(height: screenHeight * 0.025),

                        // Continue button — navigates to AI Processing Screen (Page 8)
                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: ElevatedButton(
                            onPressed: (!_isAnalyzing && _allChecksPassed)
                                ? () {
                                    // Navigate to Face Analyzing Screen (Page 8)
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FaceAnalyzingScreen(
                                          imagePath: widget.imagePath,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6EB4),
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: contentWidth * 0.045,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.012),

                        // Retake button — goes back to camera
                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
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
                              'Retake',
                              style: TextStyle(
                                fontSize: contentWidth * 0.045,
                                color: const Color(0xFFFF6EB4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable checklist item with green check or red X
  Widget _buildCheckItem({
    required String label,
    required bool passed,
    required double contentWidth,
  }) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          color: passed ? Colors.green : Colors.red,
          size: contentWidth * 0.06,
        ),
        SizedBox(width: contentWidth * 0.03),
        Text(
          label,
          style: TextStyle(
            fontSize: contentWidth * 0.042,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}