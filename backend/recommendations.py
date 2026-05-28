"""
Capstone Glow - Casual Everyday Makeup Recommendation Engine
With explanations for each recommendation
Sources:
- L'Oreal Paris (lorealparisusa.com)
- Florida Academy Makeup Guide (florida-academy.edu)
- Casa de Hilo Beauty Guide (casadehilo.com)
- IRJMETS Color Theory Study (2024)
"""

def get_makeup_recommendation(skin_tone, face_shape):
    """
    Args:
        skin_tone: String - "warm", "cool", or "neutral"
        face_shape: String - "oval", "round", "square", "heart", "oblong"
    Returns:
        Dictionary with recommendations AND explanations
    """

    recommendations = {}

    # ── FOUNDATION ─────────────────────────────────────────
    if skin_tone == "warm":
        recommendations["foundation"] = {
            "shade": "Golden Beige or Honey",
            "finish": "Lightweight tinted moisturizer",
            "why": "Your warm skin has golden or yellow undertones. Golden Beige matches these undertones seamlessly so your foundation blends naturally without looking ashy or too pink."
        }
    elif skin_tone == "cool":
        recommendations["foundation"] = {
            "shade": "Rose Beige or Cool Ivory",
            "finish": "Lightweight tinted moisturizer",
            "why": "Your cool skin has pink or rosy undertones. Rose Beige complements these undertones so your foundation looks natural and even without appearing orange or muddy."
        }
    elif skin_tone == "neutral":
        recommendations["foundation"] = {
            "shade": "Neutral Beige or Buff",
            "finish": "Lightweight tinted moisturizer",
            "why": "Your neutral skin has a balance of warm and cool undertones. Neutral Beige works with both undertones so your foundation looks naturally seamless on your skin."
        }

    # ── BLUSH ──────────────────────────────────────────────
    if skin_tone == "warm":
        recommendations["blush"] = {
            "shade": "Peach or Coral",
            "finish": "Cream blush",
            "why": "Peach and coral shades share warm undertones with your skin, creating a natural healthy flush. These shades enhance your golden glow without clashing with your complexion."
        }
    elif skin_tone == "cool":
        recommendations["blush"] = {
            "shade": "Soft Pink or Light Rose",
            "finish": "Cream blush",
            "why": "Soft pink and rose shades complement the cool pink undertones in your skin. These shades mimic a natural flush and enhance your cool complexion beautifully."
        }
    elif skin_tone == "neutral":
        recommendations["blush"] = {
            "shade": "Dusty Rose or Soft Peach",
            "finish": "Cream blush",
            "why": "Dusty rose and soft peach are balanced shades that work with both warm and cool undertones. They give your neutral skin a healthy natural glow without being too warm or too cool."
        }

    # ── EYESHADOW ──────────────────────────────────────────
    if skin_tone == "warm":
        recommendations["eyeshadow"] = {
            "shade": "Soft Bronze or Warm Brown",
            "finish": "Matte or subtle shimmer",
            "why": "Bronze and warm brown shades share the same golden undertones as your skin, creating a harmonious look. These earthy tones enhance your eyes without overpowering your warm complexion."
        }
    elif skin_tone == "cool":
        recommendations["eyeshadow"] = {
            "shade": "Taupe or Soft Mauve",
            "finish": "Matte",
            "why": "Taupe and mauve have cool undertones that complement your skin's pink or rosy base. These shades add subtle definition to your eyes while staying harmonious with your cool complexion."
        }
    elif skin_tone == "neutral":
        recommendations["eyeshadow"] = {
            "shade": "Warm Taupe or Rose Brown",
            "finish": "Matte or subtle shimmer",
            "why": "Taupe and rose brown are versatile neutral shades that flatter both warm and cool undertones. They add dimension to your eyes without leaning too warm or too cool."
        }

    # ── MASCARA ────────────────────────────────────────────
    recommendations["mascara"] = {
        "shade": "Black or Dark Brown",
        "finish": "Lengthening or volumizing",
        "why": "Mascara defines and opens up your eyes for any casual everyday look. Black suits all skin tones while dark brown gives a softer more natural effect for daytime wear."
    }

    # ── LIPSTICK based on face shape ──────────────────────
    if face_shape == "oval":
        recommendations["lipstick"] = {
            "shade": "Tinted lip balm or Nude Pink gloss",
            "finish": "Glossy or sheer",
            "why": "Oval face shape is the most balanced and versatile. A simple tinted lip balm keeps your look effortlessly casual and lets your natural features shine without overcomplicating the look."
        }
    elif face_shape == "round":
        recommendations["lipstick"] = {
            "shade": "Soft Berry or Muted Rose lip tint",
            "finish": "Matte or satin",
            "why": "A slightly deeper lip color draws attention to the center of your face and adds subtle definition. This creates an elongating effect that balances a round face shape for everyday wear."
        }
    elif face_shape == "square":
        recommendations["lipstick"] = {
            "shade": "Nude Pink or Peachy lip gloss",
            "finish": "Glossy",
            "why": "Soft glossy lip colors soften the appearance of a strong angular jawline. Light and neutral shades keep the focus balanced across your face for a natural casual look."
        }
    elif face_shape == "heart":
        recommendations["lipstick"] = {
            "shade": "Rose tinted lip balm or Sheer Mauve",
            "finish": "Sheer or glossy",
            "why": "Sheer lip colors draw the eye downward to your lips and chin, balancing a wider forehead. Light rose and mauve shades complement most skin tones for a simple everyday look."
        }
    elif face_shape == "oblong":
        recommendations["lipstick"] = {
            "shade": "Coral lip tint or Warm Nude gloss",
            "finish": "Glossy",
            "why": "Warm glossy lip shades add visual width to the lips, helping to balance a longer face shape. Coral and warm nude tones are bright enough to draw attention without being overdone for casual wear."
        }

    # ── FACE SHAPE TIP ─────────────────────────────────────
    face_tips = {
        "oval":    "Your oval face shape is the most versatile! Almost any makeup style works well for you.",
        "round":   "For your round face, focus on adding subtle definition with slightly deeper lip shades.",
        "square":  "For your square face, soft and rounded makeup choices help balance your strong features.",
        "heart":   "For your heart face shape, keep lips light and eyes soft to balance your wider forehead.",
        "oblong":  "For your oblong face, bold lips and horizontal emphasis help create a balanced look."
    }
    recommendations["face_tip"] = face_tips.get(face_shape, "")

    return recommendations


# Test
if __name__ == "__main__":
    result = get_makeup_recommendation("warm", "oval")
    print("=== Capstone Glow - Casual Everyday Makeup ===\n")
    for product, details in result.items():
        if isinstance(details, dict):
            print(f"{product.upper()}:")
            print(f"  Shade:  {details.get('shade', '')}")
            print(f"  Finish: {details.get('finish', '')}")
            print(f"  Why:    {details.get('why', '')}")
            print()
        else:
            print(f"TIP: {details}\n")