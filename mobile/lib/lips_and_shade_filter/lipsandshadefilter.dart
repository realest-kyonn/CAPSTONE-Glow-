import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'shade_face_service.dart';

class LipsAndShadeFilter extends StatefulWidget {
  const LipsAndShadeFilter({super.key});
  @override
  State<LipsAndShadeFilter> createState() => _LipsAndShadeFilterState();
}

class _Shade {
  final String name;
  final Color color;
  final String tags;
  const _Shade(this.name, this.color, this.tags);
}

const _shades = [
  _Shade('Deep Rose', Color(0xFF963440), 'red rose dark'),
  _Shade('Cherry', Color(0xFFCF3659), 'red pink'),
  _Shade('Petal Pink', Color(0xFFF36289), 'pink bright'),
  _Shade('Terracotta', Color(0xFFBD6155), 'orange brown warm'),
  _Shade('Rosy Nude', Color(0xFFD99196), 'pink nude light'),
  _Shade('Peach', Color(0xFFF2A080), 'orange peach light warm'),
  _Shade('Coral', Color(0xFFEF7D83), 'orange pink warm'),
  _Shade('Berry', Color(0xFFA63E70), 'purple berry dark cool'),
  _Shade('Mauve', Color(0xFFAA7188), 'purple pink muted cool'),
  _Shade('Cocoa', Color(0xFF885447), 'brown nude dark'),
  _Shade('Classic Red', Color(0xFFB92035), 'red bold'),
  _Shade('Plum', Color(0xFF783B64), 'purple plum dark'),
  _Shade('Apricot', Color(0xFFEA9972), 'peach orange warm'),
  _Shade('Dusty Pink', Color(0xFFC78096), 'pink muted cool'),
  _Shade('Soft Rose', Color(0xFFE58CA0), 'pink rose light'),
];

class _LipsAndShadeFilterState extends State<LipsAndShadeFilter> {
  static const pink = Color(0xFFFF65B5);
  static const soft = Color(0xFFFFEFF7);
  static const ink = Color(0xFFAC275F);
  final _service = ShadeFaceService();
  final _search = TextEditingController();
  ValidatedPhoto? _photo;
  bool _busy = false;
  String? _error;
  int _tab = 0;
  final List<_Shade?> _selected = [null, null];
  final _intensity = [0.5, 0.5];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void _reset() {
    _selected[0] = null; _selected[1] = null;
    _intensity[0] = 0.5; _intensity[1] = 0.5;
  }

  Future<void> _pick() async {
    if (_busy) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      setState(() => _error = 'This face-detection version must be tested on Android.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final result = await _service.validate(await picked.readAsBytes());
      if (!mounted) return;
      setState(() { _photo = result; _reset(); });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matches = _shades.where((s) => '${s.name} ${s.tags}'.toLowerCase().contains(query)).toList();
    final photo = _photo;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: SingleChildScrollView(child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(color: pink, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
          child: const Center(child: SizedBox(width: 480, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Shade Check', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),
            Text('Try lip and blush shades on your photo', style: TextStyle(color: Colors.white, fontSize: 15)),
          ]))),
        ),
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 528),
          child: Padding(padding: const EdgeInsets.all(24), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1BDD5))),
              child: AspectRatio(aspectRatio: 1, child: photo == null
                ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 54, color: pink),
                    SizedBox(height: 16), Text('Add a photo of your face', style: TextStyle(color: ink)),
                  ])
                : CustomPaint(
                    foregroundPainter: _MakeupPainter(photo, _selected[0]?.color, _selected[1]?.color, _intensity[0], _intensity[1]),
                    child: Image.memory(photo.bytes, fit: BoxFit.contain, gaplessPlayback: true),
                  )),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _pick,
              style: FilledButton.styleFrom(backgroundColor: pink, foregroundColor: Colors.white, minimumSize: const Size(0, 48)),
              icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_library_outlined),
              label: Text(_busy ? 'Checking face…' : photo == null ? 'Add image' : 'Change photo'),
            ),
            const SizedBox(height: 10),
            const Text('Use one uncovered face, looking straight ahead, in even lighting.', textAlign: TextAlign.center, style: TextStyle(color: ink, fontSize: 12)),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red), semanticsLabel: _error)),
            if (photo != null) ...[
              const SizedBox(height: 20),
              const Text('Face check passed • Virtual makeup preview', style: TextStyle(color: ink, fontSize: 12)),
              const SizedBox(height: 16),
              Container(decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.all(4), child: Row(children: List.generate(2, (i) => Expanded(child: TextButton(
                onPressed: () => setState(() { _tab = i; _search.clear(); }),
                style: TextButton.styleFrom(backgroundColor: _tab == i ? pink : Colors.transparent, foregroundColor: _tab == i ? Colors.white : ink, minimumSize: const Size(0, 48)),
                child: Text(i == 0 ? 'Lips' : 'Blush'),
              ))))),
              const SizedBox(height: 18),
              TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(
                hintText: 'Search shades: pink, nude, berry…', prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty ? null : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close), onPressed: () => setState(_search.clear)),
                filled: true, fillColor: soft, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              )),
              const SizedBox(height: 16),
              if (matches.isEmpty) const Text('No matching shades. Try pink, red, or peach.'),
              Wrap(spacing: 10, runSpacing: 10, children: matches.map((shade) {
                final active = _selected[_tab] == shade;
                return Semantics(selected: active, button: true, label: shade.name, child: Tooltip(message: shade.name, child: InkWell(
                  onTap: () => setState(() => _selected[_tab] = shade), customBorder: const CircleBorder(),
                  child: Container(width: 48, height: 48, padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: active ? ink : Colors.transparent, width: 2)),
                    child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: shade.color), child: active ? const Icon(Icons.check, color: Colors.white, size: 22) : null)),
                )));
              }).toList()),
              const SizedBox(height: 12),
              Text(_selected[_tab]?.name ?? 'No shade selected', style: const TextStyle(color: ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Text('${_tab == 0 ? 'Lips' : 'Blush'} intensity: ${(_intensity[_tab] * 100).round()}%'),
              Slider(value: _intensity[_tab], divisions: 100, activeColor: pink,
                onChanged: _selected[_tab] == null ? null : (value) => setState(() => _intensity[_tab] = value)),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtle'), Text('Strong')]),
              const SizedBox(height: 20),
              const Text('Approximate try-on only. Colors vary with lighting, skin tone, and your display.', style: TextStyle(color: ink, fontSize: 12)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _selected.any((s) => s != null) ? () => setState(_reset) : null, child: const Text('Clear'))),
                const SizedBox(width: 12),
                const Expanded(child: FilledButton(onPressed: null, child: Text('Save'))),
              ]),
              const SizedBox(height: 8),
              const Text('Save/export is not connected yet.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ])),
        )),
      ]))),
    );
  }
}

class _MakeupPainter extends CustomPainter {
  final ValidatedPhoto photo;
  final Color? lips;
  final Color? blush;
  final double lipIntensity;
  final double blushIntensity;
  _MakeupPainter(this.photo, this.lips, this.blush, this.lipIntensity, this.blushIntensity);

  Path _polygon(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) { path.lineTo(p.dx, p.dy); }
    return path..close();
  }

  // Join two contour edges by their nearest endpoints. This avoids assuming
  // that ML Kit returns both edges in the same direction.
  List<Offset> _join(List<Offset> a, List<Offset> b) {
    if (a.isEmpty || b.isEmpty) return [];
    final edge = (a.last - b.first).distance <= (a.last - b.last).distance ? b : b.reversed.toList();
    return [...a, ...edge];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / photo.size.width, size.height / photo.size.height);
    canvas.save();
    canvas.translate((size.width - photo.size.width * scale) / 2, (size.height - photo.size.height * scale) / 2);
    canvas.scale(scale);
    final contours = photo.contours;
    if (blush != null && blushIntensity > 0) {
      final outline = contours[FaceContourType.face];
      canvas.save();
      if (outline != null && outline.length > 3) canvas.clipPath(_polygon(outline));
      final face = photo.faceBounds;
      // Cheek placement is contour/bounds based, not skin segmentation.
      for (final type in [FaceContourType.leftCheek, FaceContourType.rightCheek]) {
        final cheek = contours[type];
        if (cheek == null || cheek.isEmpty) continue;
        final center = cheek.first;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(1, 0.65);
        final radius = face.width * 0.15;
        final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
        final color = blush!.withValues(alpha: blushIntensity * 0.48);
        final paint = Paint()..shader = RadialGradient(colors: [color, blush!.withValues(alpha: 0)]).createShader(rect);
        canvas.drawCircle(Offset.zero, radius, paint);
        canvas.restore();
      }
      canvas.restore();
    }
    if (lips != null && lipIntensity > 0) {
      final outer = _join(contours[FaceContourType.upperLipTop]!, contours[FaceContourType.lowerLipBottom]!);
      final inner = _join(contours[FaceContourType.upperLipBottom]!, contours[FaceContourType.lowerLipTop]!);
      // Even-odd fill leaves the mouth opening and teeth uncolored.
      final path = Path()..fillType = PathFillType.evenOdd;
      path.addPath(_polygon(outer), Offset.zero);
      path.addPath(_polygon(inner), Offset.zero);
      canvas.drawPath(path, Paint()..isAntiAlias = true..color = lips!.withValues(alpha: lipIntensity * 0.78));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MakeupPainter old) => old.photo != photo || old.lips != lips || old.blush != blush || old.lipIntensity != lipIntensity || old.blushIntensity != blushIntensity;
}
