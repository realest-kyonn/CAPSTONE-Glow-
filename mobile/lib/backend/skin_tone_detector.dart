/// Capstone Glow - Skin Tone Detector (Dart port of skin_tone_detector.py)
///
/// Analyzes face image pixels to classify skin tone as warm, cool, or neutral.
/// Uses OpenCV's LAB color space (0-255 range per channel, NOT standard
/// CIELAB 0-100) — this MUST use opencv_dart, not a hand-rolled LAB formula,
/// because the monk_scale thresholds below (avg_L > 180, > 160, etc.) were
/// tuned against OpenCV's specific 8-bit LAB encoding. A different LAB
/// formula would shift every threshold and silently break the mapping.
import 'dart:io';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class SkinToneResult {
  final String? skinTone; // "warm" | "cool" | "neutral"
  final int? monkScale; // 1-10
  final String? confidence; // "low" | "medium" | "high"
  final double? avgLightness;
  final double? avgWarmth;
  final double? avgRedness;
  final String? error;

  const SkinToneResult({
    this.skinTone,
    this.monkScale,
    this.confidence,
    this.avgLightness,
    this.avgWarmth,
    this.avgRedness,
    this.error,
  });

  bool get hasError => error != null;
}

/// Mirrors detect_skin_tone(image_path) exactly — same HSV skin mask range,
/// same LAB averaging, same warm/cool/neutral thresholds, same Monk Scale
/// bucketing.
SkinToneResult detectSkinTone(String imagePath) {
  // STEP 1: Load the image
  if (!File(imagePath).existsSync()) {
    return const SkinToneResult(error: "Could not load image");
  }
  final image = cv.imread(imagePath);
  if (image.isEmpty) {
    return const SkinToneResult(error: "Could not load image");
  }

  // STEP 2: Convert to LAB color space
  final labImage = cv.cvtColor(image, cv.COLOR_BGR2Lab);

  // STEP 3: Extract skin region using HSV mask
  final hsvImage = cv.cvtColor(image, cv.COLOR_BGR2HSV);

  // inRange() requires actual Mat (InputArray) bounds, not a bare Scalar
  // — confirmed against opencv_dart 1.4.5's real signature:
  //   Mat inRange(InputArray src, InputArray lowerb, InputArray upperb, ...)
  // Build full-size Mats filled with the scalar bound values instead.
  final lowerSkin = cv.Mat.fromScalar(
    hsvImage.rows, hsvImage.cols, hsvImage.type, cv.Scalar(0, 20, 70, 0),
  );
  final upperSkin = cv.Mat.fromScalar(
    hsvImage.rows, hsvImage.cols, hsvImage.type, cv.Scalar(20, 255, 255, 0),
  );
  final skinMask = cv.inRange(hsvImage, lowerSkin, upperSkin);

  // STEP 4: Get average LAB values of skin pixels
  // opencv_dart doesn't support fancy boolean-mask indexing like numpy, so
  // walk the mask manually and accumulate only the masked pixels.
  double sumL = 0, sumA = 0, sumB = 0;
  int count = 0;

  final rows = labImage.rows;
  final cols = labImage.cols;

  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      // Single-channel mask value — confirmed real method: atNum()
      final maskVal = skinMask.atNum(y, x);
      if (maskVal > 0) {
        // Multi-channel pixel (L, A, B) — confirmed real method: atPixel(),
        // returns List<num> with one value per channel.
        final pixel = labImage.atPixel(y, x);
        sumL += pixel[0];
        sumA += pixel[1];
        sumB += pixel[2];
        count++;
      }
    }
  }

  if (count == 0) {
    return const SkinToneResult(error: "No skin detected in image");
  }

  final avgL = sumL / count;
  final avgA = sumA / count;
  final avgB = sumB / count;

  // STEP 5: Classify skin tone
  // B - A difference tells us warm vs cool
  // positive = more yellow = WARM
  // negative = more pink/red = COOL
  // near zero = balanced = NEUTRAL
  final diff = avgB - avgA;

  String skinTone;
  String confidence;
  if (diff > 8) {
    skinTone = "warm";
    confidence = diff > 12 ? "high" : "medium";
  } else if (diff < -2) {
    skinTone = "cool";
    confidence = diff < -6 ? "high" : "medium";
  } else {
    skinTone = "neutral";
    confidence = "medium";
  }

  // STEP 6: Map to Monk Scale (1-10)
  int monkScale;
  if (avgL > 180) {
    monkScale = 1;
  } else if (avgL > 160) {
    monkScale = 2;
  } else if (avgL > 145) {
    monkScale = 3;
  } else if (avgL > 130) {
    monkScale = 4;
  } else if (avgL > 115) {
    monkScale = 5;
  } else if (avgL > 100) {
    monkScale = 6;
  } else if (avgL > 85) {
    monkScale = 7;
  } else if (avgL > 70) {
    monkScale = 8;
  } else if (avgL > 55) {
    monkScale = 9;
  } else {
    monkScale = 10;
  }

  return SkinToneResult(
    skinTone: skinTone,
    monkScale: monkScale,
    confidence: confidence,
    avgLightness: double.parse(avgL.toStringAsFixed(2)),
    avgWarmth: double.parse(avgB.toStringAsFixed(2)),
    avgRedness: double.parse(avgA.toStringAsFixed(2)),
  );
}