"""
Capstone Glow - Recommendation Engine (Phase 3 — What To Use)

Returns the full "What To Use" payload for a chosen makeup style:
    - Suggested shade per product (looked up by undertone + Monk scale)
    - Prep items (no shade needed — general skincare prep)
    - Tools (no shade needed — brushes, lash curler, tape, etc.)
    - A general prep tip

Shade lookup logic:
    Each shaded product has 3 undertone rows (warm / neutral / cool),
    each with 10 shades corresponding to Monk Scale M1 (lightest) -> M10 (deepest).

    shade = recommendations.json["shades"][product_slug][undertone][monk_scale - 1]

Data source:
    recommendations.json (generated from the Glow Makeup Style Guide Word doc)
"""

import json
import os

# ── LOAD DATA ────────────────────────────────────────────────
_DATA_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "recommendations.json")

with open(_DATA_PATH, "r", encoding="utf-8") as f:
    _DATA = json.load(f)

SHADES              = _DATA["shades"]
PRODUCT_NAMES       = _DATA["product_display_names"]
STYLES              = _DATA["styles"]


# ── HELPERS ──────────────────────────────────────────────────
def _get_shade(product_slug, undertone, monk_scale):
    """
    Looks up the suggested shade for a single product.

    Args:
        product_slug: internal product key, e.g. "concealer"
        undertone:    "warm", "cool", or "neutral"
        monk_scale:   int, 1-10

    Returns:
        str — the suggested shade name, or a fallback message if not found
    """
    product_shades = SHADES.get(product_slug)
    if not product_shades:
        return "Shade not available"

    undertone_shades = product_shades.get(undertone) or product_shades.get("neutral")
    if not undertone_shades:
        return "Shade not available"

    # Clamp monk_scale to valid 1-10 range just in case
    index = max(1, min(10, monk_scale)) - 1

    try:
        return undertone_shades[index]
    except (IndexError, TypeError):
        return "Shade not available"


# ── MAIN FUNCTION ────────────────────────────────────────────
def get_makeup_recommendation(undertone, monk_scale, face_shape, eye_shape, makeup_style):
    """
    Returns the complete "What To Use" payload for a chosen makeup style.

    Args:
        undertone:    "warm", "cool", or "neutral"
        monk_scale:   int, 1-10 (Monk Skin Tone Scale)
        face_shape:   "oval", "round", "square", "heart", "long"
                      (not currently used for shade selection — reserved)
        eye_shape:    "almond", "round", "monolid", "hooded", "downturned", "upturned"
                      (not currently used for shade selection — reserved)
        makeup_style: style key, e.g. "clean_girl", "soft_glam"

    Returns:
        dict with:
            style_name:    display name of the chosen style
            products:      list of { "product": display_name, "shade": "Suggested: ..." }
            prep_items:    list of prep items (no shade needed)
            tools:         list of tools (no shade needed)
            tip:           general prep tip string
    """

    style = STYLES.get(makeup_style)
    if not style:
        return {
            "error": f"Unknown makeup style: {makeup_style}"
        }

    products_output = []
    for product_slug in style["products"]:
        display_name = PRODUCT_NAMES.get(product_slug, product_slug.replace("_", " ").title())
        shade = _get_shade(product_slug, undertone, monk_scale)
        products_output.append({
            "product": display_name,
            "shade":   f"Suggested: {shade}"
        })

    return {
        "style_name":  style["name"],
        "products":    products_output,
        "prep_items":  style["prep_items"],
        "tools":       style["tools"],
        "tip":         style.get("general_tip", "Make sure to properly prep your face before putting on makeup.")
    }


# ── TUTORIAL (Phase 4 — called when user taps "Let's Start") ─
def get_tutorial(makeup_style):
    """
    Returns the step-by-step tutorial for a chosen makeup style,
    split into two labeled sections so the UI can show them as
    separate headed groups with their own step numbering:

        1. Skin Prep            (prep the face before any makeup)
        2. Makeup Application   (the actual makeup steps)

    Called separately from get_makeup_recommendation(), once the
    user taps "Let's Start" on the "What To Use" screen.

    Args:
        makeup_style: style key, e.g. "clean_girl", "soft_glam"

    Returns:
        dict with:
            style_name:          display name of the chosen style
            skin_prep:           list of skin prep steps
            makeup_application:  list of makeup application steps
            tips:                list of style-specific tips
    """

    style = STYLES.get(makeup_style)
    if not style:
        return {
            "error": f"Unknown makeup style: {makeup_style}"
        }

    tutorial = style["tutorial"]

    return {
        "style_name":         style["name"],
        "skin_prep":          tutorial.get("skin_prep", []),
        "makeup_application": tutorial.get("makeup_application", []),
        "tips":               style["tips"]
    }


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    result = get_makeup_recommendation(
        undertone    = "warm",
        monk_scale   = 4,
        face_shape   = "oval",
        eye_shape    = "almond",
        makeup_style = "clean_girl"
    )

    print("=== Capstone Glow — What To Use ===")
    print(f"Style: {result['style_name']}")
    print("Undertone: Warm | Monk Scale: 4 | Face: Oval | Eyes: Almond")
    print()
    print("For this make-up style you will need:")
    for item in result["products"]:
        print(f"  {item['product']:<28} {item['shade']}")

    if result["prep_items"]:
        print("\nSkin Prep (no shade needed):")
        for item in result["prep_items"]:
            print(f"  - {item}")

    if result["tools"]:
        print("\nTools:")
        for item in result["tools"]:
            print(f"  - {item}")

    print(f"\nTip: {result['tip']}")
