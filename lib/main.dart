import 'package:flutter/material.dart';
import 'database/database_helper.dart'; // ✅ ЭТОТ ИМПОРТ ОБЯЗАТЕЛЕН!
import 'screens/add_book_screen.dart'; // ✅ И ЭТОТ ТОЖЕ!

void main() {
  runApp(const HomeLibraryApp());
}

class HomeLibraryApp extends StatelessWidget {
  const HomeLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '📚 Моя библиотека',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const BookListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks(); // ✅ Загружаем книги при старте
  }

  // ✅ Метод загрузки из БД
  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await _dbHelper.getAllBooks();
      setState(() {
        _books = books;
        _isLoading = false;
      });
      print('📚 Загружено книг: ${books.length}'); // Для отладки
    } catch (e) {
      print('❌ Ошибка загрузки: $e');
      setState(() => _isLoading = false);
    }
  }

  // ✅ Метод удаления
  Future<void> _deleteBook(int id) async {
    await _dbHelper.deleteBook(id);
    _loadBooks();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🗑️ Книга удалена')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Моя библиотека'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? const Center(
              child: Text(
                'Библиотека пуста\nДобавь первую книгу!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _books.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final book = _books[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.book,
                      size: 50,
                      color: Colors.teal,
                    ),
                    title: Text(book['title'] ?? 'Без названия'),
                    subtitle: Text(book['author'] ?? 'Неизвестный автор'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✏️ Скоро!')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBook(book['id']),
                        ),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('📖 ${book['title']}')),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookScreen()),
          ).then((_) => _loadBooks());
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
