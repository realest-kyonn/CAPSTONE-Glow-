/// Capstone Glow — Adjust Skin Tone
///
/// Lets the user correct the detected skin tone. This exists because we
/// MEASURED that automatic skin-depth estimation does not work: evaluated
/// against Dr. Ellis Monk's own expert labels (MST-E, 599 images) it scored
/// 13.9% where random guessing is 10%, and it systematically reads 1-2 tones
/// too dark. The cause is uncontrolled lighting, which no amount of tuning
/// fixes.
///
/// So rather than present a number we know is unreliable, the app shows what
/// it detected and lets the user correct it against the official swatches —
/// which is precisely what the Monk Skin Tone Scale was designed for. It is a
/// self-identification scale.
///
/// Two things can be adjusted, and they have DIFFERENT consequences:
///
///   DEPTH (Monk 1-10) — feeds only the shade lookup
///                       (shades[product][undertone][monk-1]).
///                       Changing it changes suggested shades, not which
///                       styles are recommended.
///
///   UNDERTONE         — feeds BOTH the shade lookup AND style scoring
///                       (worth 1 point in scoreStyles). Changing it can
///                       change the recommended styles themselves, so the
///                       caller must re-run scoring.
///
/// The undertone quiz uses the standard professional tests (vein colour,
/// jewellery, sun reaction) rather than invented questions.
library;

import 'package:flutter/material.dart';

/// The 10 official Monk Skin Tone Scale swatches, as sRGB hex.
/// Verified against skintone.google and Wikipedia. These are a published
/// standard — do not edit them by eye.
const List<int> kMonkSwatchHex = [
  0xFFF6EDE4, 0xFFF3E7DB, 0xFFF7EAD0, 0xFFEADABA, 0xFFD7BD96,
  0xFFA07E56, 0xFF825C43, 0xFF604134, 0xFF3A312A, 0xFF292420,
];

/// What the adjust screen hands back to the results screen.
class SkinToneAdjustment {
  final int monkScale; // 1-10
  final String undertone; // warm | cool | neutral
  final bool monkChanged;
  final bool undertoneChanged;

  const SkinToneAdjustment({
    required this.monkScale,
    required this.undertone,
    required this.monkChanged,
    required this.undertoneChanged,
  });
}

class SkinToneAdjustScreen extends StatefulWidget {
  final int detectedMonk;
  final String detectedUndertone;

  const SkinToneAdjustScreen({
    super.key,
    required this.detectedMonk,
    required this.detectedUndertone,
  });

  @override
  State<SkinToneAdjustScreen> createState() => _SkinToneAdjustScreenState();
}

class _SkinToneAdjustScreenState extends State<SkinToneAdjustScreen> {
  static const _pink = Color(0xFFFF6EB4);

  late int _monk;
  late String _undertone;
  bool _quizOpen = false;

  /// Quiz answers, one per question; null until answered. Each answer maps to
  /// "warm" | "cool" | "neutral".
  final List<String?> _answers = [null, null, null];

  @override
  void initState() {
    super.initState();
    _monk = widget.detectedMonk.clamp(1, 10);
    _undertone = _normalise(widget.detectedUndertone);
  }

  String _normalise(String s) {
    final t = s.toLowerCase().trim();
    if (t.contains('warm')) return 'warm';
    if (t.contains('cool')) return 'cool';
    return 'neutral';
  }

  // ── the three professional undertone tests ────────────────────────
  static const _questions = <Map<String, Object>>[
    {
      'q': 'Look at the veins on your inner wrist, in daylight. What colour do they look?',
      'a': [
        ['Greenish', 'warm'],
        ['Blue or purple', 'cool'],
        ['A mix, or hard to tell', 'neutral'],
      ],
    },
    {
      'q': 'Which jewellery makes your skin look brighter?',
      'a': [
        ['Gold', 'warm'],
        ['Silver', 'cool'],
        ['Both look fine', 'neutral'],
      ],
    },
    {
      'q': 'After time in the sun, your skin usually…',
      'a': [
        ['Tans easily, rarely burns', 'warm'],
        ['Burns easily, rarely tans', 'cool'],
        ['Burns a little, then tans', 'neutral'],
      ],
    },
  ];

  /// Majority vote across answered questions; ties resolve to neutral.
  String? get _quizResult {
    final given = _answers.whereType<String>().toList();
    if (given.length < _questions.length) return null;
    final counts = <String, int>{};
    for (final a in given) {
      counts[a] = (counts[a] ?? 0) + 1;
    }
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final tied = counts.values.where((v) => v == best.value).length > 1;
    return tied ? 'neutral' : best.key;
  }

  void _save() {
    Navigator.pop(
      context,
      SkinToneAdjustment(
        monkScale: _monk,
        undertone: _undertone,
        monkChanged: _monk != widget.detectedMonk,
        undertoneChanged: _undertone != _normalise(widget.detectedUndertone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Adjust Skin Tone',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Not quite right? You can correct it here.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lighting affects how skin looks in photos, so our reading can '
              'be off. Your own choice is always used if you change it.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 22),

            // ── DEPTH ─────────────────────────────────────────────
            _sectionTitle('1. Skin depth'),
            const Text(
              'Tap the swatch closest to your skin. Compare against your jaw '
              'or inner arm in natural light.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 14),
            _swatchGrid(),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Selected: Monk $_monk'
                '${_monk == widget.detectedMonk ? "  (as detected)" : "  (changed by you)"}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _monk == widget.detectedMonk ? Colors.black54 : _pink,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── UNDERTONE ─────────────────────────────────────────
            _sectionTitle('2. Undertone'),
            const Text(
              'The colour under your skin — not how light or deep it is.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _toneCard('warm', 'Warm', 'golden, yellow,\npeachy',
                    const Color(0xFFE8A33D)),
                const SizedBox(width: 8),
                _toneCard('cool', 'Cool', 'pink, red,\nrosy',
                    const Color(0xFF5B8DEF)),
                const SizedBox(width: 8),
                _toneCard('neutral', 'Neutral', 'balanced,\nno clear cast',
                    const Color(0xFF9E9E9E)),
              ],
            ),
            const SizedBox(height: 14),

            // quiz toggle
            InkWell(
              onTap: () => setState(() => _quizOpen = !_quizOpen),
              child: Row(
                children: [
                  Icon(_quizOpen ? Icons.expand_less : Icons.help_outline,
                      size: 19, color: _pink),
                  const SizedBox(width: 6),
                  Text(
                    _quizOpen ? 'Hide the quiz' : "Not sure? Take a short quiz",
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _pink),
                  ),
                ],
              ),
            ),
            if (_quizOpen) ...[
              const SizedBox(height: 12),
              ..._questions.asMap().entries.map((e) => _quizQuestion(e.key, e.value)),
              const SizedBox(height: 4),
              _quizResultBox(),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Save changes',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.black54)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(t,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
      );

  Widget _swatchGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(10, (i) {
        final tone = i + 1;
        final selected = tone == _monk;
        return GestureDetector(
          onTap: () => setState(() => _monk = tone),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(kMonkSwatchHex[i]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? _pink : Colors.black12,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check,
                        color: i >= 5 ? Colors.white : Colors.black87, size: 22)
                    : null,
              ),
              const SizedBox(height: 3),
              Text('$tone',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? _pink : Colors.black54)),
            ],
          ),
        );
      }),
    );
  }

  Widget _toneCard(String value, String label, String hint, Color swatch) {
    final selected = _undertone == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _undertone = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? _pink.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _pink : Colors.black12,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
              ),
              const SizedBox(height: 7),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? _pink : Colors.black87)),
              const SizedBox(height: 2),
              Text(hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quizQuestion(int index, Map<String, Object> q) {
    final options = q['a'] as List;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${q['q']}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...options.map((o) {
            final opt = o as List;
            final text = opt[0] as String;
            final value = opt[1] as String;
            final selected = _answers[index] == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: GestureDetector(
                onTap: () => setState(() {
                  _answers[index] = value;
                  final r = _quizResult;
                  if (r != null) _undertone = r; // apply as soon as complete
                }),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected ? _pink.withValues(alpha: 0.10) : Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: selected ? _pink : Colors.black12,
                        width: selected ? 1.6 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 17,
                        color: selected ? _pink : Colors.black26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(text,
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _quizResultBox() {
    final r = _quizResult;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: r == null ? const Color(0xFFF5F5F5) : _pink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        r == null
            ? 'Answer all three questions to see a suggestion.'
            : 'Your answers suggest: ${r[0].toUpperCase()}${r.substring(1)}. '
                'It has been selected above — you can still change it.',
        style: TextStyle(
            fontSize: 12.5,
            color: r == null ? Colors.black54 : Colors.black87,
            fontWeight: r == null ? FontWeight.normal : FontWeight.w600),
      ),
    );
  }
}
