"""
Capstone Glow - Recommendation Engine
Returns makeup recommendations based on skin tone and face shape
"""

def get_makeup_recommendation(skin_tone, face_shape):
    """
    Args:
        skin_tone: String - "warm", "cool", or "neutral"
        face_shape: String - "oval", "round", "square", "heart", "long"
    
    Returns:
        Dictionary with makeup recommendations
    """
    recommendations = {
        "foundation": "",
        "blush": "",
        "lipstick": "",
        "eyeshadow": ""
    }
    
    # Foundation and blush based on skin tone
    if skin_tone == "warm":
        recommendations["foundation"] = "Warm Beige, Golden Undertones"
        recommendations["blush"] = "Peach, Coral"
        recommendations["eyeshadow"] = "Bronze, Copper, Warm Browns"
    elif skin_tone == "cool":
        recommendations["foundation"] = "Cool Ivory, Pink Undertones"
        recommendations["blush"] = "Rose Pink, Mauve"
        recommendations["eyeshadow"] = "Silver, Plum, Cool Grays"
    elif skin_tone == "neutral":
        recommendations["foundation"] = "Neutral Beige"
        recommendations["blush"] = "Soft Pink, Dusty Rose"
        recommendations["eyeshadow"] = "Taupe, Neutral Browns"
    
    # Lipstick based on face shape
    if face_shape == "oval":
        recommendations["lipstick"] = "Any shade works well"
    elif face_shape == "round":
        recommendations["lipstick"] = "Matte Berry, Deep Rose"
    elif face_shape == "square":
        recommendations["lipstick"] = "Nude Pink, Soft Coral"
    elif face_shape == "heart":
        recommendations["lipstick"] = "Rose, Mauve"
    elif face_shape == "long":
        recommendations["lipstick"] = "Bright Red, Bold Colors"
    
    return recommendations


# Test the function
if __name__ == "__main__":
    result = get_makeup_recommendation("warm", "oval")
    print("Makeup Recommendations:")
    print(f"Foundation: {result['foundation']}")
    print(f"Blush: {result['blush']}")
    print(f"Lipstick: {result['lipstick']}")
    print(f"Eyeshadow: {result['eyeshadow']}")