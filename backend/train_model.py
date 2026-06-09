"""
Capstone Glow - Face Shape Classifier Training Script
Trains a model to classify face shapes using the annotated dataset
Run this AFTER Member 4 finishes labeling (labels.csv is complete)

Usage: py -3.12 backend/train_model.py
"""

import os
import numpy as np
import pandas as pd
import tensorflow as tf
from PIL import Image
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# ── PATHS ──────────────────────────────────────────────────
DATASET_PATH = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data"
IMAGES_PATH  = os.path.join(DATASET_PATH, "images")
LABELS_PATH  = os.path.join(DATASET_PATH, "labels.csv")
MODEL_PATH   = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\backend\models\face_shape_model.tflite"

# ── SETTINGS ───────────────────────────────────────────────
IMAGE_SIZE   = (128, 128)  # resize all images to 128x128
BATCH_SIZE   = 32
EPOCHS       = 20
TEST_SPLIT   = 0.2         # 80% training, 20% testing

# ── STEP 1: LOAD DATASET ───────────────────────────────────
def load_dataset():
    print("Loading dataset...")
    
    # Read labels CSV
    labels_df = pd.read_csv(LABELS_PATH)
    
    # Drop rows with missing face_shape
    labels_df = labels_df.dropna(subset=["face_shape"])
    labels_df = labels_df[labels_df["face_shape"] != ""]
    
    print(f"Total labeled images: {len(labels_df)}")
    print(f"Face shape distribution:\n{labels_df['face_shape'].value_counts()}")
    
    images = []
    labels = []
    
    for _, row in labels_df.iterrows():
        img_path = os.path.join(IMAGES_PATH, row["image_name"])
        
        if not os.path.exists(img_path):
            continue
        
        # Load and resize image
        img = Image.open(img_path).convert("RGB")
        img = img.resize(IMAGE_SIZE)
        img_array = np.array(img) / 255.0  # normalize to 0-1
        
        images.append(img_array)
        labels.append(row["face_shape"].lower().strip())
    
    print(f"Successfully loaded: {len(images)} images")
    return np.array(images), np.array(labels)


# ── STEP 2: BUILD MODEL ────────────────────────────────────
def build_model(num_classes):
    print("\nBuilding model...")
    
    model = tf.keras.Sequential([
        # Input layer
        tf.keras.layers.Input(shape=(128, 128, 3)),
        
        # Convolutional layers
        tf.keras.layers.Conv2D(32, (3, 3), activation="relu"),
        tf.keras.layers.MaxPooling2D(2, 2),
        
        tf.keras.layers.Conv2D(64, (3, 3), activation="relu"),
        tf.keras.layers.MaxPooling2D(2, 2),
        
        tf.keras.layers.Conv2D(128, (3, 3), activation="relu"),
        tf.keras.layers.MaxPooling2D(2, 2),
        
        # Flatten and dense layers
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(256, activation="relu"),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(num_classes, activation="softmax")
    ])
    
    model.compile(
        optimizer="adam",
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )
    
    model.summary()
    return model


# ── STEP 3: TRAIN MODEL ────────────────────────────────────
def train(images, labels):
    print("\nPreparing training data...")
    
    # Encode labels (oval=0, round=1, square=2, etc.)
    encoder = LabelEncoder()
    encoded_labels = encoder.fit_transform(labels)
    num_classes = len(encoder.classes_)
    
    print(f"Classes: {encoder.classes_}")
    print(f"Number of classes: {num_classes}")
    
    # Split into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(
        images, encoded_labels,
        test_size=TEST_SPLIT,
        random_state=42,
        stratify=encoded_labels
    )
    
    print(f"Training set: {len(X_train)} images")
    print(f"Testing set:  {len(X_test)} images")
    
    # Build model
    model = build_model(num_classes)
    
    # Train model
    print("\nTraining started...")
    history = model.fit(
        X_train, y_train,
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        validation_data=(X_test, y_test),
        verbose=1
    )
    
    # Evaluate model
    print("\nEvaluating model...")
    test_loss, test_accuracy = model.evaluate(X_test, y_test)
    print(f"Test Accuracy: {test_accuracy * 100:.2f}%")
    
    return model, encoder, test_accuracy


# ── STEP 4: EXPORT TO TFLITE ───────────────────────────────
def export_tflite(model):
    print("\nExporting to TensorFlow Lite...")
    
    # Create models folder if it doesn't exist
    os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
        
    # Save model
    with open(MODEL_PATH, "wb") as f:
        f.write(tflite_model)
    
    print(f"✅ Model saved to: {MODEL_PATH}")


# ── MAIN ───────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 50)
    print("Script started!")
    print("Capstone Glow - Face Shape Classifier Training")
    print("=" * 50)
    
    # Check if labels.csv exists
    if not os.path.exists(LABELS_PATH):
        print("❌ ERROR: labels.csv not found!")
        print("Please ask Member 4 to finish labeling the dataset first.")
        exit()
    
    # Check if images folder exists
    if not os.path.exists(IMAGES_PATH):
        print("❌ ERROR: images folder not found!")
        exit()
    
    # Load dataset
    images, labels = load_dataset()
    
    if len(images) == 0:
        print("❌ ERROR: No images loaded!")
        print("Make sure labels.csv has face_shape column filled in.")
        exit()
    
    # Train model
    model, encoder, accuracy = train(images, labels)
    
    # Export to TFLite
    export_tflite(model)
    
    print("\n" + "=" * 50)
    print("TRAINING COMPLETE!")
    print(f"Final Accuracy: {accuracy * 100:.2f}%")
    print("Model saved to: backend/models/face_shape_model.tflite")
    print("Give this .tflite file to Member 2 for Flutter integration!")
    print("=" * 50)

        