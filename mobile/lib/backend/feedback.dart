import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens Glow's feedback form in the device's browser.
/// Returns false if it couldn't be launched (no browser found, offline,
/// or the launch itself failed) so callers can show an error instead of
/// failing silently.
Future<bool> openFeedbackForm() async {
  final uri = Uri.parse(
    'https://docs.google.com/forms/d/e/1FAIpQLSds1RhMyPzYiSsRIs5AbOQBkWGwpxXOrRSIJpRj95qW8KwRRw/viewform',
  );
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Tracks whether the user has already seen the post-save feedback popup —
/// it should only ever appear once; after that, feedback is reachable from
/// Settings instead.
class FeedbackPrefs {
  static const _hasSeenPromptKey = 'has_seen_feedback_prompt';

  static Future<bool> hasSeenPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenPromptKey) ?? false;
  }

  static Future<void> markPromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenPromptKey, true);
  }
}
