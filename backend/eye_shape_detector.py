"""
Capstone Glow - Eye Shape Detector v2
Updated for MediaPipe 0.10+ (new Tasks API)

Eye Shapes Detected:
    - almond    : Most versatile, slightly pointed ends
    - round     : Visible white above/below iris, circular appearance
    - monolid   : Little to no crease visible on upper lid
    - hooded    : Upper lid partially hidden by brow bone/skin fold
    - downturned: Outer corners angle downward
    - upturned  : Outer corners angle upward

Detection Method:
    - Eye Aspect Ratio (EAR)  -> round vs almond vs hooded
    - Outer corner angle      -> downturned vs upturned
    - Lid visibility ratio    -> hooded vs monolid
    - Inter-eye distance      -> close-set vs normal

Dependencies:
    py -3.12 -m pip install mediapipe opencv-python numpy
"""

import cv2
import numpy as np

try:
    import mediapipe as mp
    from mediapipe.tasks import python as mp_python
    from mediapipe.tasks.python import vision as mp_vision
    MEDIAPIPE_AVAILABLE = True
except (ImportError, AttributeError):
    MEDIAPIPE_AVAILABLE = False
    print("[WARNING] MediaPipe not available — defaulting to almond")


# ── LANDMARK INDICES ───────────────────────────────────────
LEFT_EYE = {
    "inner_corner":  133,
    "outer_corner":  33,
    "upper_lid_top": 159,
    "lower_lid_bot": 145,
    "lid_crease":    246,
}
RIGHT_EYE = {
    "inner_corner":  362,
    "outer_corner":  263,
    "upper_lid_top": 386,
    "lower_lid_bot": 374,
    "lid_crease":    466,
}
FACE_LEFT_EDGE  = 234
FACE_RIGHT_EDGE = 454


def _euclidean(p1, p2):
    return np.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)


def _get_xy(landmarks, index, img_w, img_h):
    lm = landmarks[index]
    return (int(lm.x * img_w), int(lm.y * img_h))


def _ear(landmarks, eye, img_w, img_h):
    inner  = _get_xy(landmarks, eye["inner_corner"], img_w, img_h)
    outer  = _get_xy(landmarks, eye["outer_corner"], img_w, img_h)
    top    = _get_xy(landmarks, eye["upper_lid_top"], img_w, img_h)
    bottom = _get_xy(landmarks, eye["lower_lid_bot"], img_w, img_h)
    width  = _euclidean(inner, outer)
    height = _euclidean(top, bottom)
    return height / width if width > 0 else 0.0


def _corner_angle(landmarks, eye, img_w, img_h):
    inner = _get_xy(landmarks, eye["inner_corner"], img_w, img_h)
    outer = _get_xy(landmarks, eye["outer_corner"], img_w, img_h)
    dx    = outer[0] - inner[0]
    dy    = outer[1] - inner[1]
    if dx == 0:
        return 0.0
    return np.degrees(np.arctan2(-dy, abs(dx)))


def _lid_ratio(landmarks, eye, img_w, img_h):
    top    = _get_xy(landmarks, eye["upper_lid_top"], img_w, img_h)
    crease = _get_xy(landmarks, eye["lid_crease"], img_w, img_h)
    bottom = _get_xy(landmarks, eye["lower_lid_bot"], img_w, img_h)
    total  = _euclidean(top, bottom)
    return _euclidean(crease, top) / total if total > 0 else 1.0


def _inter_eye_ratio(landmarks, img_w, img_h):
    try:
        l_inner    = _get_xy(landmarks, LEFT_EYE["inner_corner"], img_w, img_h)
        r_inner    = _get_xy(landmarks, RIGHT_EYE["inner_corner"], img_w, img_h)
        face_left  = _get_xy(landmarks, FACE_LEFT_EDGE, img_w, img_h)
        face_right = _get_xy(landmarks, FACE_RIGHT_EDGE, img_w, img_h)
        inter      = _euclidean(l_inner, r_inner)
        face_w     = _euclidean(face_left, face_right)
        return inter / face_w if face_w > 0 else 0.3
    except Exception:
        return 0.3


def _classify(ear, angle, lid, inter):
    if lid < 0.15:
        return "hooded"
    if lid < 0.22 and ear < 0.28:
        return "monolid"
    if angle < -5.0:
        return "downturned"
    if angle > 5.0:
        return "upturned"
    if ear > 0.35:
        return "round"
    return "almond"


def detect_eye_shape(image_path):
    """
    Detects eye shape from an image using MediaPipe 0.10+ Tasks API.

    Returns:
        dict: { eye_shape, confidence, metrics, error }
    """

    if not MEDIAPIPE_AVAILABLE:
        return {
            "eye_shape":  "almond",
            "confidence": "low",
            "metrics":    {},
            "error":      "MediaPipe not available — defaulting to almond"
        }

    try:
        # ── New MediaPipe 0.10+ API ────────────────────────
        BaseOptions  = mp_python.BaseOptions
        FaceLandmarker      = mp_vision.FaceLandmarker
        FaceLandmarkerOptions = mp_vision.FaceLandmarkerOptions
        VisionRunningMode   = mp_vision.RunningMode

        options = FaceLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=_get_model_path()),
            running_mode=VisionRunningMode.IMAGE,
            num_faces=1,
            min_face_detection_confidence=0.5,
            min_face_presence_confidence=0.5,
            min_tracking_confidence=0.5,
        )

        img     = cv2.imread(image_path)
        if img is None:
            return {"eye_shape": "almond", "confidence": "low", "metrics": {}, "error": f"Could not load image: {image_path}"}

        img_h, img_w = img.shape[:2]
        mp_image = mp.Image(
            image_format=mp.ImageFormat.SRGB,
            data=cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        )

        with FaceLandmarker.create_from_options(options) as landmarker:
            result = landmarker.detect(mp_image)

        if not result.face_landmarks:
            return {"eye_shape": "almond", "confidence": "low", "metrics": {}, "error": "No face detected"}

        landmarks = result.face_landmarks[0]

        left_ear   = _ear(landmarks, LEFT_EYE, img_w, img_h)
        right_ear  = _ear(landmarks, RIGHT_EYE, img_w, img_h)
        avg_ear    = (left_ear + right_ear) / 2

        left_ang   = _corner_angle(landmarks, LEFT_EYE, img_w, img_h)
        right_ang  = _corner_angle(landmarks, RIGHT_EYE, img_w, img_h)
        avg_angle  = (left_ang + right_ang) / 2

        left_lid   = _lid_ratio(landmarks, LEFT_EYE, img_w, img_h)
        right_lid  = _lid_ratio(landmarks, RIGHT_EYE, img_w, img_h)
        avg_lid    = (left_lid + right_lid) / 2

        inter      = _inter_eye_ratio(landmarks, img_w, img_h)

        eye_shape  = _classify(avg_ear, avg_angle, avg_lid, inter)
        confidence = "medium" if 0.28 <= avg_ear <= 0.35 and -5 <= avg_angle <= 5 else "high"

        return {
            "eye_shape":  eye_shape,
            "confidence": confidence,
            "metrics": {
                "eye_aspect_ratio":     round(avg_ear, 4),
                "outer_corner_angle":   round(avg_angle, 2),
                "lid_visibility_ratio": round(avg_lid, 4),
                "inter_eye_ratio":      round(inter, 4),
            },
            "error": None
        }

    except Exception as e:
        return {
            "eye_shape":  "almond",
            "confidence": "low",
            "metrics":    {},
            "error":      f"Detection error: {str(e)}"
        }


def _get_model_path():
    """Download and return path to MediaPipe face landmarker model."""
    import os
    import urllib.request

    model_dir  = os.path.join(os.path.dirname(__file__), "models")
    model_path = os.path.join(model_dir, "face_landmarker.task")

    os.makedirs(model_dir, exist_ok=True)

    if not os.path.exists(model_path):
        print("Downloading MediaPipe face landmarker model...")
        url = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
        urllib.request.urlretrieve(url, model_path)
        print(f"✅ Model saved to: {model_path}")

    return model_path


# ── EYE SHAPE MAKEUP LOOKUP ────────────────────────────────
EYE_SHAPE_MAKEUP = {
    "almond":     {
        "eyeliner": "Classic thin liner or winged liner — almond eyes are the most versatile.",
        "eyeshadow_technique": "Soft wash of color on lid with deeper shade on outer corner.",
        "why": "Almond eyes are naturally balanced — almost any technique flatters them."
    },
    "round":      {
        "eyeliner": "Winged or cat-eye liner extending past the outer corner to elongate.",
        "eyeshadow_technique": "Focus darker shades on outer corner, blend slightly upward.",
        "why": "Extending liner outward creates the illusion of length on round eyes."
    },
    "monolid":    {
        "eyeliner": "Graphic bold liner on the upper lid — avoid tight lining.",
        "eyeshadow_technique": "Bold color across the full lid — no crease blending needed.",
        "why": "Bold lid color and graphic liner create definition on monolid eyes."
    },
    "hooded":     {
        "eyeliner": "Thin liner placed slightly above the actual lash line.",
        "eyeshadow_technique": "Apply shadow above where the hood falls so it stays visible.",
        "why": "Placing liner and shadow higher ensures they show when the eye is open."
    },
    "downturned": {
        "eyeliner": "Flick liner upward at the outer corner to lift the eye.",
        "eyeshadow_technique": "Darker shade on upper outer corner blended upward to lift.",
        "why": "Upward flicks counteract the downward angle of the outer corner."
    },
    "upturned":   {
        "eyeliner": "Keep liner close to lash line — avoid heavy outer wing.",
        "eyeshadow_technique": "Blend shadow slightly downward on outer corner to balance.",
        "why": "Keeping liner close to the lash line balances naturally upturned eyes."
    },
}


def get_eye_recommendations(eye_shape):
    return EYE_SHAPE_MAKEUP.get(eye_shape, EYE_SHAPE_MAKEUP["almond"])


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: py -3.12 backend/eye_shape_detector.py <image_path>")
        sys.exit(0)

    result = detect_eye_shape(sys.argv[1])

    print("\n=== Capstone Glow — Eye Shape Detection ===\n")
    if result["error"]:
        print(f"[!] {result['error']}")

    print(f"Eye Shape  : {result['eye_shape'].upper()}")
    print(f"Confidence : {result['confidence']}")

    if result["metrics"]:
        print("\nMetrics:")
        for k, v in result["metrics"].items():
            print(f"  {k:<25} {v}")

    recs = get_eye_recommendations(result["eye_shape"])
    print(f"\nEyeliner  : {recs['eyeliner']}")
    print(f"Eyeshadow : {recs['eyeshadow_technique']}")