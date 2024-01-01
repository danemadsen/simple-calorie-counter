import 'package:simple_calorie_counter/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Metrics',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blue,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0, vertical: 15.0), // Padding inside the TextField
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(
              fontWeight: FontWeight.normal, color: Colors.grey, fontSize: 15.0),
          hintStyle: const TextStyle(
              fontWeight: FontWeight.normal, color: Colors.white, fontSize: 15.0),
          fillColor: Colors.grey.shade900,
          filled: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
      home: const HomePage(title: 'Fitness Metrics'),
    );
  }
}
