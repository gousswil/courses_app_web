// lib/services/supabase_auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  SupabaseAuthService() {
    // Récupérer l'utilisateur actuel
    _user = _client.auth.currentUser;
    
    // Écouter les changements d'authentification
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;
      
      _user = user;
      notifyListeners();
      
      print('Auth event: $event, user: ${user?.email}');
    });
  }

  // Inscription avec email/password
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Erreur lors de l\'inscription');
      }

    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e.message));
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Connexion avec email/password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Erreur lors de la connexion');
      }

    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e.message));
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e.message));
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  // Gestion des erreurs Supabase
  String _handleAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    } else if (message.contains('User already registered')) {
      return 'Un compte existe déjà avec cet email';
    } else if (message.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    } else if (message.contains('Unable to validate email address')) {
      return 'Adresse email invalide';
    } else if (message.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre email avant de vous connecter';
    }
    return message;
  }
}