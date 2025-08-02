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
  Map<String, List<Map<String, dynamic>>> _groupedExpenses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final expenses = await _supabaseService.getExpenses();

      // Trie par date décroissante
      expenses.sort((a, b) => b['date'].compareTo(a['date']));

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      for (final expense in expenses) {
        final date = DateTime.parse(expense['date']);
        final key = DateFormat.yMMMM('fr_FR').format(date); // "août 2025"
        grouped.putIfAbsent(key, () => []).add(expense);
      }

      setState(() {
        _groupedExpenses = grouped;
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
          : _groupedExpenses.isEmpty
              ? const Center(child: Text('Aucune dépense enregistrée.'))
              : ListView(
                  children: _groupedExpenses.entries.map((entry) {
                    final groupTitle = entry.key;
                    final expenses = entry.value;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupTitle[0].toUpperCase() + groupTitle.substring(1),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...expenses.map((expense) {
                            final amount = expense['amount'] ?? '?';
                            final category = expense['category'] ?? '?';
                            final date = expense['date'] ?? '';
                            final imageBase64 = expense['image_base64'] ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: imageBase64.isNotEmpty
                                    ? Image.memory(
                                        UriData.parse(imageBase64).contentAsBytes(),
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.receipt),
                                title: Text('$amount € - $category'),
                                subtitle: Text(_formatDate(date)),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
