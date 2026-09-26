import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ValidatedPhoto {
  final Uint8List bytes;
  final ui.Size size;
  final Map<FaceContourType, List<ui.Offset>> contours;
  final ui.Rect faceBounds;
  const ValidatedPhoto(this.bytes, this.size, this.contours, this.faceBounds);
}

class ShadeFaceService {
  Future<ValidatedPhoto> validate(Uint8List source) async {
    // Bake EXIF rotation into the pixels so detection and painting use the
    // same orientation and coordinates. Never overwrite the user's photo.
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      throw Exception('Please choose a supported JPG or PNG photo.');
    }
    var image = img.bakeOrientation(decoded);
    if (image.width > 1600 || image.height > 1600) {
      image = image.width >= image.height
          ? img.copyResize(image, width: 1600)
          : img.copyResize(image, height: 1600);
    }
    final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/shade_${DateTime.now().microsecondsSinceEpoch}.jpg');
    FaceDetector? counter;
    FaceDetector? contourDetector;
    try {
      await file.writeAsBytes(bytes, flush: true);
      final input = InputImage.fromFilePath(file.path);
      // Separate pass: contour mode primarily returns contours for the most
      // prominent face, so don't use it alone to count faces.
      counter = FaceDetector(options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.1,
      ));
      final faces = await counter.processImage(input);
      if (faces.isEmpty) throw Exception('No face detected. Use a clear, uncovered face photo.');
      if (faces.length != 1) throw Exception('Please choose a photo with only one face.');
      final face = faces.single;
      final bounds = face.boundingBox;
      final yaw = face.headEulerAngleY;
      final pitch = face.headEulerAngleX;
      final roll = face.headEulerAngleZ;
      if (yaw == null || pitch == null || roll == null) {
        throw Exception('Could not check face angle. Try a clearer front-facing photo.');
      }
      // Initial heuristic thresholds; tune after Android testing.
      if (yaw.abs() > 15 || pitch.abs() > 15 || roll.abs() > 15) {
        throw Exception('Look straight at the camera and keep your head upright.');
      }
      if (bounds.width < 150 || bounds.height < 150 ||
          bounds.width / image.width < 0.20) {
        throw Exception('Your face is too small. Choose a closer, sharper photo.');
      }
      if (bounds.left < 0 || bounds.top < 0 ||
          bounds.right > image.width || bounds.bottom > image.height) {
        throw Exception('Keep your whole face inside the photo.');
      }
      contourDetector = FaceDetector(options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: true,
        enableLandmarks: true,
      ));
      final detailed = await contourDetector.processImage(input);
      if (detailed.isEmpty) throw Exception('Could not locate facial details. Try another photo.');
      final detected = detailed.first;
      final contours = <FaceContourType, List<ui.Offset>>{};
      for (final type in FaceContourType.values) {
        final points = detected.contours[type]?.points;
        if (points != null) {
          contours[type] = points.map((p) => ui.Offset(p.x.toDouble(), p.y.toDouble())).toList();
        }
      }
      for (final type in [FaceContourType.upperLipTop, FaceContourType.upperLipBottom,
        FaceContourType.lowerLipTop, FaceContourType.lowerLipBottom]) {
        if ((contours[type]?.length ?? 0) < 3) {
          throw Exception('Your lips must be clearly visible. Remove face coverings and try again.');
        }
      }
      return ValidatedPhoto(bytes, ui.Size(image.width.toDouble(), image.height.toDouble()),
          contours, detected.boundingBox);
    } finally {
      // Close both detectors and remove the temporary working copy.
      try { await counter?.close(); } finally {
        try { await contourDetector?.close(); } finally {
          if (await file.exists()) await file.delete();
        }
      }
    }
  }
}
