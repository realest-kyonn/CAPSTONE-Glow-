/// Capstone Glow - Skin Tone Detector v2 (Dart port of skin_tone_detector.py)
///
/// Classifies undertone (warm / cool / neutral) and Monk Skin Tone scale from
/// facial skin pixels, in OpenCV's 8-bit LAB colour space (0-255 per channel,
/// NOT standard CIELAB 0-100). This MUST use opencv_dart rather than a
/// hand-rolled LAB formula: the Monk swatches below are converted through the
/// same encoding, so a different formula would shift every comparison.
///
/// WHAT CHANGED IN v2 — mirrors the Python rewrite:
///
///   1. Samples CHEEK AND FOREHEAD PATCHES instead of running an HSV skin
///      mask over the whole image. That mask was selecting a median of ~52%
///      of the entire frame, so background, hair, neck and clothing entered
///      the average that decided undertone.
///
///   2. Removing the mask also removes its `V >= 70` floor, which discarded
///      dark pixels before averaging and biased the scale against darker
///      skin — the old code never produced a Monk value above 6.
///
///   3. Monk scale maps to the REAL published swatches by nearest neighbour
///      in LAB, replacing ten hand-picked lightness cutoffs that put 196 of
///      236 measured faces in the two LIGHTEST tones.
///
///   4. Undertone bands derived from the measured distribution. The old
///      [-2, 8] classified ~72% of faces "neutral".
///
/// This also fixes the performance problem by construction: the old version
/// walked EVERY pixel of a full-resolution photo with an FFI call per pixel,
/// on the UI isolate. Sampling nine small patches is a few hundred reads.
///
/// KNOWN LIMITATION: even with correct swatch mapping, ~97% of the reference
/// dataset lands in MST 5-6. The photos are not colour-calibrated and
/// uncontrolled lighting shifts a face several tones.
library;

import 'dart:io';
import 'dart:math' as math;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'eye_shape_detector.dart' show Landmark;

/// The published Monk Skin Tone Scale swatches, as sRGB 0-255 triples.
/// Verified against two independent sources (Wikipedia's Monk Skin Tone
/// Scale article and skintone.google). Do NOT edit these from memory —
/// they are a published standard, and the Python side uses the same values.
const List<List<int>> kMstRgb = [
  [0xf6, 0xed, 0xe4],
  [0xf3, 0xe7, 0xdb],
  [0xf7, 0xea, 0xd0],
  [0xea, 0xda, 0xba],
  [0xd7, 0xbd, 0x96],
  [0xa0, 0x7e, 0x56],
  [0x82, 0x5c, 0x43],
  [0x60, 0x41, 0x34],
  [0x3a, 0x31, 0x2a],
  [0x29, 0x24, 0x20],
];

/// Face-mesh indices sitting on flat skin, away from eyes, brows, nostrils
/// and lips. Identical to CHEEK_POINTS + FOREHEAD_POINTS in the Python file.
const List<int> kCheekPoints = [50, 280, 101, 330, 116, 345];
const List<int> kForeheadPoints = [151, 9, 8];
const int kPatchHalf = 6;

/// Undertone bands on (b - a). Terciles of the measured distribution
/// (n=236, mean +3.56, sd 5.33) — NOT hand-picked. Must match Python.
const double kUndertoneCoolBelow = 1.85;
const double kUndertoneWarmAbove = 4.77;

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

/// The Monk swatches in OpenCV 8-bit LAB — the same space the image pixels
/// are read in, so comparisons are apples to apples.
///
/// Precomputed rather than converted at runtime. These are constants, and
/// converting them per analysis would allocate and free 20 Mats for values
/// that never change. Each row is [L, a, b] and was produced by running the
/// verified sRGB hex in kMstRgb above through OpenCV's COLOR_BGR2Lab — the
/// identical conversion Python's skin_tone_detector.py performs at import,
/// so both platforms compare against the same numbers.
///
/// If kMstRgb is ever edited, regenerate these; do not hand-adjust them.
const List<List<double>> kMstLab = [
  [240.0, 129.0, 133.0], // MST 1  #f6ede4
  [235.0, 130.0, 135.0], // MST 2  #f3e7db
  [238.0, 128.0, 142.0], // MST 3  #f7ead0
  [223.0, 128.0, 146.0], // MST 4  #eadaba
  [199.0, 131.0, 151.0], // MST 5  #d7bd96
  [141.0, 136.0, 155.0], // MST 6  #a07e56
  [108.0, 140.0, 148.0], // MST 7  #825c43
  [78.0, 140.0, 141.0], // MST 8  #604134
  [54.0, 130.0, 134.0], // MST 9  #3a312a
  [37.0, 130.0, 132.0], // MST 10 #292420
];

/// Nearest Monk swatch in LAB (1-10). Mirrors Python's _monk_scale.
int _monkScale(double l, double a, double b) {
  var best = 1;
  var bestDist = double.infinity;
  for (var i = 0; i < kMstLab.length; i++) {
    final s = kMstLab[i];
    final dl = s[0] - l;
    final da = s[1] - a;
    final db = s[2] - b;
    final d = math.sqrt(dl * dl + da * da + db * db);
    if (d < bestDist) {
      bestDist = d;
      best = i + 1;
    }
  }
  return best;
}

/// Undertone plus a confidence reflecting distance to the nearest band edge.
/// Mirrors Python's _undertone.
({String tone, String confidence}) _undertone(double diff) {
  final String tone;
  if (diff > kUndertoneWarmAbove) {
    tone = "warm";
  } else if (diff < kUndertoneCoolBelow) {
    tone = "cool";
  } else {
    tone = "neutral";
  }

  final margin = math.min((diff - kUndertoneCoolBelow).abs(),
      (diff - kUndertoneWarmAbove).abs());
  final String confidence;
  if (margin < 0.5) {
    confidence = "low";
  } else if (margin < 1.5) {
    confidence = "medium";
  } else {
    confidence = "high";
  }
  return (tone: tone, confidence: confidence);
}

/// Mirrors detect_skin_tone(image_path, landmarks) — same sampling points,
/// same Monk swatch mapping, same undertone bands.
///
/// [landmarks] is the face mesh (MeshResult.meshLandmarks). Required: unlike
/// Python this does NOT fall back to detecting its own, because the caller
/// already runs the mesh for eye shape and running it twice on a phone is
/// wasteful. Returns an error result if it is missing or too short.
SkinToneResult detectSkinTone(String imagePath, List<Landmark> landmarks) {
  if (!File(imagePath).existsSync()) {
    return const SkinToneResult(error: "Could not load image");
  }
  // Highest index sampled is 345, so anything shorter cannot be a face mesh.
  if (landmarks.length < 346) {
    return const SkinToneResult(error: "No face landmarks available");
  }

  final image = cv.imread(imagePath);
  if (image.isEmpty) {
    image.dispose();
    return const SkinToneResult(error: "Could not load image");
  }

  // Mats hold native memory Dart's GC will not reclaim. Released in the
  // finally block so an exception mid-analysis cannot skip cleanup.
  cv.Mat? labImage;

  try {
    labImage = cv.cvtColor(image, cv.COLOR_BGR2Lab);
    final imgW = labImage.cols;
    final imgH = labImage.rows;

    // Average LAB over small patches centred on cheek and forehead points.
    // These pixels are skin by construction, so there is no HSV mask and no
    // V>=70 floor — which is what removes the bias against darker skin.
    //
    // This is also why the old performance problem is gone: the previous
    // version made two FFI calls for EVERY pixel of a full-resolution photo
    // on the UI isolate. Nine 13x13 patches is roughly 1,500 reads
    // regardless of image size.
    double sumL = 0, sumA = 0, sumB = 0;
    int count = 0;

    for (final idx in [...kCheekPoints, ...kForeheadPoints]) {
      final lm = landmarks[idx];
      // Landmarks are already pixel-space (see mesh_provider.dart) — do not
      // multiply by image dimensions.
      final cx = lm.x.round();
      final cy = lm.y.round();
      final x0 = math.max(0, cx - kPatchHalf);
      final x1 = math.min(imgW, cx + kPatchHalf + 1);
      final y0 = math.max(0, cy - kPatchHalf);
      final y1 = math.min(imgH, cy + kPatchHalf + 1);
      if (x1 <= x0 || y1 <= y0) continue;

      for (int y = y0; y < y1; y++) {
        for (int x = x0; x < x1; x++) {
          final px = labImage.atPixel(y, x);
          sumL += px[0];
          sumA += px[1];
          sumB += px[2];
          count++;
        }
      }
    }

    if (count == 0) {
      return const SkinToneResult(error: "Could not sample skin pixels");
    }

    final avgL = sumL / count;
    final avgA = sumA / count;
    final avgB = sumB / count;

    // b - a is positive for yellow (warm), negative for pink/red (cool).
    // Both channels use OpenCV's 128-centred encoding, but the offset
    // cancels in the difference.
    final u = _undertone(avgB - avgA);

    return SkinToneResult(
      skinTone: u.tone,
      monkScale: _monkScale(avgL, avgA, avgB),
      confidence: u.confidence,
      avgLightness: double.parse(avgL.toStringAsFixed(2)),
      avgWarmth: double.parse(avgB.toStringAsFixed(2)),
      avgRedness: double.parse(avgA.toStringAsFixed(2)),
    );
  } finally {
    image.dispose();
    labImage?.dispose();
  }
}