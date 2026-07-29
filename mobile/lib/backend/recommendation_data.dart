import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Loads assets/recommendations.json and builds the per-style tutorial
/// and "what to use" data that MakeupTutorialScreen expects, resolving
/// product shades against the user's detected undertone + Monk Scale.
class RecommendationData {
  static Map<String, dynamic>? _cache;

  static Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/recommendations.json');
    _cache = jsonDecode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  /// Builds the styleData map for [styleKey] (e.g. 'clean_girl'), with
  /// shades resolved for [undertone] ('warm'/'cool'/'neutral') and
  /// [monkScale] (1-10). [styleIndex] is the style's rank (1, 2, or 3)
  /// among the user's top matches.
  static Future<Map<String, dynamic>> buildStyleData({
    required String styleKey,
    required String undertone,
    required int monkScale,
    required int styleIndex,
  }) async {
    final data = await _load();
    final styles = data['styles'] as Map<String, dynamic>;
    final entry = styles[styleKey] as Map<String, dynamic>?;

    if (entry == null) {
      return {'styleIndex': '$styleIndex', 'totalStyles': '3'};
    }

    final tutorial = entry['tutorial'] as Map<String, dynamic>? ?? {};
    final skinPrep = (tutorial['skin_prep'] as List?)?.cast<String>() ?? [];
    final application =
        (tutorial['makeup_application'] as List?)?.cast<String>() ?? [];

    final steps = <Map<String, String>>[
      for (final instruction in [...skinPrep, ...application])
        {'instruction': instruction, 'imagePath': ''},
    ];

    final tips = <String>[
      ...((entry['tips'] as List?)?.cast<String>() ?? []),
      if (entry['general_tip'] is String) entry['general_tip'] as String,
    ];

    final normalizedUndertone =
        ['warm', 'cool', 'neutral'].contains(undertone.toLowerCase())
            ? undertone.toLowerCase()
            : 'neutral';
    final clampedMonk = monkScale.clamp(1, 10);

    final shades = data['shades'] as Map<String, dynamic>;
    final productKeys = (entry['products'] as List?)?.cast<String>() ?? [];
    final products = <Map<String, String>>[
      for (final key in productKeys)
        _buildProduct(shades, key, normalizedUndertone, clampedMonk),
    ];

    final tagline = entry['tagline'] as String?;

    return {
      'name': entry['name'] ?? '',
      'subtitle': tagline ?? '',
      'quote': tagline != null ? '"$tagline"' : '',
      'styleIndex': '$styleIndex',
      'totalStyles': '3',
      'steps': steps,
      'tips': tips,
      'products': products,
    };
  }

  static Map<String, String> _buildProduct(
    Map<String, dynamic> shades,
    String productKey,
    String undertone,
    int monkScale,
  ) {
    final shadeList = shades[productKey]?[undertone] as List?;
    final shade = (shadeList != null && shadeList.length >= monkScale)
        ? shadeList[monkScale - 1] as String
        : '';

    return {
      'category': _categoryFor(productKey),
      'name': _displayName(productKey),
      'shade': shade,
    };
  }

  // Human-readable name from a snake_case product key, e.g.
  // 'color_corrector' -> 'Color Corrector'.
  static String _displayName(String key) {
    return key
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Groups a product key into one of the UI's category buckets by
  // keyword — recommendations.json has no explicit category field.
  static String _categoryFor(String key) {
    if (key.contains('eye') ||
        key.contains('brow') ||
        key.contains('lash') ||
        key.contains('mascara') ||
        key.contains('liner')) {
      return 'BROWS AND EYES';
    }
    if (key.contains('lip')) return 'LIPS';
    if (key.contains('blush') ||
        key.contains('bronzer') ||
        key.contains('contour') ||
        key.contains('highlight')) {
      return 'CHEEKS';
    }
    if (key.contains('spray')) return 'FINISH';
    return 'BASE';
  }
}
