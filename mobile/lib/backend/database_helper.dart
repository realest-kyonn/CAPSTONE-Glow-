import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the local SQLite connection + schema for Glow's offline
/// storage. Single table, single user, no sync — see saved_results
/// in favorites.dart for the CRUD layer built on top of this.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  // Bump this whenever the schema changes, and add a matching step in
  // _migrate below. Existing installs run onUpgrade from their stored
  // version up to this one; fresh installs run onCreate at this version.
  static const int _schemaVersion = 1;

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'glow.db');
    return openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE saved_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            saved_name TEXT NOT NULL UNIQUE,
            saved_at INTEGER NOT NULL,
            skin_tone TEXT NOT NULL,
            face_shape TEXT NOT NULL,
            eye_shape TEXT NOT NULL,
            undertone TEXT NOT NULL,
            monk_scale INTEGER NOT NULL,
            style_key TEXT NOT NULL,
            style_name TEXT NOT NULL,
            style_index INTEGER NOT NULL,
            match_pct INTEGER
          )
        ''');
      },
      onUpgrade: _migrate,
    );
  }

  /// Runs each migration step needed to move an existing database from its
  /// stored [oldVersion] up to [newVersion]. Empty today because the schema
  /// is still at version 1 — but the framework is in place so a future
  /// column can be added without wiping users' saved looks. To add one:
  /// bump _schemaVersion, then add `if (oldVersion < N) { ...ALTER... }`
  /// here in ascending order (each step upgrades from the previous version).
  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    // Example for the next change (do NOT enable until _schemaVersion == 2):
    //   if (oldVersion < 2) {
    //     await db.execute('ALTER TABLE saved_results ADD COLUMN notes TEXT');
    //   }
  }
}
