/// Capstone Glow - Face Shape Detector (Dart port of face_shape_detector.py)
///
/// Uses the trained TFLite model to predict face shape from a photo.
///
/// IMPORTANT DIFFERENCE FROM PYTHON: the Python version uses MTCNN for face
/// cropping. There is no MTCNN in Flutter. This port expects a bounding box
/// already produced by `face_detection_tflite` (the package we discussed
/// replacing google_mlkit_face_detection with) to be passed in — it does
/// NOT run its own face detection. Wire it up as:
///   1. face_detection_tflite detects the face -> bounding box
///   2. pass that bounding box into cropFace() below
///   3. feed the cropped+resized image into detectFaceShape()
///
/// CRITICAL — MUST UPDATE BEFORE SHIPPING:
///   IMAGE_SIZE below is hardcoded to 224 to match v9 (VGG16) / VGGFace
///   (also VGG16-based). If Xception (v10) or any 299x299 model is ever
///   deployed instead, this constant MUST change to 299, exactly like the
///   Python face_shape_detector.py's IMAGE_SIZE. Mismatched size will NOT
///   crash — it will silently corrupt every prediction. Check this against
///   whichever .tflite file you actually bundle.
library face_shape_detector;

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// UPDATE THIS to match the deployed model. See warning above.
const int kImageSize = 224;

class FaceBoundingBox {
  final int x;
  final int y;
  final int width;
  final int height;
  const FaceBoundingBox(this.x, this.y, this.width, this.height);
}

class FaceShapeResult {
  final String faceShape; // "Heart" | "Long" | "Oval" | "Round" | "Square"
  final double confidence; // 0.0 - 1.0
  final Map<String, double> allScores;
  final String? error;

  const FaceShapeResult({
    required this.faceShape,
    required this.confidence,
    required this.allScores,
    this.error,
  });
}

class FaceShapeDetector {
  FaceShapeDetector._(this._interpreter, this._labels);

  final Interpreter _interpreter;
  final List<String> _labels;

  /// Loads the TFLite model + label file once. Call at app startup and
  /// keep the instance alive for the app's lifetime (mirrors Python
  /// loading the model once at module level) — do NOT reload per-frame.
  // Paths MUST match pubspec.yaml's flutter: assets: list exactly.
  static Future<FaceShapeDetector> load({
    String modelAsset = "assets/face_shape_model.tflite",
    String labelsAsset = "assets/face_shape_model_labels.txt",
  }) async {
    final interpreter = await Interpreter.fromAsset(modelAsset);
    // Bundled assets are packed into the app, not present as real files on
    // disk — File() silently fails on a real device. rootBundle is the
    // correct way to read them.
    final labelsRaw = await rootBundle.loadString(labelsAsset);
    final labels = labelsRaw
        .split("\n")
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return FaceShapeDetector._(interpreter, labels);
  }

  /// Mirrors the CURRENT _crop_face(image_path) in face_shape_detector.py
  /// (v11 / VGGFace training crop) — NOT the old 30%-padding version.
  ///
  /// Python's own comments confirm the old 30%-padding + direct-resize
  /// approach (which this file used to mirror) caused a ~40-point accuracy
  /// drop when tested against the real deployed pipeline. This is the
  /// fixed logic: small fixed 10px top/bottom padding, then FORCE a square
  /// crop (expand width to match the padded height, centered) before
  /// resizing — preserves aspect ratio instead of stretching/squashing.
  ///
  /// Falls back to a CENTER-SQUARE crop (not the unmodified full image) if
  /// no bounding box is provided or the computed crop is degenerate —
  /// matching Python's training-time fallback exactly.
  img.Image cropFace(img.Image source, FaceBoundingBox? box) {
    final w = source.width;
    final h = source.height;

    if (box == null) {
      return _centerSquareCrop(source, w, h);
    }

    final x = box.x < 0 ? 0 : box.x;
    final y = box.y;

    // Fixed 10px vertical padding (NOT a percentage of box size)
    final y1 = (y - 10) < 0 ? 0 : (y - 10);
    final y2 = (y + box.height + 10) > h ? h : (y + box.height + 10);
    final x1 = x;
    final x2 = (x + box.width) > w ? w : (x + box.width);

    final newHeight = y2 - y1;
    final width = x2 - x1;

    // Force a square crop: expand width to match height, centered
    final adjW = ((newHeight - width) / 2).toInt();
    final newX1 = (x1 - adjW) < 0 ? 0 : (x1 - adjW);
    final newX2 = (x2 + adjW) > w ? w : (x2 + adjW);

    if (y2 <= y1 || newX2 <= newX1) {
      return _centerSquareCrop(source, w, h); // degenerate crop
    }

    return img.copyCrop(source, x: newX1, y: y1, width: newX2 - newX1, height: y2 - y1);
  }

  /// Matches Python's fallback: center-crop to the largest possible square,
  /// used both for "no face detected" and any degenerate box case.
  img.Image _centerSquareCrop(img.Image source, int w, int h) {
    final side = w < h ? w : h;
    final top = (h - side) ~/ 2;
    final left = (w - side) ~/ 2;
    return img.copyCrop(source, x: left, y: top, width: side, height: side);
  }

  /// Mirrors _preprocess(img) exactly.
  ///
  /// CRITICAL: hands the model raw 0-255 RGB values, NOT normalized/BGR
  /// values. Preprocessing (RGB->BGR + ImageNet mean subtraction, or
  /// whatever the winning model's preprocess_input does) is baked into the
  /// exported .tflite graph itself. Doing it again here reproduces the
  /// exact double-preprocessing bug already fixed once in Python — do not
  /// "helpfully" normalize this data.
  Float32List _preprocess(img.Image image) {
    final resized = img.copyResize(
      image,
      width: kImageSize,
      height: kImageSize,
      interpolation: img.Interpolation.linear, // matches PIL's BILINEAR
    );

    final input = Float32List(1 * kImageSize * kImageSize * 3);
    int i = 0;
    for (int y = 0; y < kImageSize; y++) {
      for (int x = 0; x < kImageSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[i++] = pixel.r.toDouble();
        input[i++] = pixel.g.toDouble();
        input[i++] = pixel.b.toDouble();
      }
    }
    return input;
  }

  /// Mirrors detect_face_shape(image_path) exactly, given an already-decoded
  /// image and an optional bounding box from face_detection_tflite.
  FaceShapeResult detectFaceShape(img.Image sourceImage, {FaceBoundingBox? box}) {
    try {
      // Step 1: Crop face
      final faceImg = cropFace(sourceImage, box);

      // Step 2: Preprocess
      final inputData = _preprocess(faceImg);
      final inputTensor = inputData.reshape([1, kImageSize, kImageSize, 3]);

      // Step 3: Run inference
      final outputShape = _interpreter.getOutputTensor(0).shape;
      final outputBuffer = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape(outputShape);
      _interpreter.run(inputTensor, outputBuffer);

      final List<double> outputData =
          (outputBuffer[0] as List).cast<double>();

      // Step 4: Get prediction
      int predictedIdx = 0;
      double maxVal = outputData[0];
      for (int i = 1; i < outputData.length; i++) {
        if (outputData[i] > maxVal) {
          maxVal = outputData[i];
          predictedIdx = i;
        }
      }
      final predictedShape = _labels[predictedIdx];

      // Step 5: Build all scores map
      final allScores = <String, double>{};
      for (int i = 0; i < _labels.length; i++) {
        allScores[_labels[i]] = double.parse(outputData[i].toStringAsFixed(4));
      }

      return FaceShapeResult(
        faceShape: predictedShape,
        confidence: double.parse(maxVal.toStringAsFixed(4)),
        allScores: allScores,
      );
    } catch (e) {
      return FaceShapeResult(
        faceShape: "Oval", // same fallback default as Python
        confidence: 0.0,
        allScores: const {},
        error: "Detection failed: $e",
      );
    }
  }

  void dispose() => _interpreter.close();
}