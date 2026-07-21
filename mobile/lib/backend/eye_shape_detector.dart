/// Capstone Glow - Eye Shape Detector (Dart port of eye_shape_detector.py)
///
/// Eye Shapes Detected:
///   - almond    : Most versatile, slightly pointed ends
///   - round     : Visible white above/below iris, circular appearance
///   - monolid   : Little to no crease visible on upper lid
///   - hooded    : Upper lid partially hidden by brow bone/skin fold
///   - downturned: Outer corners angle downward
///   - upturned  : Outer corners angle upward
///
/// Detection Method (identical thresholds to the Python version):
///   - Eye Aspect Ratio (EAR)  -> round vs almond vs hooded
///   - Outer corner angle      -> downturned vs upturned
///   - Lid visibility ratio    -> hooded vs monolid
///   - Inter-eye distance      -> close-set vs normal
///
/// Dependency: this file expects landmarks already extracted by
/// face_detection_tflite (confirmed v4.0.0 API — see mesh_provider.dart).
///
/// IMPORTANT — COORDINATE SPACE (confirmed against the real installed
/// package example, not assumed):
/// face_detection_tflite returns face.mesh?.points as PIXEL-space
/// coordinates already (same space as the original image), NOT
/// normalized 0-1 like Python's MediaPipe FaceLandmarker. This is
/// DIFFERENT from the original Python backend's landmark convention.
///
/// Because of this, detectEyeShape() below does NOT multiply by
/// imgW/imgH — the Landmark values passed in must already be real
/// pixel coordinates. Do not normalize them, and do not multiply them
/// by image dimensions again — that would be a second, inverse version
/// of the same double-preprocessing bug already fixed once in Python.
library eye_shape_detector;

import 'dart:math' as math;

/// Point already in pixel space (as returned by
/// face_detection_tflite's face.mesh.points).
class Landmark {
  final double x;
  final double y;
  const Landmark(this.x, this.y);
}

class EyePoint {
  final double x;
  final double y;
  const EyePoint(this.x, this.y);
}

class EyeShapeResult {
  final String eyeShape;
  final String confidence; // "low" | "medium" | "high"
  final Map<String, double> metrics;
  final String? error;

  const EyeShapeResult({
    required this.eyeShape,
    required this.confidence,
    required this.metrics,
    this.error,
  });
}

class EyeRecommendation {
  final String eyeliner;
  final String eyeshadowTechnique;
  final String why;
  const EyeRecommendation(this.eyeliner, this.eyeshadowTechnique, this.why);
}

// ── LANDMARK INDICES (identical to Python) ─────────────────────────
// CAVEAT — NOT YET VERIFIED: these indices assume face_detection_tflite's
// face.mesh.points list uses the same point ordering as the standard
// MediaPipe 468-point face mesh topology (since this package is a port
// of the same underlying model family). This is a reasonable assumption
// given the package's own description ("port of Google's MediaPipe face
// mesh model"), but it has NOT been empirically confirmed against this
// specific package's actual output. Before trusting eye shape results,
// sanity-check: print landmarks[33] and landmarks[263] for a real photo
// and confirm they land near the outer eye corners visually (e.g. by
// drawing them on the image), not just trust the index numbers blindly.
class _EyeIndices {
  final int innerCorner;
  final int outerCorner;
  final int upperLidTop;
  final int lowerLidBot;
  final int lidCrease;
  const _EyeIndices({
    required this.innerCorner,
    required this.outerCorner,
    required this.upperLidTop,
    required this.lowerLidBot,
    required this.lidCrease,
  });
}

const _leftEye = _EyeIndices(
  innerCorner: 133,
  outerCorner: 33,
  upperLidTop: 159,
  lowerLidBot: 145,
  lidCrease: 246,
);

const _rightEye = _EyeIndices(
  innerCorner: 362,
  outerCorner: 263,
  upperLidTop: 386,
  lowerLidBot: 374,
  lidCrease: 466,
);

const int _faceLeftEdge = 234;
const int _faceRightEdge = 454;

// ── HELPERS ──────────────────────────────────────────────────────────
double _euclidean(EyePoint p1, EyePoint p2) {
  final dx = p1.x - p2.x;
  final dy = p1.y - p2.y;
  return math.sqrt(dx * dx + dy * dy);
}

EyePoint _getXY(List<Landmark> landmarks, int index) {
  final lm = landmarks[index];
  return EyePoint(lm.x, lm.y); // already pixel space — no scaling needed
}

double _ear(List<Landmark> landmarks, _EyeIndices eye) {
  final inner = _getXY(landmarks, eye.innerCorner);
  final outer = _getXY(landmarks, eye.outerCorner);
  final top = _getXY(landmarks, eye.upperLidTop);
  final bottom = _getXY(landmarks, eye.lowerLidBot);
  final width = _euclidean(inner, outer);
  final height = _euclidean(top, bottom);
  return width > 0 ? height / width : 0.0;
}

double _cornerAngle(List<Landmark> landmarks, _EyeIndices eye) {
  final inner = _getXY(landmarks, eye.innerCorner);
  final outer = _getXY(landmarks, eye.outerCorner);
  final dx = outer.x - inner.x;
  final dy = outer.y - inner.y;
  if (dx == 0) return 0.0;
  return _degrees(math.atan2(-dy, dx.abs()));
}

double _lidRatio(List<Landmark> landmarks, _EyeIndices eye) {
  final top = _getXY(landmarks, eye.upperLidTop);
  final crease = _getXY(landmarks, eye.lidCrease);
  final bottom = _getXY(landmarks, eye.lowerLidBot);
  final total = _euclidean(top, bottom);
  return total > 0 ? _euclidean(crease, top) / total : 1.0;
}

double _interEyeRatio(List<Landmark> landmarks) {
  try {
    final lInner = _getXY(landmarks, _leftEye.innerCorner);
    final rInner = _getXY(landmarks, _rightEye.innerCorner);
    final faceLeft = _getXY(landmarks, _faceLeftEdge);
    final faceRight = _getXY(landmarks, _faceRightEdge);
    final inter = _euclidean(lInner, rInner);
    final faceW = _euclidean(faceLeft, faceRight);
    return faceW > 0 ? inter / faceW : 0.3;
  } catch (_) {
    return 0.3;
  }
}

double _degrees(double radians) => radians * 180.0 / math.pi;

String _classify(double ear, double angle, double lid, double inter) {
  if (lid < 0.15) return "hooded";
  if (lid < 0.22 && ear < 0.28) return "monolid";
  if (angle < -5.0) return "downturned";
  if (angle > 5.0) return "upturned";
  if (ear > 0.35) return "round";
  return "almond";
}

// ── MAIN ENTRY POINT ─────────────────────────────────────────────────
/// Classifies eye shape given a face mesh point list from
/// face_detection_tflite (face.mesh?.points — already pixel-space,
/// confirmed against v4.0.0's real example code).
///
/// IMPORTANT: unlike Python's MediaPipe (normalized 0-1, needs
/// imgW/imgH to convert to pixels), face_detection_tflite's mesh
/// points are ALREADY in pixel space. Pass them straight through —
/// do not scale by image dimensions.
EyeShapeResult detectEyeShape(List<Landmark> landmarks) {
  if (landmarks.isEmpty) {
    return const EyeShapeResult(
      eyeShape: "almond",
      confidence: "low",
      metrics: {},
      error: "No face detected",
    );
  }

  try {
    final leftEar = _ear(landmarks, _leftEye);
    final rightEar = _ear(landmarks, _rightEye);
    final avgEar = (leftEar + rightEar) / 2;

    final leftAngle = _cornerAngle(landmarks, _leftEye);
    final rightAngle = _cornerAngle(landmarks, _rightEye);
    final avgAngle = (leftAngle + rightAngle) / 2;

    final leftLid = _lidRatio(landmarks, _leftEye);
    final rightLid = _lidRatio(landmarks, _rightEye);
    final avgLid = (leftLid + rightLid) / 2;

    final inter = _interEyeRatio(landmarks);

    final eyeShape = _classify(avgEar, avgAngle, avgLid, inter);
    final confidence = (avgEar >= 0.28 && avgEar <= 0.35 && avgAngle >= -5 && avgAngle <= 5)
        ? "medium"
        : "high";

    return EyeShapeResult(
      eyeShape: eyeShape,
      confidence: confidence,
      metrics: {
        "eye_aspect_ratio": double.parse(avgEar.toStringAsFixed(4)),
        "outer_corner_angle": double.parse(avgAngle.toStringAsFixed(2)),
        "lid_visibility_ratio": double.parse(avgLid.toStringAsFixed(4)),
        "inter_eye_ratio": double.parse(inter.toStringAsFixed(4)),
      },
      error: null,
    );
  } catch (e) {
    return EyeShapeResult(
      eyeShape: "almond",
      confidence: "low",
      metrics: const {},
      error: "Detection error: $e",
    );
  }
}

// ── EYE SHAPE MAKEUP LOOKUP (identical content to Python) ────────────
const Map<String, EyeRecommendation> eyeShapeMakeup = {
  "almond": EyeRecommendation(
    "Classic thin liner or winged liner — almond eyes are the most versatile.",
    "Soft wash of color on lid with deeper shade on outer corner.",
    "Almond eyes are naturally balanced — almost any technique flatters them.",
  ),
  "round": EyeRecommendation(
    "Winged or cat-eye liner extending past the outer corner to elongate.",
    "Focus darker shades on outer corner, blend slightly upward.",
    "Extending liner outward creates the illusion of length on round eyes.",
  ),
  "monolid": EyeRecommendation(
    "Graphic bold liner on the upper lid — avoid tight lining.",
    "Bold color across the full lid — no crease blending needed.",
    "Bold lid color and graphic liner create definition on monolid eyes.",
  ),
  "hooded": EyeRecommendation(
    "Thin liner placed slightly above the actual lash line.",
    "Apply shadow above where the hood falls so it stays visible.",
    "Placing liner and shadow higher ensures they show when the eye is open.",
  ),
  "downturned": EyeRecommendation(
    "Flick liner upward at the outer corner to lift the eye.",
    "Darker shade on upper outer corner blended upward to lift.",
    "Upward flicks counteract the downward angle of the outer corner.",
  ),
  "upturned": EyeRecommendation(
    "Keep liner close to lash line — avoid heavy outer wing.",
    "Blend shadow slightly downward on outer corner to balance.",
    "Keeping liner close to the lash line balances naturally upturned eyes.",
  ),
};

EyeRecommendation getEyeRecommendations(String eyeShape) {
  return eyeShapeMakeup[eyeShape] ?? eyeShapeMakeup["almond"]!;
}