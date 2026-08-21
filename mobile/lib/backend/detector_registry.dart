/// Capstone Glow - Detector Registry
///
/// Holds the expensive, reusable detectors so they load ONCE and are shared
/// across every analysis, instead of being re-created (and thrown away) per
/// photo.
///
/// Why this exists: FaceShapeDetector loads a ~130MB TFLite interpreter and
/// MeshProvider spins up a detector plus a background isolate. Building both
/// on every capture was slow and an out-of-memory risk on mid-range phones —
/// the source files' own docs already said "load once at startup, keep the
/// instance alive." This is that single owner.
///
/// Lifetime: these live for the whole app session. They are deliberately NOT
/// disposed per analysis — that is the entire point. The one bounded ~130MB
/// footprint is held once and reused; the OS reclaims it when the process
/// ends. (This is different from the per-photo leaks that were fixed
/// earlier: those created a NEW instance each time and dropped it. Here there
/// is exactly one instance, reused.)
///
/// Concurrency: the load Future is cached, so if two calls race, both await
/// the same load rather than starting two. A failed load is not cached, so
/// the next call can retry.
library;

import 'face_shape_detector.dart';
import 'mesh_provider.dart';

class DetectorRegistry {
  DetectorRegistry._();
  static final DetectorRegistry instance = DetectorRegistry._();

  Future<MeshProvider>? _meshFuture;
  Future<FaceShapeDetector>? _faceShapeFuture;

  /// The shared MeshProvider, loading it on first use.
  Future<MeshProvider> meshProvider() {
    return _meshFuture ??= MeshProvider.load().catchError((Object e) {
      _meshFuture = null; // let the next call retry after a failed load
      throw e;
    });
  }

  /// The shared FaceShapeDetector, loading the 130MB model on first use.
  Future<FaceShapeDetector> faceShapeDetector() {
    return _faceShapeFuture ??= FaceShapeDetector.load().catchError((Object e) {
      _faceShapeFuture = null;
      throw e;
    });
  }

  /// Releases both detectors and clears the cache. Not called per analysis —
  /// only if the whole registry should be torn down (e.g. an explicit app
  /// reset). After this, the next accessor reloads from scratch.
  Future<void> disposeAll() async {
    final mesh = _meshFuture;
    final face = _faceShapeFuture;
    _meshFuture = null;
    _faceShapeFuture = null;
    if (face != null) {
      (await face).dispose();
    }
    if (mesh != null) {
      await (await mesh).dispose();
    }
  }
}
