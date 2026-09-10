import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LipsAndShadeFilter extends StatefulWidget {
  const LipsAndShadeFilter({super.key});

  @override
  State<LipsAndShadeFilter> createState() => _LipsAndShadeFilterState();
}

class _LipsAndShadeFilterState extends State<LipsAndShadeFilter> {
  static const _pink = Color(0xFFFF65B5);
  static const _softPink = Color(0xFFFFEFF7);
  static const _borderPink = Color(0xFFF1BDD5);
  static const _darkPink = Color(0xFFAC275F);

  final _picker = ImagePicker();

  Uint8List? _photo;
  bool _loading = false;
  int _activeTab = 0;

  // Each category remembers its own selection and intensity.
  final List<int?> _selectedShades = [null, null];
  final List<double> _intensities = [0.5, 0.5];

  static const List<List<_MakeupShade>> _palettes = [
    [
      _MakeupShade('Deep Rose', Color(0xFF963440)),
      _MakeupShade('Cherry', Color(0xFFCF3659)),
      _MakeupShade('Petal Pink', Color(0xFFF36289)),
      _MakeupShade('Terracotta', Color(0xFFBD6155)),
      _MakeupShade('Rosy Nude', Color(0xFFD99196)),
    ],
    [
      _MakeupShade('Soft Rose', Color(0xFFE58CA0)),
      _MakeupShade('Peach', Color(0xFFF2A080)),
      _MakeupShade('Coral', Color(0xFFEF7D83)),
      _MakeupShade('Berry', Color(0xFFB95178)),
      _MakeupShade('Dusty Pink', Color(0xFFC78096)),
    ],
  ];

  Future<void> _pickPhoto() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      // Canceling the picker keeps the current photo and settings.
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _photo = bytes;
        _resetControls();
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open that photo. Please try another image.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _resetControls() {
    _selectedShades[0] = null;
    _selectedShades[1] = null;
    _intensities[0] = 0.5;
    _intensities[1] = 0.5;
  }

  void _clear() {
    setState(_resetControls);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo != null;
    final palette = _palettes[_activeTab];
    final selectedIndex = _selectedShades[_activeTab];
    final category = _activeTab == 0 ? 'Lips' : 'Blush';
    final hasSelection = _selectedShades.any((shade) => shade != null);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header styled after your existing GLOW screens.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: const BoxDecoration(
                  color: _pink,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: const SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shade Check',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try lip and blush shades on your photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 528),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Uploaded image / empty state.
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: _softPink,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _borderPink),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: hasPhoto
                                ? Image.memory(
                                    _photo!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, error, stackTrace) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Text(
                                            'This photo cannot be displayed. '
                                            'Try a JPG or PNG image.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: _pink,
                                        size: 54,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Add a photo of your face',
                                        style: TextStyle(
                                          color: _darkPink,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Choose an image from your gallery',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        FilledButton.icon(
                          onPressed: _loading ? null : _pickPhoto,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.photo_library_outlined,
                                ),
                          label: Text(
                            _loading
                                ? 'Opening photo…'
                                : hasPhoto
                                    ? 'Change photo'
                                    : 'Add image',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _pink,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'A front-facing photo with even lighting works best.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _darkPink,
                            fontSize: 12,
                          ),
                        ),

                        if (hasPhoto) ...[
                          const SizedBox(height: 28),

                          // Lips / Blush tabs.
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _softPink,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: List.generate(2, (index) {
                                final active = _activeTab == index;

                                return Expanded(
                                  child: Semantics(
                                    selected: active,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() => _activeTab = index);
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            active ? _pink : Colors.transparent,
                                        foregroundColor:
                                            active ? Colors.white : _darkPink,
                                        minimumSize: const Size(0, 48),
                                      ),
                                      child: Text(
                                        index == 0 ? 'Lips' : 'Blush',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Choose your shade',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(palette.length, (index) {
                              final shade = palette[index];
                              final selected = selectedIndex == index;

                              return Semantics(
                                button: true,
                                selected: selected,
                                label: '$category, ${shade.name}',
                                child: Tooltip(
                                  message: shade.name,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setState(() {
                                        _selectedShades[_activeTab] = index;
                                      });
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected
                                              ? _darkPink
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: shade.color,
                                          shape: BoxShape.circle,
                                        ),
                                        child: selected
                                            ? const Icon(
                                                Icons.check,
                                                size: 22,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selectedIndex == null
                                ? 'No ${category.toLowerCase()} shade selected'
                                : '${palette[selectedIndex].name} · $category',
                            style: const TextStyle(
                              color: _darkPink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$category intensity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(_intensities[_activeTab] * 100).round()}%',
                                style: const TextStyle(color: _darkPink),
                              ),
                            ],
                          ),
                          Slider(
                            value: _intensities[_activeTab],
                            activeColor: _pink,
                            inactiveColor: _softPink,
                            divisions: 100,
                            label:
                                '${(_intensities[_activeTab] * 100).round()}%',
                            onChanged: selectedIndex == null
                                ? null
                                : (value) {
                                    setState(() {
                                      _intensities[_activeTab] = value;
                                    });
                                  },
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtle'),
                              Text('Strong'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _softPink,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'UI preview only: shade and intensity controls '
                              'are ready, but makeup is not applied to your '
                              'photo yet.',
                              style: TextStyle(
                                color: _darkPink,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: hasSelection ? _clear : null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _darkPink,
                                    minimumSize: const Size(0, 48),
                                    side: const BorderSide(color: _borderPink),
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  // Enabled once rendering/export is ready.
                                  onPressed: null,
                                  icon: const Icon(
                                    Icons.download_outlined,
                                  ),
                                  label: const Text('Save'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Saving will be available after makeup rendering '
                            'is added.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MakeupShade {
  final String name;
  final Color color;

  const _MakeupShade(this.name, this.color);
}