import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:my_library/services/book_service.dart';
import 'package:my_library/models/book.dart';
import 'package:my_library/widgets/book_cover_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BarcodeSearchPage extends StatefulWidget {
  const BarcodeSearchPage({super.key});

  @override
  State<BarcodeSearchPage> createState() => _BarcodeSearchPageState();
}

class _BarcodeSearchPageState extends State<BarcodeSearchPage> {
  String? scannedCode;
  bool isScanCompleted = false;

  final _bookService = const BookService();

  final MobileScannerController _scannerController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleScanResult(String code) async {
    if (isScanCompleted) return;

    if (!BookService.isValidIsbn(code)) return;

    setState(() {
      isScanCompleted = true;
      scannedCode = code;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final book = await _bookService.fetchBookCombined(code);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (book != null) {
        _showSuccessDialog(book);
      } else {
        _showErrorDialog('Kein Buch mit der ISBN $code gefunden.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showErrorDialog('Fehler bei der Verbindung: $e');
    }
  }

  void _resetScanner() {
    setState(() {
      isScanCompleted = false;
      scannedCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double scanAreaWidth = 250;
    const double scanAreaHeight = 150;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Bücher hinzufügen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Taschenlampe',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && !isScanCompleted) {
                      final code = barcodes.first.rawValue;
                      if (code != null) _handleScanResult(code);
                    }
                  },
                ),

                if (!isScanCompleted)
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(150),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: scanAreaWidth,
                            height: scanAreaHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Rahmen um den Scan-Bereich
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanAreaWidth,
                    height: scanAreaHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isScanCompleted ? Colors.green : Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Optional: Anleitungstext für den User
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Book book) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('Buch gefunden', textAlign: TextAlign.center),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetScanner();
                },
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
                  _resetScanner();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Buch zur Bibliothek hinzugefügt!'),
                    ),
                  );
                },
                label: const Text('Hinzufügen'),
              ),
            ],
          ),
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
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Nicht gefunden'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
