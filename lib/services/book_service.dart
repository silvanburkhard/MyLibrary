import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/book.dart';

const _kTimeout = Duration(seconds: 8);
const String _userAgent = 'MyBookApp/1.0 (Contact: admin@example.com)';

class BookService {
  const BookService();

  static bool isValidIsbn(String isbn) {
    final clean = isbn.replaceAll('-', '').replaceAll(' ', '');
    if (clean.length == 13) {
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        final digit = int.tryParse(clean[i]);
        if (digit == null) return false;
        sum += (i % 2 == 0) ? digit : digit * 3;
      }
      final check = (10 - (sum % 10)) % 10;
      return check == int.tryParse(clean[12]);
    } else if (clean.length == 10) {
      int sum = 0;
      for (int i = 0; i < 9; i++) {
        final digit = int.tryParse(clean[i]);
        if (digit == null) return false;
        sum += digit * (10 - i);
      }
      final last = clean[9].toUpperCase() == 'X' ? 10 : int.tryParse(clean[9]);
      if (last == null) return false;
      return (sum + last) % 11 == 0;
    }
    return false;
  }

  Future<Book?> fetchBookCombined(String isbn) async {
    if (!isValidIsbn(isbn)) {
      debugPrint('Ungültige ISBN: $isbn');
      return null;
    }

    final cleanIsbn = isbn.replaceAll('-', '').replaceAll(' ', '');
    debugPrint('Starte Suche für ISBN: $cleanIsbn');

    // Versuche zuerst DNB mit Cover-Check parallel
    final dnbResults = await Future.wait([
      _fetchFromDNB(cleanIsbn),
      _checkDnbCover(cleanIsbn),
    ]);

    final dnbBook = dnbResults[0] as Book?;
    final dnbCoverUrl = dnbResults[1] as String?;

    // Wenn DNB erfolgreich → nutze DNB mit optionalem Fallback für Cover
    if (dnbBook != null) {
      debugPrint('DNB Ergebnis gefunden für ISBN: $cleanIsbn');

      // Wenn DNB kein Cover hat, versuche OpenLibrary Cover
      if (dnbCoverUrl == null) {
        final olCoverUrl = await _checkOpenLibraryCover(cleanIsbn);
        return dnbBook.copyWith(isbn: isbn, coverPath: olCoverUrl);
      }

      return dnbBook.copyWith(isbn: isbn, coverPath: dnbCoverUrl);
    }

    debugPrint(
      'DNB hatte keine Ergebnisse, versuche Google und OpenLibrary...',
    );

    // Fallback: Hole Daten von Google und OpenLibrary parallel
    final fallbackResults = await Future.wait([
      _fetchFromGoogle(cleanIsbn),
      _fetchFromOpenLibrary(cleanIsbn),
      _checkOpenLibraryCover(cleanIsbn),
    ]);

    final googleBook = fallbackResults[0] as Book?;
    final olBook = fallbackResults[1] as Book?;
    final olCoverUrl = fallbackResults[2] as String?;

    return _mergeBooks(
      google: googleBook,
      dnb: null,
      ol: olBook,
      olCoverUrl: olCoverUrl,
      dnbCoverUrl: null,
      originalIsbn: isbn,
    );
  }

  Book? _mergeBooks({
    required Book? google,
    required Book? dnb,
    required Book? ol,
    required String? olCoverUrl,
    required String? dnbCoverUrl,
    required String originalIsbn,
  }) {
    if (google == null && dnb == null && ol == null) return null;

    final Book base = google ?? dnb ?? ol!;

    // Cover-Priorität:
    // 1. DNB (bevorzugt für deutschsprachige Bücher)
    // 2. OpenLibrary Covers API (zuverlässig, großes Format)
    // 3. OpenLibrary Metadaten-Response
    // 4. Google Metadaten-Response
    final cover =
        dnbCoverUrl ?? olCoverUrl ?? ol?.coverPath ?? google?.coverPath;

    return base.copyWith(
      id: google?.id ?? dnb?.id ?? ol?.id,
      title: google?.title ?? dnb?.title ?? ol?.title,
      author: google?.author ?? dnb?.author ?? ol?.author,
      isbn: originalIsbn,
      coverPath: cover,
    );
  }

  // ─── Metadaten-Quellen ────────────────────────────────────────────────────

  Future<Book?> _fetchFromGoogle(String isbn) async {
    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
    );
    try {
      final response = await http
          .get(url, headers: {'User-Agent': _userAgent})
          .timeout(_kTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if ((data['totalItems'] as int? ?? 0) > 0) {
          return Book.fromJsonGoogle(data['items'][0], isbn);
        }
      }
    } catch (e) {
      debugPrint('Google API Fehler: $e');
    }
    return null;
  }

  Future<Book?> _fetchFromDNB(String isbn) async {
    final sruUrl = Uri.parse(
      'https://services.dnb.de/sru/dnb?version=1.1&operation=searchRetrieve&query=isbn%3D$isbn&recordSchema=MARC21plus-xml',
    );
    try {
      final response = await http
          .get(sruUrl, headers: {'User-Agent': _userAgent})
          .timeout(_kTimeout);
      if (response.statusCode != 200) return null;

      final document = XmlDocument.parse(response.body);

      // Prüfe ob Suchergebnisse vorhanden sind
      final recordData = document.findAllElements('record').firstOrNull;
      if (recordData == null) return null;

      // Extrahiere Titel und Autor aus MARC21 Feldern
      final titleElement = document
          .findAllElements('datafield')
          .where((e) => e.getAttribute('tag') == '245')
          .firstOrNull
          ?.findElements('subfield')
          .where((s) => s.getAttribute('code') == 'a')
          .firstOrNull;

      final authorElement = document
          .findAllElements('datafield')
          .where((e) => e.getAttribute('tag') == '100')
          .firstOrNull
          ?.findElements('subfield')
          .where((s) => s.getAttribute('code') == 'a')
          .firstOrNull;

      final title = titleElement?.innerText.trim() ?? 'Unbekannter Titel';
      final author = authorElement?.innerText.trim() ?? 'Unbekannter Autor';

      return Book(
        id: 'dnb-$isbn',
        title: title,
        author: author,
        isbn: isbn,
        coverPath: null, // Cover kommt separat via _checkDnbCover
      );
    } catch (e) {
      debugPrint('DNB API Fehler: $e');
    }
    return null;
  }

  Future<Book?> _fetchFromOpenLibrary(String isbn) async {
    final url = Uri.parse(
      'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data',
    );
    try {
      final response = await http
          .get(url, headers: {'User-Agent': _userAgent})
          .timeout(_kTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookKey = 'ISBN:$isbn';
        if (data.containsKey(bookKey)) {
          return Book.fromJsonOpenLibrary(data[bookKey], isbn);
        }
      }
    } catch (e) {
      debugPrint('Open Library API Fehler: $e');
    }
    return null;
  }

  // ─── Cover-Checks (geben nur eine validierte URL zurück) ─────────────────

  /// Open Library Covers API: direkte Bild-URL ohne HTML-Parsing.
  /// ?default=false → 404 statt leerem Platzhalterbild wenn kein Cover vorhanden.
  Future<String?> _checkOpenLibraryCover(String isbn) async {
    final coverUrl =
        'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg?default=false';
    try {
      final response = await http
          .head(Uri.parse(coverUrl), headers: {'User-Agent': _userAgent})
          .timeout(_kTimeout);
      if (response.statusCode == 200) return coverUrl;
    } catch (_) {}
    return null;
  }

  /// DNB-Cover: https://portal.dnb.de/opac/mvb/cover?isbn={isbn}
  /// Besonders gut für deutschsprachige Bücher.
  /// Die ISBN kann mit oder ohne Bindestriche übergeben werden.
  Future<String?> _checkDnbCover(String isbn) async {
    final coverUrl = 'https://portal.dnb.de/opac/mvb/cover?isbn=$isbn';
    try {
      final response = await http
          .head(Uri.parse(coverUrl), headers: {'User-Agent': _userAgent})
          .timeout(_kTimeout);
      if (response.statusCode == 200) return coverUrl;
    } catch (_) {}
    return null;
  }
}
