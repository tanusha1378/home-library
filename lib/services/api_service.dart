import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class ApiService {
  static const String _googleBaseUrl =
      'https://www.googleapis.com/books/v1/volumes';
  static const String _openLibraryBaseUrl = 'https://openlibrary.org';

  // Поиск по ISBN (возвращает одну книгу)
  Future<Book?> fetchBookByIsbn(String isbn) async {
    final cleanIsbn = isbn.replaceAll(RegExp(r'[-\s]'), '');

    print('🔍 Поиск по ISBN: $cleanIsbn');

    Book? book = await _fetchFromGoogleBooks(cleanIsbn);
    if (book != null) {
      print('  ✅ Найдено в Google Books!');
      return book;
    }

    book = await _fetchFromOpenLibraryByIsbn(cleanIsbn);
    if (book != null) {
      print('  ✅ Найдено в OpenLibrary!');
      return book;
    }

    print('❌ Не найдено по ISBN');
    return null;
  }

  // Поиск по названию и автору (возвращает СПИСОК книг для выбора!)
  Future<List<Book>> searchBookByTitle(String title, String author) async {
    print('🔍 Поиск по названию: "$title", автор: "$author"');

    List<Book> allBooks = [];

    // 1️⃣ Google Books - до 10 результатов
    print('  → Google Books...');
    final googleBooks = await _searchGoogleBooksByTitle(
      title,
      author,
      maxResults: 10,
    );
    allBooks.addAll(googleBooks);

    // 2️⃣ OpenLibrary - до 10 результатов
    print('  → OpenLibrary...');
    final openLibraryBooks = await _searchOpenLibraryByTitle(
      title,
      author,
      limit: 10,
    );
    allBooks.addAll(openLibraryBooks);

    print('✅ Найдено всего книг: ${allBooks.length}');
    return allBooks;
  }

  // Google Books по ISBN
  Future<Book?> _fetchFromGoogleBooks(String isbn) async {
    try {
      final response = await http.get(
        Uri.parse('$_googleBaseUrl?q=isbn:$isbn'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['totalItems'] > 0) {
          final volumeInfo = data['items'][0]['volumeInfo'];
          return _parseGoogleBook(volumeInfo, isbn);
        }
      }
    } catch (e) {
      print('  ❌ Ошибка Google Books: $e');
    }
    return null;
  }

  // Google Books поиск по названию (возвращает список)
  Future<List<Book>> _searchGoogleBooksByTitle(
    String title,
    String author, {
    int maxResults = 10,
  }) async {
    List<Book> books = [];
    try {
      final query = Uri.encodeComponent(
        '$title ${author.isNotEmpty ? "inauthor:$author" : ""}',
      );
      final response = await http.get(
        Uri.parse('$_googleBaseUrl?q=$query&maxResults=$maxResults'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['totalItems'] > 0) {
          final items = data['items'] as List<dynamic>;
          for (var item in items) {
            final volumeInfo = item['volumeInfo'];
            if (volumeInfo != null) {
              books.add(_parseGoogleBook(volumeInfo, null));
            }
          }
        }
      }
    } catch (e) {
      print('  ❌ Ошибка поиска Google Books: $e');
    }
    return books;
  }

  Book _parseGoogleBook(Map<String, dynamic> volumeInfo, String? isbn) {
    final title = volumeInfo['title'] ?? 'Без названия';
    final authors = volumeInfo['authors'] as List<dynamic>?;
    final publisher = volumeInfo['publisher'] as String?;
    final publishedDate = volumeInfo['publishedDate'] as String?;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final description = volumeInfo['description'] as String?;
    final categories = volumeInfo['categories'] as List<dynamic>?;

    int? year;
    if (publishedDate != null && publishedDate.length >= 4) {
      year = int.tryParse(publishedDate.substring(0, 4));
    }

    String? coverImage;
    if (imageLinks != null) {
      coverImage = imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'];
    }

    String? genre;
    if (categories != null && categories.isNotEmpty) {
      genre = categories[0].toString();
    }

    return Book(
      isbn: isbn,
      title: title,
      author: authors != null ? authors.join(', ') : 'Неизвестный автор',
      publisher: publisher,
      year: year,
      coverImage: coverImage,
      genre: genre,
      description: description,
    );
  }

  // OpenLibrary по ISBN
  Future<Book?> _fetchFromOpenLibraryByIsbn(String isbn) async {
    try {
      final response = await http.get(
        Uri.parse('$_openLibraryBaseUrl/isbn/$isbn.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return _parseOpenLibraryBook(data, isbn);
        }
      }
    } catch (e) {
      print('  ❌ Ошибка OpenLibrary: $e');
    }
    return null;
  }

  // OpenLibrary поиск по названию (возвращает список)
  Future<List<Book>> _searchOpenLibraryByTitle(
    String title,
    String author, {
    int limit = 10,
  }) async {
    List<Book> books = [];
    try {
      final query = Uri.encodeComponent(
        '$title ${author.isNotEmpty ? author : ""}',
      );
      final response = await http.get(
        Uri.parse('$_openLibraryBaseUrl/search.json?title=$query&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['docs'] as List<dynamic>?;

        if (docs != null) {
          for (var doc in docs) {
            if (doc is Map<String, dynamic>) {
              books.add(_parseOpenLibrarySearchResult(doc));
            }
          }
        }
      }
    } catch (e) {
      print('  ❌ Ошибка поиска OpenLibrary: $e');
    }
    return books;
  }

  Book _parseOpenLibraryBook(Map<String, dynamic> data, String isbn) {
    final title = data['title'] as String? ?? 'Без названия';
    final authors = data['authors'] as List<dynamic>?;
    final publishers = data['publishers'] as List<dynamic>?;
    final firstPublishDate = data['first_publish_date'] as String?;
    final covers = data['covers'] as List<dynamic>?;
    final subjects = data['subjects'] as List<dynamic>?;

    String author = 'Неизвестный автор';
    if (authors != null && authors.isNotEmpty) {
      final authorNames = authors
          .whereType<Map<String, dynamic>>()
          .map((a) => a['name'] as String?)
          .whereType<String>()
          .toList();
      if (authorNames.isNotEmpty) {
        author = authorNames.join(', ');
      }
    }

    String? publisher;
    if (publishers != null && publishers.isNotEmpty) {
      publisher = publishers.first.toString();
    }

    int? year;
    if (firstPublishDate != null && firstPublishDate.length >= 4) {
      year = int.tryParse(firstPublishDate.substring(0, 4));
    }

    String? coverImage;
    if (covers != null && covers.isNotEmpty) {
      final coverId = covers.first;
      coverImage = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    }

    String? genre;
    if (subjects != null && subjects.isNotEmpty) {
      genre = subjects.first.toString();
    }

    return Book(
      isbn: isbn,
      title: title,
      author: author,
      publisher: publisher,
      year: year,
      coverImage: coverImage,
      genre: genre,
      description: null,
    );
  }

  Book _parseOpenLibrarySearchResult(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'Без названия';
    final authorName = data['author_name'] as List<dynamic>?;
    final firstPublishYear = data['first_publish_year'] as int?;
    final coverI = data['cover_i'] as int?;
    final subject = data['subject'] as List<dynamic>?;

    String author = 'Неизвестный автор';
    if (authorName != null && authorName.isNotEmpty) {
      author = authorName.first.toString();
    }

    String? coverImage;
    if (coverI != null) {
      coverImage = 'https://covers.openlibrary.org/b/id/${coverI}-M.jpg';
    }

    String? genre;
    if (subject != null && subject.isNotEmpty) {
      genre = subject.first.toString();
    }

    return Book(
      isbn: null,
      title: title,
      author: author,
      publisher: null,
      year: firstPublishYear,
      coverImage: coverImage,
      genre: genre,
      description: null,
    );
  }
}
