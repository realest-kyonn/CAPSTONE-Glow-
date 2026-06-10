"""
Capstone Glow - test_crop.py (v2)
Tests face detection using OpenCV instead of MediaPipe
Works with all MediaPipe versions

Usage: py -3.12 test_crop.py
"""

import os
import cv2

# ── CONFIG ─────────────────────────────────────────────────
IMAGES_DIR  = r"data/images"
SAMPLE_SIZE = 20
SAVE_CROPS  = True
CROP_DIR    = "test_crops"

# ── SETUP — uses OpenCV built-in face detector ─────────────
# No mediapipe needed for this test
cascade_path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
detector     = cv2.CascadeClassifier(cascade_path)

if SAVE_CROPS:
    os.makedirs(CROP_DIR, exist_ok=True)

# ── RUN TEST ───────────────────────────────────────────────
all_images   = [f for f in sorted(os.listdir(IMAGES_DIR))
                if f.lower().endswith((".jpg", ".jpeg", ".png"))]
images       = all_images[:SAMPLE_SIZE]
detected     = 0
not_detected = []

print("=== Capstone Glow — Face Crop Test (OpenCV) ===")
print(f"Testing {len(images)} images from {IMAGES_DIR}\n")

for fname in images:
    path = os.path.join(IMAGES_DIR, fname)
    img  = cv2.imread(path)

    if img is None:
        print(f"  [!] Cannot read: {fname}")
        not_detected.append(fname)
        continue

    gray  = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = detector.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=4,
        minSize=(60, 60)
    )

    if len(faces) > 0:
        detected += 1
        x, y, w, h = faces[0]

        # Add padding
        pad = int(0.2 * min(w, h))
        x1  = max(0, x - pad)
        y1  = max(0, y - pad)
        x2  = min(img.shape[1], x + w + pad)
        y2  = min(img.shape[0], y + h + pad)

        cropped = img[y1:y2, x1:x2]
        status  = "✅"

        if SAVE_CROPS and cropped.size > 0:
            cv2.imwrite(os.path.join(CROP_DIR, fname), cropped)
    else:
        status = "❌"
        not_detected.append(fname)

    print(f"  {status} {fname}")

# ── SUMMARY ────────────────────────────────────────────────
rate = detected / len(images) if images else 0
print(f"\n{'='*45}")
print(f"Results:         {detected}/{len(images)} faces detected")
print(f"Detection rate:  {round(rate * 100)}%")

if not_detected:
    print(f"\nFailed on:")
    for f in not_detected:
        print(f"  - {f}")

if SAVE_CROPS:
    print(f"\nCrops saved to: {CROP_DIR}/")
    print("Open that folder and visually check if crops look correct!")

print(f"\n{'='*45}")
if rate >= 0.8:
    print("✅ Face detection is working well (80%+)")
    print("   Safe to use face cropping in training!")
elif rate >= 0.5:
    print("⚠️  Detection is okay but not great.")
    print("   Consider training WITHOUT face cropping first.")
else:
    print("❌ Face detection is poor — this is hurting your model!")
    print("   Train WITHOUT face cropping for now.")