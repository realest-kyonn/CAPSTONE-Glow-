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