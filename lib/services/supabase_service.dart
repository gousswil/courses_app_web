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

}
