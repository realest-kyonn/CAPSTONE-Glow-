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
MODEL_PATH  = os.path.join(os.path.dirname(__file__), "models", "face_shape_model.tflite")
LABELS_PATH = os.path.join(os.path.dirname(__file__), "models", "face_shape_model_labels.txt")

# ── SETTINGS ───────────────────────────────────────────────
IMAGE_SIZE = (224, 224)
PADDING    = 0.3

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
    Falls back to full image if no face detected.
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

            # Clamp negative values (MTCNN can return negatives)
            x  = max(0, x)
            y  = max(0, y)

            # Add padding
            pad = int(PADDING * min(fw, fh))
            x1  = max(0, x - pad)
            y1  = max(0, y - pad)
            x2  = min(w, x + fw + pad)
            y2  = min(h, y + fh + pad)

            cropped = img_array[y1:y2, x1:x2]
            if cropped.size > 0:
                return Image.fromarray(cropped)

        # No face detected — use full image
        return img

    except Exception:
        return Image.open(image_path).convert("RGB")


def _preprocess(img):
    """
    Resize image and return raw RGB pixels for the model.

    NOTE: The exported .tflite graph already includes VGG16's
    preprocess_input step (RGB->BGR + ImageNet mean subtraction) as
    part of the model itself — it was traced in from train_model.py's
    `x = tf.keras.applications.vgg16.preprocess_input(x)` call inside
    the Keras model definition. Confirmed by inspecting the graph ops
    (STRIDED_SLICE x3 -> PACK -> ADD right after the input tensor).

    So this function must hand the model raw 0-255 RGB values.
    Do NOT convert to BGR or subtract the mean here — the model does
    that internally, and doing it twice silently corrupts every
    prediction (this was happening before this fix).
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