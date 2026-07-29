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
  final int imgWidth;
  final int imgHeight;
  final String? error;

  const MeshResult({
    this.boundingBox,
    this.meshLandmarks = const [],
    required this.imgWidth,
    required this.imgHeight,
    this.error,
  });

  bool get hasFace => boundingBox != null;
}

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
    final box = FaceBoundingBox(
      bb.topLeft.x.round(),
      bb.topLeft.y.round(),
      (bb.bottomRight.x - bb.topLeft.x).round(),
      (bb.bottomRight.y - bb.topLeft.y).round(),
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

    return MeshResult(
      boundingBox: box,
      meshLandmarks: meshPoints,
      imgWidth: size.width.toInt(),
      imgHeight: size.height.toInt(),
      error: faceMesh == null ? "Face detected but no mesh returned" : null,
    );
  }

  void dispose() {
    // Check face_detection_tflite 6.6.3's actual API for a dispose()/close()
    // method before assuming none exists — verify against the currently
    // installed version rather than trusting this comment from an earlier
    // version check.
  }
}