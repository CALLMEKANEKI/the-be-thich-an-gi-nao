import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalCacheService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'cache.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE cached_response(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint_key TEXT UNIQUE,
            response_json TEXT,
            cached_at TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveCache(String key, String jsonString) async {
    final db = await database;

    await db.insert(
      'cached_response',
      {
        'endpoint_key': key,
        'response_json': jsonString,
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCache(String key) async {
    final db = await database;
    final result = await db.query(
      'cached_response',
      where: 'endpoint_key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['response_json'] as String;
  }
}