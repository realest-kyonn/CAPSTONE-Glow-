/// Capstone Glow - Face Mesh Provider
///
/// Wraps face_detection_tflite (upgraded to 6.6.3 to resolve an Android
/// namespace conflict with tflite_flutter — see project notes) to provide
/// the bounding box (for face shape crop) and mesh points (for eye shape)
/// needed by the rest of the Dart backend port.
///
/// NOTE ON VERSION HISTORY: this package went through several breaking-
/// change releases between 4.0.0 (originally verified) and 6.6.3 (current).
/// Re-confirm any assumption below against the actual installed version's
/// docs/example if something here stops compiling after a future upgrade.
///
/// CONFIRMED FACTS (re-verified against 6.6.3's public docs):
///   - Coordinates (boundingBox, landmarks, mesh, eyes) are in PIXEL
///     space already — NOT normalized 0-1 like Python's MediaPipe.
///     Do not multiply by image width/height again.
///   - face.mesh is nullable (FaceMesh?) — check for null, not .isEmpty
///   - face.originalSize is a property on the Face object itself.
///   - detector.getOriginalSize(bytes) — REMOVED in 6.x (existed in 4.0.0).
///     Fixed here by decoding dimensions directly via the `image` package
///     instead, which doesn't depend on face_detection_tflite's API at
///     all — avoids this breaking again on a future version bump.
///   - detectFaces() takes raw image bytes (e.g. JPEG), not a decoded
///     img.Image or a file path directly
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:image/image.dart' as img;
import 'eye_shape_detector.dart' as eyes;
import 'face_shape_detector.dart' show FaceBoundingBox;

class MeshResult {
  final FaceBoundingBox? boundingBox;
  final List<eyes.Landmark> meshLandmarks;

  /// Iris landmarks, kept SEPARATE from meshLandmarks because this package
  /// structures them differently from Python's MediaPipe.
  ///
  /// Python's face_landmarker.task returns 478 points with the iris living
  /// inside the mesh at indices 468-477. This package returns a 468-point
  /// mesh and a separate 152-point iris list (76 per eye: 71 eye-contour
  /// points then 5 iris keypoints). Confirmed against the installed 6.6.3
  /// source, not assumed — see _kLeftIrisStart/_kRightIrisStart in the
  /// package's face_detector.dart.
  ///
  /// Empty when the detector ran without iris data (FaceDetectionMode below
  /// must be .full) — eye_shape_detector degrades gracefully in that case.
  final List<eyes.Landmark> irisLandmarks;

  final int imgWidth;
  final int imgHeight;
  final String? error;

  const MeshResult({
    this.boundingBox,
    this.meshLandmarks = const [],
    this.irisLandmarks = const [],
    required this.imgWidth,
    required this.imgHeight,
    this.error,
  });

  bool get hasFace => boundingBox != null;

  /// True when iris data is usable for the hooding measure.
  bool get hasIris => irisLandmarks.length >= 152;
}

/// Fraction of the detected box height added ABOVE the BlazeFace box before
/// it reaches the face-shape crop.
///
/// THIS IS DELIBERATELY NOT MIRRORED IN PYTHON. Do not "fix" the
/// inconsistency by removing it — doing so silently costs ~2.75 accuracy
/// points. Python crops MTCNN boxes, which is what the model was trained
/// on and needs no correction. Flutter has no MTCNN, so it uses BlazeFace,
/// whose boxes are measurably different: they sit lower (y offset +0.162 of
/// box height) and are shorter (-0.102), cropping away forehead and
/// hairline. That region is exactly what separates heart / oval / square,
/// so the model was being fed faces missing their most discriminative part.
///
/// Measured on the project's own held-out test set, all arms scored on
/// identical images:
///
///     BlazeFace, uncorrected : 90.75%
///     BlazeFace, calibrated  : 93.50%   <- this constant
///     MTCNN (reference)      : 92.75%
///
/// The value was grid-searched on 300 images, then validated on 400
/// DIFFERENT images the search never saw. The gain held (+2.75, versus
/// +2.00 on the tuning set), and a McNemar-style check gave 16 predictions
/// newly correct against 5 newly wrong — so this is genuine reframing, not
/// noise being reshuffled.
///
/// Calibrated mobile reaches PARITY with the reference pipeline. The +0.75
/// over MTCNN is within noise at n=400 and should not be claimed as an
/// improvement.
///
/// Width is left alone on purpose: the crop step forces a square by growing
/// width to match height, so horizontal adjustments are overwritten. That
/// was confirmed empirically — every x_inset value scored identically.
const double kBlazeToMtcnnTopPad = 0.25;

class MeshProvider {
  MeshProvider._(this._detector);

  final FaceDetector _detector;

  /// Initialize once at app startup, same lifecycle as FaceShapeDetector
  /// and RecommendationEngine — do not re-initialize per photo.
  static Future<MeshProvider> load({
    FaceDetectionModel model = FaceDetectionModel.frontCamera,
  }) async {
    final detector = FaceDetector();
    await detector.initialize(model: model);
    return MeshProvider._(detector);
  }

  /// Runs detection on a captured photo file. Uses FaceDetectionMode.full
  /// since we need both the mesh (eye shape math) and eyes (if ever used
  /// for iris-based features later) in one pass.
  Future<MeshResult> analyzePhoto(String imagePath) async {
    final Uint8List bytes = await File(imagePath).readAsBytes();

    final List<Face> faces = await _detector.detectFaces(
      bytes,
      mode: FaceDetectionMode.full,
    );

    if (faces.isEmpty) {
      // getOriginalSize() no longer exists on FaceDetector in 6.x — decode
      // dimensions directly instead, independent of this package's API.
      final decoded = img.decodeImage(bytes);
      final width = decoded?.width ?? 0;
      final height = decoded?.height ?? 0;

      return MeshResult(
        imgWidth: width,
        imgHeight: height,
        error: "No face detected",
      );
    }

    final face = faces.first;
    final size = face.originalSize;

    // boundingBox.topLeft / .bottomRight are already pixel-space Points.
    final bb = face.boundingBox;
    final rawX = bb.topLeft.x.round();
    final rawY = bb.topLeft.y.round();
    final rawW = (bb.bottomRight.x - bb.topLeft.x).round();
    final rawH = (bb.bottomRight.y - bb.topLeft.y).round();

    // BlazeFace-to-MTCNN crop calibration. See kBlazeToMtcnnTopPad below.
    final box = FaceBoundingBox(
      rawX,
      rawY - (kBlazeToMtcnnTopPad * rawH).round(),
      rawW,
      rawH + (kBlazeToMtcnnTopPad * rawH).round(),
    );

    // face.mesh is nullable — check == null, not .isEmpty.
    final meshPoints = <eyes.Landmark>[];
    final faceMesh = face.mesh;
    if (faceMesh != null) {
      for (final p in faceMesh.points) {
        // Already pixel space — pass straight through, no scaling.
        meshPoints.add(eyes.Landmark(p.x, p.y));
      }
    }

    // Iris points come back as their OWN list, not folded into the mesh —
    // this is the key structural difference from Python's MediaPipe, where
    // the iris occupies mesh indices 468-477 of a 478-point array. Here the
    // mesh stays 468 points and face.irisPoints holds 152 (76 per eye).
    // Requires FaceDetectionMode.full above; empty otherwise.
    final irisPoints = <eyes.Landmark>[];
    for (final p in face.irisPoints) {
      irisPoints.add(eyes.Landmark(p.x, p.y));
    }

    return MeshResult(
      boundingBox: box,
      meshLandmarks: meshPoints,
      irisLandmarks: irisPoints,
      imgWidth: size.width.toInt(),
      imgHeight: size.height.toInt(),
      error: faceMesh == null ? "Face detected but no mesh returned" : null,
    );
  }

  /// Releases the detector and its background isolate.
  ///
  /// This used to be an empty stub with a comment suggesting someone check
  /// whether the package provides a disposal method. It does:
  /// FaceDetector.dispose() at face_detector.dart:950 in 6.6.3. Until this
  /// was wired up, every analysis leaked a detector plus its isolate.
  ///
  /// Async because the underlying call is — callers that cannot await
  /// (e.g. State.dispose) may safely fire-and-forget it.
  Future<void> dispose() async {
    await _detector.dispose();
  }
}