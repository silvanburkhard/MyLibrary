import 'package:flutter/material.dart';
import 'package:my_library/models/book.dart';
import 'package:my_library/services/book_service.dart';
import 'package:my_library/widgets/book_cover_image.dart';

class IsbnSearchPage extends StatefulWidget {
  const IsbnSearchPage({super.key});

  @override
  State<IsbnSearchPage> createState() => _IsbnSearchPageState();
}

class _IsbnSearchPageState extends State<IsbnSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final _bookService = const BookService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'ISBN Suche',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: TextField(
            controller: _controller,
            maxLength: 13,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              labelText: 'ISBN',
            ),
            onSubmitted: (value) => _handleScanResult(value),
          ),
        ),
      ),
    );
  }

  void _handleScanResult(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    if (!BookService.isValidIsbn(trimmed)) {
      _showErrorDialog(
        'Die eingegebene ISBN ist ungültig. Bitte prüfe die Nummer.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final book = await _bookService.fetchBookCombined(trimmed);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (book != null) {
        _showSuccessDialog(book);
        _controller.clear();
      } else {
        _showErrorDialog('Kein Buch unter dieser ISBN gefunden.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showErrorDialog('Fehler bei der Suche: $e');
    }
  }

  void _showSuccessDialog(Book book) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: AppBar(
            title: const Text('Buch gefunden'),
            centerTitle: true,
            backgroundColor: Colors.transparent,

            actions: [IconButton(onPressed: () {}, icon: Icon(Icons.edit))],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (book.coverPath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: BookCoverImage(url: book.coverPath!, height: 180),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Icon(Icons.book, size: 80, color: Colors.blueGrey),
                ),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.author,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'ISBN: ${book.isbn}',
                style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Abbrechen',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () {
                // TODO: Speicher-Logik hier (z.B. Hive / Isar / sqflite)
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buch zur Bibliothek hinzugefügt!'),
                  ),
                );
              },
              label: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('Nicht gefunden'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
