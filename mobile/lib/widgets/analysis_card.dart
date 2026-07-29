import 'package:flutter/material.dart';

// Shared by the live Beauty Profile screen (page_9) and the saved-
// result revisit screen (page_14_favorites) so both render the same
// 4 face-analysis cards identically.

// Official Monk Skin Tone Scale reference colors (M1 lightest -> M10
// deepest). Index 0 = Monk 01, so use (monkScale - 1) to look up.
const List<Color> monkScaleColors = [
  Color(0xFFF6EDE4), // Monk 01
  Color(0xFFF3E7DB), // Monk 02
  Color(0xFFF7EAD0), // Monk 03
  Color(0xFFEADABA), // Monk 04
  Color(0xFFD7BD96), // Monk 05
  Color(0xFFA07E56), // Monk 06
  Color(0xFF825C43), // Monk 07
  Color(0xFF604134), // Monk 08
  Color(0xFF3A312A), // Monk 09
  Color(0xFF292420), // Monk 10
];

// Returns the Monk Scale reference color, falling back to a mid-tone
// default when no valid scale (1-10) is given.
Color monkScaleColor(int? scale) {
  if (scale != null && scale >= 1 && scale <= 10) {
    return monkScaleColors[scale - 1];
  }
  return const Color(0xFFD4956A);
}

// Capitalizes the first letter — detector values come lowercase
// ("warm", "almond") but display should read "Warm", "Almond".
String titleCase(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

// One of the 4 face-analysis cards (skin tone, face shape, eye shape,
// undertone). Pass `icon` for shape-based cards (renders the icon on
// a tinted circle background); leave it null for color-based cards
// (renders a solid color swatch instead) — color represents the
// actual detected value there, so a generic icon would be misleading.
class AnalysisCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double contentWidth;
  final bool isCircle;
  final IconData? icon;

  const AnalysisCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.contentWidth,
    this.isCircle = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: contentWidth * 0.015,
        vertical: contentWidth * 0.025,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Icon (shape cards) or solid swatch (color cards)
          Container(
            width: contentWidth * 0.11,
            height: contentWidth * 0.11,
            decoration: BoxDecoration(
              color: icon != null ? color.withValues(alpha: 0.25) : color,
              shape: (icon != null || isCircle)
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              borderRadius: (icon != null || isCircle)
                  ? null
                  : BorderRadius.circular(8),
            ),
            child: icon != null
                ? Icon(icon, color: color, size: contentWidth * 0.06)
                : null,
          ),
          SizedBox(height: contentWidth * 0.02),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.02,
              color: Colors.grey,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: contentWidth * 0.008),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: contentWidth * 0.028,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
