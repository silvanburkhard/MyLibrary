class Book {
  final String? id;
  final String title;
  final String author;
  final String isbn;
  final String? coverPath;

  const Book({
    this.id,
    required this.title,
    required this.author,
    required this.isbn,
    this.coverPath,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? coverPath,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverPath: coverPath ?? this.coverPath,
    );
  }

  // Mapper für Google Books
  factory Book.fromJsonGoogle(Map<String, dynamic> json, String searchIsbn) {
    final info = json['volumeInfo'];

    String displayIsbn = searchIsbn;
    if (info['industryIdentifiers'] != null) {
      final identifiers = info['industryIdentifiers'] as List;
      final isbn13 = identifiers.firstWhere(
        (i) => i['type'] == 'ISBN_13',
        orElse: () => identifiers.firstWhere(
          (i) => i['type'] == 'ISBN_10',
          orElse: () => {'identifier': searchIsbn},
        ),
      );
      displayIsbn = isbn13['identifier'];
    }

    return Book(
      id: json['id'],
      title: info['title'] ?? 'Unbekannter Titel',
      author: (info['authors'] as List?)?.join(', ') ?? 'Unbekannter Autor',
      isbn: displayIsbn,
      // Google liefert oft http – wir erzwingen https
      coverPath: info['imageLinks']?['thumbnail']?.replaceFirst(
        'http://',
        'https://',
      ),
    );
  }

  // Mapper für Open Library (Metadaten-Response)
  // Hinweis: Das Cover aus dieser Response ist oft kleiner als das der Covers API.
  // BookService._checkOpenLibraryCover() liefert das hochauflösendere Bild.
  factory Book.fromJsonOpenLibrary(Map<String, dynamic> json, String isbn) {
    return Book(
      id: null,
      title: json['title'] ?? 'Unbekannter Titel',
      author:
          (json['authors'] as List?)?.map((a) => a['name']).join(', ') ??
          'Unbekannter Autor',
      isbn: isbn,
      coverPath: json['cover']?['large'] ?? json['cover']?['medium'],
    );
  }

  // ENTFERNT: fromJsonIsbnDe
  // isbn.de bietet keine öffentliche JSON-API. Die Seite liefert HTML,
  // das nicht per jsonDecode() verarbeitet werden kann.
  // Das DNB-Cover (portal.dnb.de/opac/mvb/cover) deckt denselben
  // deutschsprachigen Buchbestand zuverlässig ab.
}
