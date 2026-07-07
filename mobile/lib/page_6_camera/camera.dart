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

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  bool _isDetecting = false;
  String _guidanceMessage = 'Position your face within the guide';
  bool _isReadyToCapture = false;

  // Real check results to pass to validation screen
  bool _brightnessOk = false;
  bool _faceDetected = false;
  bool _distanceOk = false;
  bool _blurOk = false;

  // Blur threshold — tune based on your testing (see note below)
  static const double _blurThreshold = 6.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

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
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
        _controller!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  // Runs on every camera frame — checks lighting + blur + face distance
  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      // ── Step 1: Check brightness ──
      final brightness = _calculateAverageBrightness(image);
      final brightnessOk = brightness >= 60;

      if (!brightnessOk) {
        _updateGuidance('Too dark — find better lighting', false,
            brightnessOk: false,
            faceDetected: false,
            distanceOk: false,
            blurOk: false);
        _isDetecting = false;
        return;
      }

      // ── Step 2: Check blur (sharpness) ──
      final blurScore = _calculateBlurScore(image);
      final blurOk = blurScore >= _blurThreshold;

      // Uncomment while calibrating to see real values on your device:
      // debugPrint('Blur score: $blurScore');

      if (!blurOk) {
        _updateGuidance('Image too blurry — hold the camera steady', false,
            brightnessOk: brightnessOk,
            faceDetected: false,
            distanceOk: false,
            blurOk: false);
        _isDetecting = false;
        return;
      }

      // ── Step 3: Check face distance using ML Kit ──
      final inputImage = _convertToInputImage(image, _controller!.description);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _updateGuidance('No face detected', false,
            brightnessOk: brightnessOk,
            faceDetected: false,
            distanceOk: false,
            blurOk: blurOk);
      } else {
        final face = faces.first;
        final faceWidth = face.boundingBox.width;
        final imageWidth = image.width;
        final ratio = faceWidth / imageWidth;

        if (ratio < 0.25) {
          _updateGuidance('Move closer', false,
              brightnessOk: brightnessOk,
              faceDetected: true,
              distanceOk: false,
              blurOk: blurOk);
        } else if (ratio > 0.55) {
          _updateGuidance('Move back a bit', false,
              brightnessOk: brightnessOk,
              faceDetected: true,
              distanceOk: false,
              blurOk: blurOk);
        } else {
          _updateGuidance('Perfect! Hold still', true,
              brightnessOk: brightnessOk,
              faceDetected: true,
              distanceOk: true,
              blurOk: blurOk);
        }
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    }

    _isDetecting = false;
  }

  void _updateGuidance(
    String message,
    bool ready, {
    required bool brightnessOk,
    required bool faceDetected,
    required bool distanceOk,
    required bool blurOk,
  }) {
    if (mounted) {
      setState(() {
        _guidanceMessage = message;
        _isReadyToCapture = ready;
        _brightnessOk = brightnessOk;
        _faceDetected = faceDetected;
        _distanceOk = distanceOk;
        _blurOk = blurOk;
      });
    }
  }

  double _calculateAverageBrightness(CameraImage image) {
    final Uint8List yPlane = image.planes[0].bytes;
    int sum = 0;
    for (int i = 0; i < yPlane.length; i += 10) {
      sum += yPlane[i];
    }
    final sampledCount = (yPlane.length / 10).ceil();
    return sum / sampledCount;
  }

  // Measures sharpness using variance of Laplacian on the Y-plane.
  // Sharp images have high edge contrast (high variance);
  // blurry/motion-blurred images look smooth (low variance).
  double _calculateBlurScore(CameraImage image) {
    final Uint8List yPlane = image.planes[0].bytes;
    final int rowStride = image.planes[0].bytesPerRow;
    final int height = image.height;

    const int step = 8;
    final List<int> laplacianValues = [];

    for (int y = step; y < height - step; y += step) {
      for (int x = step; x < rowStride - step; x += step) {
        final int idx = y * rowStride + x;
        if (idx - rowStride < 0 || idx + rowStride >= yPlane.length) continue;

        final int center = yPlane[idx];
        final int top = yPlane[idx - rowStride];
        final int bottom = yPlane[idx + rowStride];
        final int left = yPlane[idx - 1];
        final int right = yPlane[idx + 1];

        final int laplacian =
            (4 * center - top - bottom - left - right).abs();
        laplacianValues.add(laplacian);
      }
    }

    if (laplacianValues.isEmpty) return 0;

    final double mean =
        laplacianValues.reduce((a, b) => a + b) / laplacianValues.length;
    final double variance = laplacianValues
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        laplacianValues.length;

    return variance;
  }

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

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.stopImageStream();
      final image = await _controller!.takePicture();
      debugPrint('Photo saved at: ${image.path}');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageValidationScreen(
              imagePath: image.path,
              brightnessOk: _brightnessOk,
              faceDetected: _faceDetected,
              distanceOk: _distanceOk,
              blurOk: _blurOk,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  // Builds the camera preview without stretching, filling the screen
  // by scaling based on the actual screen vs camera aspect ratio.
  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview — fills screen without stretching
          if (_isCameraReady && _controller != null)
            Positioned.fill(child: _buildCameraPreview())
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