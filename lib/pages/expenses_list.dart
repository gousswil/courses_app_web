import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await _supabaseService.getExpenses();
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur de chargement des dépenses : $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des dépenses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text('Aucune dépense enregistrée.'))
              : ListView.builder(
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    final amount = expense['amount'] ?? '?';
                    final category = expense['category'] ?? '?';
                    final date = expense['date'] ?? '';
                    final imageBase64 = expense['image_base64'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: imageBase64.isNotEmpty
                            ? Image.memory(
                                UriData.parse(imageBase64).contentAsBytes(),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.receipt_long),
                        title: Text('$amount € - $category'),
                        subtitle: Text(_formatDate(date)),
                      ),
                    );
                  },
                ),
    );
  }
}
