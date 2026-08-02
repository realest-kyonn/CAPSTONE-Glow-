"""
Capstone Glow - Eye Shape Detector v3
MediaPipe 0.10+ (Tasks API), iris-aware

Eye Shapes Detected:
    - almond    : Balanced proportions, no dominant feature (the default)
    - round     : Tall aperture relative to width
    - hooded    : Upper lid sits low relative to the lower lid
    - downturned: Outer corner low relative to the population norm
    - upturned  : Outer corner high relative to the population norm

    - monolid   : NOT DETECTED — see the note in _classify(). Monolid is
                  the absence of a lid crease, a texture feature that no
                  landmark arrangement can observe. It is left out
                  deliberately rather than advertised and never returned.

Detection Method:
    - MRD1/MRD2 (iris-normalised lid position) -> hooded
    - Outer corner angle vs population norm    -> upturned / downturned
    - Eye Aspect Ratio (EAR)                   -> round vs almond

WHAT CHANGED IN v3, AND WHY IT MATTERS:
    v2 could only ever return three of its six advertised shapes. Two
    independent defects, both confirmed by measuring this project's own
    dataset rather than by reading the code:

      1. The corner angle was compared against zero, but a normal eye has
         a positive canthal tilt (measured mean +6.63 deg, minimum +0.80
         across 308 faces — never negative). "downturned" was therefore
         unreachable and ~81% of all faces returned "upturned".

      2. The "lid crease" measurement did not measure a crease. Its real
         range was 0.788-2.089 against thresholds of 0.15 and 0.22, so
         "hooded" and "monolid" could never fire, and it was 90.4%
         explained by EAR alone — a duplicate metric, not a broken one.

    v3 replaces (2) with an iris-normalised measure of upper-lid position
    which is statistically independent of EAR (r^2 = 0.001), and recentres
    (1) on the measured population distribution. See CLASSIFICATION
    THRESHOLDS below for provenance of every constant.

KNOWN LIMITATIONS — state these rather than hide them:
    - No eye-shape ground truth exists for this dataset (it is labelled
      for face shape), so these thresholds are calibrated to the measured
      population distribution, NOT validated for accuracy.
    - ~47% of faces sit within 10% of some threshold, so classification
      can vary between photographs of the same person. The confidence
      field reflects this honestly; multi-frame voting in the app layer
      would reduce it.
    - MRD1 reflects where the lid sits at the moment of capture, so
      squinting or downward gaze reads as hooding. Frame validation
      should reject those captures.

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
# The bundled face_landmarker.task returns 478 landmarks, not 468: the
# standard mesh plus 10 iris points (468-472 left, 473-477 right; the
# first index of each is the centre). Verified against the actual model
# output, not assumed.
#
# The iris points matter because iris diameter is very nearly constant
# across adults (~11.7mm regardless of face size), which makes it a
# built-in scale reference. That is what lets the hooding measure below
# be independent of face size and camera distance.
#
# NOTE: there is deliberately no "lid_crease" entry any more. Indices
# 246/466 used to be labelled that, but they sit on the eye contour
# beside the outer corner — MediaPipe has no crease landmark at all.
# Measured against this project's own dataset, the ratio built from them
# was 90.4% explained by EAR alone (r = +0.951 vs 1/EAR), i.e. it was
# re-measuring eye elongation under another name and carried no
# information about lid folds. Do not reintroduce it.
LEFT_EYE = {
    "inner_corner":  133,
    "outer_corner":  33,
    "upper_lid_top": 159,
    "lower_lid_bot": 145,
    "iris":          [468, 469, 470, 471, 472],
}
RIGHT_EYE = {
    "inner_corner":  362,
    "outer_corner":  263,
    "upper_lid_top": 386,
    "lower_lid_bot": 374,
    "iris":          [473, 474, 475, 476, 477],
}
FACE_LEFT_EDGE  = 234
FACE_RIGHT_EDGE = 454


# ── CLASSIFICATION THRESHOLDS ──────────────────────────────
# Every number here was derived by measuring this project's own dataset
# (data/images, n=364 spread across all five face-shape groups), NOT
# chosen by hand. If you change the dataset, re-derive them rather than
# nudging the values.
#
# Why mean +/- 1 standard deviation rather than a fixed cutoff: a normal
# human eye has a naturally POSITIVE canthal tilt. Measured mean here is
# +6.63 deg (sd 2.05), and across 308 faces the angle was never once
# negative — minimum +0.80 deg. The previous code compared against zero,
# which is why "downturned" could never fire and ~81% of every face came
# back "upturned". Upturned/downturned are only meaningful RELATIVE to
# the population norm, which is exactly what these cutoffs encode.
MRD_HOODED       = 0.707   # MRD1/MRD2 below this -> hooded (mean - 1sd)
ANGLE_UPTURNED   = 8.68    # degrees, above this -> upturned (mean + 1sd)
ANGLE_DOWNTURNED = 4.58    # degrees, below this -> downturned (mean - 1sd)
EAR_ROUND        = 0.387   # EAR above this -> round (90th percentile)


def _euclidean(p1, p2):
    return np.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)


def _get_xy(landmarks, index, img_w, img_h):
    """
    Landmark to pixel coordinates, as FLOATS.

    Deliberately not int(). The iris-based measures work at a scale of a
    few pixels — iris diameter is only ~20-40px on a typical photo, and
    the MRD distances are smaller still — so integer truncation both
    destroys precision and can round MRD2 to zero, silently sending the
    hooding test down its neutral fallback path (measured: 13% of images
    before this was fixed).

    It also matters for correctness of the thresholds themselves. The
    constants in CLASSIFICATION THRESHOLDS were derived from float
    coordinates; truncating here would measure on a slightly different
    scale than the constants assume — the same class of train/inference
    mismatch as the double-preprocessing bug in face_shape_detector.py.
    Keep these floats.
    """
    lm = landmarks[index]
    return (lm.x * img_w, lm.y * img_h)


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


def _iris_diameter(landmarks, eye, img_w, img_h):
    """
    Widest span across the 5 iris landmarks, in pixels.

    Used as a scale reference: iris diameter is ~11.7mm in virtually all
    adults, so dividing by it makes a measurement independent of face
    size and camera distance. Returns 0.0 if the iris points are absent
    (a 468-point model instead of 478), which callers must handle.
    """
    try:
        pts = [_get_xy(landmarks, i, img_w, img_h) for i in eye["iris"]]
    except (IndexError, KeyError):
        return 0.0
    return max(_euclidean(a, b) for a in pts for b in pts)


def _mrd_ratio(landmarks, eye, img_w, img_h):
    """
    MRD1 / MRD2 — the hooding measure that replaces the old _lid_ratio.

    MRD1 ("margin-reflex distance 1") is the vertical distance from the
    pupil centre UP to the upper lid margin; MRD2 is pupil centre DOWN to
    the lower lid margin. Both are standard clinical measures of eyelid
    position. Hooding is specifically the upper lid sitting low, so the
    RATIO of the two isolates exactly that, while cancelling overall eye
    size — a small eye and a large eye with the same lid proportions give
    the same ratio.

    Why the ratio rather than MRD1 alone: measured on this project's
    dataset, raw MRD1 still correlates with EAR (r^2 = 0.67), but the
    ratio does not (r^2 = 0.001). The ratio is genuinely new information;
    raw MRD1 partly restates what EAR already says.

    Returns 1.0 (neutral, i.e. "not hooded") if the iris is unavailable
    or the geometry is degenerate, so a missing-iris model degrades to
    the angle/EAR rules rather than misclassifying everyone as hooded.
    """
    diam = _iris_diameter(landmarks, eye, img_w, img_h)
    if diam <= 0:
        return 1.0

    centre = _get_xy(landmarks, eye["iris"][0], img_w, img_h)
    top    = _get_xy(landmarks, eye["upper_lid_top"], img_w, img_h)
    bottom = _get_xy(landmarks, eye["lower_lid_bot"], img_w, img_h)

    # Image y grows downward, so "centre minus top" is the upward distance.
    mrd1 = (centre[1] - top[1]) / diam
    mrd2 = (bottom[1] - centre[1]) / diam

    if mrd2 <= 0:
        return 1.0
    return mrd1 / mrd2


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


def _classify(ear, angle, mrd):
    """
    Order matters. Hooding is checked first because it is a structural
    feature of the lid that dominates makeup advice regardless of the
    eye's tilt — a hooded eye that also tilts up should be treated as
    hooded. Tilt is checked next, and the EAR/round test last, since it
    is the weakest discriminator of the three.

    NOTE ON MONOLID: not returned by this function, deliberately.
    Monolid is defined by the ABSENCE of a supratarsal crease, which is
    a skin-texture feature, not a geometric one — no arrangement of mesh
    landmarks can see it. The previous code advertised monolid but its
    test could never fire (see the LANDMARK INDICES note above), so this
    is an honest statement of an existing limitation rather than a
    regression. Detecting it would require texture analysis (edge
    detection in the lid strip above the lash line). The makeup lookup
    below still carries a monolid entry so nothing breaks if it is ever
    added, and style_scorer's monolid compatibility lists stay valid.
    """
    if mrd < MRD_HOODED:
        return "hooded"
    if angle > ANGLE_UPTURNED:
        return "upturned"
    if angle < ANGLE_DOWNTURNED:
        return "downturned"
    if ear > EAR_ROUND:
        return "round"
    return "almond"


def _confidence(ear, angle, mrd):
    """
    Confidence from distance to the nearest decision boundary.

    The old version reported "high" whenever a value sat OUTSIDE the
    middle band, which meant a face 0.001 away from flipping class was
    reported as high confidence — backwards. Roughly 47% of faces in
    this project's dataset sit within 10% of some cutoff, so this needs
    to be honest or it is actively misleading.

    Margin is expressed as a fraction of each threshold so the three
    metrics (which have very different units) are comparable.
    """
    margins = [
        abs(mrd   - MRD_HOODED)       / MRD_HOODED,
        abs(angle - ANGLE_UPTURNED)   / ANGLE_UPTURNED,
        abs(angle - ANGLE_DOWNTURNED) / ANGLE_DOWNTURNED,
        abs(ear   - EAR_ROUND)        / EAR_ROUND,
    ]
    nearest = min(margins)

    if nearest < 0.05:
        return "low"
    if nearest < 0.15:
        return "medium"
    return "high"


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

        left_mrd   = _mrd_ratio(landmarks, LEFT_EYE, img_w, img_h)
        right_mrd  = _mrd_ratio(landmarks, RIGHT_EYE, img_w, img_h)
        avg_mrd    = (left_mrd + right_mrd) / 2

        inter      = _inter_eye_ratio(landmarks, img_w, img_h)

        eye_shape  = _classify(avg_ear, avg_angle, avg_mrd)
        confidence = _confidence(avg_ear, avg_angle, avg_mrd)

        # Averaging the two eyes is deliberate and load-bearing for the
        # angle: head roll raises one eye's measured tilt and lowers the
        # other's by the same amount, so the mean cancels it. Do not
        # switch to a single eye.
        return {
            "eye_shape":  eye_shape,
            "confidence": confidence,
            "metrics": {
                "eye_aspect_ratio":   round(avg_ear, 4),
                "outer_corner_angle": round(avg_angle, 2),
                "mrd_ratio":          round(avg_mrd, 4),
                # Reported for diagnostics only — no rule consumes it.
                "inter_eye_ratio":    round(inter, 4),
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


# ── ROBUST (MULTI-FRAME / TEST-TIME AUGMENTATION) ──────────
# Fixed set of small augmentations applied to the ONE captured photo.
# Deterministic on purpose: the same photo always produces the same five
# frames and therefore the same vote, so the detector is reproducible by
# construction. Each entry is (rotation_degrees, brightness_scale).
#
# Why these values: they mirror the natural frame-to-frame variation a
# real camera session shows — a couple degrees of head tilt and a small
# lighting flicker. That is exactly the wobble that flips the ~47% of
# faces sitting near a decision threshold. Measured effect: it roughly
# halves how often two photos of the same person disagree (see the
# multi-frame reproducibility test).
_TTA_FRAMES = [
    (0.0,  1.00),   # the original, unchanged
    (2.5,  1.00),   # tilt right
    (-2.5, 1.00),   # tilt left
    (0.0,  1.08),   # brighter
    (0.0,  0.92),   # darker
]


def detect_eye_shape_robust(image_path):
    """
    Same as detect_eye_shape, but classifies several lightly-augmented
    copies of the photo and returns the MAJORITY vote. This does not make
    a wrong answer right — it makes a shaky answer stable, which is what
    borderline faces need.

    Falls back to a single plain detection if augmentation is unavailable
    for any reason, so it can never do worse than detect_eye_shape.

    Returns the same dict shape as detect_eye_shape, plus:
        "votes":      {shape: count}   — the tally across frames
        "n_frames":   int              — how many frames actually voted
    detect_eye_shape itself is untouched; existing callers are unaffected.
    """
    import os
    import tempfile
    from collections import Counter

    base = cv2.imread(image_path)
    if base is None:
        # Defer to the plain path for a consistent error result.
        r = detect_eye_shape(image_path)
        r["votes"] = {}
        r["n_frames"] = 0
        return r

    h, w = base.shape[:2]
    results = []
    tmp_dir = tempfile.mkdtemp(prefix="glow_tta_")
    try:
        for i, (ang, bright) in enumerate(_TTA_FRAMES):
            if ang == 0.0:
                frame = base
            else:
                M = cv2.getRotationMatrix2D((w / 2, h / 2), ang, 1.0)
                frame = cv2.warpAffine(base, M, (w, h),
                                       borderMode=cv2.BORDER_REPLICATE)
            if bright != 1.00:
                frame = np.clip(frame.astype(np.float32) * bright,
                                0, 255).astype(np.uint8)

            fp = os.path.join(tmp_dir, f"f{i}.jpg")
            cv2.imwrite(fp, frame)
            r = detect_eye_shape(fp)
            if not r.get("error"):
                results.append(r)
    finally:
        # Best-effort cleanup; never let temp I/O break a detection.
        try:
            for f in os.listdir(tmp_dir):
                os.remove(os.path.join(tmp_dir, f))
            os.rmdir(tmp_dir)
        except OSError:
            pass

    if not results:
        # Every frame failed — fall back to the plain single detection so
        # this function is never worse than detect_eye_shape.
        r = detect_eye_shape(image_path)
        r["votes"] = {}
        r["n_frames"] = 0
        return r

    tally = Counter(r["eye_shape"] for r in results)
    winner = tally.most_common(1)[0][0]

    # Return the winning frame's full result (metrics belong to a real
    # frame rather than an average), but with the voted shape and the
    # tally attached so callers can see the agreement level.
    best = next(r for r in results if r["eye_shape"] == winner)
    best = dict(best)
    best["eye_shape"] = winner
    best["votes"] = dict(tally)
    best["n_frames"] = len(results)
    return best


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