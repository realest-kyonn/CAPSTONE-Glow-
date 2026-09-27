import 'package:flutter/material.dart';
import '../backend/feedback.dart';

// ─────────────────────────────────────────────────────────────
// Feedback Popup — shown once, after the first successful save
// ─────────────────────────────────────────────────────────────

class FeedbackPopup extends StatefulWidget {
  const FeedbackPopup({super.key});

  @override
  State<FeedbackPopup> createState() => _FeedbackPopupState();
}

class _FeedbackPopupState extends State<FeedbackPopup> {
  bool _launchFailed = false;

  Future<void> _onGiveFeedbackPressed() async {
    final opened = await openFeedbackForm();
    if (!mounted) return;
    if (opened) {
      Navigator.pop(context);
    } else {
      setState(() => _launchFailed = true);
    }
  }

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
                Icons.chat_bubble_rounded,
                size: contentWidth * 0.1,
                color: const Color(0xFFFF6EB4),
              ),
            ),

            SizedBox(height: contentWidth * 0.05),

            Text(
              'Enjoying Glow?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: contentWidth * 0.03),

            Text(
              'Your look has been saved! We\'d love to hear your thoughts — '
              'tap below to answer a few quick questions about your '
              'experience with Glow. It only takes a minute and helps us '
              'improve future updates.\n\n'
              'Please turn on your internet to be able to give feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentWidth * 0.036,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: contentWidth * 0.06),

            if (_launchFailed) ...[
              Text(
                "Couldn't open the feedback form. Check your connection "
                'and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: contentWidth * 0.032,
                  color: Colors.red.shade400,
                ),
              ),
              SizedBox(height: contentWidth * 0.03),
            ],

            SizedBox(
              width: double.infinity,
              height: contentWidth * 0.13,
              child: ElevatedButton.icon(
                onPressed: _onGiveFeedbackPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6EB4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  'Give Feedback',
                  style: TextStyle(
                    fontSize: contentWidth * 0.042,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: contentWidth * 0.02),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe later',
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