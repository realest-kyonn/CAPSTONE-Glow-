"""
Capstone Glow - prepare_dataset.py
Copies 800 Kaggle images per shape to data/images/
Generates fresh labels.csv

Run from repo root: py -3.12 prepare_dataset.py
"""
import os, pandas as pd, shutil

KAGGLE_DIR  = r"C:\Users\Kean_2\Downloads\archive\FaceShape Dataset\training_set"
OUTPUT_DIR  = r"data/images"
LABELS_PATH = r"data/labels.csv"
SHAPES      = ["Heart", "Long", "Oval", "Round", "Square"]
MAX_PER     = 800

print("=" * 52)
print("  Capstone Glow — Dataset Preparation")
print("=" * 52)

# Backup current CSV
if os.path.exists(LABELS_PATH):
    shutil.copy(LABELS_PATH, LABELS_PATH.replace(".csv", "_backup.csv"))
    print("\n💾 Backed up labels.csv to labels_backup.csv")

# Clear images
os.makedirs(OUTPUT_DIR, exist_ok=True)
for f in os.listdir(OUTPUT_DIR):
    os.remove(os.path.join(OUTPUT_DIR, f))
print(f"🗑️  Cleared {OUTPUT_DIR}")

# Copy images
print("\n📁 Copying Kaggle images...")
rows, counter = [], 1

for shape in SHAPES:
    shape_dir = os.path.join(KAGGLE_DIR, shape)
    if not os.path.exists(shape_dir):
        print(f"   ❌ Not found: {shape_dir}")
        continue
    images = [f for f in sorted(os.listdir(shape_dir)) if f.lower().endswith((".jpg",".jpeg",".png"))][:MAX_PER]
    for img in images:
        src = os.path.join(shape_dir, img)
        dst = os.path.join(OUTPUT_DIR, f"img{counter:04d}.jpg")
        with open(src,"rb") as fi, open(dst,"wb") as fo:
            fo.write(fi.read())
        rows.append({"image_name": f"img{counter:04d}.jpg", "face_shape": shape})
        counter += 1
    print(f"   ✅ {shape:<10} {len(images)} images")

df = pd.DataFrame(rows)
df.to_csv(LABELS_PATH, index=False)

print(f"\n{'='*52}")
print(f"  DONE! Total: {len(df)} images")
for shape, count in df["face_shape"].value_counts().items():
    print(f"    {shape:<10} {count}")
print(f"\n  Backup: labels_backup.csv")
print(f"{'='*52}")
