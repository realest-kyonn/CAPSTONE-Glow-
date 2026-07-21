// TEMPORARY TEST FILE — not part of the real app.
// Run with: flutter run -t lib/test_mesh_main.dart
//
// Validates face_detection_tflite's real output on one actual photo
// before wiring MeshProvider into Page 8. Prints everything to the
// console (View -> Debug Console in VS Code, or the terminal running
// `flutter run`).
//
// BEFORE RUNNING: put one real test photo (a clear face, ideally similar
// to what Page 6/7 would capture) into:
//   mobile/assets/test/sample_face.jpg
// and add it to pubspec.yaml's assets: list temporarily:
//   - assets/test/sample_face.jpg

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'backend/mesh_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: TestScreen()));
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _status = "Starting test...";

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    print("=== MeshProvider Test Starting ===");
    setState(() => _status = "Loading detector...");

    // Step 1: copy the bundled asset photo to a real file path, since
    // MeshProvider.analyzePhoto() expects a file path (matches how
    // Page 7 will hand off the captured photo path).
    final byteData = await rootBundle.load('assets/test/sample_face.jpg');
    final tempDir = await getTemporaryDirectory();
    final testFile = File('${tempDir.path}/sample_face.jpg');
    await testFile.writeAsBytes(byteData.buffer.asUint8List());
    print("Test photo written to: ${testFile.path}");

    // Step 2: load the detector (same call Page 8 will make once at
    // startup — here we just do it right before the test).
    setState(() => _status = "Initializing MeshProvider...");
    final meshProvider = await MeshProvider.load();
    print("MeshProvider loaded successfully.");

    // Step 3: run detection on the real photo.
    setState(() => _status = "Running detection...");
    final result = await meshProvider.analyzePhoto(testFile.path);

    // Step 4: print everything — this is what we actually need to see.
    print("\n=== RESULTS ===");
    print("hasFace: ${result.hasFace}");
    print("error: ${result.error}");
    print("imgWidth: ${result.imgWidth}, imgHeight: ${result.imgHeight}");

    if (result.boundingBox != null) {
      final box = result.boundingBox!;
      print("boundingBox: x=${box.x}, y=${box.y}, "
          "width=${box.width}, height=${box.height}");
    } else {
      print("boundingBox: null (no face detected)");
    }

    print("meshLandmarks count: ${result.meshLandmarks.length}");

    if (result.meshLandmarks.isNotEmpty) {
      // Print a handful of specific indices to sanity-check against the
      // unverified assumption flagged in eye_shape_detector.dart —
      // indices 33 and 263 SHOULD be near the outer eye corners if the
      // mesh ordering matches standard MediaPipe topology.
      void printIfExists(int index, String label) {
        if (index < result.meshLandmarks.length) {
          final lm = result.meshLandmarks[index];
          print("  landmark[$index] ($label): x=${lm.x}, y=${lm.y}");
        } else {
          print("  landmark[$index] ($label): OUT OF RANGE "
              "(only ${result.meshLandmarks.length} points total)");
        }
      }

      print("\nKey landmark sanity check (compare visually against photo):");
      printIfExists(33, "expected: left eye outer corner");
      printIfExists(133, "expected: left eye inner corner");
      printIfExists(263, "expected: right eye outer corner");
      printIfExists(362, "expected: right eye inner corner");
      printIfExists(234, "expected: face left edge");
      printIfExists(454, "expected: face right edge");
    }

    setState(() => _status =
        "Done — check the Debug Console for full results.\n\n"
        "hasFace: ${result.hasFace}\n"
        "mesh points: ${result.meshLandmarks.length}\n"
        "bbox: ${result.boundingBox != null ? 'found' : 'null'}");

    print("\n=== Test Complete ===");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detector Test (temporary)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            _status,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}