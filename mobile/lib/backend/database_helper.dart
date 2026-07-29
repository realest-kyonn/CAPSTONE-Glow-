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

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'glow.db');
    return openDatabase(
      path,
      version: 1,
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
    );
  }
}
