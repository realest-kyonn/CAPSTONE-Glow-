/// Capstone Glow - Full Pipeline Test (temporary)
///
/// Extends the mesh-only test to run all three detectors, printed in a
/// format meant to be compared line-by-line against Python's main.py
/// output on the SAME photo. This is the real verification step — the
/// mesh-only test confirmed the landmark geometry looks anatomically
/// correct, but only running the full pipeline confirms the Dart port
/// actually reproduces the proven 93.80% Python behavior.
///
/// IMPORTANT: TEST_ASSET_PATH is a Flutter ASSET (bundled inside the app),
/// not a raw filesystem path. Things like File().readAsBytes() and
/// cv.imread() need a REAL path on disk — they cannot read directly from
/// the asset bundle. So this test first copies the asset's bytes out to
/// a real temporary file at runtime, then uses THAT file's path for
/// everything else (mesh detection, face shape, skin tone, etc).
library test_full_pipeline;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import 'backend/mesh_provider.dart';
import 'backend/face_shape_detector.dart';
import 'backend/skin_tone_detector.dart';
import 'backend/eye_shape_detector.dart' as eyes;

// This is the ASSET path (as declared in pubspec.yaml's assets: list),
// NOT a device filesystem path. Make sure pubspec.yaml actually lists
// "assets/test/sample_face.jpg" (or the whole "assets/test/" folder)
// under flutter: assets: — otherwise rootBundle.load() below will throw
// a "Unable to load asset" error.
const String TEST_ASSET_PATH = "assets/test/sample_face.jpg";

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Full Pipeline Test (temporary)")),
        body: const Center(child: TestRunner()),
      ),
    );
  }
}

class TestRunner extends StatefulWidget {
  const TestRunner({super.key});
  @override
  State<TestRunner> createState() => _TestRunnerState();
}

class _TestRunnerState extends State<TestRunner> {
  String _status = "Running...";

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final sw = Stopwatch()..start();
    void log(String msg) {
      debugPrint("[${sw.elapsedMilliseconds}ms] $msg");
    }

    log("=== FULL PIPELINE TEST ===");
    log("Asset: $TEST_ASSET_PATH");

    // ── Step 0: Copy the bundled asset out to a real temp file ───────
    // Native/file-based code (File(), cv.imread()) can't read Flutter's
    // asset bundle directly — it needs an actual path on disk.
    String testImagePath;
    try {
      final byteData = await rootBundle.load(TEST_ASSET_PATH);
      final tempDir = Directory.systemTemp;
      final tempFile = File("${tempDir.path}/glow_test_image.jpg");
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      testImagePath = tempFile.path;
      log("Copied asset to temp file: $testImagePath");
    } catch (e) {
      log("❌ Failed to load asset '$TEST_ASSET_PATH': $e");
      log("   Check that pubspec.yaml's flutter: assets: section actually");
      log("   lists this file (or its containing folder), then run");
      log("   'flutter pub get' again — asset list changes need a re-fetch.");
      setState(() => _status = "Asset load failed — check Debug Console.");
      return;
    }

    if (!File(testImagePath).existsSync()) {
      log("❌ Temp file not found after copy — unexpected.");
      setState(() => _status = "File not found — check Debug Console.");
      return;
    }

    setState(() => _status = "Step 1/4: Running mesh detection...");
    log("--- Step 1/4: Mesh/BoundingBox ---");
    final meshProvider = await MeshProvider.load();
    final meshResult = await meshProvider.analyzePhoto(testImagePath);
    log("hasFace: ${meshResult.hasFace}");
    log("boundingBox: ${meshResult.boundingBox != null ? 'x=${meshResult.boundingBox!.x}, y=${meshResult.boundingBox!.y}, w=${meshResult.boundingBox!.width}, h=${meshResult.boundingBox!.height}' : 'none'}");
    log("meshLandmarks count: ${meshResult.meshLandmarks.length}");
    log("Step 1/4 done.");

    setState(() => _status = "Step 2/4: Running face shape model...");
    log("--- Step 2/4: Face Shape ---");
    final bytes = await File(testImagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    String faceShapeLine = "SKIPPED (image failed to decode)";
    Map<String, double> faceShapeAllScores = {};
    if (decoded != null) {
      final faceShapeDetector = await FaceShapeDetector.load();
      final faceShapeResult = faceShapeDetector.detectFaceShape(
        decoded,
        box: meshResult.boundingBox,
      );
      faceShapeLine =
          "${faceShapeResult.faceShape}  (confidence: ${faceShapeResult.confidence})"
          "${faceShapeResult.error != null ? '  [error: ${faceShapeResult.error}]' : ''}";
      faceShapeAllScores = faceShapeResult.allScores;
      log("Predicted: $faceShapeLine");
      log("All scores: $faceShapeAllScores");
      faceShapeDetector.dispose();
    } else {
      log("❌ Image failed to decode.");
    }
    log("Step 2/4 done.");

    // NOTE: this step scans every pixel of the image one at a time
    // (opencv_dart has no fast bulk-masking here) — on a full
    // camera-resolution photo this can genuinely take a while.
    // If the app looked "stuck" before, THIS is the most likely reason —
    // now you'll see the "Step 3/4 starting" line sit there while it works,
    // instead of nothing printing at all.
    setState(() => _status = "Step 3/4: Scanning pixels for skin tone (this may take a while on a large photo)...");
    log("--- Step 3/4: Skin Tone (pixel-by-pixel scan — may be slow) ---");
    final skinToneResult = detectSkinTone(testImagePath);
    if (skinToneResult.hasError) {
      log("❌ ${skinToneResult.error}");
    } else {
      log("Undertone: ${skinToneResult.skinTone}");
      log("Monk Scale: ${skinToneResult.monkScale}");
      log("Confidence: ${skinToneResult.confidence}");
      log("avgLightness: ${skinToneResult.avgLightness}, avgWarmth: ${skinToneResult.avgWarmth}, avgRedness: ${skinToneResult.avgRedness}");
    }
    log("Step 3/4 done.");

    setState(() => _status = "Step 4/4: Running eye shape classification...");
    log("--- Step 4/4: Eye Shape ---");
    final eyeShapeResult = eyes.detectEyeShape(meshResult.meshLandmarks);
    log("Predicted: ${eyeShapeResult.eyeShape}");
    log("Confidence: ${eyeShapeResult.confidence}");
    log("Metrics: ${eyeShapeResult.metrics}");
    if (eyeShapeResult.error != null) {
      log("Note: ${eyeShapeResult.error}");
    }
    log("Step 4/4 done.");

    log("=== SUMMARY (compare against py -3.12 backend/main.py) ===");
    log("Face Shape : $faceShapeLine");
    log("Undertone  : ${skinToneResult.skinTone ?? 'ERROR'}");
    log("Monk Scale : ${skinToneResult.monkScale ?? 'ERROR'}");
    log("Eye Shape  : ${eyeShapeResult.eyeShape}");
    log("Total time : ${sw.elapsedMilliseconds}ms");
    log("=== Test Complete ===");

    setState(() => _status = "Done — check the Debug Console for full results.");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(_status, textAlign: TextAlign.center),
    );
  }
}