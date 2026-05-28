"""
Capstone Glow - Skin Tone Detector
Analyzes face image pixels to classify skin tone as warm, cool, or neutral
Uses LAB color space for accurate skin tone analysis
"""

import cv2
import numpy as np

def detect_skin_tone(image_path):
    """
    Analyzes a face image and returns skin tone classification
    Args:
        image_path: Path to the face image file
    Returns:
        Dictionary with skin tone classification and details
    """

    # STEP 1: Load the image
    image = cv2.imread(image_path)
    if image is None:
        return {"error": "Could not load image"}

    # STEP 2: Convert to LAB color space
    lab_image = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)

    # STEP 3: Extract skin region using HSV mask
    hsv_image = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    lower_skin = np.array([0, 20, 70], dtype=np.uint8)
    upper_skin = np.array([20, 255, 255], dtype=np.uint8)
    skin_mask = cv2.inRange(hsv_image, lower_skin, upper_skin)

    # STEP 4: Get average LAB values of skin pixels
    skin_pixels = lab_image[skin_mask > 0]
    if len(skin_pixels) == 0:
        return {"error": "No skin detected in image"}

    avg_L = np.mean(skin_pixels[:, 0])
    avg_A = np.mean(skin_pixels[:, 1])
    avg_B = np.mean(skin_pixels[:, 2])

    # STEP 5: Classify skin tone
    # B - A difference tells us warm vs cool
    # positive = more yellow = WARM
    # negative = more pink/red = COOL
    # near zero = balanced = NEUTRAL
    diff = avg_B - avg_A

    if diff > 8:
        skin_tone = "warm"
        confidence = "high" if diff > 12 else "medium"
    elif diff < -2:
        skin_tone = "cool"
        confidence = "high" if diff < -6 else "medium"
    else:
        skin_tone = "neutral"
        confidence = "medium"

    # STEP 6: Map to Monk Scale (1-10)
    if avg_L > 180:
        monk_scale = 1
    elif avg_L > 160:
        monk_scale = 2
    elif avg_L > 145:
        monk_scale = 3
    elif avg_L > 130:
        monk_scale = 4
    elif avg_L > 115:
        monk_scale = 5
    elif avg_L > 100:
        monk_scale = 6
    elif avg_L > 85:
        monk_scale = 7
    elif avg_L > 70:
        monk_scale = 8
    elif avg_L > 55:
        monk_scale = 9
    else:
        monk_scale = 10

    return {
        "skin_tone": skin_tone,
        "monk_scale": monk_scale,
        "confidence": confidence,
        "avg_lightness": round(float(avg_L), 2),
        "avg_warmth": round(float(avg_B), 2),
        "avg_redness": round(float(avg_A), 2)
    }


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    import os

    test_images = [
        r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images\img001.jpg",
        r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images\img010.jpg",
        r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images\img050.jpg",
        r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images\img251.jpg",
        r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images\img400.jpg",
    ]

    print("=== Skin Tone Detection Results ===\n")
    for img_path in test_images:
        result = detect_skin_tone(img_path)
        img_name = img_path.split("\\")[-1]
        print(f"{img_name}:")
        print(f"  Skin Tone: {result.get('skin_tone')}")
        print(f"  Monk Scale: {result.get('monk_scale')}")
        print(f"  Confidence: {result.get('confidence')}")
        print(f"  L: {result.get('avg_lightness')} | A: {result.get('avg_redness')} | B: {result.get('avg_warmth')}")
        print()