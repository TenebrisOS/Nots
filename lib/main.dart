import 'package:flutter/material.dart';
import 'ui/home_screen.dart'; // Import the new home screen

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: ThemeData( // Ensure you have a theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Merriweather',
        // iconTheme: IconThemeData(color: Colors.white) // You could try explicitly setting icon color
      ),
    );
  }
}
