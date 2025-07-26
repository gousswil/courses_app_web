import 'package:flutter/material.dart';
import 'expense_form.dart'; // Assure-toi que ce fichier existe
import 'expense_history.dart'; 
import 'ocr_scan.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/supabase_auth_service.dart';
import 'pages/supabase_login_page.dart';

/* void main() => runApp(CoursesApp()); */

    void main() async {
      WidgetsFlutterBinding.ensureInitialized();
       
        // Initialiser Supabase
      await Supabase.initialize(
        url: 'https://nixuyburyjreegfnozio.supabase.co', // À remplacer
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5peHV5YnVyeWpyZWVnZm5vemlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM0ODgzNjgsImV4cCI6MjA2OTA2NDM2OH0.TLFs0V_8dYFJSNfR1q0hfDa530aALOz1i9ebOcv-des', // À remplacer
      );
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
      home: AuthGate(), /* HomePage(), */
    );
  }
}

// AuthGate - Gère le routage selon l'état d'authentification
class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _getInitialSession();
    _listenToAuthChanges();
  }

   // Récupère la session initiale
  Future<void> _getInitialSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

   void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        _session = data.session;
      });
    });
  }

   @override
  Widget build(BuildContext context) {
    // Écran de chargement pendant la vérification de session
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si session existe -> page d'accueil, sinon -> login
    return _session != null ? HomePage() : SupabaseLoginPage();
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

