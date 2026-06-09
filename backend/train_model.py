"""
Capstone Glow - Face Shape Classifier Training Script v2
Fixes from v1:
  - Replaced MediaPipe with OpenCV face cropping (fixes crash)
  - Added class weights to handle imbalanced dataset
  - Added stronger augmentation for minority classes
  - Added early stopping to prevent overfitting
  - Added learning rate scheduler

Usage: py -3.12 backend/train_model.py
"""

import os
import cv2
import numpy as np
import pandas as pd
import tensorflow as tf
from PIL import Image
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
FINE_TUNE_EPOCHS = 20
TEST_SPLIT       = 0.2
PADDING          = 0.3

# ── OPENCV FACE DETECTOR ───────────────────────────────────
# Using OpenCV instead of MediaPipe — no version issues
cascade_path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
face_cascade = cv2.CascadeClassifier(cascade_path)


def crop_face(image_path):
    """
    Detects and crops face using OpenCV Haar Cascade.
    Returns cropped face as PIL Image.
    Falls back to full image if no face detected.
    """
    img = cv2.imread(image_path)
    if img is None:
        return None

    gray  = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=4,
        minSize=(60, 60)
    )

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    h, w    = img_rgb.shape[:2]

    if len(faces) > 0:
        x, y, fw, fh = faces[0]

        # Add padding around face
        pad = int(PADDING * min(fw, fh))
        x1  = max(0, x - pad)
        y1  = max(0, y - pad)
        x2  = min(w, x + fw + pad)
        y2  = min(h, y + fh + pad)

        cropped = img_rgb[y1:y2, x1:x2]
        if cropped.size > 0:
            return Image.fromarray(cropped)

    # Fallback: return full image
    return Image.fromarray(img_rgb)


# ── STEP 1: LOAD DATASET ───────────────────────────────────
def load_dataset():
    print("Loading dataset...")

    df = pd.read_csv(LABELS_PATH)
    df = df.dropna(subset=["face_shape"])
    df = df[df["face_shape"].str.strip() != ""]
    df["face_shape"] = df["face_shape"].str.strip().str.title()

    print(f"\nFace shape distribution:")
    print(df["face_shape"].value_counts().to_string())
    print(f"\nTotal: {len(df)} images\n")

    images  = []
    labels  = []
    skipped = 0
    cropped_count = 0

    for idx, (_, row) in enumerate(df.iterrows()):
        img_path = os.path.join(IMAGES_PATH, row["image_name"])

        if not os.path.exists(img_path):
            skipped += 1
            continue

        face_img = crop_face(img_path)

        if face_img is None:
            skipped += 1
            continue

        # Check if it was actually cropped (smaller than original)
        orig = Image.open(img_path)
        if face_img.size != orig.size:
            cropped_count += 1

        face_img  = face_img.resize(IMAGE_SIZE)
        img_array = np.array(face_img) / 255.0

        # Handle grayscale images
        if img_array.ndim == 2:
            img_array = np.stack([img_array] * 3, axis=-1)
        elif img_array.shape[-1] == 4:
            img_array = img_array[:, :, :3]

        images.append(img_array)
        labels.append(row["face_shape"])

        if (idx + 1) % 50 == 0:
            print(f"  Processed {idx+1}/{len(df)} images...")

    print(f"\n✅ Loaded:   {len(images)} images")
    print(f"✂️  Cropped:  {cropped_count} faces detected and cropped")
    print(f"⏭️  Skipped:  {skipped} images")

    return np.array(images), np.array(labels)


# ── STEP 2: DATA AUGMENTATION ──────────────────────────────
def create_augmentation():
    """Stronger augmentation to help minority classes."""
    return tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.15),
        tf.keras.layers.RandomZoom(0.15),
        tf.keras.layers.RandomBrightness(0.2),
        tf.keras.layers.RandomContrast(0.2),
        tf.keras.layers.RandomTranslation(0.1, 0.1),
    ])


# ── STEP 3: BUILD MODEL ────────────────────────────────────
def build_model(num_classes):
    print(f"\nBuilding MobileNetV2 model for {num_classes} classes...")

    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(224, 224, 3),
        include_top=False,
        weights="imagenet"
    )
    base_model.trainable = False

    inputs      = tf.keras.Input(shape=(224, 224, 3))
    augment     = create_augmentation()
    x = augment(inputs, training=True)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = base_model(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dense(256, activation="relu")(x)
    x = tf.keras.layers.Dropout(0.5)(x)
    x = tf.keras.layers.Dense(128, activation="relu")(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax")(x)

    model = tf.keras.Model(inputs, outputs)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )

    return model, base_model


# ── STEP 4: TRAIN ──────────────────────────────────────────
def train(images, labels):
    print("\nPreparing training data...")

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

    print(f"Training: {len(X_train)} | Testing: {len(X_test)}")

    # ── CLASS WEIGHTS — fixes imbalanced dataset ───────────
    class_weights_array = compute_class_weight(
        class_weight="balanced",
        classes=np.unique(encoded_labels),
        y=encoded_labels
    )
    class_weights = dict(enumerate(class_weights_array))

    print(f"\nClass weights (higher = model pays more attention):")
    for idx, cls in enumerate(encoder.classes_):
        print(f"  {cls:<10} weight: {class_weights[idx]:.2f}")

    model, base_model = build_model(num_classes)

    # ── CALLBACKS ──────────────────────────────────────────
    callbacks = [
        # Stop early if not improving
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=7,
            restore_best_weights=True,
            verbose=1
        ),
        # Reduce learning rate when stuck
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=4,
            min_lr=1e-6,
            verbose=1
        ),
    ]

    # ── PHASE 1: Train top layers ──────────────────────────
    print("\n── Phase 1: Training top layers (base frozen) ───")
    model.fit(
        X_train, y_train,
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        validation_data=(X_test, y_test),
        class_weight=class_weights,
        callbacks=callbacks,
        verbose=1
    )

    # ── PHASE 2: Fine-tune last 30 layers ─────────────────
    print("\n── Phase 2: Fine-tuning last 30 layers ──────────")
    base_model.trainable = True
    for layer in base_model.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
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

    # ── EVALUATE ───────────────────────────────────────────
    print("\nEvaluating model...")
    loss, accuracy = model.evaluate(X_test, y_test, verbose=0)
    print(f"\n✅ Final Test Accuracy: {accuracy * 100:.2f}%")

    # Per-class accuracy
    print("\nPer-class accuracy:")
    predictions = np.argmax(model.predict(X_test, verbose=0), axis=1)
    for idx, cls in enumerate(encoder.classes_):
        mask     = y_test == idx
        if mask.sum() > 0:
            cls_acc  = (predictions[mask] == y_test[mask]).mean()
            print(f"  {cls:<10} {cls_acc * 100:.1f}%  ({mask.sum()} test images)")

    return model, encoder, accuracy


# ── STEP 5: EXPORT TFLITE ──────────────────────────────────
def export_tflite(model, encoder):
    print("\nExporting to TensorFlow Lite...")

    os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)

    converter    = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    with open(MODEL_PATH, "wb") as f:
        f.write(tflite_model)

    # Save class labels alongside model
    labels_path = MODEL_PATH.replace(".tflite", "_labels.txt")
    with open(labels_path, "w") as f:
        for cls in encoder.classes_:
            f.write(cls + "\n")

    print(f"✅ Model saved:  {MODEL_PATH}")
    print(f"✅ Labels saved: {labels_path}")
    print(f"   Classes: {list(encoder.classes_)}")


# ── MAIN ───────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 52)
    print("  Capstone Glow — Face Shape Classifier v2")
    print("  MobileNetV2 + OpenCV Crop + Class Weights")
    print("=" * 52)

    if not os.path.exists(LABELS_PATH):
        print("❌ labels.csv not found!")
        exit()

    if not os.path.exists(IMAGES_PATH):
        print("❌ images folder not found!")
        exit()

    images, labels = load_dataset()

    if len(images) == 0:
        print("❌ No images loaded!")
        exit()

    model, encoder, accuracy = train(images, labels)

    export_tflite(model, encoder)

    print("\n" + "=" * 52)
    print("  TRAINING COMPLETE!")
    print(f"  Final Accuracy: {accuracy * 100:.2f}%")
    print("  Model: backend/models/face_shape_model.tflite")
    print("  Labels: backend/models/face_shape_model_labels.txt")
    print("  Give the .tflite file to Member 2!")
    print("=" * 52)