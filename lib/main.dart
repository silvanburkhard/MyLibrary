import 'package:flutter/material.dart';
import 'package:my_library/pages/homepage.dart';
import 'package:my_library/pages/barcode_search_page.dart';
import 'package:my_library/pages/isbn_search_page.dart';
import 'package:my_library/pages/manual_search_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Library',
      home: Homepage(),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Color.fromARGB(255, 74, 105, 217),
          onSecondary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color.fromARGB(255, 74, 105, 217),
        ),


      ),




      routes: {
        '/homepage': (context) => Homepage(),
        '/barcodesearchpage': (context) => BarcodeSearchPage(),
        '/isbnsearchpage': (context) => IsbnSearchPage(),
        '/manualsearchpage': (context) => ManualSearchPage(),
      },
    );
  }
}
