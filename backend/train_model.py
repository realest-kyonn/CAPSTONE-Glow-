"""
Capstone Glow - Face Shape Classifier v5
Based on: Pratch-yani/Face-Shape-Classification-using-CNN
- MTCNN face detection (same as research)
- VGG16 architecture with ImageNet weights
- Horizontal flip + rotate ±20 degrees augmentation (same as research)
- 3950 images (comparable to research's 4000)

Usage: py -3.12 backend/train_model.py
"""

import os
import numpy as np
import pandas as pd
import tensorflow as tf
from PIL import Image
from mtcnn import MTCNN
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.utils.class_weight import compute_class_weight

# ── PATHS ──────────────────────────────────────────────────
DATASET_PATH = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data"
IMAGES_PATH  = os.path.join(DATASET_PATH, "images")
LABELS_PATH  = os.path.join(DATASET_PATH, "labels.csv")
MODEL_PATH   = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\backend\models\face_shape_model.tflite"

# ── SETTINGS ───────────────────────────────────────────────
IMAGE_SIZE       = (224, 224)
BATCH_SIZE       = 32
EPOCHS           = 30
FINE_TUNE_EPOCHS = 10
TEST_SPLIT       = 0.2

# ── MTCNN FACE DETECTOR ────────────────────────────────────
print("Loading MTCNN face detector...")
detector = MTCNN()

def crop_face_mtcnn(image_path):
    """
    Uses MTCNN to detect and crop face from image.
    Same approach as the research paper.
    """
    try:
        img = Image.open(image_path).convert("RGB")
        img_array = np.array(img)
        h, w = img_array.shape[:2]

        # Detect faces
        results = detector.detect_faces(img_array)

        if results:
            # Get the first face bounding box
            x, y, fw, fh = results[0]['box']

            # Add 30% padding around face
            pad = int(0.3 * min(fw, fh))
            x1  = max(0, x - pad)
            y1  = max(0, y - pad)
            x2  = min(w, x + fw + pad)
            y2  = min(h, y + fh + pad)

            cropped = img_array[y1:y2, x1:x2]
            if cropped.size > 0:
                return Image.fromarray(cropped)

        # No face detected — return full image
        return img

    except Exception:
        return None


# ── STEP 1: LOAD DATASET ───────────────────────────────────
def load_dataset():
    print("Loading dataset with MTCNN face detection...")

    df = pd.read_csv(LABELS_PATH)
    df = df.dropna(subset=["face_shape"])
    df["face_shape"] = df["face_shape"].str.strip().str.title()

    print(f"Total images: {len(df)}")
    print(f"Distribution:\n{df['face_shape'].value_counts().to_string()}\n")

    images, labels = [], []
    skipped = 0

    for idx, (_, row) in enumerate(df.iterrows()):
        img_path = os.path.join(IMAGES_PATH, row["image_name"])

        if not os.path.exists(img_path):
            skipped += 1
            continue

        face_img = crop_face_mtcnn(img_path)

        if face_img is None:
            skipped += 1
            continue

        face_img  = face_img.resize(IMAGE_SIZE, Image.BILINEAR)
        img_array = np.array(face_img, dtype=np.float32)

        if img_array.ndim == 2:
            img_array = np.stack([img_array] * 3, axis=-1)
        elif img_array.shape[-1] == 4:
            img_array = img_array[:, :, :3]

        if img_array.shape == (224, 224, 3):
            images.append(img_array)
            labels.append(row["face_shape"])
        else:
            skipped += 1

        if (idx + 1) % 200 == 0:
            print(f"  {idx+1}/{len(df)} processed...")

    print(f"\nLoaded: {len(images)} | Skipped: {skipped}")
    return np.array(images, dtype=np.float32), np.array(labels)


# ── STEP 2: BUILD MODEL ────────────────────────────────────
def build_model(num_classes):
    print(f"\nBuilding VGG16 model (same architecture as research)...")

    base_model = tf.keras.applications.VGG16(
        input_shape=(224, 224, 3),
        include_top=False,
        weights="imagenet",
        pooling='avg'
    )
    base_model.trainable = False

    inputs = tf.keras.Input(shape=(224, 224, 3))

    # Same augmentation as research paper
    # Horizontal flip + rotation ±20 degrees
    x = tf.keras.layers.RandomFlip("horizontal")(inputs)
    x = tf.keras.layers.RandomRotation(0.055)(x)  # ±20 degrees = 0.055 in radians ratio

    # VGG16 preprocessing
    x = tf.keras.applications.vgg16.preprocess_input(x)
    x = base_model(x, training=False)

    # Dense layers
    x = tf.keras.layers.Dense(512, activation="relu")(x)
    x = tf.keras.layers.Dropout(0.5)(x)
    x = tf.keras.layers.Dense(256, activation="relu")(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax")(x)

    model = tf.keras.Model(inputs, outputs)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )

    return model, base_model


# ── STEP 3: TRAIN ──────────────────────────────────────────
def train(images, labels):
    print("\nPreparing training...")

    encoder        = LabelEncoder()
    encoded_labels = encoder.fit_transform(labels)
    num_classes    = len(encoder.classes_)
    print(f"Classes: {list(encoder.classes_)}")

    X_train, X_test, y_train, y_test = train_test_split(
        images, encoded_labels,
        test_size=TEST_SPLIT,
        random_state=42,
        stratify=encoded_labels
    )
    print(f"Train: {len(X_train)} | Test: {len(X_test)}")

    # Class weights for imbalance
    cw_array      = compute_class_weight("balanced", classes=np.unique(encoded_labels), y=encoded_labels)
    class_weights = dict(enumerate(cw_array))

    model, base_model = build_model(num_classes)

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=8,
            restore_best_weights=True,
            verbose=1
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=4,
            min_lr=1e-6,
            verbose=1
        ),
    ]

    # Phase 1: Train top layers
    print("\nPhase 1: Training top layers...")
    model.fit(
        X_train, y_train,
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        validation_data=(X_test, y_test),
        class_weight=class_weights,
        callbacks=callbacks,
        verbose=1
    )

    # Phase 2: Fine-tune last 4 VGG16 layers (conservative)
    print("\nPhase 2: Fine-tuning...")
    base_model.trainable = True
    for layer in base_model.layers[:-4]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.00001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )

    model.fit(
        X_train, y_train,
        epochs=FINE_TUNE_EPOCHS,
        batch_size=BATCH_SIZE,
        validation_data=(X_test, y_test),
        class_weight=class_weights,
        callbacks=callbacks,
        verbose=1
    )

    loss, accuracy = model.evaluate(X_test, y_test, verbose=0)
    print(f"\n✅ Final Accuracy: {accuracy * 100:.2f}%")

    # Per class breakdown
    print("\nPer-class accuracy:")
    preds = np.argmax(model.predict(X_test, verbose=0), axis=1)
    for i, cls in enumerate(encoder.classes_):
        mask = y_test == i
        if mask.sum() > 0:
            acc = (preds[mask] == y_test[mask]).mean()
            print(f"  {cls:<10} {acc*100:.1f}%  ({mask.sum()} images)")

    return model, encoder, accuracy


# ── STEP 4: EXPORT TFLITE ──────────────────────────────────
def export_tflite(model, encoder):
    print("\nExporting to TFLite...")
    os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)

    converter    = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    with open(MODEL_PATH, "wb") as f:
        f.write(tflite_model)

    labels_path = MODEL_PATH.replace(".tflite", "_labels.txt")
    with open(labels_path, "w") as f:
        for cls in encoder.classes_:
            f.write(cls + "\n")

    print(f"✅ Model:  {MODEL_PATH}")
    print(f"✅ Labels: {labels_path}")


# ── MAIN ───────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 52)
    print("  Capstone Glow — Face Shape Classifier v5")
    print("  VGG16 + MTCNN (based on research paper)")
    print("=" * 52)

    images, labels = load_dataset()

    if len(images) == 0:
        print("❌ No images loaded!")
        exit()

    model, encoder, accuracy = train(images, labels)
    export_tflite(model, encoder)

    print("\n" + "=" * 52)
    print("  TRAINING COMPLETE!")
    print(f"  Final Accuracy: {accuracy * 100:.2f}%")
    print("=" * 52)