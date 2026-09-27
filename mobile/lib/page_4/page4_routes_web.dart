import 'package:flutter/material.dart';

Widget analysisScreen() => const _BrowserPreviewScreen(
      title: 'Begin Analysis',
      icon: Icons.face_retouching_natural,
    );

Widget skinQuizScreen() => const _BrowserPreviewScreen(
      title: 'Skin Type Test',
      icon: Icons.spa_rounded,
    );

Widget shadeScreen() => const _BrowserPreviewScreen(
      title: 'Try on shades',
      icon: Icons.brush_rounded,
    );

Widget favoritesScreen() => const _BrowserPreviewScreen(
      title: 'Saved Results',
      icon: Icons.favorite_rounded,
    );

Widget aboutScreen() => const _BrowserPreviewScreen(
      title: 'About GLOW',
      icon: Icons.help_outline_rounded,
    );

Widget settingsScreen() => const _BrowserPreviewScreen(
      title: 'Settings',
      icon: Icons.settings_rounded,
    );

class _BrowserPreviewScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _BrowserPreviewScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFFF6EB4),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: const Color(0xFFFF6EB4),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Browser preview only',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The home-screen button for "$title" works.\n\n'
                  'This preview intentionally does not load the real '
                  'destination screen or native processing code.\n\n'
                  'Run the Android app to test the actual feature.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6EB4),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}