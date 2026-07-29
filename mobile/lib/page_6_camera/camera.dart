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

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
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

  // Whether everything looks good
  bool _isReadyToCapture = false;

  // Real check results to pass to validation screen
  bool _brightnessOk = false;
  bool _faceDetected = false;
  bool _distanceOk = false;
  bool _blurOk = false;

  // Blur threshold
  static const double _blurThreshold = 6.0;

  @override
  void initState() {
    super.initState();
    // Register observer to detect app/screen lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  // Called when app lifecycle changes (resumed = screen comes back into focus)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Restart stream when returning from validation screen
      _restartStreamIfNeeded();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.stopImageStream();
    }
  }

  // Restart image stream if it was stopped (e.g. after retake)
  void _restartStreamIfNeeded() {
    if (_isCameraReady &&
        _controller != null &&
        _controller!.value.isInitialized &&
        !_controller!.value.isStreamingImages) {
      _controller!.startImageStream(_processCameraImage);
    }
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
        ResolutionPreset.high,
        enableAudio: false,
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

  // Runs on every camera frame — checks brightness, blur, and face distance
  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      // Step 1: Check brightness
      final brightness = _calculateAverageBrightness(image);
      final brightnessOk = brightness >= 80;

      if (!brightnessOk) {
        _updateGuidance('Too dark — find better lighting', false,
            brightnessOk: false,
            faceDetected: false,
            distanceOk: false,
            blurOk: false);
        _isDetecting = false;
        return;
      }

      // Step 2: Check blur
      final blurScore = _calculateBlurScore(image);
      final blurOk = blurScore >= _blurThreshold;

      if (!blurOk) {
        _updateGuidance('Image too blurry — hold camera steady', false,
            brightnessOk: brightnessOk,
            faceDetected: false,
            distanceOk: false,
            blurOk: false);
        _isDetecting = false;
        return;
      }

      // Step 3: Check face distance using ML Kit
      final inputImage = _convertToInputImage(image, _controller!.description);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _updateGuidance('No face detected — look at the camera', false,
            brightnessOk: brightnessOk,
            faceDetected: false,
            distanceOk: false,
            blurOk: blurOk);
      } else {
        final face = faces.first;
        final faceWidth = face.boundingBox.width;
        final imageWidth = image.width.toDouble();
        final ratio = faceWidth / imageWidth;

        if (ratio < 0.3) {
          _updateGuidance('Move closer', false,
              brightnessOk: brightnessOk,
              faceDetected: true,
              distanceOk: false,
              blurOk: blurOk);
        } else if (ratio > 0.7) {
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

  // Updates the guidance text and all check results
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

  // Calculates average brightness from Y-plane of YUV420 image
  double _calculateAverageBrightness(CameraImage image) {
    final Uint8List yPlane = image.planes[0].bytes;
    int sum = 0;
    for (int i = 0; i < yPlane.length; i += 10) {
      sum += yPlane[i];
    }
    final sampledCount = (yPlane.length / 10).ceil();
    return sum / sampledCount;
  }

  // Measures sharpness using variance of Laplacian on Y-plane
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

  // Converts CameraImage to InputImage for ML Kit
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
    // Remove observer and clean up camera
    WidgetsBinding.instance.removeObserver(this);
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
        // Navigate to validation — when user retakes, stream restarts via observer
        await Navigator.push(
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

        // Restart stream when returning from validation screen
        _restartStreamIfNeeded();
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
          // Camera preview — FittedBox fixes stretch issue
          if (_isCameraReady && _controller != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6EB4),
              ),
            ),

          // Face outline guide — turns green when ready
          if (_isCameraReady)
            Center(
              child: Container(
                width: screenWidth * 0.7,
                height: screenWidth * 0.9,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isReadyToCapture
                        ? Colors.greenAccent
                        : Colors.white.withValues(alpha: 0.8),
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
                color: Colors.black.withValues(alpha: 0.6),
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
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Capture button — turns green when ready
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