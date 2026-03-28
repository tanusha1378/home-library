import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../models/book.dart';
import 'scanner_screen.dart';
import 'book_selection_screen.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;
  final _apiService = ApiService();
  bool _isLoadingFromApi = false;

  // Контроллеры для полей ввода
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _genreController = TextEditingController();
  final _seriesController = TextEditingController();
  final _seriesNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _tocController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedStatus = 'new';

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _genreController.dispose();
    _seriesController.dispose();
    _seriesNumberController.dispose();
    _locationController.dispose();
    _coverImageController.dispose();
    _tocController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ✅ Сканирование ISBN и автозаполнение из API
  Future<void> _scanAndFetch() async {
    final isbn = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (isbn != null && mounted) {
      setState(() {
        _isbnController.text = isbn;
        _isLoadingFromApi = true;
      });

      final book = await _apiService.fetchBookByIsbn(isbn);

      if (book != null && mounted) {
        _fillFormWithBook(book);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Данные загружены из онлайн-источников!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Книга не найдена. Попробуйте поиск по названию или заполните вручную.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoadingFromApi = false;
        });
      }
    }
  }

  // ✅ Заполнение формы данными книги
  void _fillFormWithBook(Book book) {
    setState(() {
      _titleController.text = book.title;
      _authorController.text = book.author;
      if (book.publisher != null) _publisherController.text = book.publisher!;
      if (book.year != null) _yearController.text = book.year.toString();
      if (book.coverImage != null)
        _coverImageController.text = book.coverImage!;
      if (book.genre != null) _genreController.text = book.genre!;
      if (book.isbn != null) _isbnController.text = book.isbn!;
      if (book.description != null) _tocController.text = book.description!;
    });
  }

  // ✅ Поиск по названию и автору (со списком выбора!)
  Future<void> _searchByTitle() async {
    String title = _titleController.text;
    String author = _authorController.text;

    // Если поля пустые — открываем диалог для ввода
    if (title.isEmpty && author.isEmpty) {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => _buildSearchDialog(),
      );

      if (result != null && mounted) {
        title = result['title'] ?? '';
        author = result['author'] ?? '';

        if (title.isEmpty) return;
      } else {
        return;
      }
    }

    // Выполняем поиск
    await _performTitleSearch(title, author);
  }

  Future<void> _performTitleSearch(String title, String author) async {
    setState(() => _isLoadingFromApi = true);

    // Получаем СПИСОК книг
    final books = await _apiService.searchBookByTitle(title, author);

    setState(() => _isLoadingFromApi = false);

    if (books.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Книги не найдены. Попробуйте другое название.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Открываем экран выбора книги
    if (mounted) {
      final selectedBook = await Navigator.push<Book>(
        context,
        MaterialPageRoute(builder: (_) => BookSelectionScreen(books: books)),
      );

      // Если пользователь выбрал книгу — заполняем форму
      if (selectedBook != null && mounted) {
        _fillFormWithBook(selectedBook);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Книга выбрана! Проверьте данные.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildSearchDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();

    return AlertDialog(
      title: const Text('🔍 Поиск книги'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Название книги *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: authorController,
            decoration: const InputDecoration(
              labelText: 'Автор (необязательно)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.isNotEmpty) {
              Navigator.pop(context, {
                'title': titleController.text,
                'author': authorController.text,
              });
            }
          },
          child: const Text('Поиск'),
        ),
      ],
    );
  }

  // ✅ Сохранение книги в базу данных
  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      final book = {
        'isbn': _isbnController.text.isEmpty ? null : _isbnController.text,
        'title': _titleController.text,
        'author': _authorController.text,
        'publisher': _publisherController.text.isEmpty
            ? null
            : _publisherController.text,
        'year': _yearController.text.isEmpty
            ? null
            : int.tryParse(_yearController.text),
        'pages': _pagesController.text.isEmpty
            ? null
            : int.tryParse(_pagesController.text),
        'genre': _genreController.text.isEmpty ? null : _genreController.text,
        'series': _seriesController.text.isEmpty
            ? null
            : _seriesController.text,
        'series_number': _seriesNumberController.text.isEmpty
            ? null
            : int.tryParse(_seriesNumberController.text),
        'cover_image': _coverImageController.text.isEmpty
            ? null
            : _coverImageController.text,
        'table_of_contents': _tocController.text.isEmpty
            ? null
            : _tocController.text,
        'location': _locationController.text.isEmpty
            ? null
            : _locationController.text,
        'status': _selectedStatus,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _dbHelper.createBook(book);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Книга добавлена!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ Добавить книгу'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingFromApi
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === ISBN И СКАНЕР ===
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📷 Сканирование / Поиск',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _isbnController,
                                    label: 'ISBN',
                                    icon: Icons.bookmark,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.teal,
                                  ),
                                  tooltip: 'Сканировать ISBN',
                                  iconSize: 32,
                                  onPressed: _scanAndFetch,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _searchByTitle,
                                icon: const Icon(Icons.search, size: 18),
                                label: const Text(
                                  '🔍 Найти книгу по названию и автору',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // === ОБЯЗАТЕЛЬНЫЕ ПОЛЯ ===
                    _buildTextField(
                      controller: _titleController,
                      label: 'Название книги *',
                      icon: Icons.title,
                      validator: (v) => v!.isEmpty ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _authorController,
                      label: 'Автор *',
                      icon: Icons.person,
                      validator: (v) => v!.isEmpty ? 'Введите автора' : null,
                    ),
                    const SizedBox(height: 16),

                    // === ДЕТАЛИ КНИГИ ===
                    _buildSectionTitle('📋 Детали'),
                    const SizedBox(height: 8),

                    _buildTextField(
                      controller: _publisherController,
                      label: 'Издательство',
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _yearController,
                            label: 'Год издания',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _pagesController,
                            label: 'Страниц',
                            icon: Icons.menu_book,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _genreController,
                      label: 'Жанр / Категория',
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 16),

                    // === СЕРИЯ КНИГ ===
                    _buildSectionTitle('📚 Серия'),
                    const SizedBox(height: 8),

                    _buildTextField(
                      controller: _seriesController,
                      label: 'Название серии',
                      icon: Icons.collections_bookmark,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _seriesNumberController,
                      label: 'Номер в серии',
                      icon: Icons.looks_one,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // === ОГЛАВЛЕНИЕ ===
                    _buildSectionTitle('📑 Оглавление (для сборников)'),
                    const SizedBox(height: 8),

                    _buildTextField(
                      controller: _tocController,
                      label: 'Авторы и рассказы в сборнике',
                      icon: Icons.list,
                      maxLines: 5,
                      hintText: 'Например:\n• А. Чехов — Дама с собачкой',
                    ),
                    const SizedBox(height: 16),

                    // === МЕСТОПОЛОЖЕНИЕ И ОБЛОЖКА ===
                    _buildSectionTitle('📍 Хранение'),
                    const SizedBox(height: 8),

                    _buildTextField(
                      controller: _locationController,
                      label: 'Где стоит (шкаф, полка)',
                      icon: Icons.location_on,
                      hintText: 'Например: Шкаф 2, Полка 3',
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _coverImageController,
                      label: 'Обложка (URL)',
                      icon: Icons.image,
                      hintText: 'https://example.com/cover.jpg',
                    ),
                    const SizedBox(height: 16),

                    // === СТАТУС ===
                    _buildSectionTitle('🏷 Статус'),
                    const SizedBox(height: 8),

                    _buildDropdown(
                      initialValue: _selectedStatus,
                      label: 'Статус чтения',
                      icon: Icons.flag,
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('🆕 Новая')),
                        DropdownMenuItem(
                          value: 'reading',
                          child: Text('📖 Читаю'),
                        ),
                        DropdownMenuItem(
                          value: 'read',
                          child: Text('✅ Прочитано'),
                        ),
                        DropdownMenuItem(
                          value: 'planned',
                          child: Text('🗓 В планах'),
                        ),
                        DropdownMenuItem(
                          value: 'paused',
                          child: Text('⏸ Отложено'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                    const SizedBox(height: 16),

                    // === ЗАМЕТКИ ===
                    _buildSectionTitle('📝 Заметки'),
                    const SizedBox(height: 8),

                    _buildTextField(
                      controller: _notesController,
                      label: 'Личные заметки',
                      icon: Icons.note,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    // === КНОПКА СОХРАНИТЬ ===
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          '💾 Сохранить книгу',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // === ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ===

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: maxLines == 1
          ? TextCapitalization.words
          : TextCapitalization.sentences,
    );
  }

  Widget _buildDropdown({
    required String initialValue,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
