import os
import random
import shutil
import pandas as pd

# ── PATHS ──────────────────────────────────────────────────
KAGGLE_SOURCE = r"C:\Users\Kean_2\Downloads\archive\FaceShape Dataset\training_set"
IMAGES_DEST   = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images"
LABELS_PATH   = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\labels.csv"

# ── HOW MANY TO ADD FROM KAGGLE PER CLASS ──────────────────
KAGGLE_TO_ADD = {
    "Oval":  275,
}

# ── LOAD EXISTING LABELS ───────────────────────────────────
df = pd.read_csv(LABELS_PATH)
print(f"Current dataset: {len(df)} images")
print(f"Current distribution:\n{df['face_shape'].value_counts()}\n")

# Find the last image number
existing_nums = []
for name in df['image_name']:
    try:
        num = int(name.replace('img', '').replace('.jpg', ''))
        existing_nums.append(num)
    except:
        pass

counter = max(existing_nums) + 1
print(f"Starting from: img{counter:03d}.jpg\n")

new_rows = []

# ── PULL FROM KAGGLE ───────────────────────────────────────
for kaggle_folder, count in KAGGLE_TO_ADD.items():
    folder_path = os.path.join(KAGGLE_SOURCE, kaggle_folder)

    if not os.path.exists(folder_path):
        print(f"❌ Folder not found: {folder_path}")
        continue

    # Get all images in folder
    all_images = [f for f in os.listdir(folder_path)
                  if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

    # Exclude images already in dataset
    existing_names = set(df['image_name'].tolist())
    available = [f for f in all_images if f not in existing_names]

    # Randomly pick the needed count
    selected = random.sample(available, min(count, len(available)))

    # Copy and rename
    for image in selected:
        src      = os.path.join(folder_path, image)
        new_name = f"img{counter:03d}.jpg"
        dst      = os.path.join(IMAGES_DEST, new_name)
        shutil.copy2(src, dst)

        # Label as Long if Oblong
        face_shape = "Long" if kaggle_folder == "Oblong" else kaggle_folder
        new_rows.append({
            "image_name": new_name,
            "skin_tone":  "",
            "face_shape": face_shape
        })
        counter += 1

    print(f"✅ {kaggle_folder}: {len(selected)} images added")

# ── UPDATE LABELS.CSV ──────────────────────────────────────
new_df     = pd.DataFrame(new_rows)
updated_df = pd.concat([df, new_df], ignore_index=True)
updated_df.to_csv(LABELS_PATH, index=False)

print(f"\nUpdated dataset: {len(updated_df)} images")
print(f"New distribution:\n{updated_df['face_shape'].value_counts()}")
print(f"\n✅ labels.csv updated!")