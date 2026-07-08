"""
Capstone Glow - Face Shape Classifier v11 (VGGFace, fine-tuned)

This is what your reference paper (Pratch-yani) actually did to get
92.7%: VGG16 ARCHITECTURE initialized with VGGFace WEIGHTS (trained on
faces, not ImageNet), then fine-tuned toward face-shape classification
— not frozen feature extraction. This reproduces that recipe.

Key facts confirmed before writing this:
  - deepface's VGGFace.load_model() returns a REAL, plain tf.keras.Model
    (built from ordinary Conv2D/MaxPooling2D layers) — not a black box.
    We import it directly, no legacy keras-vggface / Python 3.8 needed.
  - VGG-Face's ACTUAL training-time preprocessing (confirmed by reading
    deepface's own source, deepface/modules/preprocessing.py) is:
    RGB->BGR conversion, then subtract per-channel means:
      B -= 93.5940, G -= 104.7624, R -= 129.1863
    (deepface's default DeepFace.represent() call does NOT apply this
    by default — it uses raw 0-1 scaled pixels unless you explicitly
    pass normalization="VGGFace". We bake the CORRECT preprocessing
    into this model instead, same pattern as v5's vgg16.preprocess_input
    and v10's xception.preprocess_input, to avoid a repeat of the
    double-preprocessing bug from earlier in this project.)
  - Face cropping now matches the paper's ACTUAL code (confirmed by
    reading their real deploy notebook, not just the README): small
    fixed 10px padding + square crop (preserving aspect ratio) when a
    face IS found, and a center-square-crop fallback (not "use the full
    image") when it isn't — replacing v5/v10's 30%-padding + direct
    resize, which could distort/squash non-square crops.

Usage: py -3.12 backend/train_vggface.py
"""

import os
import json
import numpy as np
import pandas as pd
import tensorflow as tf
from PIL import Image
from mtcnn import MTCNN
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.utils.class_weight import compute_class_weight

from deepface import DeepFace

# ── PATHS ──────────────────────────────────────────────────
# Standardized dataset produced by prepare_dataset.py / prepare_testset.py
DATASET_PATH      = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data"
IMAGES_PATH       = os.path.join(DATASET_PATH, "images")
LABELS_PATH       = os.path.join(DATASET_PATH, "labels.csv")
TEST_IMAGES_PATH  = os.path.join(DATASET_PATH, "test_images")
TEST_LABELS_PATH  = os.path.join(DATASET_PATH, "test_labels.csv")

# NOTE: separate filename — does NOT overwrite the deployed v5 model
MODEL_PATH = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\backend\models\face_shape_model_v11_vggface.tflite"

CHECKPOINT_DIR     = os.path.join(os.path.dirname(MODEL_PATH), "checkpoints_v11")
CHECKPOINT_WEIGHTS = os.path.join(CHECKPOINT_DIR, "train_checkpoint.weights.h5")
CHECKPOINT_STATE   = os.path.join(CHECKPOINT_DIR, "checkpoint_state.json")

# ── SETTINGS ───────────────────────────────────────────────
IMAGE_SIZE          = (224, 224)   # VGG-Face's expected input, same as v5
BATCH_SIZE          = 32
EPOCHS              = 30
FINE_TUNE_EPOCHS    = 10
INTERNAL_VAL_SPLIT  = 0.15

# VGG-Face's actual training-time mean values (BGR order), confirmed
# from deepface's own source (deepface/modules/preprocessing.py)
VGGFACE_MEAN_BGR = [93.5940, 104.7624, 129.1863]

# ── MTCNN FACE DETECTOR ────────────────────────────────────
print("Loading MTCNN face detector...")
detector = MTCNN()


def crop_face_mtcnn(image_path):
    """
    Detect and crop face — matches the paper's ACTUAL approach, confirmed
    by reading their real deploy notebook code (not just the README):

      - If a face IS detected: expand the bounding box by a small fixed
        10px top/bottom, then expand to a SQUARE crop (by growing width
        to match height, centered) — this preserves aspect ratio, unlike
        v5's 30%-padding + direct .resize(), which can distort/squash
        the face if the crop isn't already square.
      - If NO face is detected: center-crop to a square using the
        shorter dimension, then resize — a proper aspect-ratio-preserving
        fallback, rather than v5's "just use the full unmodified image."
    """
    try:
        img = Image.open(image_path).convert("RGB")
        img_array = np.array(img)
        h, w = img_array.shape[:2]

        results = detector.detect_faces(img_array)

        if results:
            x, y, fw, fh = results[0]['box']

            # Expand top & bottom by a small fixed 10px (paper's approach,
            # not v5's 30%-of-min-dimension padding)
            y1 = max(0, y - 10)
            y2 = min(h, y + fh + 10)
            x1 = max(0, x)
            x2 = min(w, x + fw)

            new_height = y2 - y1
            width      = x2 - x1

            # Expand width to match height, centered — forces a SQUARE
            # crop so the later resize doesn't distort the face
            adj_w = int((new_height - width) / 2)
            new_x1 = max(0, x1 - adj_w)
            new_x2 = min(w, x2 + adj_w)

            cropped = img_array[y1:y2, new_x1:new_x2]
            if cropped.size > 0:
                return Image.fromarray(cropped)

        # No face detected — center-crop to square (preserves aspect
        # ratio) instead of using the full, possibly non-square image
        side = min(h, w)
        top  = (h - side) // 2
        left = (w - side) // 2
        cropped = img_array[top:top + side, left:left + side]
        return Image.fromarray(cropped)

    except Exception:
        return None


# ── STEP 1: LOAD A LABELED IMAGE SET ────────────────────────
def load_labeled_set(images_dir, labels_path, set_name="set"):
    print(f"\nLoading {set_name} from {labels_path} ...")

    df = pd.read_csv(labels_path)
    df = df.dropna(subset=["face_shape"])
    df["face_shape"] = df["face_shape"].str.strip().str.title()

    print(f"Total rows: {len(df)}")
    print(f"Distribution:\n{df['face_shape'].value_counts().to_string()}\n")

    images, labels = [], []
    skipped = 0

    for idx, (_, row) in enumerate(df.iterrows()):
        img_path = os.path.join(images_dir, row["image_name"])

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

        if img_array.shape == (IMAGE_SIZE[0], IMAGE_SIZE[1], 3):
            images.append(img_array)
            labels.append(row["face_shape"])
        else:
            skipped += 1

        if (idx + 1) % 200 == 0:
            print(f"  {idx+1}/{len(df)} processed...")

    print(f"\nLoaded: {len(images)} | Skipped: {skipped}")
    return np.array(images, dtype=np.float32), np.array(labels)


# ── CHECKPOINT/RESUME SUPPORT ───────────────────────────────
class StateTrackingCheckpoint(tf.keras.callbacks.Callback):
    def __init__(self, phase):
        super().__init__()
        self.phase = phase

    def on_epoch_end(self, epoch, logs=None):
        os.makedirs(CHECKPOINT_DIR, exist_ok=True)
        self.model.save_weights(CHECKPOINT_WEIGHTS)
        with open(CHECKPOINT_STATE, "w") as f:
            json.dump({"phase": self.phase, "epoch": epoch}, f)


def clear_checkpoint():
    for p in (CHECKPOINT_WEIGHTS, CHECKPOINT_STATE):
        if os.path.exists(p):
            os.remove(p)


# ── STEP 2: BUILD MODEL ────────────────────────────────────
def vggface_preprocess(x):
    """
    Bakes VGG-Face's ACTUAL training-time preprocessing into the graph:
    RGB -> BGR, then subtract per-channel means. This becomes part of
    the exported .tflite, same as v5/v10's baked-in preprocessing —
    inference code must hand it raw 0-255 RGB and nothing else.
    """
    # RGB -> BGR
    x = x[..., ::-1]
    # Subtract per-channel means (BGR order)
    mean = tf.constant(VGGFACE_MEAN_BGR, dtype=tf.float32)
    x = x - mean
    return x


def build_model(num_classes):
    print("\nBuilding VGG-Face model (real weights, from deepface)...")

    # This is a genuine tf.keras.Model — plain Conv2D/MaxPooling2D layers,
    # loaded with actual VGGFace-trained weights (not ImageNet). Going
    # through DeepFace.build_model() rather than importing VGGFace's
    # load_model() directly — direct import triggers a circular-import
    # error inside deepface (confirmed while testing this script).
    vggface_wrapper = DeepFace.build_model("VGG-Face")
    vggface_full = vggface_wrapper.model

    # vggface_full's input already expects (224, 224, 3). We rebuild it
    # as our "base_model" the same way v5 used VGG16(include_top=False):
    # take everything through the 4096-d descriptor, drop VGG-Face's own
    # identity-classification head (we're not classifying identities).
    base_model = tf.keras.Model(
        inputs=vggface_full.input,
        outputs=vggface_full.output,
        name="vggface_backbone"
    )
    base_model.trainable = False

    inputs = tf.keras.Input(shape=(IMAGE_SIZE[0], IMAGE_SIZE[1], 3))

    # Same augmentation as v5/v10
    x = tf.keras.layers.RandomFlip("horizontal")(inputs)
    x = tf.keras.layers.RandomRotation(0.055)(x)  # ±20 degrees

    # VGG-Face preprocessing — BAKED INTO THE GRAPH (see docstring above)
    x = tf.keras.layers.Lambda(vggface_preprocess, name="vggface_preprocess")(x)
    x = base_model(x, training=False)

    # Same dense head as v5/v10, for fair comparison
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
def train(images, labels, encoder):
    print("\nPreparing training...")

    encoded_labels = encoder.transform(labels)
    num_classes    = len(encoder.classes_)
    print(f"Classes: {list(encoder.classes_)}")

    X_train, X_val, y_train, y_val = train_test_split(
        images, encoded_labels,
        test_size=INTERNAL_VAL_SPLIT,
        random_state=42,
        stratify=encoded_labels
    )
    print(f"Train: {len(X_train)} | Internal val (early-stop only): {len(X_val)}")

    cw_array      = compute_class_weight("balanced", classes=np.unique(encoded_labels), y=encoded_labels)
    class_weights = dict(enumerate(cw_array))

    model, base_model = build_model(num_classes)

    start_phase = 1
    start_epoch = 0

    if os.path.exists(CHECKPOINT_STATE) and os.path.exists(CHECKPOINT_WEIGHTS):
        with open(CHECKPOINT_STATE) as f:
            state = json.load(f)
        print(f"\n🔄 Found a checkpoint from an interrupted run:")
        print(f"   Phase {state['phase']}, epoch {state['epoch'] + 1} was the last one completed.")
        resume = input("   Resume from here instead of starting over? (y/n): ").strip().lower()

        if resume == "y":
            if state["phase"] == 2:
                base_model.trainable = True
                for layer in base_model.layers[:-4]:  # same as v5 — VGG-shaped backbone
                    layer.trainable = False
                model.compile(
                    optimizer=tf.keras.optimizers.Adam(learning_rate=0.00001),
                    loss="sparse_categorical_crossentropy",
                    metrics=["accuracy"]
                )
            model.load_weights(CHECKPOINT_WEIGHTS)
            start_phase = state["phase"]
            start_epoch = state["epoch"] + 1
            print(f"✅ Resumed. Continuing Phase {start_phase} from epoch {start_epoch + 1}.\n")
        else:
            print("Starting fresh (old checkpoint will be overwritten as training progresses).\n")

    callbacks_phase1 = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=8, restore_best_weights=True, verbose=1
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.5, patience=4, min_lr=1e-6, verbose=1
        ),
        StateTrackingCheckpoint(phase=1),
    ]

    if start_phase == 1:
        print("\nPhase 1: Training top layers...")
        model.fit(
            X_train, y_train,
            epochs=EPOCHS,
            initial_epoch=start_epoch,
            batch_size=BATCH_SIZE,
            validation_data=(X_val, y_val),
            class_weight=class_weights,
            callbacks=callbacks_phase1,
            verbose=1
        )
        start_epoch = 0
    else:
        print("\nPhase 1 already completed in a prior run — skipping to Phase 2.")

    print("\nPhase 2: Fine-tuning...")
    base_model.trainable = True
    # VGG-Face is VGG16-shaped, same as v5 — same conservative "last 4
    # layers" unfreeze v5 used, unlike v10's Xception which needed more.
    for layer in base_model.layers[:-4]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.00001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )

    callbacks_phase2 = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=8, restore_best_weights=True, verbose=1
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.5, patience=4, min_lr=1e-6, verbose=1
        ),
        StateTrackingCheckpoint(phase=2),
    ]

    model.fit(
        X_train, y_train,
        epochs=FINE_TUNE_EPOCHS,
        initial_epoch=(start_epoch if start_phase == 2 else 0),
        batch_size=BATCH_SIZE,
        validation_data=(X_val, y_val),
        class_weight=class_weights,
        callbacks=callbacks_phase2,
        verbose=1
    )

    clear_checkpoint()
    return model


# ── STEP 4: HONEST EVALUATION ────────────────────────────────
def evaluate_honest(model, encoder, test_images, test_labels):
    print("\n" + "=" * 52)
    print("  HONEST EVALUATION — real held-out test set")
    print("=" * 52)

    y_test = encoder.transform(test_labels)
    loss, accuracy = model.evaluate(test_images, y_test, verbose=0)
    print(f"\n✅ Honest Test Accuracy: {accuracy * 100:.2f}%")

    preds = np.argmax(model.predict(test_images, verbose=0), axis=1)
    print("\nPer-class accuracy:")
    for i, cls in enumerate(encoder.classes_):
        mask = y_test == i
        if mask.sum() > 0:
            acc = (preds[mask] == y_test[mask]).mean()
            print(f"  {cls:<10} {acc*100:.1f}%  ({mask.sum()} images)")

    return accuracy


# ── STEP 5: EXPORT TFLITE ──────────────────────────────────
def export_tflite(model, encoder):
    print("\nExporting to TFLite...")
    os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)

    # Save the raw Keras model FIRST, separately from any .tflite export.
    # This is what lets you re-export with different quantization settings
    # later WITHOUT re-running the multi-hour training again — that
    # wasn't possible for this run since this line didn't exist yet.
    keras_path = MODEL_PATH.replace(".tflite", "_keras.keras")
    model.save(keras_path)
    print(f"✅ Keras model (for future re-export): {keras_path}")

    # ── Float32 export (original, ~500MB+ for full VGG16) ──────────
    converter_fp32 = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_fp32 = converter_fp32.convert()
    with open(MODEL_PATH, "wb") as f:
        f.write(tflite_fp32)
    fp32_mb = len(tflite_fp32) / (1024 * 1024)
    print(f"✅ Float32 model: {MODEL_PATH}  ({fp32_mb:.1f} MB)")

    # ── Quantized export (dynamic range quantization) ───────────────
    # converter.optimizations = [tf.lite.Optimize.DEFAULT] with no
    # target_spec set does DYNAMIC RANGE quantization: weights become
    # int8, activations stay float32. No representative dataset needed
    # (unlike full int8 quantization), typically ~4x smaller with only
    # a small accuracy cost — a safe default given how much accuracy
    # headroom this model has (93.6%).
    quant_path = MODEL_PATH.replace(".tflite", "_quantized.tflite")
    converter_quant = tf.lite.TFLiteConverter.from_keras_model(model)
    converter_quant.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_quant = converter_quant.convert()
    with open(quant_path, "wb") as f:
        f.write(tflite_quant)
    quant_mb = len(tflite_quant) / (1024 * 1024)
    print(f"✅ Quantized model: {quant_path}  ({quant_mb:.1f} MB, ~{fp32_mb/quant_mb:.1f}x smaller)")

    labels_path = MODEL_PATH.replace(".tflite", "_labels.txt")
    with open(labels_path, "w") as f:
        for cls in encoder.classes_:
            f.write(cls + "\n")
    print(f"✅ Labels: {labels_path}")

    print("\n⚠️  Separate files — your deployed v5 model is untouched.")
    print("⚠️  IMPORTANT: run evaluate_deployed.py against the QUANTIZED")
    print("   model specifically before deciding to ship it — quantization")
    print("   can shift accuracy slightly, and you need the real number,")
    print("   not an assumption.")


# ── MAIN ───────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 52)
    print("  Capstone Glow — Face Shape Classifier v11")
    print("  VGG-Face (real weights) + fine-tuning")
    print("=" * 52)

    if not os.path.isdir(TEST_IMAGES_PATH) or len(os.listdir(TEST_IMAGES_PATH)) == 0:
        print(f"\n❌ {TEST_IMAGES_PATH} is empty or missing. Run: py -3.12 prepare_testset.py")
        exit()
    if not os.path.exists(TEST_LABELS_PATH):
        print(f"\n❌ {TEST_LABELS_PATH} not found. Run: py -3.12 prepare_testset.py")
        exit()
    if not os.path.exists(LABELS_PATH):
        print(f"\n❌ {LABELS_PATH} not found. Run: py -3.12 prepare_dataset.py")
        exit()

    train_images, train_labels = load_labeled_set(IMAGES_PATH, LABELS_PATH, "TRAINING set")
    if len(train_images) == 0:
        print("❌ No training images loaded!")
        exit()

    test_images, test_labels = load_labeled_set(TEST_IMAGES_PATH, TEST_LABELS_PATH, "HONEST TEST set")
    if len(test_images) == 0:
        print("❌ No test images loaded!")
        exit()

    encoder = LabelEncoder()
    encoder.fit(np.concatenate([train_labels, test_labels]))

    model = train(train_images, train_labels, encoder)
    honest_accuracy = evaluate_honest(model, encoder, test_images, test_labels)
    export_tflite(model, encoder)

    print("\n" + "=" * 52)
    print("  TRAINING COMPLETE!")
    print(f"  Honest Test Accuracy: {honest_accuracy * 100:.2f}%")
    print(f"  (compare against v9: 59.80%, v5: 65.95%, v10 Xception: 41.70%)")
    print("=" * 52)