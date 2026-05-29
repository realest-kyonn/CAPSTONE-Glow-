"""
Capstone Glow - Main Pipeline
Combines skin tone detection + makeup recommendations
"""

from skin_tone_detector import detect_skin_tone
from recommendations import get_makeup_recommendation

def analyze_and_recommend(image_path, face_shape):
    """
    Full pipeline:
    1. Detect skin tone from image
    2. Return makeup recommendations
    
    Args:
        image_path: Path to face image
        face_shape: String - oval/round/square/heart/oblong
    
    Returns:
        Complete analysis with skin tone + recommendations
    """

    # Step 1: Detect skin tone
    skin_result = detect_skin_tone(image_path)

    if "error" in skin_result:
        return {"error": skin_result["error"]}

    skin_tone = skin_result["skin_tone"]
    monk_scale = skin_result["monk_scale"]

    # Step 2: Get recommendations
    makeup = get_makeup_recommendation(skin_tone, face_shape)

    # Step 3: Combine results
    return {
        "skin_tone": skin_tone,
        "monk_scale": monk_scale,
        "face_shape": face_shape,
        "recommendations": makeup
    }


# Test
if __name__ == "__main__":
    result = analyze_and_recommend(
        image_path=r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\data\images\img001.jpg",
        face_shape="oval"
    )

    print("=== Capstone Glow - Full Analysis ===\n")
    print(f"Skin Tone: {result['skin_tone']}")
    print(f"Monk Scale: {result['monk_scale']}")
    print(f"Face Shape: {result['face_shape']}")
    print("\n=== Recommendations ===\n")

    for product, details in result["recommendations"].items():
        if isinstance(details, dict):
            print(f"{product.upper()}:")
            print(f"  Shade:  {details.get('shade', '')}")
            print(f"  Finish: {details.get('finish', '')}")
            print(f"  Why:    {details.get('why', '')}")
            print()
        else:
            print(f"TIP: {details}\n")

import json

def export_recommendations_json():
    """
    Exports all possible recommendations to a JSON file
    for Member 2 to use in Flutter
    """
    skin_tones = ["warm", "cool", "neutral"]
    face_shapes = ["oval", "round", "square", "heart", "oblong"]
    
    all_recommendations = {}
    
    for tone in skin_tones:
        all_recommendations[tone] = {}
        for shape in face_shapes:
            result = get_makeup_recommendation(tone, shape)
            all_recommendations[tone][shape] = result
    
    # Save to JSON file
    output_path = r"C:\Users\Kean_2\Documents\GitHub\CAPSTONE (Glow)\backend\recommendations.json"
    
    with open(output_path, "w") as f:
        json.dump(all_recommendations, f, indent=4)
    
    print("✅ recommendations.json exported successfully!")
    print(f"📁 Saved to: {output_path}")


# Add this at the bottom of your if __name__ == "__main__": block
export_recommendations_json()