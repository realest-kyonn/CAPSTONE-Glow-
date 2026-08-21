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

  // Sort by score (highest first), breaking ties by style key. The
  // tie-break is load-bearing: scores are integers capped at 6 across 15
  // styles, so ties for 3rd place are common, and Dart's List.sort is NOT
  // stable. Without an explicit tie-break this could return a different 3rd
  // recommendation than Python (whose sort is stable) for the same input.
  // Matches Python's `key=lambda x: (-x[1], x[0])`.
  // Tie-break by SPECIFICITY, then alphabetically. Must match Python's
  // `key=lambda x: (-x[1], _specificity(x[0]), x[0])` exactly.
  //
  // Scores are integers capped at 6 across 15 styles, so ties are common — for
  // some feature combinations eight styles tie for third place. Alphabetical
  // order alone is deterministic but systematically favours whatever style
  // sits earliest in the alphabet, so one style won nearly every tie no matter
  // what the user's features were.
  //
  // Specificity fixes that on a principle: a style whose compatibility lists
  // are NARROWER was designed for a narrower set of faces, so when two styles
  // match equally well the more specialised one is the better recommendation.
  int specificity(String key) =>
      (_faceShapeScores[key]?.length ?? 0) +
      (_eyeShapeScores[key]?.length ?? 0) +
      (_undertoneScores[key]?.length ?? 0);

  final sortedEntries = scores.entries.toList()
    ..sort((a, b) {
      final byScore = b.value.compareTo(a.value);
      if (byScore != 0) return byScore;
      final bySpecificity = specificity(a.key).compareTo(specificity(b.key));
      if (bySpecificity != 0) return bySpecificity;
      return a.key.compareTo(b.key);
    });

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