import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('match_scores.db');
    return _database!;
  }

  Future<Database> _initDB(String path) async {
    final dbPath = await getDatabasesPath();
    final dbFullPath =
        join(dbPath, path); // Renaming local variable to dbFullPath
    return await openDatabase(dbFullPath, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE match_scores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playerId TEXT,
        score INTEGER,
        matchDate TEXT,
        synced INTEGER
      )
    ''');
  }

  Future<void> insertScore(Map<String, dynamic> score) async {
    final db = await database;
    await db.insert('match_scores', score);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedScores() async {
    final db = await database;
    return await db.query('match_scores', where: 'synced = 0');
  }

  Future<void> updateSyncStatus(int id) async {
    final db = await database;
    await db.update(
      'match_scores',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteScore(int id) async {
    final db = await database;
    await db.delete(
      'match_scores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
