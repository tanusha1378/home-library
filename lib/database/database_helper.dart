import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('library.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isbn TEXT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        publisher TEXT,
        year INTEGER,
        pages INTEGER,
        genre TEXT,
        series TEXT,
        series_number INTEGER,
        cover_image TEXT,
        table_of_contents TEXT,
        location TEXT,
        status TEXT DEFAULT 'new',
        notes TEXT,
        created_at TEXT
      )
    ''');
  }

  // Добавить книгу
  Future<int> createBook(Map<String, dynamic> book) async {
    final db = await database;
    return await db.insert('books', book);
  }

  // Получить все книги
  Future<List<Map<String, dynamic>>> getAllBooks() async {
    final db = await database;
    return await db.query('books', orderBy: 'created_at DESC');
  }

  // Удалить книгу
  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
