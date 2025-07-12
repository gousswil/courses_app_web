
import 'package:flutter/material.dart';

void main() => runApp(CoursesApp());

class CoursesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Courses',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.grey[900]!,
          secondary: Colors.blueGrey,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AccueilPage(),
    );
  }
}

class AccueilPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accueil')),
      body: Center(child: Text('Bienvenue dans Courses')),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Ajouter'),
        ],
      ),
    );
  }
}
