"""
Capstone Glow - Main Pipeline
Connects all detectors and returns complete analysis

PHASE 1: Detect features (undertone, face shape, eye shape)
PHASE 2: Score all 15 styles, return top 3
PHASE 3: User picks a style, return what to use
"""

from skin_tone_detector import detect_skin_tone
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

    # Step 2: Detect face shape
    # [PLACEHOLDER] — waiting for trained model
    # Will be replaced with face_shape_detector.py output
    face_shape = "oval"  # placeholder

    # Step 3: Detect eye shape
    # [PLACEHOLDER] — waiting for eye_shape_detector integration
    # Will be replaced with eye_shape_detector.py output
    eye_shape = "almond"  # placeholder

    # Step 4: Score all 15 styles and return top 3
    top_3_styles = score_styles(undertone, face_shape, eye_shape)

    return {
        "phase": 1,
        "features": {
            "undertone":   undertone,
            "monk_scale":  monk_scale,
            "face_shape":  face_shape,
            "eye_shape":   eye_shape,
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
        face_shape:    "oval", "round", "square", "heart", "oblong"
        eye_shape:     "almond", "round", "monolid", "hooded", "downturned", "close_set"
        chosen_style:  style key e.g. "clean_girl", "soft_glam"

    Returns:
        List of products with shades
    """

    products = get_makeup_recommendation(
        undertone    = undertone,
        face_shape   = face_shape,
        eye_shape    = eye_shape,
        makeup_style = chosen_style
    )

    return {
        "phase": 3,
        "chosen_style": chosen_style,
        "undertone":    undertone,
        "face_shape":   face_shape,
        "eye_shape":    eye_shape,
        "products":     products
    }


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    test_image = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images\img001.jpg"

    print("=" * 50)
    print("CAPSTONE GLOW — FULL PIPELINE TEST")
    print("=" * 50)

    # PHASE 1 + 2: Analyze face
    print("\n📸 PHASE 1 — Analyzing face...")
    analysis = analyze_face(test_image)

    if "error" in analysis:
        print(f"Error: {analysis['error']}")
        exit()

    features = analysis["features"]
    print(f"\n✅ Features Detected:")
    print(f"   Undertone:  {features['undertone']}")
    print(f"   Monk Scale: {features['monk_scale']}")
    print(f"   Face Shape: {features['face_shape']} (placeholder)")
    print(f"   Eye Shape:  {features['eye_shape']} (placeholder)")

    print(f"\n🎨 PHASE 2 — Top 3 Recommended Styles:")
    for i, style in enumerate(analysis["top_3_styles"], 1):
        print(f"   #{i}: {style['style_name']} ({style['match_pct']}% match)")
        print(f"        {style['description']}")

    # PHASE 3: User picks style #1 for testing
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
        print(f"   {item['product']}: {item['shade']}")

    print("\n" + "=" * 50)
    print("Phase 4 (How To Apply) — Coming soon!")
    print("=" * 50)