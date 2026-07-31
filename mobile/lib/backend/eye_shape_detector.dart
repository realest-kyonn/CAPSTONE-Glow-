/// Capstone Glow - Eye Shape Detector (Dart port of eye_shape_detector.py)
///
/// Eye Shapes Detected:
///   - almond    : Balanced proportions, no dominant feature (the default)
///   - round     : Tall aperture relative to width
///   - hooded    : Upper lid sits low relative to the lower lid
///   - downturned: Outer corner low relative to the population norm
///   - upturned  : Outer corner high relative to the population norm
///
///   - monolid   : NOT DETECTED — see _classify(). Monolid is the absence
///                 of a lid crease, a texture feature no landmark can see.
///                 Left out deliberately rather than advertised and never
///                 returned, which is what the previous version did.
///
/// Detection Method (identical thresholds to the Python version):
///   - MRD1/MRD2 (iris-normalised lid position) -> hooded
///   - Outer corner angle vs population norm    -> upturned / downturned
///   - Eye Aspect Ratio (EAR)                   -> round vs almond
///
/// WHAT CHANGED, AND WHY: the previous version could only ever return three
/// of its six advertised shapes. The corner angle was compared against zero
/// when a normal eye has a positive canthal tilt (measured mean +6.63 deg,
/// never negative across 308 faces), making "downturned" unreachable and
/// forcing ~81% of faces to "upturned". Separately the "lid crease" measure
/// used landmarks that are not on a crease, giving a range of 0.788-2.089
/// against thresholds of 0.15/0.22 — "hooded" and "monolid" could never
/// fire. Both defects were confirmed by measuring the project's dataset.
///
/// Dependency: landmarks extracted by face_detection_tflite — see
/// mesh_provider.dart. Verified against the installed 6.6.3 source.
///
/// STILL UNVERIFIED: the mesh indices below (33, 133, 159, 145, ...) assume
/// this package orders its 468 mesh points using the standard MediaPipe
/// topology. The package describes itself as a port of that model, and the
/// iris layout matched its documented constants exactly, but the mesh
/// ordering has NOT been confirmed empirically. Before trusting mobile eye
/// results, draw landmarks 33 and 263 on a real photo and confirm they land
/// on the outer eye corners. If they do not, every measurement here is
/// invalid regardless of the fixes above.
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
library;

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
  const _EyeIndices({
    required this.innerCorner,
    required this.outerCorner,
    required this.upperLidTop,
    required this.lowerLidBot,
  });
}

const _leftEye = _EyeIndices(
  innerCorner: 133,
  outerCorner: 33,
  upperLidTop: 159,
  lowerLidBot: 145,
);

const _rightEye = _EyeIndices(
  innerCorner: 362,
  outerCorner: 263,
  upperLidTop: 386,
  lowerLidBot: 374,
);

const int _faceLeftEdge = 234;
const int _faceRightEdge = 454;

// ── IRIS INDICES ─────────────────────────────────────────────────────
// These index into MeshResult.irisLandmarks, NOT into the mesh. This is
// the one place the Dart port cannot mirror Python structurally.
//
// Python's face_landmarker.task returns 478 mesh points with the iris at
// 468-477. face_detection_tflite instead returns a 468-point mesh plus a
// SEPARATE 152-point iris list laid out as:
//
//     left  eye: 0-75    (71 eye-contour points, then iris at 71-75)
//     right eye: 76-151  (71 eye-contour points, then iris at 147-151)
//
// Confirmed by reading the installed 6.6.3 source directly
// (_kLeftIrisStart = 71, _kRightIrisStart = 147 in face_detector.dart),
// not inferred from documentation.
const List<int> _leftIris = [71, 72, 73, 74, 75];
const List<int> _rightIris = [147, 148, 149, 150, 151];

/// Minimum length of irisLandmarks for the hooding measure to be usable.
const int _kIrisPointCount = 152;

// ── CLASSIFICATION THRESHOLDS ────────────────────────────────────────
// Identical values to eye_shape_detector.py — derived by measuring the
// project's own dataset (n=364), not chosen by hand. If these are ever
// re-derived, change BOTH files together or the platforms will disagree.
//
// The angle cutoffs are not centred on zero because a normal eye has a
// naturally positive canthal tilt (measured mean +6.63 deg, never once
// negative across 308 faces). Comparing against zero is what made
// "downturned" unreachable and forced ~81% of faces to "upturned".
const double kMrdHooded = 0.707; // MRD1/MRD2 below this -> hooded
const double kAngleUpturned = 8.68; // degrees, above -> upturned
const double kAngleDownturned = 4.58; // degrees, below -> downturned
const double kEarRound = 0.387; // EAR above this -> round

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

/// Geometric centre of one eye's 5 iris keypoints.
///
/// Uses the centroid rather than indexing a "centre" point, because
/// face_detection_tflite does NOT guarantee the iris points are ordered
/// with the centre first — its own irisCenterFromPoints() (face_types.dart)
/// computes the centroid and returns the nearest point to it. Python can
/// index directly since MediaPipe documents 468/473 as the iris centres;
/// here we must derive it. The 4 rim points are symmetric about the centre
/// so the centroid lands in the same place to sub-pixel precision, and any
/// residual difference cancels in the MRD1/MRD2 ratio.
EyePoint _irisCentre(List<Landmark> iris, List<int> idx) {
  double sx = 0, sy = 0;
  for (final i in idx) {
    sx += iris[i].x;
    sy += iris[i].y;
  }
  return EyePoint(sx / idx.length, sy / idx.length);
}

/// Widest span across one eye's 5 iris keypoints, in pixels.
///
/// Scale reference: iris diameter is ~11.7mm in virtually all adults, so
/// dividing by it makes the lid measurement independent of face size and
/// camera distance.
double _irisDiameter(List<Landmark> iris, List<int> idx) {
  double maxD = 0;
  for (final a in idx) {
    for (final b in idx) {
      final d = _euclidean(
        EyePoint(iris[a].x, iris[a].y),
        EyePoint(iris[b].x, iris[b].y),
      );
      if (d > maxD) maxD = d;
    }
  }
  return maxD;
}

/// MRD1/MRD2 — the hooding measure replacing the old _lidRatio.
///
/// MRD1 is pupil centre to UPPER lid margin; MRD2 is pupil centre to LOWER
/// lid margin. Both are standard clinical measures of eyelid position.
/// Hooding is specifically the upper lid sitting low, so their ratio
/// isolates that while cancelling overall eye size.
///
/// The old _lidRatio it replaces was not measuring a crease at all —
/// landmarks 246/466 sit on the eye contour near the outer corner, and the
/// resulting value proved 90.4% explained by EAR alone. This measure is
/// statistically independent of EAR (r^2 = 0.001) on the same dataset.
///
/// Returns 1.0 (neutral, "not hooded") when iris data is missing or the
/// geometry is degenerate, so the classifier falls back to the angle/EAR
/// rules rather than labelling everyone hooded.
double _mrdRatio(
  List<Landmark> landmarks,
  List<Landmark> iris,
  _EyeIndices eye,
  List<int> irisIdx,
) {
  if (iris.length < _kIrisPointCount) return 1.0;

  final diam = _irisDiameter(iris, irisIdx);
  if (diam <= 0) return 1.0;

  final centre = _irisCentre(iris, irisIdx);
  final top = _getXY(landmarks, eye.upperLidTop);
  final bottom = _getXY(landmarks, eye.lowerLidBot);

  // Image y grows downward, so "centre minus top" is the upward distance.
  final mrd1 = (centre.y - top.y) / diam;
  final mrd2 = (bottom.y - centre.y) / diam;

  if (mrd2 <= 0) return 1.0;
  return mrd1 / mrd2;
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

/// Order matters and mirrors the Python version exactly. Hooding is a
/// structural lid feature that dominates makeup advice regardless of tilt,
/// so it is tested first; tilt next; the EAR/round test last, being the
/// weakest discriminator.
///
/// MONOLID IS NOT RETURNED, deliberately. It is defined by the absence of a
/// supratarsal crease — a skin-texture feature no landmark arrangement can
/// observe. The previous code advertised it but its test could never fire,
/// so omitting it states an existing limitation rather than introducing
/// one. eyeShapeMakeup below keeps its monolid entry so nothing breaks if
/// texture-based detection is added later.
String _classify(double ear, double angle, double mrd) {
  if (mrd < kMrdHooded) return "hooded";
  if (angle > kAngleUpturned) return "upturned";
  if (angle < kAngleDownturned) return "downturned";
  if (ear > kEarRound) return "round";
  return "almond";
}

/// Confidence from distance to the nearest decision boundary.
///
/// The previous version reported "high" whenever a value sat outside the
/// middle band, so a face 0.001 from flipping class was called high
/// confidence — backwards. Roughly 47% of faces in this project's dataset
/// sit within 10% of some cutoff, so this must be honest to be useful.
/// Margins are normalised by their threshold so the three metrics, which
/// have very different units, are comparable.
String _confidence(double ear, double angle, double mrd) {
  final margins = <double>[
    (mrd - kMrdHooded).abs() / kMrdHooded,
    (angle - kAngleUpturned).abs() / kAngleUpturned,
    (angle - kAngleDownturned).abs() / kAngleDownturned,
    (ear - kEarRound).abs() / kEarRound,
  ];
  final nearest = margins.reduce((a, b) => a < b ? a : b);

  if (nearest < 0.05) return "low";
  if (nearest < 0.15) return "medium";
  return "high";
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
/// [irisLandmarks] is MeshResult.irisLandmarks — the SEPARATE 152-point
/// iris list, not part of the mesh. Optional so existing call sites keep
/// compiling; when omitted or short, hooding is skipped and the classifier
/// degrades to the angle/EAR rules rather than failing.
EyeShapeResult detectEyeShape(
  List<Landmark> landmarks, {
  List<Landmark> irisLandmarks = const [],
}) {
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
    // Averaging the eyes is load-bearing for the angle: head roll raises
    // one eye's measured tilt and lowers the other's by the same amount,
    // so the mean cancels it. Do not switch to a single eye.
    final avgAngle = (leftAngle + rightAngle) / 2;

    final leftMrd = _mrdRatio(landmarks, irisLandmarks, _leftEye, _leftIris);
    final rightMrd = _mrdRatio(landmarks, irisLandmarks, _rightEye, _rightIris);
    final avgMrd = (leftMrd + rightMrd) / 2;

    final inter = _interEyeRatio(landmarks);

    final eyeShape = _classify(avgEar, avgAngle, avgMrd);
    final confidence = _confidence(avgEar, avgAngle, avgMrd);

    return EyeShapeResult(
      eyeShape: eyeShape,
      confidence: confidence,
      metrics: {
        "eye_aspect_ratio": double.parse(avgEar.toStringAsFixed(4)),
        "outer_corner_angle": double.parse(avgAngle.toStringAsFixed(2)),
        "mrd_ratio": double.parse(avgMrd.toStringAsFixed(4)),
        // Reported for diagnostics only — no rule consumes it.
        "inter_eye_ratio": double.parse(inter.toStringAsFixed(4)),
      },
      error: irisLandmarks.length < _kIrisPointCount
          ? "No iris data — hooding not evaluated"
          : null,
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