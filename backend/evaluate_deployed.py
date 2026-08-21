"""
Capstone Glow - As-Deployed Accuracy Evaluator

Unlike train_model.py's model.evaluate() (which tests the raw in-memory
Keras model with preprocessing applied exactly once, as a layer), this
script tests the ACTUAL pipeline a real user hits: MTCNN crop -> resize
-> raw RGB -> face_shape_model.tflite via detect_face_shape().

This is the number that matters for your defense — it reflects the
fixed face_shape_detector.py, not just the training-time Keras model.

Supports two dataset layouts, auto-detected:

  MODE 1 — Folder-per-class (typical Kaggle face-shape "testing_set"):
      test_set/
        Heart/  img1.jpg  img2.jpg ...
        Long/   ...
        Oval/   ...
        Round/  ...
        Square/ ...

  MODE 2 — CSV (same format as train_model.py's labels.csv):
      labels.csv with columns: image_name, face_shape
      (point IMAGES_PATH at the folder holding those images)

Usage:
    py -3.12 backend/evaluate_deployed.py "C:\\path\\to\\test_set"
    py -3.12 backend/evaluate_deployed.py "C:\\path\\to\\labels.csv" --images "C:\\path\\to\\images"
"""

import os
import sys
import argparse
from collections import defaultdict

from face_shape_detector import detect_face_shape, _labels as MODEL_LABELS

VALID_LABELS = {l.lower() for l in MODEL_LABELS}  # heart, long, oval, round, square


def _normalize_label(raw):
    return raw.strip().title()


def collect_folder_mode(test_dir):
    """Walk test_dir/<ClassName>/*.jpg style layout."""
    samples = []
    for entry in sorted(os.listdir(test_dir)):
        class_dir = os.path.join(test_dir, entry)
        if not os.path.isdir(class_dir):
            continue
        label = _normalize_label(entry)
        if label.lower() not in VALID_LABELS:
            print(f"[!] Skipping unrecognized folder '{entry}' (doesn't match model labels)")
            continue
        for fname in sorted(os.listdir(class_dir)):
            if fname.lower().endswith((".jpg", ".jpeg", ".png")):
                samples.append((os.path.join(class_dir, fname), label))
    return samples


def collect_csv_mode(csv_path, images_dir):
    import pandas as pd
    df = pd.read_csv(csv_path)
    df = df.dropna(subset=["face_shape"])
    df["face_shape"] = df["face_shape"].str.strip().str.title()

    samples = []
    for _, row in df.iterrows():
        img_path = os.path.join(images_dir, row["image_name"])
        samples.append((img_path, row["face_shape"]))
    return samples


def evaluate(samples):
    total = 0
    correct = 0
    skipped = 0

    per_class_total = defaultdict(int)
    per_class_correct = defaultdict(int)

    # confusion[true_label][predicted_label] = count
    confusion = defaultdict(lambda: defaultdict(int))

    print(f"\nEvaluating {len(samples)} images through the real detect_face_shape() pipeline...\n")

    for idx, (img_path, true_label) in enumerate(samples, 1):
        if not os.path.exists(img_path):
            skipped += 1
            continue

        result = detect_face_shape(img_path)

        if result.get("error") and result.get("face_shape") is None:
            skipped += 1
            continue

        predicted_label = result["face_shape"]

        total += 1
        per_class_total[true_label] += 1
        confusion[true_label][predicted_label] += 1

        if predicted_label == true_label:
            correct += 1
            per_class_correct[true_label] += 1

        if idx % 50 == 0:
            running_acc = (correct / total * 100) if total else 0.0
            print(f"  {idx}/{len(samples)} processed... running accuracy: {running_acc:.1f}%")

    return total, correct, skipped, per_class_total, per_class_correct, confusion


def print_report(total, correct, skipped, per_class_total, per_class_correct, confusion):
    print("\n" + "=" * 52)
    print("  AS-DEPLOYED ACCURACY REPORT")
    print("  (real detect_face_shape() pipeline, post preprocessing-fix)")
    print("=" * 52)

    if total == 0:
        print("❌ No valid images were evaluated. Check your paths.")
        return

    overall_acc = correct / total * 100
    print(f"\nTotal evaluated : {total}")
    print(f"Skipped (missing/unreadable): {skipped}")
    print(f"\n✅ Overall as-deployed accuracy: {overall_acc:.2f}%  ({correct}/{total})")

    print("\nPer-class accuracy:")
    for label in sorted(per_class_total.keys()):
        n = per_class_total[label]
        c = per_class_correct.get(label, 0)
        acc = (c / n * 100) if n else 0.0
        bar = "█" * int(acc / 5)
        print(f"  {label:<10} {acc:5.1f}%  ({c}/{n})  {bar}")

    print("\nConfusion matrix (rows = true label, cols = predicted):")
    labels_sorted = sorted(per_class_total.keys())
    header = "  " + "".join(f"{l:>9}" for l in labels_sorted)
    print(header)
    for true_label in labels_sorted:
        row = f"  {true_label:<9}"
        for pred_label in labels_sorted:
            row += f"{confusion[true_label].get(pred_label, 0):>9}"
        print(row)

    print("\n" + "=" * 52)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="As-deployed accuracy evaluator")
    parser.add_argument("path", help="Path to test_set folder (folder-per-class mode) OR labels.csv (CSV mode)")
    parser.add_argument("--images", help="Path to images folder (required if 'path' is a CSV)")
    args = parser.parse_args()

    if args.path.lower().endswith(".csv"):
        if not args.images:
            print("❌ CSV mode requires --images <folder>")
            sys.exit(1)
        samples = collect_csv_mode(args.path, args.images)
    else:
        samples = collect_folder_mode(args.path)

    if not samples:
        print("❌ No samples found. Check your path/layout.")
        sys.exit(1)

    total, correct, skipped, per_class_total, per_class_correct, confusion = evaluate(samples)
    print_report(total, correct, skipped, per_class_total, per_class_correct, confusion)