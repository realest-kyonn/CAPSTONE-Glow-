"""
Capstone Glow - Style Scorer
Scores all 15 makeup styles based on detected features
Returns TOP 3 best-matching styles for the user

Based on research data from makeup_styles_by_features.xlsx
"""

# ── COMPATIBILITY DATA FROM EXCEL FILE ─────────────────────

# Face shape compatibility (✓ = compatible)
FACE_SHAPE_SCORES = {
    "clean_girl":       ["oval", "round", "square", "heart"],
    "no_makeup":        ["oval", "heart", "long"],
    "fresh_dewy":       ["round", "oval", "square"],
    "soft_glam":        ["oval", "heart", "long"],
    "korean_daily":     ["round", "oval", "heart"],
    "peach_makeup":     ["round", "oval", "heart"],
    "soft_contour":     ["round", "square", "long"],
    "lifted_makeup":    ["round", "square", "heart"],
    "snatched":         ["round", "square", "long"],
    "igari":            ["round", "oval", "heart"],
    "douyin":           ["round", "oval"],
    "strawberry":       ["round", "heart", "oval"],
    "office":           ["oval", "square", "heart", "long"],
    "neutral_glam":     ["oval", "heart", "long"],
    "corporate_clean":  ["oval", "square", "long", "heart"],
}

# Eye shape compatibility (✓ = compatible)
EYE_SHAPE_SCORES = {
    "clean_girl":       ["almond", "monolid", "hooded"],
    "no_makeup":        ["almond", "round", "monolid", "hooded", "downturned", "close_set"],
    "fresh_dewy":       ["almond", "monolid", "round"],
    "soft_glam":        ["almond", "downturned", "hooded"],
    "korean_daily":     ["monolid", "almond", "round"],
    "peach_makeup":     ["almond", "monolid", "round"],
    "soft_contour":     ["almond", "round", "monolid", "hooded", "downturned", "close_set"],
    "lifted_makeup":    ["hooded", "downturned", "monolid"],
    "snatched":         ["almond", "hooded", "close_set"],
    "igari":            ["monolid", "almond", "round"],
    "douyin":           ["monolid", "almond", "round"],
    "strawberry":       ["round", "almond", "monolid"],
    "office":           ["almond", "round", "monolid", "hooded", "downturned", "close_set"],
    "neutral_glam":     ["almond", "downturned", "close_set"],
    "corporate_clean":  ["almond", "round", "monolid", "hooded", "downturned", "close_set"],
}

# Undertone compatibility
UNDERTONE_SCORES = {
    "clean_girl":       ["warm", "cool", "neutral"],
    "no_makeup":        ["warm", "cool", "neutral"],
    "fresh_dewy":       ["warm", "cool", "neutral"],
    "soft_glam":        ["warm", "cool", "neutral"],
    "korean_daily":     ["cool", "neutral"],
    "peach_makeup":     ["warm", "neutral"],
    "soft_contour":     ["warm", "cool", "neutral"],
    "lifted_makeup":    ["warm", "cool", "neutral"],
    "snatched":         ["warm", "cool", "neutral"],
    "igari":            ["cool", "neutral"],
    "douyin":           ["cool", "neutral"],
    "strawberry":       ["warm", "neutral"],
    "office":           ["warm", "cool", "neutral"],
    "neutral_glam":     ["warm", "cool", "neutral"],
    "corporate_clean":  ["warm", "cool", "neutral"],
}

# Style display names
STYLE_NAMES = {
    "clean_girl":       "Clean Girl Makeup",
    "no_makeup":        "No-Makeup Makeup",
    "fresh_dewy":       "Fresh Dewy Makeup",
    "soft_glam":        "Soft Glam Everyday",
    "korean_daily":     "Korean Daily Makeup",
    "peach_makeup":     "Peach Makeup",
    "soft_contour":     "Soft Contour Makeup",
    "lifted_makeup":    "Lifted Makeup",
    "snatched":         "Snatched Everyday Makeup",
    "igari":            "Igari-Inspired Makeup",
    "douyin":           "Douyin Natural Makeup",
    "strawberry":       "Strawberry Makeup",
    "office":           "Office Makeup",
    "neutral_glam":     "Neutral Glam",
    "corporate_clean":  "Corporate Clean Makeup",
}

# Style descriptions
STYLE_DESCRIPTIONS = {
    "clean_girl":       "Minimal, skin-first look with dewy finish. Less is more.",
    "no_makeup":        "Enhanced naturalness — looks like you're wearing nothing.",
    "fresh_dewy":       "Glassy, lit-from-within luminous finish. Glass skin effect.",
    "soft_glam":        "Polished but effortless. Neutral tones with subtle shimmer.",
    "korean_daily":     "Fresh and youthful K-beauty aesthetic. Gradient lip focus.",
    "peach_makeup":     "Warm peachy tones for a cute, sun-kissed everyday flush.",
    "soft_contour":     "Subtle reshaping with soft bronzer and natural blush.",
    "lifted_makeup":    "Fox-eye and cat techniques that open and lift the eyes.",
    "snatched":         "Defined and sharp with highlight and contour combo.",
    "igari":            "Japanese hangover blush across nose bridge. Dreamy flush.",
    "douyin":           "Chinese social-media aesthetic. Porcelain skin + big eyes.",
    "strawberry":       "Rosy red tones with dewy skin for a fresh fruity look.",
    "office":           "Professional and polished. Neutral palette for workplace.",
    "neutral_glam":     "Timeless and sophisticated. Evening-ready neutrals.",
    "corporate_clean":  "Refined and minimal. Boardroom-ready with clean finish.",
}


# ── SCORER FUNCTION ────────────────────────────────────────

def score_styles(undertone, face_shape, eye_shape):
    """
    Scores all 15 makeup styles based on user's detected features.
    Returns top 3 best-matching styles.

    Args:
        undertone:   String - "warm", "cool", or "neutral"
        face_shape:  String - "oval", "round", "square", "heart", "oblong"
        eye_shape:   String - "almond", "round", "monolid", "hooded", "downturned", "close_set"

    Returns:
        List of top 3 styles with scores and descriptions
    """

    # Normalize oblong to long (same shape, different name)
    if face_shape == "oblong":
        face_shape = "long"

    scores = {}

    for style in STYLE_NAMES.keys():
        score = 0

        # Face shape match = 3 points
        if face_shape in FACE_SHAPE_SCORES.get(style, []):
            score += 3

        # Eye shape match = 2 points
        if eye_shape in EYE_SHAPE_SCORES.get(style, []):
            score += 2

        # Undertone match = 1 point
        if undertone in UNDERTONE_SCORES.get(style, []):
            score += 1

        scores[style] = score

    # Sort by score (highest first)
    sorted_styles = sorted(scores.items(), key=lambda x: x[1], reverse=True)

    # Return top 3
    top_3 = []
    for style_key, score in sorted_styles[:3]:
        top_3.append({
            "style_key":   style_key,
            "style_name":  STYLE_NAMES[style_key],
            "description": STYLE_DESCRIPTIONS[style_key],
            "score":       score,
            "max_score":   6,
            "match_pct":   round((score / 6) * 100)
        })

    return top_3


# ── TEST ───────────────────────────────────────────────────

if __name__ == "__main__":
    print("=== Capstone Glow - Style Scorer Test ===\n")

    # Test case 1: warm, oval, almond
    print("Test 1: Warm undertone | Oval face | Almond eyes")
    results = score_styles("warm", "oval", "almond")
    for i, style in enumerate(results, 1):
        print(f"  #{i}: {style['style_name']} ({style['match_pct']}% match)")
        print(f"       {style['description']}")
    print()

    # Test case 2: cool, round, monolid
    print("Test 2: Cool undertone | Round face | Monolid eyes")
    results = score_styles("cool", "round", "monolid")
    for i, style in enumerate(results, 1):
        print(f"  #{i}: {style['style_name']} ({style['match_pct']}% match)")
        print(f"       {style['description']}")
    print()

    # Test case 3: neutral, heart, hooded
    print("Test 3: Neutral undertone | Heart face | Hooded eyes")
    results = score_styles("neutral", "heart", "hooded")
    for i, style in enumerate(results, 1):
        print(f"  #{i}: {style['style_name']} ({style['match_pct']}% match)")
        print(f"       {style['description']}")