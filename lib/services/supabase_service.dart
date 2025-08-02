import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Ajoute une dépense dans Supabase
  Future<void> addExpense(Map<String, dynamic> data, String? base64Image) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final expense = {
      'user_id': user.id,
      'amount': data['amount'],
      'category': data['category'],
      'date': data['date'],
      'image_base64': base64Image,
    };

    try{
    final response = await _client.from('expenses').insert(expense);
    
    }catch (error) {
        throw Exception('Erreur Supabase : $error');
      }

    
  }

  /// Récupère les dépenses de l'utilisateur connecté
    Future<List<Map<String, dynamic>>> getExpenses() async {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      try {
        final response = await _client
            .from('expenses')
            .select()
            .eq('user_id', user.id)
            .order('date', ascending: false);

        // response est déjà de type List<Map<String, dynamic>>
        return response;
      } catch (error) {
        throw Exception('Erreur Supabase : $error');
      }
    }

  /// Supprime une dépense de l'utilisateur connecté
  Future<void> deleteExpense(String expenseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      await _client
          .from('expenses')
          .delete()
          .eq('id', expenseId)
          .eq('user_id', user.id); // Sécurité : vérifier que c'est bien la dépense de l'utilisateur
    } catch (error) {
      throw Exception('Erreur lors de la suppression : $error');
    }
  }

  /// Met à jour une dépense de l'utilisateur connecté
  Future<void> updateExpense(String expenseId, Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      await _client
          .from('expenses')
          .update(updates)
          .eq('id', expenseId)
          .eq('user_id', user.id); // Sécurité : vérifier que c'est bien la dépense de l'utilisateur
    } catch (error) {
      throw Exception('Erreur lors de la mise à jour : $error');
    }
  }

}