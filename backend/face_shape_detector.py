"""
Capstone Glow - Face Shape Detector
Uses the trained TFLite model to predict face shape from a photo.
Uses MTCNN for face detection (same as training pipeline).

Face Shapes: Heart, Long, Oval, Round, Square

Usage:
    from face_shape_detector import detect_face_shape
    result = detect_face_shape("data/images/img001.jpg")

    py -3.12 backend/face_shape_detector.py data/images/img001.jpg
"""

import os
import numpy as np
from PIL import Image
from mtcnn import MTCNN
import tensorflow as tf

# ── PATHS ──────────────────────────────────────────────────
# Can be overridden via environment variables — useful for testing an
# alternate model (e.g. the quantized v11 export) without touching the
# deployed face_shape_model.tflite. Defaults are unchanged for normal use.
MODEL_PATH  = os.environ.get(
    "GLOW_MODEL_PATH",
    os.path.join(os.path.dirname(__file__), "models", "face_shape_model.tflite")
)
LABELS_PATH = os.environ.get(
    "GLOW_LABELS_PATH",
    os.path.join(os.path.dirname(__file__), "models", "face_shape_model_labels.txt")
)

# ── SETTINGS ───────────────────────────────────────────────
IMAGE_SIZE = (224, 224)
# NOTE: no PADDING constant anymore — crop logic now uses a fixed 10px
# pad + forced square crop, matching v11's training (see _crop_face below)

# ── LOAD MODEL & LABELS ONCE ───────────────────────────────
def _load_model():
    """Load TFLite model and allocate tensors."""
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    return interpreter

def _load_labels():
    """Load class labels from labels.txt."""
    with open(LABELS_PATH, "r") as f:
        return [line.strip() for line in f.readlines() if line.strip()]

# Load once at module level
try:
    _interpreter = _load_model()
    _labels      = _load_labels()
    _input_details  = _interpreter.get_input_details()
    _output_details = _interpreter.get_output_details()
    MODEL_LOADED = True
except Exception as e:
    MODEL_LOADED = False
    print(f"[WARNING] Could not load face shape model: {e}")

# ── MTCNN FACE DETECTOR ────────────────────────────────────
try:
    _detector = MTCNN()
    MTCNN_LOADED = True
except Exception as e:
    MTCNN_LOADED = False
    print(f"[WARNING] Could not load MTCNN: {e}")


def _crop_face(image_path):
    """
    Detects and crops face from image using MTCNN.
    Returns PIL Image of cropped face.

    IMPORTANT: This MUST match whatever crop logic the currently-
    deployed model was actually trained with, or you get a silent
    train/inference mismatch — the same class of bug as the
    double-preprocessing issue, just in the cropping step instead.

    This matches v11 (VGGFace)'s training crop, confirmed against the
    reference paper's actual deploy-notebook code: small fixed 10px
    padding, then FORCE a square crop (expand width to match height,
    centered) before resizing — this preserves aspect ratio, unlike
    the old 30%-padding + direct-resize approach (which could
    stretch/squash non-square crops and was the cause of a ~40-point
    accuracy drop when first tested against the real deployed pipeline).

    Falls back to a center-square crop (not the unmodified full image)
    if no face is detected — also matching v11's training logic.
    """
    try:
        img       = Image.open(image_path).convert("RGB")
        img_array = np.array(img)
        h, w      = img_array.shape[:2]

        if not MTCNN_LOADED:
            return img

        results = _detector.detect_faces(img_array)

        if results:
            x, y, fw, fh = results[0]["box"]

            # Expand top & bottom by a small fixed 10px (matches v11's
            # training crop — NOT the old 30%-of-min-dimension padding)
            y1 = max(0, y - 10)
            y2 = min(h, y + fh + 10)
            x1 = max(0, x)
            x2 = min(w, x + fw)

            new_height = y2 - y1
            width      = x2 - x1

            # Expand width to match height, centered — forces a SQUARE
            # crop so the resize step doesn't distort the face
            adj_w  = int((new_height - width) / 2)
            new_x1 = max(0, x1 - adj_w)
            new_x2 = min(w, x2 + adj_w)

            cropped = img_array[y1:y2, new_x1:new_x2]
            if cropped.size > 0:
                return Image.fromarray(cropped)

        # No face detected — center-crop to square (matches v11's
        # training fallback), not the old "use the full image" approach
        side = min(h, w)
        top  = (h - side) // 2
        left = (w - side) // 2
        cropped = img_array[top:top + side, left:left + side]
        return Image.fromarray(cropped)

    except Exception:
        return Image.open(image_path).convert("RGB")


def _preprocess(img):
    """
    Resize image and return raw RGB pixels for the model.

    NOTE: The exported .tflite graph already includes VGG-Face's own
    preprocessing step as part of the model itself — RGB->BGR conversion,
    then subtracting VGG-Face's per-channel training means (BGR order):
        B -= 93.5940, G -= 104.7624, R -= 129.1863
    This was traced in from train_vggface.py's `vggface_preprocess()`
    function, applied via a `tf.keras.layers.Lambda` layer inside the
    Keras model definition — confirmed against deepface's own source
    (deepface/modules/preprocessing.py), not ImageNet's mean values.

    So this function must hand the model raw 0-255 RGB values.
    Do NOT convert to BGR or subtract any mean here — the model does
    that internally, and doing it twice silently corrupts every
    prediction (this was happening before this fix — do not reintroduce it
    when swapping in a future model version; always check what
    preprocessing THAT version's training script actually baked in).
    """
    img       = img.resize(IMAGE_SIZE, Image.BILINEAR)
    img_array = np.array(img, dtype=np.float32)

    # Handle grayscale
    if img_array.ndim == 2:
        img_array = np.stack([img_array] * 3, axis=-1)
    elif img_array.shape[-1] == 4:
        img_array = img_array[:, :, :3]

    return np.expand_dims(img_array, axis=0)  # add batch dimension


def detect_face_shape(image_path):
    """
    Main function — detects face shape from an image file.

    Args:
        image_path (str): Path to the face image

    Returns:
        dict: {
            "face_shape":   str,   # e.g. "Oval", "Round", "Square", "Heart", "Long"
            "confidence":   float, # confidence score 0.0 - 1.0
            "all_scores":   dict,  # scores for all 5 shapes
            "error":        str | None
        }
    """

    if not MODEL_LOADED:
        return {
            "face_shape": "Oval",
            "confidence": 0.0,
            "all_scores": {},
            "error": "Model not loaded — defaulting to Oval"
        }

    if not os.path.exists(image_path):
        return {
            "face_shape": None,
            "confidence": 0.0,
            "all_scores": {},
            "error": f"Image not found: {image_path}"
        }

    try:
        # Step 1: Crop face
        face_img = _crop_face(image_path)

        # Step 2: Preprocess
        input_data = _preprocess(face_img)

        # Step 3: Run inference
        _interpreter.set_tensor(_input_details[0]["index"], input_data)
        _interpreter.invoke()
        output_data = _interpreter.get_tensor(_output_details[0]["index"])[0]

        # Step 4: Get prediction
        predicted_idx   = int(np.argmax(output_data))
        confidence      = float(output_data[predicted_idx])
        predicted_shape = _labels[predicted_idx]

        # Step 5: Build all scores dict
        all_scores = {
            _labels[i]: round(float(output_data[i]), 4)
            for i in range(len(_labels))
        }

        return {
            "face_shape": predicted_shape,
            "confidence": round(confidence, 4),
            "all_scores": all_scores,
            "error":      None
        }

    except Exception as e:
        return {
            "face_shape": "Oval",
            "confidence": 0.0,
            "all_scores": {},
            "error": f"Detection failed: {str(e)}"
        }


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: py -3.12 backend/face_shape_detector.py <image_path>")
        print("\nExample: py -3.12 backend/face_shape_detector.py data/images/img001.jpg")
        sys.exit(0)

    image_path = sys.argv[1]

    print("\n=== Capstone Glow — Face Shape Detection ===\n")

    if not MODEL_LOADED:
        print("❌ Model not loaded! Make sure face_shape_model.tflite exists in backend/models/")
        sys.exit(1)

    result = detect_face_shape(image_path)

    if result["error"]:
        print(f"[!] Note: {result['error']}")

    print(f"Face Shape : {result['face_shape']}")
    print(f"Confidence : {result['confidence'] * 100:.1f}%")

    if result["all_scores"]:
        print("\nAll Scores:")
        sorted_scores = sorted(result["all_scores"].items(), key=lambda x: x[1], reverse=True)
        for shape, score in sorted_scores:
            bar    = "█" * int(score * 20)
            marker = " ← predicted" if shape == result["face_shape"] else ""
            print(f"  {shape:<10} {score:.4f}  {bar}{marker}")