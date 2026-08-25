import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Skin Type Quiz — static content
//
// Standard dermatological skin-type criteria (Oily/Dry/Combination/
// Normal), with skincare + makeup guidance adapted for the Philippines'
// hot, humid, near-equator-sun climate — researched from dermatologist
// and skincare-expert sources (see chat for citations). Not a substitute
// for professional dermatological advice; persistent or worsening skin
// issues should still see a dermatologist.
// ─────────────────────────────────────────────────────────────

class SkinTypeInfo {
  final String key;
  final String name;
  final String feelDescription; // shown as the tappable answer on the quiz
  final String description; // shown on the result screen
  final IconData icon;
  final List<String> skincareTips;
  final List<String> makeupGuidance;

  const SkinTypeInfo({
    required this.key,
    required this.name,
    required this.feelDescription,
    required this.description,
    required this.icon,
    required this.skincareTips,
    required this.makeupGuidance,
  });
}

const Map<String, SkinTypeInfo> skinTypes = {
  'oily': SkinTypeInfo(
    key: 'oily',
    name: 'Oily',
    feelDescription: 'Your entire face feels slick or looks shiny.',
    description:
        'Oily skin produces more sebum than it needs, so your face can look '
        'shiny by midday, pores tend to be more visible, and breakouts '
        'happen more easily — especially in a hot, humid climate like the '
        'Philippines, where heat and sweat push oil production even higher.',
    icon: Icons.water_drop_rounded,
    skincareTips: [
      'Cleanse twice a day (morning and night) with a gentle salicylic acid '
          '(BHA) cleanser — over-washing strips your skin and can trigger '
          'even more oil as a rebound.',
      'Use a niacinamide serum to help regulate sebum and calm redness '
          'without over-drying.',
      "Don't skip moisturizer — an oil-free, gel-based moisturizer keeps "
          'skin balanced; skipping it makes skin overcompensate with more oil.',
      'Exfoliate 2–3x a week with a BHA instead of harsh physical scrubs, '
          'which can irritate and worsen breakouts.',
      'Wear a lightweight, gel or fluid broad-spectrum sunscreen (SPF50 '
          "PA++++) daily — mattifying formulas exist so sunscreen doesn't "
          'add extra shine.',
      'Keep blotting sheets or oil-control papers on hand for midday shine, '
          'especially during hot, humid months.',
      'During rainy season, watch for small, itchy, uniform bumps along the '
          'hairline, forehead, or jaw — that can be fungal (Malassezia) acne, '
          "not regular acne, and needs different care. If it doesn't improve "
          'with your usual routine, see a dermatologist.',
    ],
    makeupGuidance: [
      'Choose oil-free, non-comedogenic, or "fungal-acne-safe" labeled '
          'bases — heavy, oil-rich formulas trap sweat and oil in the '
          'humidity, encouraging breakouts.',
      'Mineral powders (zinc oxide, titanium dioxide) give coverage without '
          'clogging pores and can even help calm inflammation.',
      'Set your T-zone with a lightweight translucent powder, and blot '
          'rather than reapplying full layers of makeup throughout the day.',
      'Avoid heavy dewy/illuminating primers and foundations — they tend to '
          'slide off and clog pores faster in heat and humidity.',
      'Always remove makeup fully before bed — leftover makeup mixed with '
          'sweat overnight is a common breakout trigger.',
    ],
  ),
  'dry': SkinTypeInfo(
    key: 'dry',
    name: 'Dry',
    feelDescription: 'Your skin feels tight, rough, or flaky.',
    description:
        "Dry skin doesn't produce enough natural oil to stay comfortable, "
        'so it can feel tight after washing, look dull or flaky, and show '
        'fine lines more easily. In the Philippines this is usually less '
        'about the humid outdoor air (which is naturally moisture-rich) and '
        'more about air-conditioned malls, offices, and commutes, plus '
        "over-cleansing to fight midday heat — both of which strip your "
        "skin's natural moisture.",
    icon: Icons.grain_rounded,
    skincareTips: [
      'Cleanse with a gentle, sulfate-free, cream or milk cleanser — avoid '
          'foaming cleansers, which strip the oils your skin already lacks.',
      'Apply a hyaluronic acid serum to damp skin to pull in moisture, then '
          'seal it in with a richer, ceramide-based moisturizer to repair '
          'your skin barrier.',
      'Use lukewarm (not hot) water when washing your face — hot water '
          'worsens dryness.',
      'Exfoliate gently, at most once a week — over-exfoliating damages an '
          'already-compromised barrier.',
      "Don't skip sunscreen — dry, barrier-compromised skin is actually "
          'more vulnerable to UV damage, not less. Look for a hydrating, '
          'non-drying SPF50 PA++++ formula.',
      'Carry a travel-size moisturizer or facial mist if you spend long '
          'hours in air-conditioned spaces.',
    ],
    makeupGuidance: [
      'Look for hydrating, dewy, or "luminous finish" formulas with '
          'hyaluronic acid or glycerin — matte, long-wear, or heavily '
          'powdered products tend to cling to dry patches and look flaky.',
      'Use a hydrating primer as your base so foundation applies smoothly '
          'instead of settling into fine lines.',
      'Choose cream or liquid blush and bronzer over powder formulas, which '
          'can emphasize dry texture.',
      'Set makeup with a hydrating setting spray instead of powder to lock '
          'in moisture without adding dryness.',
      'Avoid high-alcohol, "transfer-proof" formulas — the alcohol content '
          'that makes them long-wearing also dries out your skin further.',
      'Remove makeup with a gentle, non-stripping cleanser or micellar '
          'water — avoid alcohol-based removers.',
    ],
  ),
  'combination': SkinTypeInfo(
    key: 'combination',
    name: 'Combination',
    feelDescription:
        'You have shine in the T-zone (forehead, nose, chin) but normal or '
        'dry cheeks.',
    description:
        'Combination skin runs oily through the T-zone (forehead, nose, and '
        'chin) while the cheeks stay normal or even dry. In a hot, humid '
        'climate like the Philippines, the T-zone shine usually shows up '
        'faster and more intensely than it would elsewhere, so this skin '
        'type often needs different care for different parts of the face '
        'rather than one blanket routine.',
    icon: Icons.gradient_rounded,
    skincareTips: [
      'Cleanse with a gentle, balanced cleanser once or twice a day — avoid '
          'anything overly stripping, which can make the T-zone produce '
          'even more oil to compensate.',
      'Use a niacinamide serum all over — it helps regulate oil in the '
          'T-zone while also supporting the skin barrier on drier cheeks.',
      'Moisturize by "zoning": a lightweight, oil-free gel on the T-zone '
          'and a richer cream on the cheeks — or one balanced, non-greasy '
          "moisturizer if that's simpler for your routine.",
      'Focus BHA exfoliation (2x a week) on the T-zone only, where oil and '
          'clogged pores build up fastest.',
      'Use a broad-spectrum gel-cream sunscreen (SPF50 PA++++) daily — it '
          'should feel light enough for the T-zone without under-hydrating '
          'the cheeks.',
      'Blot the T-zone midday with oil-control papers, especially during '
          'hot or humid weather, rather than reapplying more product.',
    ],
    makeupGuidance: [
      'Use a mattifying primer on the T-zone and a hydrating primer on the '
          'cheeks — or a "blurring" primer formulated for combination skin.',
      'Choose a medium-coverage, buildable, non-comedogenic foundation '
          'rather than a heavy full-matte formula, which can look dry on '
          'the cheeks while still slipping on the T-zone.',
      'Set only the T-zone with translucent powder; leave the cheeks '
          'dewier for a natural finish.',
      'Blot the T-zone through the day instead of adding more powder, '
          'which can build up and look cakey.',
      'At night, remove makeup fully — residue mixed with T-zone oil and '
          'sweat is a common cause of clogged pores in this climate.',
    ],
  ),
  'normal': SkinTypeInfo(
    key: 'normal',
    name: 'Normal',
    feelDescription:
        'Your skin feels comfortable with minimal shine or tightness.',
    description:
        'Normal skin is well-balanced — not too oily, not too dry, with '
        "minimal visible shine or tightness and fewer breakouts. It's easy "
        "to assume balanced skin doesn't need much care, but in the "
        "Philippines' strong, near-equator sun, the biggest real risk for "
        'this skin type is UV damage — sun exposure that quietly causes '
        'premature aging and dark spots long before skin feels "bad."',
    icon: Icons.spa_rounded,
    skincareTips: [
      'Keep it simple: a gentle cleanser, a lightweight moisturizer with '
          'ceramides or hyaluronic acid, and daily sunscreen are enough to '
          "maintain your skin's balance.",
      "Don't skip sunscreen just because your skin looks fine — daily "
          'broad-spectrum SPF50 PA++++ is the single most important step '
          'for preventing premature aging and pigmentation here, even on '
          'cloudy or rainy days.',
      'Add an antioxidant serum (like vitamin C) in the morning for extra '
          'protection against sun and pollution exposure.',
      'Exfoliate gently once or twice a week to keep skin renewing itself '
          'and prevent dullness.',
      "Stay hydrated and reapply sunscreen if you're outdoors for extended "
          'periods — heat and sweat can wear it off faster than the label '
          'suggests.',
    ],
    makeupGuidance: [
      'You have the most flexibility — most formula types (dewy, matte, or '
          'natural finish) will work well without much risk of irritation.',
      'Still lean toward non-comedogenic formulas where possible, since '
          'heat and occasional sweat can still affect any skin type.',
      'A lightweight BB cream or tinted moisturizer with SPF is ideal for '
          'daily wear and adds sun protection on top of your skincare.',
      'Save heavier, full-coverage, long-wear formulas for special '
          'occasions rather than daily use, to avoid unnecessary buildup.',
      "Always remove makeup before bed to keep your skin's natural balance "
          'from being disrupted.',
    ],
  ),
};
