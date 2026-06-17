"""
Capstone Glow - Main Pipeline
Connects all detectors and returns complete analysis

PHASE 1: Detect features (undertone, face shape, eye shape)
PHASE 2: Score all 15 styles, return top 3
PHASE 3: User picks a style, return what to use
"""

from skin_tone_detector import detect_skin_tone
from eye_shape_detector import detect_eye_shape
from face_shape_detector import detect_face_shape
from style_scorer import score_styles
from recommendations import get_makeup_recommendation


# ── PHASE 1 + 2: Analyze face and return top 3 styles ──────
def analyze_face(image_path):
    """
    Takes a face image and returns:
    - Detected features (undertone, monk scale, face shape, eye shape)
    - Top 3 recommended makeup styles

    Args:
        image_path: Path to face image

    Returns:
        Dictionary with features + top 3 styles
    """

    # Step 1: Detect skin undertone
    skin_result = detect_skin_tone(image_path)
    if "error" in skin_result:
        return {"error": skin_result["error"]}

    undertone  = skin_result["skin_tone"]
    monk_scale = skin_result["monk_scale"]

    # Step 2: Detect face shape using trained TFLite model
    face_result = detect_face_shape(image_path)
    if face_result["error"]:
        print(f"[!] Face shape warning: {face_result['error']}")
    face_shape       = face_result["face_shape"].lower()  # e.g. "oval"
    face_confidence  = face_result["confidence"]

    # Step 3: Detect eye shape using MediaPipe FaceMesh
    eye_result = detect_eye_shape(image_path)
    if eye_result["error"]:
        print(f"[!] Eye shape warning: {eye_result['error']}")
    eye_shape       = eye_result["eye_shape"]   # e.g. "almond"
    eye_confidence  = eye_result["confidence"]

    # Step 4: Score all 15 styles and return top 3
    top_3_styles = score_styles(undertone, face_shape, eye_shape)

    return {
        "phase": 1,
        "features": {
            "undertone":        undertone,
            "monk_scale":       monk_scale,
            "face_shape":       face_shape,
            "face_confidence":  face_confidence,
            "eye_shape":        eye_shape,
            "eye_confidence":   eye_confidence,
        },
        "top_3_styles": top_3_styles
    }


# ── PHASE 3: Get what to use based on chosen style ─────────
def get_recommendations(undertone, face_shape, eye_shape, chosen_style):
    """
    Takes detected features + user's chosen style
    Returns complete list of products and shades to use

    Args:
        undertone:     "warm", "cool", or "neutral"
        face_shape:    "oval", "round", "square", "heart", "long"
        eye_shape:     "almond", "round", "monolid", "hooded", "downturned", "upturned"
        chosen_style:  style key e.g. "clean_girl", "soft_glam"

    Returns:
        Dictionary with products and shades
    """

    products = get_makeup_recommendation(
        undertone    = undertone,
        face_shape   = face_shape,
        eye_shape    = eye_shape,
        makeup_style = chosen_style
    )

    return {
        "phase":        3,
        "chosen_style": chosen_style,
        "undertone":    undertone,
        "face_shape":   face_shape,
        "eye_shape":    eye_shape,
        "products":     products
    }


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    test_image = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images\img001.jpg"

    print("=" * 52)
    print("  CAPSTONE GLOW — FULL PIPELINE TEST")
    print("=" * 52)

    # PHASE 1 + 2
    print("\n📸 PHASE 1 — Analyzing face...")
    analysis = analyze_face(test_image)

    if "error" in analysis:
        print(f"❌ Error: {analysis['error']}")
        exit()

    features = analysis["features"]
    print(f"\n✅ Features Detected:")
    print(f"   Undertone   : {features['undertone']}")
    print(f"   Monk Scale  : {features['monk_scale']}")
    print(f"   Face Shape  : {features['face_shape']} ({features['face_confidence']*100:.1f}% confidence)")
    print(f"   Eye Shape   : {features['eye_shape']} ({features['eye_confidence']} confidence)")

    print(f"\n🎨 PHASE 2 — Top 3 Recommended Styles:")
    for i, style in enumerate(analysis["top_3_styles"], 1):
        print(f"   #{i}: {style['style_name']} ({style['match_pct']}% match)")
        print(f"        {style['description']}")

    # PHASE 3: pick style #1 for testing
    print(f"\n👆 User picks: {analysis['top_3_styles'][0]['style_name']}")
    chosen = analysis["top_3_styles"][0]["style_key"]

    print(f"\n💄 PHASE 3 — What To Use:")
    recs = get_recommendations(
        undertone    = features["undertone"],
        face_shape   = features["face_shape"],
        eye_shape    = features["eye_shape"],
        chosen_style = chosen
    )

    for item in recs["products"]:
        print(f"   {item['product']:<20} {item['shade']}")

    print("\n" + "=" * 52)
    print("  Phase 4 (How To Apply) — Coming soon!")
    print("=" * 52)