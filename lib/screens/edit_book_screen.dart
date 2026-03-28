import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'genres_screen.dart';

class EditBookScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;

  // Контроллеры для полей ввода
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _isbnController;
  late TextEditingController _publisherController;
  late TextEditingController _yearController;
  late TextEditingController _pagesController;
  late TextEditingController _genreController;
  late TextEditingController _seriesController;
  late TextEditingController _seriesNumberController;
  late TextEditingController _locationController;
  late TextEditingController _coverImageController;
  late TextEditingController _tocController;
  late TextEditingController _notesController;

  String _selectedStatus = 'new';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Заполняем контроллеры текущими данными книги
    _titleController = TextEditingController(text: widget.book['title'] ?? '');
    _authorController = TextEditingController(
      text: widget.book['author'] ?? '',
    );
    _isbnController = TextEditingController(text: widget.book['isbn'] ?? '');
    _publisherController = TextEditingController(
      text: widget.book['publisher'] ?? '',
    );
    _yearController = TextEditingController(
      text: widget.book['year']?.toString() ?? '',
    );
    _pagesController = TextEditingController(
      text: widget.book['pages']?.toString() ?? '',
    );
    _genreController = TextEditingController(text: widget.book['genre'] ?? '');
    _seriesController = TextEditingController(
      text: widget.book['series'] ?? '',
    );
    _seriesNumberController = TextEditingController(
      text: widget.book['series_number']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: widget.book['location'] ?? '',
    );
    _coverImageController = TextEditingController(
      text: widget.book['cover_image'] ?? '',
    );
    _tocController = TextEditingController(
      text: widget.book['table_of_contents'] ?? '',
    );
    _notesController = TextEditingController(text: widget.book['notes'] ?? '');
    _selectedStatus = widget.book['status'] ?? 'new';
  }

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

  // Сохранение изменений
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final updatedBook = {
        'id': widget.book['id'],
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
      };

      await _dbHelper.updateBook(updatedBook);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Изменения сохранены!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  // Подтверждение удаления
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Удалить книгу?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _dbHelper.deleteBook(widget.book['id']);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✏️ Редактировать книгу'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить книгу',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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

                    // === ISBN ===
                    _buildTextField(
                      controller: _isbnController,
                      label: 'ISBN',
                      icon: Icons.bookmark,
                      keyboardType: TextInputType.number,
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

                    // === ЖАНР С АВТОДОПОЛНЕНИЕМ ===
                    FutureBuilder<List<String>>(
                      future: _dbHelper.getAllGenres(),
                      builder: (context, snapshot) {
                        final genres = snapshot.data ?? [];
                        return Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) return genres;
                            return genres.where(
                              (genre) => genre.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Жанр / Категория',
                                    hintText:
                                        'Начни вводить или выбери из списка',
                                    prefixIcon: const Icon(
                                      Icons.category,
                                      color: Colors.teal,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.list,
                                        color: Colors.teal,
                                      ),
                                      tooltip: 'Выбрать из справочника',
                                      onPressed: () async {
                                        final selected =
                                            await Navigator.push<String>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const GenresScreen(),
                                              ),
                                            );
                                        if (selected != null && mounted) {
                                          _genreController.text = selected;
                                        }
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                );
                              },
                          onSelected: (value) {
                            _genreController.text = value;
                          },
                        );
                      },
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
                    _buildSectionTitle('📑 Оглавление'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _tocController,
                      label: 'Авторы и рассказы в сборнике',
                      icon: Icons.list,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    // === МЕСТОПОЛОЖЕНИЕ И ОБЛОЖКА ===
                    _buildSectionTitle('📍 Хранение'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Где стоит (шкаф, полка)',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _coverImageController,
                      label: 'Обложка (URL)',
                      icon: Icons.image,
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
                        onPressed: _saveChanges,
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
                          '💾 Сохранить изменения',
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
