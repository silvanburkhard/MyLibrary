import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:my_library/widgets/book_cover_image.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) _searchController.clear();
              });
            },
          ),
        ],
        centerTitle: true,
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Suche nach Büchern...',
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'Meine Bücher',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ReadingBanner(theme: theme),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add_rounded,
        activeIcon: Icons.close_rounded,
        spacing: 12,
        spaceBetweenChildren: 8,
        renderOverlay: true,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner_rounded),
            label: 'Barcode scannen',
            onTap: () => Navigator.pushNamed(context, '/barcodesearchpage'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.onetwothree_rounded),
            label: 'ISBN eingeben',
            onTap: () => Navigator.pushNamed(context, '/isbnsearchpage'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit),
            label: 'Manuell hinzufügen',
            onTap: () => Navigator.pushNamed(context, '/manualsearchpage'),
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Suche'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Bücher'),
        ],
      ),
    );
  }
}

class ReadingBanner extends StatelessWidget {
  const ReadingBanner({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 15, 15, 15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Buch-Cover mit Shimmer-Ladeanimation
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Material(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8.0),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/barcodesearchpage'),
                borderRadius: BorderRadius.circular(8.0),
                child: BookCoverImage(
                  url:
                      'https://exlibris.azureedge.net/covers/9783/4534/3584/1/9783453435841xxl.webp',
                  height: 150,
                  width: 100,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          // Buch-Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                right: 16.0,
                top: 12.0,
                bottom: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Green Mile',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stephen King',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '65% gelesen',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '200/400',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Starten'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
