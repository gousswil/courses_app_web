import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';

class ExpenseHistoryPage extends StatelessWidget {
  const ExpenseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> rawExpenses =
        (html.window.localStorage['expenses'] != null)
            ? List<String>.from(json.decode(html.window.localStorage['expenses']!))
            : [];

    final List<Map<String, dynamic>> expenses = rawExpenses
        .map((e) => json.decode(e) as Map<String, dynamic>)
        .toList();

    print('Dépenses trouvées : $expenses');

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des dépenses')),
      body: expenses.isEmpty
          ? const Center(child: Text('Aucune dépense enregistrée'))
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final date = DateTime.tryParse(expense['date'] ?? '') ?? DateTime.now();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long),
                            const SizedBox(width: 8),
                            Text(
                              '${expense['amount']} € - ${expense['category']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${date.day}/${date.month}/${date.year}'),
                        if (expense['imageBase64'] != null &&
                            expense['imageBase64'].toString().isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: InteractiveViewer(
                                      child: Image.memory(
                                        base64Decode(
                                          expense['imageBase64']
                                              .toString()
                                              .split(',')
                                              .last,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.image),
                              label: const Text('Voir le ticket'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

    );
  }
}