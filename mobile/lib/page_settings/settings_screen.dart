import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../page_14_favorites/favorites.dart';

// ─────────────────────────────────────────────────────────────
// Settings Screen
// Reached from the gear icon in the Home Dashboard's bottom nav.
//   - Permissions: reflects the OS-level camera permission and lets
//     the user grant it (or jump to system settings to revoke it —
//     apps cannot revoke their own permissions programmatically).
//   - Data Management: wipes every saved look from the local database.
// ─────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when the app resumes — covers the case where the user
  // granted/revoked camera access from system Settings and came back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCameraPermission();
    }
  }

  Future<void> _refreshCameraPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    setState(() => _cameraGranted = status.isGranted);
  }

  Future<void> _onCameraToggle(bool wantsOn) async {
    if (wantsOn) {
      final status = await Permission.camera.request();
      if (!mounted) return;
      setState(() => _cameraGranted = status.isGranted);
      if (!status.isGranted && status.isPermanentlyDenied) {
        _showOpenSettingsDialog(
          title: 'Camera access blocked',
          message:
              'Camera permission was permanently denied. Enable it from '
              'system Settings to use the face scan feature.',
        );
      }
      return;
    }

    // Turning "off" — Android/iOS give apps no API to self-revoke a
    // permission they already hold, so send the user to system Settings
    // instead of pretending the switch did something.
    _showOpenSettingsDialog(
      title: 'Turn off camera access?',
      message:
          'Apps can\'t remove their own permissions. To turn this off, '
          'disable Camera access for GLOW in system Settings.',
    );
  }

  void _showOpenSettingsDialog({
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: const Color(0xFFFF6EB4)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDeleteAllPressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete all saved results?'),
        content: const Text(
          'This removes every saved look from your favorites. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete All',
                style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await SavedResultsStore.deleteAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All saved results have been deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, contentWidth, screenHeight),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.06,
                      vertical: screenHeight * 0.025,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERMISSIONS',
                          style: TextStyle(
                            fontSize: contentWidth * 0.032,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6EB4),
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        _buildToggleRow(
                          icon: Icons.camera_alt_rounded,
                          title: 'Camera permission',
                          subtitle: 'Allow access to your camera',
                          value: _cameraGranted,
                          onChanged: _onCameraToggle,
                          contentWidth: contentWidth,
                        ),

                        SizedBox(height: screenHeight * 0.035),

                        Text(
                          'DATA MANAGEMENT',
                          style: TextStyle(
                            fontSize: contentWidth * 0.032,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6EB4),
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        _buildNavRow(
                          icon: Icons.delete_outline_rounded,
                          title: 'Delete saved results',
                          subtitle: 'Remove all scan history',
                          onTap: _onDeleteAllPressed,
                          contentWidth: contentWidth,
                        ),
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

  Widget _buildHeader(
      BuildContext context, double contentWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: screenHeight * 0.03,
        left: contentWidth * 0.06,
        right: contentWidth * 0.06,
        bottom: screenHeight * 0.03,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFF6EB4),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.keyboard_double_arrow_left_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(width: contentWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: contentWidth * 0.11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Manage your preferences',
                  style: TextStyle(
                    fontSize: contentWidth * 0.036,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double contentWidth,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(contentWidth * 0.04),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFB6D9)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: contentWidth * 0.13,
            height: contentWidth * 0.13,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD9EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6EB4),
              size: contentWidth * 0.06,
            ),
          ),
          SizedBox(width: contentWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: contentWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: contentWidth * 0.033,
                    color: const Color(0xFFFF6EB4),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFFF6EB4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double contentWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(contentWidth * 0.04),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFB6D9)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: contentWidth * 0.13,
              height: contentWidth * 0.13,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD9EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF6EB4),
                size: contentWidth * 0.06,
              ),
            ),
            SizedBox(width: contentWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: contentWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: contentWidth * 0.033,
                      color: const Color(0xFFFF6EB4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFFF6EB4),
              size: contentWidth * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}
