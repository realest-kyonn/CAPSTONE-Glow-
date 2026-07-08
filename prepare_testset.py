"""
Capstone Glow - prepare_testset.py
Copies Kaggle testing_set images to data/test_images/
Generates test_labels.csv

Run from repo root: py -3.12 prepare_testset.py
"""
import os, pandas as pd

TEST_SRC    = r"C:\Users\Kean_2\Downloads\archive\FaceShape Dataset\testing_set"
TEST_DST    = r"data/test_images"
TEST_LABELS = r"data/test_labels.csv"
SHAPES      = ["Heart", "Long", "Oval", "Round", "Square"]

print("=" * 52)
print("  Capstone Glow — Test Set Preparation")
print("=" * 52)

os.makedirs(TEST_DST, exist_ok=True)
for f in os.listdir(TEST_DST):
    os.remove(os.path.join(TEST_DST, f))
print(f"\n🗑️  Cleared {TEST_DST}")

print("\n📁 Copying test images...")
rows, counter = [], 1

for shape in SHAPES:
    shape_dir = os.path.join(TEST_SRC, shape)
    if not os.path.exists(shape_dir):
        print(f"   ❌ Not found: {shape_dir}")
        continue
    images = [f for f in sorted(os.listdir(shape_dir)) if f.lower().endswith((".jpg",".jpeg",".png"))]
    for img in images:
        src = os.path.join(shape_dir, img)
        dst = os.path.join(TEST_DST, f"test{counter:04d}.jpg")
        with open(src,"rb") as fi, open(dst,"wb") as fo:
            fo.write(fi.read())
        rows.append({"image_name": f"test{counter:04d}.jpg", "face_shape": shape})
        counter += 1
    print(f"   ✅ {shape:<10} {len(images)} images")

df = pd.DataFrame(rows)
df.to_csv(TEST_LABELS, index=False)

print(f"\n{'='*52}")
print(f"  DONE! Total: {len(df)} test images")
for shape, count in df["face_shape"].value_counts().items():
    print(f"    {shape:<10} {count}")
print(f"{'='*52}")
