import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton - один экземпляр на всё приложение
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Получаем базу данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('library.db');
    return _database!;
  }

  // Инициализация БД
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Создание таблиц
  Future<void> _createDB(Database db, int version) async {
    // Таблица книг
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

    // Таблица жанров (справочник)
    await db.execute('''
      CREATE TABLE genres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT
      )
    ''');

    // Заполняем справочник жанров по умолчанию
    await _seedGenres(db);
  }

  // Заполнение справочника жанров
  Future<void> _seedGenres(Database db) async {
    final defaultGenres = [
      'Фэнтези',
      'Детектив',
      'Роман',
      'Научная фантастика',
      'Биография',
      'Исторический',
      'Приключения',
      'Ужасы',
      'Комедия',
      'Драма',
      'Детская литература',
      'Поэзия',
      'Документальная',
      'Психология',
      'Бизнес',
      'Наука',
      'Кулинария',
      'Путешествия',
      'Искусство',
      'Другое',
    ];

    for (final genre in defaultGenres) {
      await db.insert('genres', {
        'name': genre,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // === CRUD для книг ===

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

  // Получить одну книгу по ID
  Future<Map<String, dynamic>?> getBook(int id) async {
    final db = await database;
    final maps = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // Обновить книгу
  Future<int> updateBook(Map<String, dynamic> book) async {
    final db = await database;
    return await db.update(
      'books',
      book,
      where: 'id = ?',
      whereArgs: [book['id']],
    );
  }

  // Удалить книгу
  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // === МЕТОДЫ ДЛЯ ЖАНРОВ ===

  // Получить все жанры
  Future<List<String>> getAllGenres() async {
    final db = await database;
    final maps = await db.query('genres', orderBy: 'name ASC');
    return maps.map((m) => m['name'] as String).toList();
  }

  // Добавить новый жанр
  Future<int> addGenre(String name, {String? description}) async {
    final db = await database;
    return await db.insert('genres', {
      'name': name.trim(),
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Можно ли удалить жанр (проверка использования)
  Future<bool> canDeleteGenre(String name) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books WHERE genre = ?', [name]),
    );
    return count == 0;
  }

  // Удалить жанр
  Future<int> deleteGenre(String name) async {
    final db = await database;
    return await db.delete('genres', where: 'name = ?', whereArgs: [name]);
  }

  // Поиск жанров
  Future<List<String>> searchGenres(String query) async {
    if (query.isEmpty) return getAllGenres();
    final db = await database;
    final maps = await db.query(
      'genres',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
      limit: 10,
    );
    return maps.map((m) => m['name'] as String).toList();
  }

  // Закрыть БД
  Future close() async {
    final db = await database;
    db.close();
  }
}
