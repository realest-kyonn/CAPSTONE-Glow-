"""
Capstone Glow - Recommendation Engine (Phase 3 — What To Use)
Returns product list + shades based on undertone and makeup style
Shades are based on UNDERTONE (warm/cool/neutral)
Product list varies per STYLE
NOTE: Items marked [TBD] need leader's final research
"""

# ── SHADES BY UNDERTONE ────────────────────────────────────
# These are the same regardless of style
SHADES = {
    "warm": {
        "foundation":     "Golden Beige",
        "concealer":      "Warm Ivory",
        "blush":          "Peach",
        "bronzer":        "Warm Tan",
        "highlighter":    "Champagne Gold",
        "eyeshadow_base": "Warm Taupe",
        "eyeshadow_lid":  "Soft Bronze",
        "eyeliner":       "Brown or Soft Black",
        "mascara":        "Black or Dark Brown",
        "brow_product":   "Warm Brown",
        "lip_liner":      "Nude Peach",
        "lipstick":       "Coral or Peachy Nude",
        "lip_gloss":      "Peachy Pink Gloss",
        "lip_oil":        "Peach Tinted Lip Oil",
        "lip_tint":       "Warm Rose Tint",
        "setting_powder": "Translucent or Warm Beige",
        "setting_spray":  "Dewy Finish Spray",
        "primer":         "Luminous Hydrating Primer",
        "skin_tint":      "Golden Beige Skin Tint",
        "bb_cream":       "Warm Beige BB Cream",
    },
    "cool": {
        "foundation":     "Rose Beige",
        "concealer":      "Cool Ivory",
        "blush":          "Soft Pink",
        "bronzer":        "Cool Bronze",
        "highlighter":    "Pearl or Icy Pink",
        "eyeshadow_base": "Cool Taupe",
        "eyeshadow_lid":  "Soft Mauve",
        "eyeliner":       "Black or Dark Gray",
        "mascara":        "Black",
        "brow_product":   "Cool Ash Brown",
        "lip_liner":      "Mauve Pink",
        "lipstick":       "Berry or Mauve",
        "lip_gloss":      "Pink Gloss",
        "lip_oil":        "Pink Tinted Lip Oil",
        "lip_tint":       "Rose Tint",
        "setting_powder": "Translucent or Lavender-toned",
        "setting_spray":  "Natural Finish Spray",
        "primer":         "Pore-minimizing Primer",
        "skin_tint":      "Rose Beige Skin Tint",
        "bb_cream":       "Cool Beige BB Cream",
    },
    "neutral": {
        "foundation":     "Neutral Beige",
        "concealer":      "Neutral Ivory",
        "blush":          "Dusty Rose",
        "bronzer":        "Neutral Bronze",
        "highlighter":    "Rose Gold",
        "eyeshadow_base": "Neutral Taupe",
        "eyeshadow_lid":  "Rose Brown",
        "eyeliner":       "Brown or Soft Black",
        "mascara":        "Black or Dark Brown",
        "brow_product":   "Medium Brown",
        "lip_liner":      "Neutral Nude",
        "lipstick":       "Dusty Rose or Soft Coral",
        "lip_gloss":      "Neutral Pink Gloss",
        "lip_oil":        "Sheer Tinted Lip Oil",
        "lip_tint":       "Neutral Rose Tint",
        "setting_powder": "Translucent",
        "setting_spray":  "Hydrating Finish Spray",
        "primer":         "Hydrating Primer",
        "skin_tint":      "Neutral Beige Skin Tint",
        "bb_cream":       "Neutral Beige BB Cream",
    }
}

# ── PRODUCTS PER STYLE ─────────────────────────────────────
# Each style has a list of products with shade keys
# Format: { "display_name": "shade_key_from_SHADES" }
# "[TBD]" = leader still researching

STYLE_PRODUCTS = {
    "clean_girl": {
        "Skin Tint":        "skin_tint",
        "Concealer":        "concealer",
        "Cream Blush":      "blush",
        "Clear Brow Gel":   "[TBD]",
        "Mascara":          "mascara",
        "Lip Oil":          "lip_oil",
        "Setting Spray":    "setting_spray",
    },
    "no_makeup": {
        "Skin Tint":        "skin_tint",
        "Concealer":        "concealer",
        "Tinted Lip Balm":  "lip_tint",
        "Clear Brow Gel":   "[TBD]",
        "Mascara":          "mascara",
    },
    "fresh_dewy": {
        "Skin Tint":        "skin_tint",
        "Concealer":        "concealer",
        "Cream Blush":      "blush",
        "Highlighter":      "highlighter",
        "Mascara":          "mascara",
        "Lip Gloss":        "lip_gloss",
        "Setting Spray":    "setting_spray",
    },
    "soft_glam": {
        "Foundation":       "foundation",
        "Concealer":        "concealer",
        "Bronzer":          "bronzer",
        "Blush":            "blush",
        "Eyeshadow":        "eyeshadow_lid",
        "Eyeliner":         "eyeliner",
        "Mascara":          "mascara",
        "Highlighter":      "highlighter",
        "Lipstick":         "lipstick",
        "Brow Pencil":      "brow_product",
        "Setting Powder":   "setting_powder",
        "Setting Spray":    "setting_spray",
    },
    "korean_daily": {
        "BB Cream":         "bb_cream",
        "Concealer":        "concealer",
        "Cream Blush":      "blush",
        "Eyeshadow":        "eyeshadow_lid",
        "Mascara":          "mascara",
        "Lip Tint":         "lip_tint",
        "Brow Pencil":      "brow_product",
        "Setting Spray":    "setting_spray",
    },
    "peach_makeup": {
        "Skin Tint":        "skin_tint",
        "Concealer":        "concealer",
        "Peach Blush":      "blush",
        "Peach Eyeshadow":  "eyeshadow_lid",
        "Mascara":          "mascara",
        "Peach Lip Gloss":  "lip_gloss",
        "Highlighter":      "highlighter",
        "Setting Spray":    "setting_spray",
    },
    "soft_contour": {
        "Foundation":       "foundation",
        "Concealer":        "concealer",
        "Contour":          "bronzer",
        "Blush":            "blush",
        "Highlighter":      "highlighter",
        "Eyeshadow":        "eyeshadow_base",
        "Mascara":          "mascara",
        "Lip Tint":         "lip_tint",
        "Brow Pencil":      "brow_product",
        "Setting Powder":   "setting_powder",
        "Setting Spray":    "setting_spray",
    },
    "lifted_makeup": {
        "Foundation":       "foundation",
        "Concealer":        "concealer",
        "Blush":            "blush",
        "Eyeshadow":        "eyeshadow_lid",
        "Eyeliner":         "eyeliner",
        "Mascara":          "mascara",
        "Highlighter":      "highlighter",
        "Lip Gloss":        "lip_gloss",
        "Brow Pencil":      "brow_product",
        "Setting Spray":    "setting_spray",
    },
    "snatched": {
        "Foundation":       "foundation",
        "Concealer":        "concealer",
        "Contour":          "bronzer",
        "Blush":            "blush",
        "Highlighter":      "highlighter",
        "Eyeshadow":        "eyeshadow_lid",
        "Eyeliner":         "eyeliner",
        "Mascara":          "mascara",
        "Lipstick":         "lipstick",
        "Lip Liner":        "lip_liner",
        "Brow Pencil":      "brow_product",
        "Setting Powder":   "setting_powder",
        "Setting Spray":    "setting_spray",
    },
    "igari": {
        "Skin Tint":        "skin_tint",
        "Concealer":        "concealer",
        "Cream Blush":      "blush",
        "Mascara":          "mascara",
        "Lip Gloss":        "lip_gloss",
        "Setting Spray":    "setting_spray",
    },
    "douyin": {
        "Foundation":       "foundation",
        "Concealer":        "concealer",
        "Blush":            "blush",
        "Eyeshadow":        "eyeshadow_lid",
        "Eyeliner":         "eyeliner",
        "Mascara":          "mascara",
        "Lip Tint":         "lip_tint",
        "Brow Pencil":      "brow_product",
        "Setting Powder":   "setting_powder",
        "Setting Spray":    "setting_spray",
    },
    "strawberry": {
        "Skin Tint":        "skin_tint",
        "Concealer":        "concealer",
        "Rosy Blush":       "blush",
        "Pink Eyeshadow":   "eyeshadow_lid",
        "Mascara":          "mascara",
        "Berry Lip Gloss":  "lip_gloss",
        "Highlighter":      "highlighter",
        "Setting Spray":    "setting_spray",
    },
    "office": {
        "Foundation":       "foundation",
        "Concealer":        "concealer",
        "Blush":            "blush",
        "Eyeshadow":        "eyeshadow_base",
        "Eyeliner":         "eyeliner",
        "Mascara":          "mascara",
        "Lipstick":         "lipstick",
        "Brow Pencil":      "brow_product",
        "Setting Powder":   "setting_powder",
        "Setting Spray":    "setting_spray",
    },
    "neutral_glam": {
        "Foundation":       "foundation",
        "Concealer":        "concealer",
        "Contour":          "bronzer",
        "Blush":            "blush",
        "Highlighter":      "highlighter",
        "Eyeshadow":        "eyeshadow_lid",
        "Eyeliner":         "eyeliner",
        "Mascara":          "mascara",
        "Lipstick":         "lipstick",
        "Lip Liner":        "lip_liner",
        "Brow Pencil":      "brow_product",
        "Setting Powder":   "setting_powder",
        "Setting Spray":    "setting_spray",
    },
    "corporate_clean": {
        "Foundation":       "foundation",
        "Concealer":        "concealer",
        "Blush":            "blush",
        "Eyeshadow":        "eyeshadow_base",
        "Mascara":          "mascara",
        "Lipstick":         "lipstick",
        "Brow Pencil":      "brow_product",
        "Setting Powder":   "setting_powder",
        "Setting Spray":    "setting_spray",
    },
}


# ── MAIN FUNCTION ──────────────────────────────────────────
def get_makeup_recommendation(undertone, face_shape, eye_shape, makeup_style):
    """
    Returns what products to use and their shades.

    Args:
        undertone:    "warm", "cool", or "neutral"
        face_shape:   "oval", "round", "square", "heart", "oblong"
        eye_shape:    "almond", "round", "monolid", "hooded", "downturned", "close_set"
        makeup_style: style key e.g. "clean_girl", "soft_glam"

    Returns:
        List of products with shades
    """

    shades = SHADES.get(undertone, SHADES["neutral"])
    products = STYLE_PRODUCTS.get(makeup_style, {})

    result = []
    for product_name, shade_key in products.items():
        if shade_key == "[TBD]":
            shade = "[TBD — leader researching]"
        else:
            shade = shades.get(shade_key, "[TBD]")

        result.append({
            "product": product_name,
            "shade":   shade
        })

    return result


# ── TEST ───────────────────────────────────────────────────
if __name__ == "__main__":
    result = get_makeup_recommendation(
        undertone    = "warm",
        face_shape   = "oval",
        eye_shape    = "almond",
        makeup_style = "clean_girl"
    )

    print("=== Capstone Glow — What To Use ===")
    print("Style: Clean Girl Makeup")
    print("Undertone: Warm | Face: Oval | Eyes: Almond")
    print()
    for item in result:
        print(f"  {item['product']}: {item['shade']}")