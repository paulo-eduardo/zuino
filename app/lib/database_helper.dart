import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE products (
        codigo TEXT PRIMARY KEY,
        name TEXT,
        unit TEXT,
        unitValue REAL,
        quantity REAL,
        used REAL
      )
    ''');
  }

  Future<void> insertReceipt(String url) async {
    final db = await database;
    await db.insert('receipts', {'url': url}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> insertOrUpdateProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }
}
