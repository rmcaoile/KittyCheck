import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/fgs_result.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fgs_results.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fgs_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        catName TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        totalFgsScore REAL NOT NULL,
        earScore REAL NOT NULL,
        eyesScore REAL NOT NULL,
        muzzleScore REAL NOT NULL,
        whiskersScore REAL NOT NULL,
        headPositionScore REAL NOT NULL,
        originalImagePath TEXT NOT NULL,
        earImagePath TEXT,
        eyesImagePath TEXT,
        muzzleImagePath TEXT,
        whiskersImagePath TEXT,
        headPositionImagePath TEXT
      )
    ''');
  }

  // CRUD Operations

  Future<int> insertResult(FGSResult result) async {
    final db = await database;
    return await db.insert('fgs_results', result.toJson());
  }

  Future<List<FGSResult>> getAllResults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('fgs_results', orderBy: 'dateTime DESC');

    return List.generate(maps.length, (i) {
      return FGSResult.fromJson(maps[i]);
    });
  }

  Future<FGSResult?> getResult(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fgs_results',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return FGSResult.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateResult(FGSResult result) async {
    final db = await database;
    return await db.update(
      'fgs_results',
      result.toJson(),
      where: 'id = ?',
      whereArgs: [result.id],
    );
  }

  Future<int> deleteResult(int id) async {
    final db = await database;
    return await db.delete(
      'fgs_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FGSResult>> searchResults(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fgs_results',
      where: 'catName LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'dateTime DESC',
    );

    return List.generate(maps.length, (i) {
      return FGSResult.fromJson(maps[i]);
    });
  }

  Future<List<FGSResult>> getResultsSorted(String sortBy, bool ascending) async {
    final db = await database;
    String orderBy;

    switch (sortBy) {
      case 'name':
        orderBy = 'catName ${ascending ? 'ASC' : 'DESC'}';
        break;
      case 'score':
        orderBy = 'totalFgsScore ${ascending ? 'ASC' : 'DESC'}';
        break;
      case 'date':
      default:
        orderBy = 'dateTime ${ascending ? 'ASC' : 'DESC'}';
        break;
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'fgs_results',
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) {
      return FGSResult.fromJson(maps[i]);
    });
  }

  // TODO: handle increment/decrement when a cat name is deleted
  Future<int> getNextCatNumber() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT COUNT(*) as count FROM fgs_results
      WHERE catName LIKE 'Cat No. %'
    ''');

    final count = maps.first['count'] as int;
    return count + 1;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}