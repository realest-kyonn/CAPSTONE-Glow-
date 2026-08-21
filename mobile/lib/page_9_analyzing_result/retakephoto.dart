import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Retake Scan Confirmation Pop-up — Page 9 (Pop-up)
// Shows when user taps "Retake Scan" on the Beauty Profile screen
// ─────────────────────────────────────────────────────────────

class RetakeScanDialog extends StatelessWidget {
  const RetakeScanDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(contentWidth * 0.07),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle at top
            Container(
              width: contentWidth * 0.1,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            SizedBox(height: contentWidth * 0.06),

            // Camera icon in pink circle
            Container(
              width: contentWidth * 0.22,
              height: contentWidth * 0.22,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: contentWidth * 0.12,
                color: const Color(0xFFFF6EB4),
              ),
            ),

            SizedBox(height: contentWidth * 0.05),

            // Title
            Text(
              'Retake your scan?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentWidth * 0.055,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: contentWidth * 0.03),

            // Subtitle
            Text(
              'Your current beauty profile and recommendations will be replaced with a new analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentWidth * 0.035,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: contentWidth * 0.05),

            // What you'll lose box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(contentWidth * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHAT YOU\'LL LOSE',
                    style: TextStyle(
                      fontSize: contentWidth * 0.028,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: contentWidth * 0.03),
                  _buildLossItem(
                    'Your current beauty profile',
                    contentWidth,
                  ),
                  SizedBox(height: contentWidth * 0.02),
                  _buildLossItem(
                    'All 3 style recommendations',
                    contentWidth,
                  ),
                  SizedBox(height: contentWidth * 0.02),
                  _buildLossItem(
                    'Tutorial progress for this session',
                    contentWidth,
                  ),
                ],
              ),
            ),

            SizedBox(height: contentWidth * 0.05),

            // Yes, retake my scan button
            SizedBox(
              width: double.infinity,
              height: contentWidth * 0.13,
              child: OutlinedButton(
                onPressed: () {
                  // Close dialog and pop all screens back to camera
                  Navigator.pop(context, true);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFFF6EB4),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Yes, retake my scan',
                  style: TextStyle(
                    fontSize: contentWidth * 0.04,
                    color: const Color(0xFFFF6EB4),
                  ),
                ),
              ),
            ),

            SizedBox(height: contentWidth * 0.03),

            // Cancel button
            TextButton(
              onPressed: () {
                // Just close the dialog — stay on Page 9
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancel',
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

  // Red X item for what you'll lose list
  Widget _buildLossItem(String text, double contentWidth) {
    return Row(
      children: [
        Icon(
          Icons.cancel_rounded,
          color: Colors.red.shade300,
          size: contentWidth * 0.05,
        ),
        SizedBox(width: contentWidth * 0.03),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: contentWidth * 0.035,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}