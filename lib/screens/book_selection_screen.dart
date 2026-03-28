import 'package:flutter/material.dart';
import '../models/book.dart';

class BookSelectionScreen extends StatelessWidget {
  final List<Book> books;

  const BookSelectionScreen({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 Выберите книгу (${books.length})'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: books.isEmpty
          ? const Center(
              child: Text(
                '❌ Книги не найдены',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: books.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final book = books[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: book.coverImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              book.coverImage!,
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.book, size: 50),
                            ),
                          )
                        : const Icon(Icons.book, size: 50, color: Colors.teal),
                    title: Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('👤 ${book.author}'),
                        if (book.year != null) Text('📅 ${book.year} год'),
                        if (book.publisher != null)
                          Text('🏢 ${book.publisher}'),
                        if (book.genre != null) Text('🏷 ${book.genre}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context, book);
                    },
                  ),
                );
              },
            ),
    );
  }
}
