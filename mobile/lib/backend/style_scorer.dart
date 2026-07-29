/// Capstone Glow - Style Scorer (Dart port of style_scorer.py)
///
/// Scores all 15 makeup styles based on detected features.
/// Returns TOP 3 best-matching styles for the user.
///
/// Based on research data from makeup_styles_by_features.xlsx — the same
/// source Python's version was built from. Scoring weights (face shape=3,
/// eye shape=2, undertone=1) and all compatibility lists below are a
/// direct line-for-line port of style_scorer.py — not re-derived.
library;

class StyleResult {
  final String styleKey;
  final String styleName;
  final String description;
  final int score;
  final int maxScore;
  final int matchPct;

  const StyleResult({
    required this.styleKey,
    required this.styleName,
    required this.description,
    required this.score,
    required this.maxScore,
    required this.matchPct,
  });
}

// ── COMPATIBILITY DATA FROM EXCEL FILE ─────────────────────
// (identical to Python's FACE_SHAPE_SCORES / EYE_SHAPE_SCORES /
// UNDERTONE_SCORES / STYLE_NAMES / STYLE_DESCRIPTIONS)

const Map<String, List<String>> _faceShapeScores = {
  'clean_girl': ['oval', 'round', 'square', 'heart'],
  'no_makeup': ['oval', 'heart', 'long'],
  'fresh_dewy': ['round', 'oval', 'square'],
  'soft_glam': ['oval', 'heart', 'long'],
  'korean_daily': ['round', 'oval', 'heart'],
  'peach_makeup': ['round', 'oval', 'heart'],
  'soft_contour': ['round', 'square', 'long'],
  'lifted_makeup': ['round', 'square', 'heart'],
  'snatched': ['round', 'square', 'long'],
  'igari': ['round', 'oval', 'heart'],
  'douyin': ['round', 'oval'],
  'strawberry': ['round', 'heart', 'oval'],
  'office': ['oval', 'square', 'heart', 'long'],
  'neutral_glam': ['oval', 'heart', 'long'],
  'corporate_clean': ['oval', 'square', 'long', 'heart'],
};

const Map<String, List<String>> _eyeShapeScores = {
  'clean_girl': ['almond', 'monolid', 'hooded'],
  'no_makeup': [
    'almond',
    'round',
    'monolid',
    'hooded',
    'downturned',
    'upturned'
  ],
  'fresh_dewy': ['almond', 'monolid', 'round'],
  'soft_glam': ['almond', 'downturned', 'hooded'],
  'korean_daily': ['monolid', 'almond', 'round'],
  'peach_makeup': ['almond', 'monolid', 'round'],
  'soft_contour': [
    'almond',
    'round',
    'monolid',
    'hooded',
    'downturned',
    'upturned'
  ],
  'lifted_makeup': ['hooded', 'downturned', 'monolid'],
  'snatched': ['almond', 'hooded', 'upturned'],
  'igari': ['monolid', 'almond', 'round'],
  'douyin': ['monolid', 'almond', 'round'],
  'strawberry': ['round', 'almond', 'monolid'],
  'office': [
    'almond',
    'round',
    'monolid',
    'hooded',
    'downturned',
    'upturned'
  ],
  'neutral_glam': ['almond', 'downturned', 'upturned'],
  'corporate_clean': [
    'almond',
    'round',
    'monolid',
    'hooded',
    'downturned',
    'upturned'
  ],
};

const Map<String, List<String>> _undertoneScores = {
  'clean_girl': ['warm', 'cool', 'neutral'],
  'no_makeup': ['warm', 'cool', 'neutral'],
  'fresh_dewy': ['warm', 'cool', 'neutral'],
  'soft_glam': ['warm', 'cool', 'neutral'],
  'korean_daily': ['cool', 'neutral'],
  'peach_makeup': ['warm', 'neutral'],
  'soft_contour': ['warm', 'cool', 'neutral'],
  'lifted_makeup': ['warm', 'cool', 'neutral'],
  'snatched': ['warm', 'cool', 'neutral'],
  'igari': ['cool', 'neutral'],
  'douyin': ['cool', 'neutral'],
  'strawberry': ['warm', 'neutral'],
  'office': ['warm', 'cool', 'neutral'],
  'neutral_glam': ['warm', 'cool', 'neutral'],
  'corporate_clean': ['warm', 'cool', 'neutral'],
};

const Map<String, String> _styleNames = {
  'clean_girl': 'Clean Girl Makeup',
  'no_makeup': 'No-Makeup Makeup',
  'fresh_dewy': 'Fresh Dewy Makeup',
  'soft_glam': 'Soft Glam Everyday',
  'korean_daily': 'Korean Daily Makeup',
  'peach_makeup': 'Peach Makeup',
  'soft_contour': 'Soft Contour Makeup',
  'lifted_makeup': 'Lifted Makeup',
  'snatched': 'Snatched Everyday Makeup',
  'igari': 'Igari-Inspired Makeup',
  'douyin': 'Douyin Natural Makeup',
  'strawberry': 'Strawberry Makeup',
  'office': 'Office Makeup',
  'neutral_glam': 'Neutral Glam',
  'corporate_clean': 'Corporate Clean Makeup',
};

const Map<String, String> _styleDescriptions = {
  'clean_girl':
      'Minimal, skin-first look with dewy finish. Less is more.',
  'no_makeup':
      "Enhanced naturalness — looks like you're wearing nothing.",
  'fresh_dewy':
      'Glassy, lit-from-within luminous finish. Glass skin effect.',
  'soft_glam':
      'Polished but effortless. Neutral tones with subtle shimmer.',
  'korean_daily':
      'Fresh and youthful K-beauty aesthetic. Gradient lip focus.',
  'peach_makeup':
      'Warm peachy tones for a cute, sun-kissed everyday flush.',
  'soft_contour':
      'Subtle reshaping with soft bronzer and natural blush.',
  'lifted_makeup':
      'Fox-eye and cat techniques that open and lift the eyes.',
  'snatched':
      'Defined and sharp with highlight and contour combo.',
  'igari':
      'Japanese hangover blush across nose bridge. Dreamy flush.',
  'douyin':
      'Chinese social-media aesthetic. Porcelain skin + big eyes.',
  'strawberry':
      'Rosy red tones with dewy skin for a fresh fruity look.',
  'office':
      'Professional and polished. Neutral palette for workplace.',
  'neutral_glam':
      'Timeless and sophisticated. Evening-ready neutrals.',
  'corporate_clean':
      'Refined and minimal. Boardroom-ready with clean finish.',
};

// ── SCORER FUNCTION ────────────────────────────────────────

/// Scores all 15 makeup styles based on the user's detected features.
/// Returns the top 3 best-matching styles, highest score first.
///
/// [undertone]: "warm", "cool", or "neutral"
/// [faceShape]: "oval", "round", "square", "heart", "long" (case-insensitive
///   — mirrors Python's `if face_shape == "Long": face_shape = "long"`
///   normalization, generalized to lowercase everything up front instead)
/// [eyeShape]: "almond", "round", "monolid", "hooded", "downturned",
///   "upturned"
List<StyleResult> scoreStyles({
  required String undertone,
  required String faceShape,
  required String eyeShape,
}) {
  // Normalize casing — mirrors Python's face_shape lowercasing, applied
  // to all three inputs since detector output casing can vary (e.g.
  // FaceShapeDetector returns "Oval", "Round" — Title Case).
  final normFace = faceShape.toLowerCase();
  final normEye = eyeShape.toLowerCase();
  final normUndertone = undertone.toLowerCase();

  final scores = <String, int>{};

  for (final style in _styleNames.keys) {
    int score = 0;

    if ((_faceShapeScores[style] ?? const []).contains(normFace)) {
      score += 3;
    }
    if ((_eyeShapeScores[style] ?? const []).contains(normEye)) {
      score += 2;
    }
    if ((_undertoneScores[style] ?? const []).contains(normUndertone)) {
      score += 1;
    }

    scores[style] = score;
  }

  // Sort by score, highest first
  final sortedEntries = scores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // Top 3
  return sortedEntries.take(3).map((entry) {
    final styleKey = entry.key;
    final score = entry.value;
    return StyleResult(
      styleKey: styleKey,
      styleName: _styleNames[styleKey]!,
      description: _styleDescriptions[styleKey]!,
      score: score,
      maxScore: 6,
      matchPct: ((score / 6) * 100).round(),
    );
  }).toList();
}