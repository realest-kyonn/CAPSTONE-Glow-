"""
Capstone Glow - check_csv.py
Checks labels.csv for distribution, case issues, and missing images.
Run this to understand your dataset before training.

Usage: py -3.12 check_csv.py
"""

import os
import pandas as pd

# ── CONFIG ─────────────────────────────────────────────────
CSV_PATH   = r"data/labels.csv"
IMAGES_DIR = r"data/images"

# ── LOAD CSV ───────────────────────────────────────────────
print("=== Capstone Glow — Dataset Check ===\n")

df = pd.read_csv(CSV_PATH)
print(f"Total rows in CSV: {len(df)}")
print(f"Columns: {list(df.columns)}\n")

# ── FACE SHAPE DISTRIBUTION ────────────────────────────────
print("── Face Shape Distribution ──────────────────")
shape_counts = df['face_shape'].value_counts()
for shape, count in shape_counts.items():
    bar    = "█" * (count // 5)
    status = "⚠️  LOW" if count < 80 else "✅"
    print(f"  {shape:<12} {count:>4}  {bar} {status}")

print(f"\n  Total: {shape_counts.sum()}")
print(f"  Min class: {shape_counts.min()} ({shape_counts.idxmin()})")
print(f"  Max class: {shape_counts.max()} ({shape_counts.idxmax()})")
print(f"  Imbalance ratio: {round(shape_counts.max() / shape_counts.min(), 1)}x\n")

# ── CASE SENSITIVITY CHECK ─────────────────────────────────
print("── Case Sensitivity Check ───────────────────")
all_shapes  = df['face_shape'].unique()
lower_check = df['face_shape'].str.lower().value_counts()
print("  All unique values found in CSV:")
for s in sorted(all_shapes):
    print(f"    '{s}'")

# Check for mixed case
lower_vals = df['face_shape'].str.lower()
if (lower_vals != df['face_shape']).any():
    bad = df[lower_vals != df['face_shape']]['face_shape'].unique()
    print(f"\n  ⚠️  Mixed case found: {bad}")
    print("  Fix: standardize all to Title Case (Oval, Round, etc.)")
else:
    print("\n  ✅ All values are consistently cased\n")

# ── UNDERTONE DISTRIBUTION ─────────────────────────────────
if 'skin_tone' in df.columns:
    print("── Skin Tone / Undertone Distribution ───────")
    tone_counts = df['skin_tone'].value_counts()
    for tone, count in tone_counts.items():
        print(f"  {tone:<12} {count:>4}")
    print()

# ── MISSING IMAGES CHECK ───────────────────────────────────
print("── Image Files Check ────────────────────────")
image_files  = set(os.listdir(IMAGES_DIR))
csv_images   = set(df['image_name'].values)
missing_imgs = csv_images - image_files
extra_imgs   = image_files - csv_images

print(f"  Images in folder:  {len(image_files)}")
print(f"  Images in CSV:     {len(csv_images)}")
print(f"  Missing from disk: {len(missing_imgs)}")
print(f"  Not in CSV:        {len(extra_imgs)}")

if missing_imgs:
    print(f"\n  ⚠️  These are in CSV but missing from disk:")
    for f in sorted(missing_imgs)[:10]:
        print(f"    - {f}")
    if len(missing_imgs) > 10:
        print(f"    ... and {len(missing_imgs)-10} more")

# ── RECOMMENDATION ─────────────────────────────────────────
print(f"\n{'='*45}")
print("Recommendation:")
min_count = shape_counts.min()
if min_count < 80:
    print(f"⚠️  Smallest class has only {min_count} images.")
    print(f"   Balance the dataset to at least 80-100 per class.")
    print(f"   Options:")
    print(f"   1. Add more images to underrepresented classes")
    print(f"   2. Undersample Oval (take only 100 from 180)")
    print(f"   3. Use class_weight in training to compensate")
else:
    print("✅ Dataset looks balanced enough to train!")