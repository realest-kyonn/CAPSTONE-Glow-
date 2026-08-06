import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// Feedback Popup — shown after a successful save
// ─────────────────────────────────────────────────────────────

class FeedbackPopup extends StatelessWidget {
  const FeedbackPopup({super.key});

  // ← the function goes right here, as a method of this class
  Future<void> _openFeedbackForm() async {
    final uri = Uri.parse('YOUR_GOOGLE_FORM_URL_HERE');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ← this is where you build the Dialog UI,
    //   copying the shape of SaveLookDialog's build() method
  }
}