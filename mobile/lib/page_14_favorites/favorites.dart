import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../backend/database_helper.dart';
import 'save_name_dialog.dart';
import 'saved_result_detail.dart';
import '../widgets/floating_bottom_nav.dart';

/// Thrown when a save/rename would collide with an existing saved_name.
/// The UI already blocks duplicates in SaveNameDialog, so this is a
/// backstop — callers can catch it to show a clear message instead of
/// letting a raw database exception crash the app.
class DuplicateNameException implements Exception {
  final String name;
  const DuplicateNameException(this.name);
  @override
  String toString() => 'A saved look named "$name" already exists.';
}

// ─────────────────────────────────────────────────────────────
// A single saved look. Deliberately thin — no tutorial/product
// content is duplicated here. Revisiting a saved look re-derives
// the full tutorial via RecommendationData using styleKey +
// undertone + monkScale, the same way the live results flow does.
// ─────────────────────────────────────────────────────────────

class SavedResult {
  // Null until this has actually been inserted — assigned by SQLite's
  // AUTOINCREMENT on save.
  final int? id;
  String savedName;
  final DateTime savedAt;

  // Facial analysis snapshot at the time this was saved.
  final String skinTone;
  final String faceShape;
  final String eyeShape;
  final String undertone;
  final int monkScale;

  // Chosen makeup style — styleKey is what's used to re-derive the
  // full tutorial/product content later via RecommendationData.
  final String styleKey;
  final String styleName;
  final int styleIndex;
  final String? matchPct;

  SavedResult({
    this.id,
    required this.savedName,
    required this.savedAt,
    required this.skinTone,
    required this.faceShape,
    required this.eyeShape,
    required this.undertone,
    required this.monkScale,
    required this.styleKey,
    required this.styleName,
    required this.styleIndex,
    this.matchPct,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'saved_name': savedName,
        'saved_at': savedAt.millisecondsSinceEpoch,
        'skin_tone': skinTone,
        'face_shape': faceShape,
        'eye_shape': eyeShape,
        'undertone': undertone,
        'monk_scale': monkScale,
        'style_key': styleKey,
        'style_name': styleName,
        'style_index': styleIndex,
        'match_pct': matchPct == null ? null : int.tryParse(matchPct!),
      };

  factory SavedResult.fromMap(Map<String, dynamic> map) => SavedResult(
        id: map['id'] as int,
        savedName: map['saved_name'] as String,
        savedAt: DateTime.fromMillisecondsSinceEpoch(map['saved_at'] as int),
        skinTone: map['skin_tone'] as String,
        faceShape: map['face_shape'] as String,
        eyeShape: map['eye_shape'] as String,
        undertone: map['undertone'] as String,
        monkScale: map['monk_scale'] as int,
        styleKey: map['style_key'] as String,
        styleName: map['style_name'] as String,
        styleIndex: map['style_index'] as int,
        matchPct: map['match_pct']?.toString(),
      );
}

// Thin CRUD layer over the saved_results table. This is the one seam
// the UI talks to — screens never touch DatabaseHelper directly.
class SavedResultsStore {
  static Future<List<SavedResult>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('saved_results', orderBy: 'saved_at DESC');
    return rows.map(SavedResult.fromMap).toList();
  }

  static Future<void> add(SavedResult result) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.insert('saved_results', result.toMap());
    } on DatabaseException catch (e) {
      // Translate the UNIQUE(saved_name) violation into a typed error the
      // UI can handle; let anything else propagate unchanged.
      if (e.isUniqueConstraintError()) {
        throw DuplicateNameException(result.savedName);
      }
      rethrow;
    }
  }

  static Future<void> rename(int id, String newName) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.update(
        'saved_results',
        {'saved_name': newName},
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DuplicateNameException(newName);
      }
      rethrow;
    }
  }

  static Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('saved_results', where: 'id = ?', whereArgs: [id]);
  }

  // Wipes every saved look — used by Settings > Data Management.
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('saved_results');
  }
}

// Saved Results / Favorites Screen — Page 15
class FavoritesScreen extends StatefulWidget {
  // True only when reached right after saving a tutorial — shows the
  // Back/Menu row so the user isn't stuck relying on the OS back
  // button (which would just land them on the tutorial screen again).
  final bool cameFromSave;

  const FavoritesScreen({super.key, this.cameFromSave = false});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<SavedResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await SavedResultsStore.getAll();
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double contentWidth = screenWidth > 420 ? 420 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: FloatingBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                _buildHeader(contentWidth, screenHeight),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF6EB4),
                          ),
                        )
                      : _results.isEmpty
                          ? _buildEmptyState(contentWidth)
                          : ListView.builder(
                              padding: EdgeInsets.all(contentWidth * 0.05),
                              itemCount: _results.length,
                              itemBuilder: (context, index) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: screenHeight * 0.02),
                                child: _buildResultCard(
                                  _results[index],
                                  contentWidth,
                                  screenHeight,
                                ),
                              ),
                            ),
                ),
                if (widget.cameFromSave)
                  _buildPostSaveNav(contentWidth, screenHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Back → the Beauty Profile screen (facial analysis + top 3 styles);
  // Menu → the Home Dashboard. Only shown right after a save, since
  // that's the only time these named routes are guaranteed to still
  // be on the stack.
  Widget _buildPostSaveNav(double contentWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        contentWidth * 0.05,
        0,
        contentWidth * 0.05,
        screenHeight * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.popUntil(
                context,
                (route) => route.settings.name == '/beauty-profile',
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6EB4)),
                padding: EdgeInsets.symmetric(
                  vertical: contentWidth * 0.035,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: contentWidth * 0.04,
                  color: const Color(0xFFFF6EB4),
                ),
              ),
            ),
          ),
          SizedBox(width: contentWidth * 0.03),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.popUntil(
                context,
                (route) => route.settings.name == '/home',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6EB4),
                padding: EdgeInsets.symmetric(
                  vertical: contentWidth * 0.035,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: contentWidth * 0.04,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double contentWidth, double screenHeight) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Journey',
            style: TextStyle(
              fontSize: contentWidth * 0.04,
              color: Colors.white.withValues(alpha: 0.85),
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            'Saved Results',
            style: TextStyle(
              fontSize: contentWidth * 0.11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            'Based on your facial analysis',
            style: TextStyle(
              fontSize: contentWidth * 0.035,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double contentWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(contentWidth * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: contentWidth * 0.16,
              color: const Color(0xFFFFB6D9),
            ),
            SizedBox(height: contentWidth * 0.04),
            Text(
              'No saved looks yet',
              style: TextStyle(
                fontSize: contentWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: contentWidth * 0.02),
            Text(
              'Save a tutorial from your results to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentWidth * 0.035,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
    SavedResult result,
    double contentWidth,
    double screenHeight,
  ) {
    final date = '${_monthName(result.savedAt.month)} '
        '${result.savedAt.day}, ${result.savedAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF6EB4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero area — style tag + placeholder illustration + date
          Padding(
            padding: EdgeInsets.all(contentWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentWidth * 0.03,
                      vertical: contentWidth * 0.012,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      result.styleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: contentWidth * 0.03,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: contentWidth * 0.1),
                Center(
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    size: contentWidth * 0.16,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: contentWidth * 0.1),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: contentWidth * 0.03,
                    vertical: contentWidth * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: contentWidth * 0.03,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer — saved name, expand button, edit/delete
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(contentWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.savedName.toUpperCase(),
                        style: TextStyle(
                          fontSize: contentWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openResult(result),
                      child: Container(
                        width: contentWidth * 0.1,
                        height: contentWidth * 0.1,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6EB4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: contentWidth * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _renameResult(result),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF6EB4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: contentWidth * 0.032,
                            color: const Color(0xFFFF6EB4),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: contentWidth * 0.03),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _deleteResult(result),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: contentWidth * 0.032,
                            color: Colors.red.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  // Shows the saved facial analysis snapshot first — tapping the
  // chosen style from there opens the full tutorial.
  void _openResult(SavedResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedResultDetailScreen(result: result),
      ),
    );
  }

  Future<void> _renameResult(SavedResult result) async {
    final existing = await SavedResultsStore.getAll();
    if (!mounted) return;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => SaveNameDialog(
        existingNames: existing.map((r) => r.savedName).toList(),
        initialName: result.savedName,
      ),
    );
    if (newName != null) {
      // Backstop: the dialog blocks duplicates, but guard the DB write so a
      // constraint or storage error surfaces as a message, not a crash.
      try {
        await SavedResultsStore.rename(result.id!, newName);
      } on DuplicateNameException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have a saved look with that name.')),
        );
        return;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't rename this look. Please try again.")),
        );
        return;
      }
      await _load();
    }
  }

  Future<void> _deleteResult(SavedResult result) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this saved look?'),
        content:
            Text('"${result.savedName}" will be removed from your favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SavedResultsStore.delete(result.id!);
      await _load();
    }
  }
}
