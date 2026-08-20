import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../page_8_face_analyzing/face_analyzing.dart';

// Image Validation Screen — Page 7
class ImageValidationScreen extends StatefulWidget {
  final String imagePath;
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
  bool _faceVisibilityPassed = false;
  bool _isAnalyzing = true;

  // ── Calibration thresholds ──
  // IMPORTANT: Uncomment the debugPrint below to see real values
  // on your device, then tune these numbers accordingly.

  // Blur: variance of Laplacian. Sharp = high, Blurry = low.
  // Raised to 150 to properly reject blurry photos.
  static const double _blurThreshold = 150.0;

  // Brightness: luminance is 0.0 to 1.0 in image package
  static const double _minBrightness = 0.05;
  static const double _maxBrightness = 0.95;

  bool get _allChecksPassed =>
      _blurCheckPassed && _brightnessCheckPassed && _faceVisibilityPassed;

  @override
  void initState() {
    super.initState();
    _analyzePhoto();
  }

  Future<void> _analyzePhoto() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        if (mounted) {
          setState(() {
            _blurCheckPassed = false;
            _brightnessCheckPassed = false;
            _faceVisibilityPassed = false;
            _isAnalyzing = false;
          });
        }
        return;
      }

      // Resize to 400px for better accuracy
      final resized = img.copyResize(decoded, width: 400);
      final grayscale = img.grayscale(resized);

      final brightness = _calculateBrightness(grayscale);
      final blurScore = _calculateBlurScore(grayscale);

      // ── UNCOMMENT THIS to see real values in VS Code debug console ──
      // Use these values to tune the thresholds for your device
      debugPrint('=== VALIDATION ===');
      debugPrint('Brightness: $brightness (min: $_minBrightness, max: $_maxBrightness)');
      debugPrint('Blur score: $blurScore (min: $_blurThreshold)');

      final brightnessOk =
          brightness >= _minBrightness && brightness <= _maxBrightness;
      final blurOk = blurScore >= _blurThreshold;

      // Real face check on actual saved photo
      final faceVisibilityOk = await _checkFaceVisibility();

      debugPrint('Face detected: $faceVisibilityOk');
      debugPrint('Results — blur: $blurOk, brightness: $brightnessOk, face: $faceVisibilityOk');

      if (mounted) {
        setState(() {
          _brightnessCheckPassed = brightnessOk;
          _blurCheckPassed = blurOk;
          _faceVisibilityPassed = faceVisibilityOk;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Photo analysis error: $e');
      if (mounted) {
        setState(() {
          _blurCheckPassed = false;
          _brightnessCheckPassed = false;
          _faceVisibilityPassed = false;
          _isAnalyzing = false;
        });
      }
    }
  }

  // ML Kit face detection on actual saved photo
  Future<bool> _checkFaceVisibility() async {
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        // Face must take up at least 15% of the image width
        minFaceSize: 0.15,
      ),
    );
    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final faces = await faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('Face visibility check error: $e');
      return false;
    } finally {
      faceDetector.close();
    }
  }

  // Average luminance (0.0 to 1.0)
  double _calculateBrightness(img.Image grayscale) {
    double sum = 0;
    int count = 0;
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        sum += grayscale.getPixel(x, y).luminanceNormalized;
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  // Variance of Laplacian — sharp = high, blurry = low
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
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: contentWidth,
          child: SafeArea(
            child: SingleChildScrollView(
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
                      textAlign: TextAlign.center,
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
                              failMessage: 'Photo is blurry — hold steady',
                              contentWidth: contentWidth,
                            ),
                            SizedBox(height: screenHeight * 0.012),

                            _buildCheckItem(
                              label: 'Brightness check',
                              passed: _brightnessCheckPassed,
                              failMessage: 'Too dark or too bright',
                              contentWidth: contentWidth,
                            ),
                            SizedBox(height: screenHeight * 0.012),

                            _buildCheckItem(
                              label: 'Face visibility',
                              passed: _faceVisibilityPassed,
                              failMessage: 'No face detected in photo',
                              contentWidth: contentWidth,
                            ),
                          ],

                          SizedBox(height: screenHeight * 0.025),

                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            height: contentWidth * 0.13,
                            child: ElevatedButton(
                              onPressed: (!_isAnalyzing && _allChecksPassed)
                                  ? () {
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

                          // Retake button
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

                          SizedBox(height: screenHeight * 0.01),
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
      ),
    );
  }

  // Checklist item with fail message when not passed
  Widget _buildCheckItem({
    required String label,
    required bool passed,
    required String failMessage,
    required double contentWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        // Show reason when check fails
        if (!passed)
          Padding(
            padding: EdgeInsets.only(
              left: contentWidth * 0.09,
              top: 2,
            ),
            child: Text(
              failMessage,
              style: TextStyle(
                fontSize: contentWidth * 0.03,
                color: Colors.red.shade400,
              ),
            ),
          ),
      ],
    );
  }
}