import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'services/indexeddb_service.dart';

class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({super.key});

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  final IndexedDbService _service = IndexedDbService();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    await _service.init();
    final loadedExpenses = await _service.getAllExpenses();
    print("LoadedExpense: $loadedExpenses");
    setState(() {
      if (loadedExpenses != null) {
        _expenses = loadedExpenses;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des dépenses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text('Aucune dépense enregistrée'))
              : ListView.builder(
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    final date = DateTime.tryParse(expense['date'] ?? '') ?? DateTime.now();

                    return ListTile(
                      leading: expense['thumbnail'] != null
                          ? Image.memory(
                              base64Decode(expense['thumbnail'].split(',').last),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.receipt_long),
                      title: Text('${expense['amount']} € - ${expense['category']}'),
                      subtitle: Text('${date.day}/${date.month}/${date.year}'),
                      onTap: () async {
                        final imageId = expense['imageId'];
                        if (imageId != null) {
                          final imageBytes = await _service.getImage(imageId);
                          if (imageBytes != null) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                content: Image.memory(imageBytes),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
    );
  }
}
