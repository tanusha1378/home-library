class Book {
  final String? isbn;
  final String title;
  final String author;
  final String? publisher;
  final int? year;
  final String? coverImage;
  final String? genre;
  final String? description;

  Book({
    this.isbn,
    required this.title,
    required this.author,
    this.publisher,
    this.year,
    this.coverImage,
    this.genre,
    this.description,
  });

  // Конвертация в Map для базы данных
  Map<String, dynamic> toMap() {
    return {
      'isbn': isbn,
      'title': title,
      'author': author,
      'publisher': publisher,
      'year': year,
      'cover_image': coverImage,
      'genre': genre,
      'table_of_contents': description, // Используем описание как оглавление
    };
  }
}
