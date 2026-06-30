import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../page_7_camera_validation/camera_validation.dart';

// Camera / Face Scan Screen — Page 6
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;

  // Face detector from ML Kit
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  // Prevents overlapping frame processing
  bool _isDetecting = false;

  // Current guidance message shown to the user
  String _guidanceMessage = 'Position your face within the guide';

  // Whether everything looks good (face centered, right distance, good light)
  bool _isReadyToCapture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // Initialize the camera (front camera preferred for face scan)
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        // YUV420 format needed for ML Kit + brightness analysis
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });

        // Start streaming frames for live detection
        _controller!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  // Runs on every camera frame — checks lighting + face distance
  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return; // skip if still processing previous frame
    _isDetecting = true;

    try {
      // ── Step 1: Check brightness ──
      final brightness = _calculateAverageBrightness(image);

      if (brightness < 60) {
        _updateGuidance('Too dark — find better lighting', false);
        _isDetecting = false;
        return;
      }

      // ── Step 2: Check face distance using ML Kit ──
      final inputImage = _convertToInputImage(image, _controller!.description);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _updateGuidance('No face detected', false);
      } else {
        final face = faces.first;
        final faceWidth = face.boundingBox.width;
        final imageWidth = image.width;

        // Ratio of face width to frame width tells us distance
        final ratio = faceWidth / imageWidth;

        if (ratio < 0.25) {
          _updateGuidance('Move closer', false);
        } else if (ratio > 0.55) {
          _updateGuidance('Move back a bit', false);
        } else {
          _updateGuidance('Perfect! Hold still', true);
        }
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    }

    _isDetecting = false;
  }

  // Updates the guidance text shown on screen
  void _updateGuidance(String message, bool ready) {
    if (mounted) {
      setState(() {
        _guidanceMessage = message;
        _isReadyToCapture = ready;
      });
    }
  }

  // Calculates average brightness from the Y-plane of a YUV420 image
  double _calculateAverageBrightness(CameraImage image) {
    final Uint8List yPlane = image.planes[0].bytes;
    int sum = 0;

    // Sample every 10th pixel for performance
    for (int i = 0; i < yPlane.length; i += 10) {
      sum += yPlane[i];
    }
    final sampledCount = (yPlane.length / 10).ceil();
    return sum / sampledCount;
  }

  // Converts a CameraImage into the format ML Kit needs
  InputImage? _convertToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final planeData = image.planes.map(
        (Plane plane) => InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: plane.bytesPerRow,
        ),
      ).first;

      return InputImage.fromBytes(bytes: bytes, metadata: planeData);
    } catch (e) {
      debugPrint('Image conversion error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  // Capture the photo
  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.stopImageStream();
      final image = await _controller!.takePicture();
      debugPrint('Photo saved at: ${image.path}');

      if (mounted) {
        // Navigate to Image Validation Screen, passing the photo path
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageValidationScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview fills the screen
          if (_isCameraReady && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6EB4),
              ),
            ),

          // Face outline guide overlay — turns green when ready
          if (_isCameraReady)
            Center(
              child: Container(
                width: screenWidth * 0.7,
                height: screenWidth * 0.9,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isReadyToCapture
                        ? Colors.greenAccent
                        : Colors.white.withOpacity(0.8),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(150),
                ),
              ),
            ),

          // Live guidance message
          Positioned(
            bottom: screenHeight * 0.2,
            left: screenWidth * 0.1,
            right: screenWidth * 0.1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _guidanceMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isReadyToCapture
                      ? Colors.greenAccent
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: screenHeight * 0.05,
            left: screenWidth * 0.05,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Capture button — turns green when conditions are good
          Positioned(
            bottom: screenHeight * 0.06,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _capturePhoto,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isReadyToCapture
                        ? Colors.greenAccent
                        : const Color(0xFFFF6EB4),
                    border: const Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}