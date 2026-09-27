import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Browser builds load placeholders.
// Android builds load your actual app screens.
import 'page4_routes_web.dart'
    if (dart.library.io) 'page4_routes_native.dart' as routes;

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  static const _pink = Color(0xFFFF6EB4);
  static const _lightPink = Color(0xFFFFF0F6);

  static const List<Map<String, String>> _styles = [
    {'name': 'Clean Girl Makeup', 'desc': 'Effortless, skin-first glow'},
    {'name': 'No-Makeup Makeup', 'desc': 'Invisible enhancement'},
    {'name': 'Fresh Dewy Makeup', 'desc': 'Glass skin, lit-from-within radiance'},
    {'name': 'Soft Glam Everyday', 'desc': 'Polished, wearable glam'},
    {'name': 'Korean Daily Makeup', 'desc': 'Youthful, dewy, and cute'},
    {'name': 'Peach Makeup', 'desc': 'Warm, sun-kissed, peachy-sweet'},
    {'name': 'Soft Contour Makeup', 'desc': 'Subtle reshaping, natural finish'},
    {'name': 'Lifted Makeup', 'desc': 'Visually lift and elongate eyes'},
    {'name': 'Snatched Everyday', 'desc': 'Defined, sculpted, sharp'},
    {'name': 'Igari-Inspired', 'desc': 'Japanese hangover blush'},
    {'name': 'Douyin Natural', 'desc': 'Porcelain skin meets soft detail'},
    {'name': 'Strawberry Makeup', 'desc': 'Red-toned, rosy, sweetly flushed'},
    {'name': 'Office Makeup', 'desc': 'Professional and polished'},
    {'name': 'Neutral Glam', 'desc': 'Understated timeless glamour'},
    {'name': 'Corporate Clean', 'desc': 'Minimalist, refined, powerful'},
  ];

  static const List<Map<String, Object>> _steps = [
    {
      'icon': Icons.face_retouching_natural,
      'title': 'Scan your face',
      'desc': 'One clear photo, good lighting',
    },
    {
      'icon': Icons.auto_awesome,
      'title': 'AI Analysis',
      'desc': 'We analyze your facial features.',
    },
    {
      'icon': Icons.brush_rounded,
      'title': 'Get Recommendations',
      'desc': 'Receive makeup styles tailored to you.',
    },
  ];

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(context, contentWidth),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(contentWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.025),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.05,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HomeFeatureCarousel(),
                        SizedBox(height: screenHeight * 0.02),
                        _sectionTitle('How It Works', contentWidth),
                        SizedBox(height: screenHeight * 0.015),
                        _buildHowItWorks(context, contentWidth),
                        SizedBox(height: screenHeight * 0.03),
                        _sectionTitle(
                          'Styles We Match You To',
                          contentWidth,
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          'Every recommendation pulls from these looks',
                          style: TextStyle(
                            fontSize: contentWidth * 0.035,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildStylesGrid(context, contentWidth),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.06,
        fontWeight: FontWeight.bold,
        color: _pink,
      ),
    );
  }

  Widget _buildHeader(double width, double height) {
    return Container(
      width: double.infinity,
      color: _pink,
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.06,
        vertical: height * 0.03,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, beautiful!',
            style: TextStyle(
              fontSize: width * 0.1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            'A free face scan, matched to your tone and features.',
            style: TextStyle(
              fontSize: width * 0.038,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context, double width) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final extraHeight = scale > 1 ? (scale - 1) * 140 : 0.0;

    return SizedBox(
      height: width * 0.5 + extraHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          final step = _steps[index];

          return Row(
            children: [
              Container(
                width: width * 0.4,
                padding: EdgeInsets.all(width * 0.035),
                decoration: BoxDecoration(
                  color: _lightPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      step['icon'] as IconData,
                      size: width * 0.11,
                      color: _pink,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.036,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['desc'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.028,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < _steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    color: _pink,
                    size: width * 0.05,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStylesGrid(BuildContext context, double width) {
    final itemWidth = (width - width * 0.1 - 16) / 3;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final extraHeight = scale > 1 ? (scale - 1) * 90 : 0.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        mainAxisExtent: itemWidth / 0.75 + extraHeight,
      ),
      itemCount: _styles.length,
      itemBuilder: (context, index) {
        final style = _styles[index];

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _lightPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(color: _pink),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style['name']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: itemWidth * 0.17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style['desc']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: itemWidth * 0.13,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, double width) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: width * 0.05,
          right: width * 0.05,
          bottom: 12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BottomNavigationBar(
            currentIndex: 0,
            backgroundColor: _pink,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            iconSize: width * 0.065,
            selectedFontSize: 0,
            unselectedFontSize: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_rounded),
                label: 'Analysis',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.help_outline_rounded),
                label: 'About',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 1:
                  _open(context, routes.favoritesScreen());
                  break;
                case 2:
                  _open(context, routes.analysisScreen());
                  break;
                case 3:
                  _open(context, routes.aboutScreen());
                  break;
                case 4:
                  _open(context, routes.settingsScreen());
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}

class _HomeFeatureCarousel extends StatefulWidget {
  const _HomeFeatureCarousel();

  @override
  State<_HomeFeatureCarousel> createState() =>
      _HomeFeatureCarouselState();
}

class _HomeFeatureCarouselState extends State<_HomeFeatureCarousel> {
  static const _pink = Color(0xFFFF6EB4);

  static const _titles = [
    "Unlock your face's full potential",
    "What's your skin type?",
    'Find your favorite lip & blush shades',
  ];

  static const _buttons = [
    'Begin Analysis',
    'Try this test',
    'Try on shades',
  ];

  static const _descriptions = [
    'Your photo is never shared',
    'A quick one-question skin type check',
    'Preview colors and adjust their intensity',
  ];

  static const _icons = [
    Icons.face_retouching_natural,
    Icons.spa_rounded,
    Icons.brush_rounded,
  ];

  final PageController _controller = PageController(
    viewportFraction: 0.90,
  );

  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFeature(int index) {
    final Widget screen;

    switch (index) {
      case 0:
        screen = routes.analysisScreen();
        break;
      case 1:
        screen = routes.skinQuizScreen();
        break;
      default:
        screen = routes.shadeScreen();
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final extraHeight = scale > 1 ? (scale - 1) * 180 : 0.0;

    return Column(
      children: [
        SizedBox(
          height: 310 + extraHeight,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
                PointerDeviceKind.invertedStylus,
              },
            ),
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: _titles.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) => _buildCard(index),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_titles.length, (index) {
            final selected = _currentPage == index;

            return Semantics(
              button: true,
              selected: selected,
              label: 'Show ${_buttons[index]}, ${index + 1} of 3',
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                  );
                },
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: selected
                            ? _pink
                            : const Color(0xFFF3CCDF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCard(int index) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 12,
        top: 6,
        bottom: 8,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIcon(index),
                        const SizedBox(height: 14),
                        Text(
                          _titles[index],
                          style: const TextStyle(
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: _pink,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () => _openFeature(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _buttons[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _descriptions[index],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(int index) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _icons[index],
            size: 40,
            color: const Color(0xFFFFB6D9),
          ),
          if (index == 0) ...[
            Positioned(
              top: 7,
              left: 7,
              child: _cornerBracket(topLeft: true),
            ),
            Positioned(
              top: 7,
              right: 7,
              child: _cornerBracket(topLeft: false),
            ),
            Positioned(
              bottom: 7,
              left: 7,
              child: _cornerBracket(topLeft: true, flip: true),
            ),
            Positioned(
              bottom: 7,
              right: 7,
              child: _cornerBracket(topLeft: false, flip: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cornerBracket({
    required bool topLeft,
    bool flip = false,
  }) {
    return Transform.scale(
      scaleX: topLeft ? 1 : -1,
      scaleY: flip ? -1 : 1,
      child: Container(
        width: 11,
        height: 11,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF4CAF50), width: 2),
            left: BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
        ),
      ),
    );
  }
}