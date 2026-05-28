import os
import random
import shutil
import csv

# ── SOURCES ────────────────────────────────────────────────
kaggle_source = r"C:\Users\Kean_2\Downloads\archive\FaceShape Dataset\training_set"
fairface_source = r"C:\Users\Kean_2\Downloads\fairface-img-margin125-trainval\train"

# ── DESTINATION ────────────────────────────────────────────
destination = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images"
labels_path = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\labels.csv"

# ── SETTINGS ───────────────────────────────────────────────
kaggle_per_shape = 50
fairface_count = 250
face_shapes = ["Square", "Round", "Oval", "Oblong", "Heart"]

# Create destination folder and clear it
os.makedirs(destination, exist_ok=True)
for f in os.listdir(destination):
    os.remove(os.path.join(destination, f))
print("Cleared destination folder")

all_labels = []
counter = 1

# ── STEP 1: Kaggle images (img001 to img250) ───────────────
print("\nSelecting Kaggle images...")
for shape in face_shapes:
    shape_folder = os.path.join(kaggle_source, shape)
    all_images = [f for f in os.listdir(shape_folder)
                  if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    selected = random.sample(all_images, min(kaggle_per_shape, len(all_images)))

    for image in selected:
        src = os.path.join(shape_folder, image)
        new_name = f"img{counter:03d}.jpg"
        dst = os.path.join(destination, new_name)
        shutil.copy2(src, dst)
        # face shape already known, skin tone needs labeling
        all_labels.append((new_name, "", shape.lower()))
        counter += 1

    print(f"  ✓ {shape}: 50 images → img{counter-50:03d} to img{counter-1:03d}")

# ── STEP 2: FairFace images (img251 to img500) ─────────────
print("\nSelecting FairFace images...")
all_fairface = [f for f in os.listdir(fairface_source)
                if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
selected_fairface = random.sample(all_fairface, min(fairface_count, len(all_fairface)))

for image in selected_fairface:
    src = os.path.join(fairface_source, image)
    new_name = f"img{counter:03d}.jpg"
    dst = os.path.join(destination, new_name)
    shutil.copy2(src, dst)
    # both skin tone and face shape need labeling
    all_labels.append((new_name, "", ""))
    counter += 1

print(f"  ✓ FairFace: 250 images → img251 to img500")

# ── STEP 3: Create labels.csv ──────────────────────────────
with open(labels_path, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["image_name", "skin_tone", "face_shape"])
    for row in all_labels:
        writer.writerow(row)

# ── SUMMARY ────────────────────────────────────────────────
print("\n" + "="*50)
print("DONE! Summary:")
print(f"  img001-img250 → Kaggle (face shape pre-labeled)")
print(f"  img251-img500 → FairFace (both need labeling)")
print(f"  TOTAL: 500 images")
print("\nWhat the annotator still needs to fill in:")
print("  - skin_tone (1-10) for ALL 500 images")
print("  - face_shape for img251-img500 only")
print("="*50)py -3.12 data/select_images.py