import 'dart:io';
import 'package:flutter/material.dart';

// Image Validation Screen — Page 7
class ImageValidationScreen extends StatefulWidget {
  // The captured photo path passed in from the Camera Screen
  final String imagePath;

  // Real check results passed in from the Camera Screen
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
  // Validation results — now driven by the real checks from camera.dart
  late bool _blurCheckPassed;
  late bool _brightnessCheckPassed;
  late bool _faceVisibilityPassed;

  // Whether all 3 checks passed (controls if "Continue" is enabled)
  bool get _allChecksPassed =>
      _blurCheckPassed && _brightnessCheckPassed && _faceVisibilityPassed;

  @override
  void initState() {
    super.initState();
    _blurCheckPassed = widget.blurOk;
    _brightnessCheckPassed = widget.brightnessOk;
    // Face visibility = face was detected AND at the right distance
    _faceVisibilityPassed = widget.faceDetected && widget.distanceOk;
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

                  // Title
                  Text(
                    _allChecksPassed ? 'You look great!' : 'Almost there',
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

                        SizedBox(height: screenHeight * 0.025),

                        // Continue button — only active if all checks passed
                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: ElevatedButton(
                            onPressed: _allChecksPassed
                                ? () {
                                    // TODO: Navigate to AI Processing Screen (Page 8)
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

                        // Retake button — always available
                        SizedBox(
                          width: double.infinity,
                          height: contentWidth * 0.13,
                          child: OutlinedButton(
                            onPressed: () {
                              // Go back to camera to retake photo
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