import 'package:flutter/material.dart';
import 'expense_form.dart'; // Assure-toi que ce fichier existe
import 'expense_history.dart'; 

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
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    AccueilPage(),
    ExpenseHistoryPage(), // À créer si ce n’est pas encore fait
    ExpenseForm(),     // Le formulaire d'ajout
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courses'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Ajouter'),
        ],
      ),
    );
  }
}

class AccueilPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Bienvenue dans Courses'));
  }
}

class ExpenseHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Historique des dépenses'));
  }
}
