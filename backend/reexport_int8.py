"""
Capstone Glow - Re-export v11 with full int8 quantization

Loads the ALREADY-TRAINED model from the .keras checkpoint saved by
train_vggface.py's export step — no retraining needed. This exists
specifically because the dynamic-range quantized export (130MB) is
still over GitHub's 100MB file limit, and re-running the full
multi-hour training just to try a different export setting would be
wasteful now that the .keras checkpoint makes that unnecessary.

Needs a small sample of real training images to calibrate int8 ranges
("representative dataset") — pulls ~200 from your training set.

Usage: py -3.12 backend/reexport_int8.py
"""

import os
import numpy as np
import pandas as pd
import tensorflow as tf
from PIL import Image
from mtcnn import MTCNN

DATASET_PATH = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data"
IMAGES_PATH  = os.path.join(DATASET_PATH, "images")
LABELS_PATH  = os.path.join(DATASET_PATH, "labels.csv")

MODELS_DIR   = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\backend\models"
KERAS_PATH   = os.path.join(MODELS_DIR, "face_shape_model_v11_vggface_keras.keras")
INT8_PATH    = os.path.join(MODELS_DIR, "face_shape_model_v11_vggface_int8.tflite")

IMAGE_SIZE   = (224, 224)
SAMPLE_SIZE  = 200  # representative images for int8 calibration


def vggface_preprocess(x):
    """
    Must match train_vggface.py's preprocessing EXACTLY — this is
    needed here because the saved .keras file can't deserialize its
    Lambda layer without being told what function it refers to
    (confirmed by testing: load_model() fails with a TypeError on
    this exact model without passing custom_objects).
    """
    x = x[..., ::-1]
    mean = tf.constant([93.5940, 104.7624, 129.1863], dtype=tf.float32)
    return x - mean


print("Loading MTCNN...")
detector = MTCNN()


def crop_face_mtcnn(image_path):
    """Same crop logic v11 was trained with — 10px pad + square crop."""
    try:
        img = Image.open(image_path).convert("RGB")
        img_array = np.array(img)
        h, w = img_array.shape[:2]

        results = detector.detect_faces(img_array)

        if results:
            x, y, fw, fh = results[0]['box']
            y1 = max(0, y - 10)
            y2 = min(h, y + fh + 10)
            x1 = max(0, x)
            x2 = min(w, x + fw)
            new_height = y2 - y1
            width      = x2 - x1
            adj_w  = int((new_height - width) / 2)
            new_x1 = max(0, x1 - adj_w)
            new_x2 = min(w, x2 + adj_w)
            cropped = img_array[y1:y2, new_x1:new_x2]
            if cropped.size > 0:
                return Image.fromarray(cropped)

        side = min(h, w)
        top  = (h - side) // 2
        left = (w - side) // 2
        return Image.fromarray(img_array[top:top + side, left:left + side])

    except Exception:
        return None


def load_representative_sample(n=SAMPLE_SIZE):
    print(f"\nLoading {n} representative images for int8 calibration...")
    df = pd.read_csv(LABELS_PATH)
    df = df.dropna(subset=["face_shape"]).sample(n=min(n, len(df)), random_state=42)

    images = []
    for idx, (_, row) in enumerate(df.iterrows()):
        img_path = os.path.join(IMAGES_PATH, row["image_name"])
        if not os.path.exists(img_path):
            continue
        face_img = crop_face_mtcnn(img_path)
        if face_img is None:
            continue
        face_img = face_img.resize(IMAGE_SIZE, Image.BILINEAR)
        img_array = np.array(face_img, dtype=np.float32)
        if img_array.ndim == 2:
            img_array = np.stack([img_array] * 3, axis=-1)
        elif img_array.shape[-1] == 4:
            img_array = img_array[:, :, :3]
        if img_array.shape == (IMAGE_SIZE[0], IMAGE_SIZE[1], 3):
            images.append(img_array)
        if (idx + 1) % 50 == 0:
            print(f"  {idx+1}/{len(df)} processed...")

    print(f"Loaded {len(images)} representative images.")
    return images


if __name__ == "__main__":
    print("=" * 52)
    print("  Re-exporting v11 with full int8 quantization")
    print("=" * 52)

    if not os.path.exists(KERAS_PATH):
        print(f"\n❌ {KERAS_PATH} not found — can't re-export without it.")
        exit()

    print(f"\nLoading trained model from {KERAS_PATH} ...")
    model = tf.keras.models.load_model(
        KERAS_PATH,
        custom_objects={"vggface_preprocess": vggface_preprocess}
    )
    print("✅ Model loaded — no retraining needed.")

    representative_images = load_representative_sample()

    if len(representative_images) == 0:
        print("❌ No representative images loaded — check IMAGES_PATH/LABELS_PATH.")
        exit()

    def representative_dataset_gen():
        for img in representative_images:
            yield [np.expand_dims(img, axis=0).astype(np.float32)]

    print("\nConverting to full int8 (external I/O stays float32 — no")
    print("changes needed in face_shape_detector.py)...")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset_gen
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
        tf.lite.OpsSet.TFLITE_BUILTINS,
    ]
    tflite_int8 = converter.convert()

    with open(INT8_PATH, "wb") as f:
        f.write(tflite_int8)

    int8_mb = len(tflite_int8) / (1024 * 1024)
    print(f"\n✅ Saved: {INT8_PATH}")
    print(f"   Size: {int8_mb:.1f} MB")
    if int8_mb < 100:
        print("   ✅ Under GitHub's 100MB limit!")
    else:
        print("   ⚠️  Still over 100MB — may need Git LFS or external hosting.")

    print("\nNext step: run evaluate_deployed.py against THIS file to confirm")
    print("accuracy held up before deciding to ship it.")