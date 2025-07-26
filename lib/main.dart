import 'package:flutter/material.dart';
import 'expense_form.dart'; // Assure-toi que ce fichier existe
import 'expense_history.dart'; 
import 'ocr_scan.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';

/* void main() => runApp(CoursesApp()); */

    void main() async {
      WidgetsFlutterBinding.ensureInitialized();
       try {
          // Firebase est déjà initialisé dans index.html
          await Firebase.initializeApp();
          print("Firebase connecté avec succès");
        } catch (e) {
          print("Erreur Firebase: $e");
        }
      runApp(const CoursesApp());
  }

class CoursesApp extends StatelessWidget {
  const CoursesApp({Key? key}) : super(key: key);
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
    OcrScanPage(),
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

