
import 'package:flutter/material.dart';
import 'expense_form.dart';

void main() => runApp(CoursesApp());

class AccueilPage extends StatefulWidget {
  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Bienvenue dans Courses')),
    const Center(child: Text('Historique à venir')),
    const ExpenseFormPage(), // la page d'ajout
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
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

