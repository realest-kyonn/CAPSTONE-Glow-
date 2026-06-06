"""
Capstone Glow - Eye Shape Detector
Detects eye shape from a facial image using MediaPipe FaceMesh landmarks.

Eye Shapes Detected:
    - almond    : Most versatile, slightly pointed ends
    - round     : Visible white above/below iris, circular appearance
    - monolid   : Little to no crease visible on upper lid
    - hooded    : Upper lid partially hidden by brow bone/skin fold
    - downturned: Outer corners angle downward
    - close_set : Eyes positioned closer to center of face

Detection Method:
    - Eye Aspect Ratio (EAR)  -> round vs almond vs hooded
    - Outer corner angle      -> downturned vs upturned
    - Lid visibility ratio    -> hooded vs normal
    - Inter-eye distance      -> close-set vs normal

Dependencies:
    pip install mediapipe opencv-python numpy
    (use: py -3.12 -m pip install mediapipe opencv-python numpy)
"""

import cv2
import numpy as np

try:
    import mediapipe as mp
    MEDIAPIPE_AVAILABLE = True
except ImportError:
    MEDIAPIPE_AVAILABLE = False
    print("[WARNING] mediapipe not installed. Run: py -3.12 -m pip install mediapipe")


# ── MediaPipe FaceMesh landmark indices for eyes ──────────────────────────────
# Left eye landmarks (from FaceMesh 468-point model)
LEFT_EYE = {
    "inner_corner":  133,
    "outer_corner":  33,
    "upper_lid_top": 159,   # highest point of upper lid
    "upper_lid_mid": 158,
    "lower_lid_bot": 145,   # lowest point of lower lid
    "lower_lid_mid": 153,
    "lid_crease":    246,   # crease/fold point
    "iris_center":   468    # iris center (only in refined landmarks)
}

# Right eye landmarks
RIGHT_EYE = {
    "inner_corner":  362,
    "outer_corner":  263,
    "upper_lid_top": 386,
    "upper_lid_mid": 385,
    "lower_lid_bot": 374,
    "lower_lid_mid": 380,
    "lid_crease":    466,
    "iris_center":   473
}

# Additional landmarks for inter-eye distance
LEFT_EYE_CENTER  = 468   # left iris center
RIGHT_EYE_CENTER = 473   # right iris center
NOSE_TIP         = 4
FACE_LEFT_EDGE   = 234
FACE_RIGHT_EDGE  = 454


def _euclidean(p1, p2):
    """Distance between two (x, y) points."""
    return np.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)


def _get_landmark_xy(landmarks, index, img_w, img_h):
    """Convert normalized landmark to pixel coordinates."""
    lm = landmarks[index]
    return (int(lm.x * img_w), int(lm.y * img_h))


def _eye_aspect_ratio(landmarks, eye_indices, img_w, img_h):
    """
    EAR = vertical_opening / horizontal_width
    Higher EAR = rounder eye
    Lower EAR  = more almond/hooded
    """
    inner  = _get_landmark_xy(landmarks, eye_indices["inner_corner"], img_w, img_h)
    outer  = _get_landmark_xy(landmarks, eye_indices["outer_corner"], img_w, img_h)
    top    = _get_landmark_xy(landmarks, eye_indices["upper_lid_top"], img_w, img_h)
    bottom = _get_landmark_xy(landmarks, eye_indices["lower_lid_bot"], img_w, img_h)

    width   = _euclidean(inner, outer)
    height  = _euclidean(top, bottom)

    if width == 0:
        return 0.0
    return height / width


def _outer_corner_angle(landmarks, eye_indices, img_w, img_h):
    """
    Angle of outer corner relative to inner corner.
    Negative angle = downturned (outer corner lower than inner)
    Positive angle = upturned
    """
    inner = _get_landmark_xy(landmarks, eye_indices["inner_corner"], img_w, img_h)
    outer = _get_landmark_xy(landmarks, eye_indices["outer_corner"], img_w, img_h)

    dx = outer[0] - inner[0]
    dy = outer[1] - inner[1]   # positive y is downward in image coords

    if dx == 0:
        return 0.0

    angle_rad = np.arctan2(-dy, abs(dx))   # negate dy so up = positive
    return np.degrees(angle_rad)


def _lid_visibility_ratio(landmarks, eye_indices, img_w, img_h):
    """
    Ratio of visible lid height to total eye opening.
    Low ratio = hooded (lid hidden by skin fold)
    """
    top    = _get_landmark_xy(landmarks, eye_indices["upper_lid_top"], img_w, img_h)
    crease = _get_landmark_xy(landmarks, eye_indices["lid_crease"], img_w, img_h)
    bottom = _get_landmark_xy(landmarks, eye_indices["lower_lid_bot"], img_w, img_h)

    total_height = _euclidean(top, bottom)
    crease_to_top = _euclidean(crease, top)

    if total_height == 0:
        return 1.0
    return crease_to_top / total_height


def _inter_eye_ratio(landmarks, img_w, img_h):
    """
    Ratio: distance between eyes / face width
    Low ratio = close-set eyes
    """
    try:
        left_inner  = _get_landmark_xy(landmarks, LEFT_EYE["inner_corner"], img_w, img_h)
        right_inner = _get_landmark_xy(landmarks, RIGHT_EYE["inner_corner"], img_w, img_h)
        face_left   = _get_landmark_xy(landmarks, FACE_LEFT_EDGE, img_w, img_h)
        face_right  = _get_landmark_xy(landmarks, FACE_RIGHT_EDGE, img_w, img_h)

        inter_eye_dist = _euclidean(left_inner, right_inner)
        face_width     = _euclidean(face_left, face_right)

        if face_width == 0:
            return 0.3
        return inter_eye_dist / face_width
    except Exception:
        return 0.3   # default to normal spacing


def _classify_eye_shape(ear, angle, lid_ratio, inter_ratio):
    """
    Rule-based classifier using computed eye metrics.

    Thresholds derived from makeup literature and facial geometry research.

    Args:
        ear         : Eye Aspect Ratio (height/width)
        angle       : Outer corner angle in degrees (negative = downturned)
        lid_ratio   : Visible lid ratio (low = hooded)
        inter_ratio : Inter-eye / face-width ratio (low = close-set)

    Returns:
        str: one of almond | round | monolid | hooded | downturned | close_set
    """

    # Close-set: inter-eye gap is narrow relative to face width
    if inter_ratio < 0.20:
        return "close_set"

    # Hooded: very little visible lid (skin fold covers the lid)
    if lid_ratio < 0.15:
        return "hooded"

    # Monolid: minimal lid crease visibility AND low EAR
    if lid_ratio < 0.22 and ear < 0.28:
        return "monolid"

    # Downturned: outer corner significantly lower than inner corner
    if angle < -5.0:
        return "downturned"

    # Round: high EAR — eye is noticeably taller relative to width
    if ear > 0.35:
        return "round"

    # Default: almond (most common, balanced proportions)
    return "almond"


def detect_eye_shape(image_path):
    """
    Main function — detects eye shape from an image file.

    Args:
        image_path (str): Path to the image file (jpg, png, etc.)

    Returns:
        dict: {
            "eye_shape": str,           # detected shape
            "confidence": str,          # "high" | "medium" | "low"
            "metrics": dict,            # raw measurements for debugging
            "error": str | None         # error message if detection failed
        }
    """

    if not MEDIAPIPE_AVAILABLE:
        return {
            "eye_shape": "almond",
            "confidence": "low",
            "metrics": {},
            "error": "mediapipe not installed — defaulting to almond"
        }

    mp_face_mesh = mp.solutions.face_mesh

    img = cv2.imread(image_path)
    if img is None:
        return {"eye_shape": None, "confidence": "low", "metrics": {}, "error": f"Could not load image: {image_path}"}

    img_h, img_w = img.shape[:2]
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    with mp_face_mesh.FaceMesh(
        static_image_mode=True,
        max_num_faces=1,
        refine_landmarks=True,    # enables iris landmarks (468, 473)
        min_detection_confidence=0.5
    ) as face_mesh:

        results = face_mesh.process(img_rgb)

        if not results.multi_face_landmarks:
            return {
                "eye_shape": "almond",
                "confidence": "low",
                "metrics": {},
                "error": "No face detected in image"
            }

        landmarks = results.multi_face_landmarks[0].landmark

        # ── Compute metrics for both eyes, then average ────────────────────
        left_ear    = _eye_aspect_ratio(landmarks, LEFT_EYE, img_w, img_h)
        right_ear   = _eye_aspect_ratio(landmarks, RIGHT_EYE, img_w, img_h)
        avg_ear     = (left_ear + right_ear) / 2

        left_angle  = _outer_corner_angle(landmarks, LEFT_EYE, img_w, img_h)
        right_angle = _outer_corner_angle(landmarks, RIGHT_EYE, img_w, img_h)
        avg_angle   = (left_angle + right_angle) / 2

        left_lid    = _lid_visibility_ratio(landmarks, LEFT_EYE, img_w, img_h)
        right_lid   = _lid_visibility_ratio(landmarks, RIGHT_EYE, img_w, img_h)
        avg_lid     = (left_lid + right_lid) / 2

        inter_ratio = _inter_eye_ratio(landmarks, img_w, img_h)

        # ── Classify ───────────────────────────────────────────────────────
        eye_shape = _classify_eye_shape(avg_ear, avg_angle, avg_lid, inter_ratio)

        # ── Confidence: high if metrics are clearly in one category ────────
        confidence = "high"
        if 0.28 <= avg_ear <= 0.35 and -5 <= avg_angle <= 0:
            confidence = "medium"   # borderline between almond/round/downturned

        metrics = {
            "eye_aspect_ratio":     round(avg_ear, 4),
            "outer_corner_angle":   round(avg_angle, 2),
            "lid_visibility_ratio": round(avg_lid, 4),
            "inter_eye_ratio":      round(inter_ratio, 4),
        }

        return {
            "eye_shape":  eye_shape,
            "confidence": confidence,
            "metrics":    metrics,
            "error":      None
        }


# ── Makeup recommendations lookup for eye shape ────────────────────────────────
EYE_SHAPE_MAKEUP = {
    "almond": {
        "eyeliner": "Classic thin liner or winged liner — almond eyes are the most versatile so any style works beautifully.",
        "eyeshadow_technique": "Apply a soft wash of color on the lid with a slightly deeper shade on the outer corner for everyday dimension.",
        "why": "Almond eyes are naturally balanced with slightly pointed ends, so almost any liner or shadow technique flatters them."
    },
    "round": {
        "eyeliner": "Winged or cat-eye liner extending just past the outer corner to elongate.",
        "eyeshadow_technique": "Focus darker shades on the outer corner and blend slightly upward to create an elongating effect.",
        "why": "Round eyes have more visible white and a circular appearance. Extending liner and shadow outward creates the illusion of length."
    },
    "monolid": {
        "eyeliner": "Graphic or bold liner on the upper lid — avoid tight lining as it can disappear on monolids.",
        "eyeshadow_technique": "Apply bold color across the entire lid without focusing on a crease. Let the lid itself be the canvas.",
        "why": "Monolid eyes have little to no visible crease. Bold lid color and graphic liner show up best and create definition."
    },
    "hooded": {
        "eyeliner": "Thin liner applied slightly above the actual lash line so it stays visible when eyes are open.",
        "eyeshadow_technique": "Apply shadow above where the hood falls — higher than the crease — so the color is visible with eyes open.",
        "why": "Hooded eyes have a skin fold that covers part of the lid. Placing liner and shadow higher ensures they show when the eye is open."
    },
    "downturned": {
        "eyeliner": "Flick the liner upward at the outer corner to counteract the downward angle and lift the eye.",
        "eyeshadow_technique": "Apply a darker shade on the upper outer corner, blending upward, to visually lift the eye.",
        "why": "Downturned eyes have outer corners that angle downward. Upward liner flicks and lifted shadow placement create a more open, lifted look."
    },
    "close_set": {
        "eyeliner": "Extend liner outward past the outer corner to draw the eyes apart visually.",
        "eyeshadow_technique": "Apply a light or shimmery shade on the inner corner and concentrate darker shades on the outer half.",
        "why": "Close-set eyes sit nearer to the center of the face. Light inner corners and extended outer liner create the illusion of wider-spaced eyes."
    }
}


def get_eye_recommendations(eye_shape):
    """
    Returns eyeliner and eyeshadow technique for a given eye shape.

    Args:
        eye_shape (str): one of the 6 detected shapes

    Returns:
        dict: eyeliner, eyeshadow_technique, why
    """
    return EYE_SHAPE_MAKEUP.get(eye_shape, EYE_SHAPE_MAKEUP["almond"])


# ── Test ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: py -3.12 eye_shape_detector.py <image_path>")
        print("\nExample: py -3.12 eye_shape_detector.py data/images/test.jpg")
        sys.exit(0)

    image_path = sys.argv[1]
    result = detect_eye_shape(image_path)

    print("\n=== Capstone Glow - Eye Shape Detection ===\n")

    if result["error"]:
        print(f"[!] Note: {result['error']}")

    print(f"Eye Shape  : {result['eye_shape'].upper()}")
    print(f"Confidence : {result['confidence']}")

    if result["metrics"]:
        print("\nMetrics:")
        for k, v in result["metrics"].items():
            print(f"  {k:<25} {v}")

    recs = get_eye_recommendations(result["eye_shape"])
    print(f"\nEyeliner    : {recs['eyeliner']}")
    print(f"Eyeshadow   : {recs['eyeshadow_technique']}")
    print(f"Why         : {recs['why']}")