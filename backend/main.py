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
from recommendations import get_makeup_recommendation, get_tutorial


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
    # face_shape can be None (e.g. image not found) — guard before .lower(),
    # falling back to "oval" (the detector's own default) so scoring still
    # runs instead of crashing. Previously this only survived because the
    # skin detector errored first on the same missing-image condition.
    face_shape       = (face_result["face_shape"] or "oval").lower()
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
def get_recommendations(undertone, monk_scale, face_shape, eye_shape, chosen_style):
    """
    Takes detected features + user's chosen style
    Returns complete list of products and shades to use

    Args:
        undertone:     "warm", "cool", or "neutral"
        monk_scale:    int, 1-10 (Monk Skin Tone Scale)
        face_shape:    "oval", "round", "square", "heart", "long"
        eye_shape:     "almond", "round", "monolid", "hooded", "downturned", "upturned"
        chosen_style:  style key e.g. "clean_girl", "soft_glam"

    Returns:
        Dictionary with products, shades, prep items, tools, and tip
    """

    recommendation = get_makeup_recommendation(
        undertone    = undertone,
        monk_scale   = monk_scale,
        face_shape   = face_shape,
        eye_shape    = eye_shape,
        makeup_style = chosen_style
    )

    return {
        "phase":        3,
        "chosen_style": chosen_style,
        "undertone":    undertone,
        "monk_scale":   monk_scale,
        "face_shape":   face_shape,
        "eye_shape":    eye_shape,
        **recommendation
    }


# ── PHASE 4: Get step-by-step tutorial (user tapped "Let's Start") ─
def get_how_to_apply(chosen_style):
    """
    Takes the user's chosen style and returns the step-by-step tutorial.
    Called when the user taps "Let's Start" on the "What To Use" screen.

    Args:
        chosen_style: style key e.g. "clean_girl", "soft_glam"

    Returns:
        Dictionary with style name, tutorial steps, and tips
    """

    tutorial = get_tutorial(chosen_style)

    return {
        "phase":        4,
        "chosen_style": chosen_style,
        **tutorial
    }


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    import os

    BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
    test_image = os.path.join(BASE_DIR, "..", "mobile", "assets", "test", "sample_face.jpg")
    test_image = os.path.abspath(test_image)

    print(f"[DEBUG] Looking for image at: {test_image}")

    if not os.path.exists(test_image):
        print(f"❌ Test image not found at: {test_image}")
        print("   Update 'test_image' above to point to a real file in your data/images folder.")
        exit()

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
        monk_scale   = features["monk_scale"],
        face_shape   = features["face_shape"],
        eye_shape    = features["eye_shape"],
        chosen_style = chosen
    )

    print(f"\nFor this make-up style you will need:")
    for item in recs["products"]:
        print(f"   {item['product']:<28} {item['shade']}")

    if recs.get("prep_items"):
        print(f"\nSkin Prep (no shade needed):")
        for item in recs["prep_items"]:
            print(f"   - {item}")

    if recs.get("tools"):
        print(f"\nTools:")
        for item in recs["tools"]:
            print(f"   - {item}")

    print(f"\nTip: {recs.get('tip', '')}")

    # PHASE 4: user taps "Let's Start"
    print("\n👆 User taps: Let's Start")

    print(f"\n📖 PHASE 4 — Step-by-Step Tutorial:")
    tutorial_result = get_how_to_apply(chosen)

    if "error" in tutorial_result:
        print(f"❌ Error: {tutorial_result['error']}")
        exit()

    print(f"\nSkin Prep:")
    for i, step in enumerate(tutorial_result["skin_prep"], 1):
        print(f"   {i}. {step}")

    print(f"\nMakeup Application:")
    for i, step in enumerate(tutorial_result["makeup_application"], 1):
        print(f"   {i}. {step}")

    print(f"\nTips:")
    for tip in tutorial_result["tips"]:
        print(f"   - {tip}")

    print("\n" + "=" * 52)
    print("  PIPELINE COMPLETE")
    print("=" * 52)