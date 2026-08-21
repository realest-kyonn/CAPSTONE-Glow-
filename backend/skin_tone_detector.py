"""
Capstone Glow - Skin Tone Detector v2
Classifies undertone (warm / cool / neutral) and Monk Skin Tone scale
from facial skin pixels, in OpenCV's 8-bit LAB colour space.

WHAT CHANGED IN v2, AND WHY:

  1. It now samples CHEEK AND FOREHEAD PATCHES instead of running an HSV
     skin mask over the whole image. Measured on this project's own
     dataset, that mask was selecting a median of ~52% of the ENTIRE
     FRAME — background, hair, neck and clothing all entered the average
     that decided undertone. Cheeks are where undertone is actually read,
     and those pixels are skin by construction, so no mask is needed.

  2. That also removes the mask's `V >= 70` floor, which discarded dark
     pixels before averaging and biased the whole scale against darker
     skin — the old code never once produced a Monk value above 6.

  3. Monk scale now maps to the REAL published reference swatches by
     nearest neighbour in LAB, replacing ten hand-picked lightness
     cutoffs. Those cutoffs had been calibrated (implicitly) against
     whole-image averages, so once the pixels were fixed they put 196 of
     236 faces in the two LIGHTEST tones. Swatch mapping recentres on
     MST 5-6, i.e. medium, which is a plausible population.

  4. Undertone bands are derived from the measured distribution instead
     of guessed. The old [-2, 8] band classified ~72% of faces
     "neutral" — the least actionable answer a makeup app can give.

KNOWN LIMITATION — state this rather than hide it: even with correct
swatch mapping, ~97% of this dataset lands in MST 5-6 and only 5 of the
10 tones are ever produced. The photos are not colour-calibrated, and
uncontrolled lighting can shift a face several tones. This fixes a
BROKEN mapping; it does not deliver the scale's full range.

Dependencies: opencv-python, numpy, mediapipe
"""

import cv2
import numpy as np

# ── MONK SKIN TONE SCALE REFERENCE SWATCHES ────────────────
# The published 10-tone scale. Verified against two independent sources
# (en.wikipedia.org/wiki/Monk_Skin_Tone_Scale and skintone.google) —
# do NOT edit these from memory, they are a published standard.
MST_HEX = [
    "#f6ede4", "#f3e7db", "#f7ead0", "#eadaba", "#d7bd96",
    "#a07e56", "#825c43", "#604134", "#3a312a", "#292420",
]


def _hex_to_lab(h):
    """sRGB hex -> OpenCV 8-bit LAB, the same space face pixels average in."""
    h = h.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    bgr = np.array([[[b, g, r]]], dtype=np.uint8)
    return cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB)[0, 0].astype(float)


MST_LAB = np.array([_hex_to_lab(h) for h in MST_HEX])

# ── SAMPLING POINTS ────────────────────────────────────────
# MediaPipe face-mesh indices sitting on flat skin, away from eyes,
# brows, nostrils and lips. Cheeks carry undertone most reliably;
# forehead points are included to average out one-sided lighting.
CHEEK_POINTS    = [50, 280, 101, 330, 116, 345]
FOREHEAD_POINTS = [151, 9, 8]
PATCH_HALF      = 6          # patch is (2*HALF+1) px square

# ── UNDERTONE BANDS ────────────────────────────────────────
# b - a on cheek skin. Derived as terciles of the measured distribution
# (n=236, mean +3.56, sd 5.33), NOT chosen by hand. The previous [-2, 8]
# put ~72% of faces in "neutral"; these split the population into rough
# thirds so the recommendation engine has something to act on.
# Re-derive rather than nudge if the dataset changes.
UNDERTONE_COOL_BELOW = 1.85
UNDERTONE_WARM_ABOVE = 4.77

def _face_landmarks(image_path):
    """
    Face mesh for an image, or None. Imported lazily so this module still
    loads (and its constants stay usable) on a machine without mediapipe.
    """
    try:
        import mediapipe as mp
        from mediapipe.tasks import python as mp_python
        from mediapipe.tasks.python import vision as mp_vision
        from eye_shape_detector import _get_model_path
    except Exception:
        return None

    try:
        options = mp_vision.FaceLandmarkerOptions(
            base_options=mp_python.BaseOptions(model_asset_path=_get_model_path()),
            running_mode=mp_vision.RunningMode.IMAGE,
            num_faces=1,
        )
        img = cv2.imread(image_path)
        if img is None:
            return None
        mp_image = mp.Image(
            image_format=mp.ImageFormat.SRGB,
            data=cv2.cvtColor(img, cv2.COLOR_BGR2RGB),
        )
        with mp_vision.FaceLandmarker.create_from_options(options) as landmarker:
            result = landmarker.detect(mp_image)
        if not result.face_landmarks:
            return None
        return result.face_landmarks[0]
    except Exception:
        return None


def _sample_patches(lab_image, landmarks, img_w, img_h):
    """
    Mean LAB over small patches centred on the cheek and forehead points.

    Averaging several small patches rather than one region keeps a stray
    shadow, a blemish or a strand of hair from dominating, without
    reintroducing the whole-image contamination this replaces.
    """
    pixels = []
    for idx in CHEEK_POINTS + FOREHEAD_POINTS:
        try:
            lm = landmarks[idx]
        except (IndexError, TypeError):
            continue
        cx, cy = int(lm.x * img_w), int(lm.y * img_h)
        x0, x1 = max(0, cx - PATCH_HALF), min(img_w, cx + PATCH_HALF + 1)
        y0, y1 = max(0, cy - PATCH_HALF), min(img_h, cy + PATCH_HALF + 1)
        if x1 <= x0 or y1 <= y0:
            continue
        pixels.append(lab_image[y0:y1, x0:x1].reshape(-1, 3))

    if not pixels:
        return None
    return np.concatenate(pixels, axis=0).astype(float).mean(axis=0)


def _monk_scale(lab):
    """
    Nearest Monk swatch in LAB (1-10).

    Full LAB rather than lightness alone. Measured on this dataset the two
    agree 98.7% of the time, so this costs nothing and uses the hue
    information as well — and "nearest swatch in CIELAB" is a far easier
    thing to defend than ten hand-picked lightness cutoffs.
    """
    return int(np.argmin(np.linalg.norm(MST_LAB - lab, axis=1))) + 1


def _undertone(diff):
    """
    Undertone plus a confidence that reflects distance to the nearest band
    edge, rather than the old version's fixed guesses.

    b - a is positive for yellow (warm) and negative for pink/red (cool).
    Note both channels are OpenCV's 128-centred encoding, but the offset
    cancels in the difference, so this stays comparable to CIELAB b* - a*.
    """
    if diff > UNDERTONE_WARM_ABOVE:
        tone = "warm"
    elif diff < UNDERTONE_COOL_BELOW:
        tone = "cool"
    else:
        tone = "neutral"

    margin = min(abs(diff - UNDERTONE_COOL_BELOW),
                 abs(diff - UNDERTONE_WARM_ABOVE))
    if margin < 0.5:
        confidence = "low"
    elif margin < 1.5:
        confidence = "medium"
    else:
        confidence = "high"

    return tone, confidence


def detect_skin_tone(image_path, landmarks=None):
    """
    Classifies undertone and Monk scale from facial skin.

    Args:
        image_path: Path to the face image file
        landmarks:  Optional pre-computed MediaPipe face mesh. Pass this
                    when the caller already has one (the pipeline runs the
                    landmarker for eye shape anyway) to avoid detecting
                    twice. Detected internally when omitted.

    Returns:
        Dictionary with skin tone classification and details
    """

    image = cv2.imread(image_path)
    if image is None:
        return {"error": "Could not load image"}

    img_h, img_w = image.shape[:2]
    lab_image = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)

    if landmarks is None:
        landmarks = _face_landmarks(image_path)
    if landmarks is None:
        return {"error": "No face detected in image"}

    avg = _sample_patches(lab_image, landmarks, img_w, img_h)
    if avg is None:
        return {"error": "Could not sample skin pixels"}

    avg_L, avg_A, avg_B = avg
    skin_tone, confidence = _undertone(avg_B - avg_A)

    return {
        "skin_tone": skin_tone,
        "monk_scale": _monk_scale(avg),
        "confidence": confidence,
        "avg_lightness": round(float(avg_L), 2),
        "avg_warmth": round(float(avg_B), 2),
        "avg_redness": round(float(avg_A), 2),
    }


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    import os
    import sys

    # Filenames are 4-digit (img0001.jpg) — prepare_dataset.py writes them
    # with f"img{counter:04d}.jpg". The previous list here used 3-digit
    # names, so every path in it was missing and this test printed nothing
    # but errors.
    BASE_DIR  = os.path.dirname(os.path.abspath(__file__))
    IMAGE_DIR = os.path.join(BASE_DIR, "..", "data", "images")

    if len(sys.argv) > 1:
        test_images = sys.argv[1:]
    else:
        test_images = [
            os.path.join(IMAGE_DIR, f"img{n:04d}.jpg")
            for n in (1, 10, 50, 251, 400, 1600, 2400, 3200)
        ]

    print("=== Skin Tone Detection Results ===")
    print("Usage: py -3.12 backend/skin_tone_detector.py [image ...]\n")

    for img_path in test_images:
        name = os.path.basename(img_path)
        if not os.path.exists(img_path):
            print(f"{name}: [not found]\n")
            continue
        result = detect_skin_tone(img_path)
        print(f"{name}:")
        if "error" in result:
            print(f"  Error: {result['error']}\n")
            continue
        print(f"  Undertone : {result['skin_tone']} ({result['confidence']} confidence)")
        print(f"  Monk Scale: {result['monk_scale']}")
        print(f"  L: {result['avg_lightness']} | A: {result['avg_redness']} | "
              f"B: {result['avg_warmth']} | b-a: "
              f"{result['avg_warmth'] - result['avg_redness']:+.2f}")
        print()