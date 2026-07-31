/// Capstone Glow - Skin Tone Detector (Dart port of skin_tone_detector.py)
///
/// Analyzes face image pixels to classify skin tone as warm, cool, or neutral.
/// Uses OpenCV's LAB color space (0-255 range per channel, NOT standard
/// CIELAB 0-100) — this MUST use opencv_dart, not a hand-rolled LAB formula,
/// because the monk_scale thresholds below (avg_L > 180, > 160, etc.) were
/// tuned against OpenCV's specific 8-bit LAB encoding. A different LAB
/// formula would shift every threshold and silently break the mapping.
library;
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
    image.dispose();
    return const SkinToneResult(error: "Could not load image");
  }

  // Every Mat below is native memory that is NOT reclaimed by Dart's GC —
  // it must be disposed explicitly. Previously none of them were, leaking
  // roughly 190MB of native memory per analysis on a 12MP photo, which
  // compounds on every capture until the app is killed. Declared nullable
  // and released in the finally block so an exception mid-analysis cannot
  // skip the cleanup.
  cv.Mat? labImage;
  cv.Mat? hsvImage;
  cv.Mat? skinMask;

  try {
    // STEP 2: Convert to LAB color space
    labImage = cv.cvtColor(image, cv.COLOR_BGR2Lab);

    // STEP 3: Extract skin region using HSV mask
    hsvImage = cv.cvtColor(image, cv.COLOR_BGR2HSV);

    // inRangebyScalar takes the bounds as Scalars directly. The previous
    // code used inRange(), which needs Mat bounds, and so allocated two
    // FULL-RESOLUTION Mats purely to hold six constant numbers — on a 12MP
    // photo that is ~70MB of pointless allocation per call. Confirmed
    // present in the pinned version: dartcv4 core.dart:670.
    skinMask = cv.inRangebyScalar(
      hsvImage,
      cv.Scalar(0, 20, 70, 0),
      cv.Scalar(20, 255, 255, 0),
    );

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
  } finally {
    image.dispose();
    labImage?.dispose();
    hsvImage?.dispose();
    skinMask?.dispose();
  }
}