import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Save Look Confirmation Pop-up — Page 14
// Shown when user taps "Save Tutorial" on the Makeup Tutorial screen,
// before the name-entry step.
// ─────────────────────────────────────────────────────────────

class SaveLookDialog extends StatelessWidget {
  final String styleName;

  const SaveLookDialog({super.key, required this.styleName});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(contentWidth * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: contentWidth * 0.22,
              height: contentWidth * 0.22,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: contentWidth * 0.1,
                color: const Color(0xFFFF6EB4),
              ),
            ),

            SizedBox(height: contentWidth * 0.05),

            Text(
              'Save this look?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: contentWidth * 0.03),

            Text(
              '$styleName will be saved to your favorites so you can revisit it anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentWidth * 0.036,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: contentWidth * 0.06),

            // Save to Favorites button
            SizedBox(
              width: double.infinity,
              height: contentWidth * 0.13,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6EB4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  'Save to Favorites',
                  style: TextStyle(
                    fontSize: contentWidth * 0.042,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: contentWidth * 0.02),

            // Not now — close without saving
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Not now',
                style: TextStyle(
                  fontSize: contentWidth * 0.038,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
