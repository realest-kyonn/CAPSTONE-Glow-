import 'package:flutter/material.dart';
import '../page_14_favorites/favorites.dart';
import '../page_14_favorites/save_confirmation_dialog.dart';
import '../page_14_favorites/save_name_dialog.dart';
import '../page_14_favorites/feedback_popup.dart';

// ─────────────────────────────────────────────────────────────
// Makeup Tutorial + What To Use Screen — Page 11 & 12
//
// BACKEND TEAM — HOW TO CONNECT:
// This screen receives a style Map from Page 10
// (RecommendationResultScreen) when user taps "Start Tutorial".
//
// Expected keys in `styleData` Map:
//   'name'          → String  e.g. 'Clean Girl Makeup'
//   'subtitle'      → String  e.g. 'Effortless, skin-first glow'
//   'styleIndex'    → String  e.g. '1' (which of the 3 styles this is)
//   'totalStyles'   → String  e.g. '3' (always 3)
//   'quote'         → String  italic quote shown at top of tutorial tab
//   'steps'         → List<Map<String, String>> — tutorial steps
//       Each step Map:
//         'instruction' → String  e.g. 'Prep skin with a hydrating serum...'
//         'tip'         → String  e.g. 'Skin prep is the most important step...'
//         'imagePath'   → String  asset path e.g. 'assets/steps/clean_girl_step1.jpg'
//   'products'      → List<Map<String, String>> — what to use list
//       Each product Map:
//         'category'    → String  e.g. 'BASE'
//         'categoryIcon'→ String  icon name (see _categoryIcon method)
//         'name'        → String  e.g. 'Skin Tint / BB Cream'
//         'shade'       → String  e.g. 'Golden Tint'
//                                 (BACKEND: matched to user's detected skin tone)
//
// IMPORTANT: The product shades in the "What to Use" tab are
// dynamically matched to the user's detected skin tone from Page 9.
// BACKEND: Pass the correct shade per product based on monkScale/undertone.
// ─────────────────────────────────────────────────────────────

class MakeupTutorialScreen extends StatefulWidget {
  // Style data passed from Page 10
  final Map<String, dynamic> styleData;

  const MakeupTutorialScreen({super.key, required this.styleData});

  @override
  State<MakeupTutorialScreen> createState() => _MakeupTutorialScreenState();
}

class _MakeupTutorialScreenState extends State<MakeupTutorialScreen>
    with SingleTickerProviderStateMixin {
  // Tab controller for Tutorial / What to Use switcher
  late TabController _tabController;

  // ── DUMMY DATA — Replace with real backend data ──

  // BACKEND: 'quote' from recommendations.json per style
  String get _quote =>
      widget.styleData['quote'] ??
      '"Effortless, skin-first glow — look like the best, '
          'most polished version of your bare face."';

  // BACKEND: 'styleIndex' from style_scorer.py (which rank 1/2/3)
  String get _styleIndex => widget.styleData['styleIndex'] ?? '1';

  // BACKEND: 'totalStyles' always 3
  String get _totalStyles => widget.styleData['totalStyles'] ?? '3';

  // General tips for the whole style (from recommendations.json's
  // 'tips' + 'general_tip') — shown as one block above the steps,
  // since the real data has 3-4 general tips rather than one per step.
  List<String> get _tips =>
      (widget.styleData['tips'] as List?)?.cast<String>() ?? const [];

  // Fields needed to save this result — only present when this screen
  // was reached via real per-style data (see recommendation_result.dart).
  // Null styleKey means there's nothing to reconstruct later, so saving
  // is disabled rather than saving something that can't be revisited.
  String? get _styleKey => widget.styleData['styleKey'] as String?;
  String get _saveUndertone =>
      widget.styleData['undertone'] as String? ?? 'neutral';
  int get _saveMonkScale =>
      int.tryParse('${widget.styleData['monkScale']}') ?? 5;
  String? get _matchPct => widget.styleData['matchPct'] as String?;
  String get _saveSkinTone => widget.styleData['skinTone'] as String? ?? '';
  String get _saveFaceShape => widget.styleData['faceShape'] as String? ?? '';
  String get _saveEyeShape => widget.styleData['eyeShape'] as String? ?? '';

  Future<void> _onSaveTutorial() async {
    final styleKey = _styleKey;
    if (styleKey == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => SaveLookDialog(
        styleName: widget.styleData['name'] as String? ?? 'This look',
      ),
    );
    if (confirmed != true || !mounted) return;

    final existing = await SavedResultsStore.getAll();
    if (!mounted) return;

    final name = await showDialog<String>(
      context: context,
      builder: (context) => SaveNameDialog(
        existingNames: existing.map((r) => r.savedName).toList(),
      ),
    );
    if (name == null || !mounted) return;

    // Guard the save so a database error shows a message instead of
    // crashing. The name dialog already blocks duplicates, so this is a
    // backstop for the constraint and for any unexpected storage failure.
    try {
      await SavedResultsStore.add(SavedResult(
        savedName: name,
        savedAt: DateTime.now(),
        skinTone: _saveSkinTone,
        faceShape: _saveFaceShape,
        eyeShape: _saveEyeShape,
        undertone: _saveUndertone,
        monkScale: _saveMonkScale,
        styleKey: styleKey,
        styleName: widget.styleData['name'] as String? ?? '',
        styleIndex: int.tryParse(_styleIndex) ?? 1,
        matchPct: _matchPct,
      ));
    } on DuplicateNameException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already have a saved look with that name.')),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save your look. Please try again.")),
      );
      return;
    }

    // Feedback popup — shown right after a successful save, before
    // navigating away to Favorites.
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => const FeedbackPopup(),
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesScreen(cameFromSave: true),
      ),
    );
  }

  // BACKEND: 'steps' from recommendations.json
  // Each step has instruction, tip, and imagePath
  List<Map<String, String>> get _steps =>
      (widget.styleData['steps'] as List<Map<String, String>>?) ??
      [
        {
          'instruction':
              'Prep skin with a hydrating serum and moisturizer — the base is everything in this look.',
          'tip':
              'Skin prep is the most important step — exfoliate the night before for best results.',
          'imagePath': '', // BACKEND: 'assets/steps/step1.jpg'
        },
        {
          'instruction':
              'Apply a light-coverage tinted moisturizer or skin tint with your fingers, blending outward.',
          'tip':
              'Choose cream or liquid products over powders to maintain that signature dewiness.',
          'imagePath': '', // BACKEND: 'assets/steps/step2.jpg'
        },
        {
          'instruction':
              'Spot-conceal only where needed (under eyes, blemishes) — avoid heavy coverage.',
          'tip': 'Less is more — build coverage only where you truly need it.',
          'imagePath': '', // BACKEND: 'assets/steps/step3.jpg'
        },
        {
          'instruction':
              'Dust a small amount of translucent powder on the T-zone to set without mattifying.',
          'tip': 'Only set where you get oily — let the rest stay dewy.',
          'imagePath': '', // BACKEND: 'assets/steps/step4.jpg'
        },
        {
          'instruction':
              'Brush a soft warm coral blush high on the cheekbones and lightly on the nose bridge.',
          'tip': 'Tap off excess before applying — a light hand gives the most natural flush.',
          'imagePath': '', // BACKEND: 'assets/steps/step5.jpg'
        },
        {
          'instruction':
              'Apply a warm brown tinted brow gel, brushing hairs upward for a fluffy, laminated look.',
          'tip': 'Use short upward strokes to mimic natural brow hairs.',
          'imagePath': '', // BACKEND: 'assets/steps/step6.jpg'
        },
        {
          'instruction':
              'Curl lashes and apply one coat of brown-black mascara.',
          'tip': 'Wiggle the wand at the root for maximum lift.',
          'imagePath': '', // BACKEND: 'assets/steps/step7.jpg'
        },
        {
          'instruction':
              'Dab a warm coral lip oil on lips for a juicy, hydrated pout.',
          'tip': 'Layer over a nude lip liner for longer-lasting color.',
          'imagePath': '', // BACKEND: 'assets/steps/step8.jpg'
        },
        {
          'instruction':
              'Mist face lightly with a setting spray for a dewy, fresh finish.',
          'tip': 'Hold spray 30cm away and use a cross pattern for even coverage.',
          'imagePath': '', // BACKEND: 'assets/steps/step9.jpg'
        },
      ];

  // BACKEND: 'products' from recommendations.json
  // Shades are matched to user's detected skin tone (monkScale + undertone)
  List<Map<String, String>> get _products =>
      (widget.styleData['products'] as List<Map<String, String>>?) ??
      [
        // BASE category
        {
          'category': 'BASE',
          'categoryIcon': 'base',
          'name': 'Skin Tint / BB Cream',
          'shade': 'Golden Tint', // BACKEND: matched to monkScale
        },
        {
          'category': 'BASE',
          'categoryIcon': 'base',
          'name': 'Concealer',
          'shade': 'Golden Nude', // BACKEND: matched to monkScale
        },
        {
          'category': 'BASE',
          'categoryIcon': 'base',
          'name': 'Setting Powder',
          'shade': 'Golden Beige', // BACKEND: matched to monkScale
        },
        // CHEEKS category
        {
          'category': 'CHEEKS',
          'categoryIcon': 'cheeks',
          'name': 'Blush (Warm/Peach)',
          'shade': 'Warm Coral', // BACKEND: matched to undertone
        },
        // BROWS AND EYES category
        {
          'category': 'BROWS AND EYES',
          'categoryIcon': 'eyes',
          'name': 'Brow Gel',
          'shade': 'Warm Brown Tinted', // BACKEND: matched to undertone
        },
        {
          'category': 'BROWS AND EYES',
          'categoryIcon': 'eyes',
          'name': 'Mascara',
          'shade': 'Black Brown', // BACKEND: matched to undertone
        },
        // LIPS category
        {
          'category': 'LIPS',
          'categoryIcon': 'lips',
          'name': 'Lip Oil',
          'shade': 'Warm Coral Oil', // BACKEND: matched to undertone
        },
        // FINISH category
        {
          'category': 'FINISH',
          'categoryIcon': 'finish',
          'name': 'Setting Spray',
          'shade': 'Natural Finish', // BACKEND: standard for all skin tones
        },
      ];

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F6),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                // Pink header with back button + style name + tabs
                _buildHeader(context, contentWidth, screenHeight),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Tutorial steps
                      _buildTutorialTab(contentWidth, screenHeight),

                      // Tab 2: What to use (products + shades)
                      _buildWhatToUseTab(contentWidth, screenHeight),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pink header with back button, style name, and tab switcher
  Widget _buildHeader(
      BuildContext context, double contentWidth, double screenHeight) {
    return Container(
      color: const Color(0xFFFF6EB4),
      child: Column(
        children: [
          // Back button + style index
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.015,
              left: contentWidth * 0.04,
              right: contentWidth * 0.04,
            ),
            child: Row(
              children: [
                // Back button
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  radius: contentWidth * 0.045,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    iconSize: contentWidth * 0.05,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.005),

          // Style index e.g. "STYLE 1 OF 3"
          Text(
            'STYLE $_styleIndex OF $_totalStyles',
            style: TextStyle(
              fontSize: contentWidth * 0.03,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1.5,
            ),
          ),

          SizedBox(height: screenHeight * 0.005),

          // Style name
          // BACKEND: 'name' from recommendations.json
          Text(
            widget.styleData['name'] ?? 'Clean Girl Makeup',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: contentWidth * 0.085,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          SizedBox(height: screenHeight * 0.015),

          // Tab switcher — Tutorial | What to use
          Padding(
            padding: EdgeInsets.symmetric(horizontal: contentWidth * 0.06),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFFFF6EB4),
                unselectedLabelColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: contentWidth * 0.038,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: contentWidth * 0.038,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Tutorial'),
                  Tab(text: 'What to use'),
                ],
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.015),
        ],
      ),
    );
  }

  // Tab 1: Tutorial steps
  Widget _buildTutorialTab(double contentWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(contentWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Italic quote
          // BACKEND: 'quote' from recommendations.json
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(contentWidth * 0.04),
            child: Text(
              _quote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentWidth * 0.036,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.01),

          // General tips block — from recommendations.json's 'tips' +
          // 'general_tip'. Only shown when real tip data was passed in.
          if (_tips.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(contentWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIPS',
                    style: TextStyle(
                      fontSize: contentWidth * 0.038,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6EB4),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  ..._tips.map((tip) => Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.008),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tips_and_updates_rounded,
                              color: const Color(0xFFFF6EB4),
                              size: contentWidth * 0.045,
                            ),
                            SizedBox(width: contentWidth * 0.02),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: contentWidth * 0.034,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
          ],

          // STEPS label
          Text(
            'STEPS',
            style: TextStyle(
              fontSize: contentWidth * 0.038,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF6EB4),
              letterSpacing: 1.5,
            ),
          ),

          SizedBox(height: screenHeight * 0.015),

          // Step cards
          // BACKEND: Steps come from recommendations.json per style
          ..._steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.02),
              child: _buildStepCard(
                stepNumber: index + 1,
                step: step,
                contentWidth: contentWidth,
                screenHeight: screenHeight,
              ),
            );
          }),

          SizedBox(height: screenHeight * 0.01),

          // Save Tutorial button — disabled when there's no styleKey
          // to reconstruct this result from later.
          SizedBox(
            width: double.infinity,
            height: contentWidth * 0.13,
            child: ElevatedButton.icon(
              onPressed: _styleKey == null ? null : _onSaveTutorial,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6EB4),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.favorite_border_rounded,
                  color: Colors.white, size: 18),
              label: Text(
                'Save Tutorial',
                style: TextStyle(
                  fontSize: contentWidth * 0.045,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  // Individual step card
  Widget _buildStepCard({
    required int stepNumber,
    required Map<String, String> step,
    required double contentWidth,
    required double screenHeight,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number + instruction
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number circle
              Container(
                width: contentWidth * 0.07,
                height: contentWidth * 0.07,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6EB4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: contentWidth * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: contentWidth * 0.03),
              // BACKEND: 'instruction' from recommendations.json
              Expanded(
                child: Text(
                  step['instruction']!,
                  style: TextStyle(
                    fontSize: contentWidth * 0.036,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.015),

          // Step image
          // BACKEND: 'imagePath' from recommendations.json
          // Add step images to assets/steps/ folder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: step['imagePath'] != null &&
                    step['imagePath']!.isNotEmpty
                ? Image.asset(
                    step['imagePath']!,
                    width: double.infinity,
                    height: contentWidth * 0.6,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildStepImagePlaceholder(contentWidth),
                  )
                : _buildStepImagePlaceholder(contentWidth),
          ),

          // Tip — only real dummy-fallback steps carry a per-step tip;
          // real per-style steps use the TIPS block above instead.
          if (step['tip'] != null && step['tip']!.isNotEmpty) ...[
            SizedBox(height: screenHeight * 0.012),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: const Color(0xFFFF6EB4),
                  size: contentWidth * 0.045,
                ),
                SizedBox(width: contentWidth * 0.02),
                Expanded(
                  child: Text(
                    step['tip']!,
                    style: TextStyle(
                      fontSize: contentWidth * 0.032,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Placeholder for step image
  Widget _buildStepImagePlaceholder(double contentWidth) {
    return Container(
      width: double.infinity,
      height: contentWidth * 0.6,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.face_rounded,
            size: contentWidth * 0.15,
            color: const Color(0xFFFFB6D9),
          ),
          SizedBox(height: contentWidth * 0.02),
          Text(
            'Step image coming soon',
            style: TextStyle(
              fontSize: contentWidth * 0.03,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Tab 2: What to use (products + shades)
  Widget _buildWhatToUseTab(double contentWidth, double screenHeight) {
    // Group products by category
    final Map<String, List<Map<String, String>>> grouped = {};
    for (final product in _products) {
      final category = product['category']!;
      grouped.putIfAbsent(category, () => []).add(product);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(contentWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          // BACKEND: skin tone match comes from monkScale + undertone
          Text(
            'Suggested shades to your detected skintone',
            style: TextStyle(
              fontSize: contentWidth * 0.034,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          // Product categories
          // BACKEND: products + shades from recommendations.json
          // matched to user's monkScale and undertone
          ...grouped.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.02),
              child: _buildCategorySection(
                category: entry.key,
                products: entry.value,
                contentWidth: contentWidth,
                screenHeight: screenHeight,
              ),
            );
          }),

          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  // Category section (BASE, CHEEKS, etc.)
  Widget _buildCategorySection({
    required String category,
    required List<Map<String, String>> products,
    required double contentWidth,
    required double screenHeight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with icon
        Row(
          children: [
            // Category icon
            Container(
              width: contentWidth * 0.08,
              height: contentWidth * 0.08,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _categoryIcon(category),
                color: const Color(0xFFFF6EB4),
                size: contentWidth * 0.045,
              ),
            ),
            SizedBox(width: contentWidth * 0.03),
            Text(
              category,
              style: TextStyle(
                fontSize: contentWidth * 0.042,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        SizedBox(height: screenHeight * 0.01),

        // Product rows
        ...products.map((product) => _buildProductRow(
              product: product,
              contentWidth: contentWidth,
              screenHeight: screenHeight,
            )),
      ],
    );
  }

  // Individual product row
  Widget _buildProductRow({
    required Map<String, String> product,
    required double contentWidth,
    required double screenHeight,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.008),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: contentWidth * 0.04,
          vertical: screenHeight * 0.012,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // BACKEND: product name from recommendations.json
            Text(
              product['name']!,
              style: TextStyle(
                fontSize: contentWidth * 0.036,
                color: Colors.black87,
              ),
            ),
            // BACKEND: shade matched to user's monkScale + undertone
            Text(
              product['shade']!,
              style: TextStyle(
                fontSize: contentWidth * 0.034,
                color: const Color(0xFFFF6EB4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Returns icon for each product category
  IconData _categoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'BASE':
        return Icons.water_drop_rounded;
      case 'CHEEKS':
        return Icons.favorite_rounded;
      case 'BROWS AND EYES':
        return Icons.remove_red_eye_rounded;
      case 'LIPS':
        return Icons.face_rounded;
      case 'FINISH':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.brush_rounded;
    }
  }
}